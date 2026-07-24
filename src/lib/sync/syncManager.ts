/**
 * Drive sync orchestrator. Owns the pull/push cycle; never blocks the UI:
 * failures are logged and silently retried on the next cycle.
 *
 * Pull flow: read Drive meta.json → compare sync_version → if Drive is newer,
 *   fetch list.json, merge with local DB, write merged result back.
 * Push flow: serialize local list → upload list.json → bump meta.json sync_version.
 *
 * The merger (src/lib/sync/merger.ts) handles field-level conflict resolution
 * with clock-skew tolerance; this file only orchestrates the I/O.
 */
import { isEnabled } from "@/lib/features";
import { getDb } from "@/lib/db";
import { getDeviceId } from "@/lib/platform";
import { APP_VERSION } from "@/lib/version";
import { loadTokens } from "@/lib/auth/tokenStore";
import {
  driveRead,
  driveWrite,
  driveReadMeta,
  DriveAuthError,
  type DriveListFile,
} from "@/lib/drive/client";
import { mergeLists } from "./merger";
import type { DriveMeta } from "@/types/sync";
import type { AnimeListEntry, DeletionTombstone } from "@/types/list";

/** How a sign-in conflict (data on both sides) is resolved. */
export type ReconcileStrategy = "merge" | "use_drive" | "use_local";

/** Outcome of the sign-in sync probe; see {@link SyncManager.signInSync}. */
export interface SignInSyncResult {
  /** True when both sides held data and the user must choose how to reconcile. */
  promptNeeded: boolean;
  localCount: number;
  remoteCount: number;
}

export type SyncLogLevel = "info" | "warn" | "error";
export interface SyncLogEntry {
  at: number;
  level: SyncLogLevel;
  msg: string;
}

/** What a Merge would produce, shown to the user before they commit to it. */
export interface MergePreview {
  /** Titles that end up on the list after merging. */
  total: number;
  /** Only in the Drive backup (arrive on this device). */
  driveOnly: number;
  /** Only on this device (get pushed up to Drive). */
  localOnly: number;
  /** On both sides (reconciled field by field). */
  shared: number;
  /** Dropped because a deletion on one side is newer than the edit on the other. */
  removed: number;
}

const LOG_KEY = "konsou.sync.log";
const LOG_LIMIT = 50;

class SyncManager {
  private log: SyncLogEntry[] = this.loadLog();

  /** The log outlives a reload so the history screen isn't wiped every launch. */
  private loadLog(): SyncLogEntry[] {
    try {
      const raw = localStorage.getItem(LOG_KEY);
      const parsed: unknown = raw ? JSON.parse(raw) : [];
      return Array.isArray(parsed) ? (parsed as SyncLogEntry[]) : [];
    } catch {
      return [];
    }
  }

  private record(level: SyncLogLevel, msg: string): void {
    this.log.push({ at: Date.now(), level, msg });
    if (this.log.length > LOG_LIMIT) this.log.shift();
    if (level === "error") console.warn(`[sync] ${msg}`);
    try {
      localStorage.setItem(LOG_KEY, JSON.stringify(this.log));
    } catch {
      // Storage full or unavailable: the in-memory log still works this session.
    }
  }

  /** Last 50 sync events, newest last. Surfaced on the Sync History screen. */
  getDebugLog(): readonly SyncLogEntry[] {
    return this.log;
  }

  /** Wipe the recorded history (a user action from the Sync History screen). */
  clearLog(): void {
    this.log = [];
    try {
      localStorage.removeItem(LOG_KEY);
    } catch {
      // Nothing to do — the in-memory copy is already cleared.
    }
  }

  /**
   * Compute — without changing anything — what a Merge of this device and the
   * Drive backup would produce, so the reconcile prompt can show the outcome
   * before the user commits. Runs the real {@link mergeLists}, so the preview
   * can't drift from what Merge actually does. Returns null when sync is off,
   * signed out, or Drive can't be reached (the prompt falls back to plain counts).
   */
  async previewMerge(): Promise<MergePreview | null> {
    if (!this.enabled || !this.isSignedIn) return null;
    try {
      const db = await getDb();
      const localEntries = await db.listAll();
      const localTombstones = await db.tombstonesAll();

      const remoteMeta = await driveReadMeta();
      const remoteFile = remoteMeta
        ? await driveRead<DriveListFile>("list.json")
        : null;
      const remoteEntries = remoteFile?.entries ?? [];
      const remoteTombstones = remoteFile?.tombstones ?? [];

      const localIds = new Set(localEntries.map((e) => e.anilist_id));
      const remoteIds = new Set(remoteEntries.map((e) => e.anilist_id));
      const { entries } = mergeLists(
        localEntries,
        remoteEntries,
        localTombstones,
        remoteTombstones,
      );

      let driveOnly = 0;
      let localOnly = 0;
      let shared = 0;
      for (const id of new Set([...localIds, ...remoteIds])) {
        const inLocal = localIds.has(id);
        const inRemote = remoteIds.has(id);
        if (inLocal && inRemote) shared++;
        else if (inRemote) driveOnly++;
        else localOnly++;
      }
      const union = new Set([...localIds, ...remoteIds]).size;

      return {
        total: entries.length,
        driveOnly,
        localOnly,
        shared,
        removed: Math.max(0, union - entries.length),
      };
    } catch (e) {
      this.record(
        "warn",
        `previewMerge: ${e instanceof Error ? e.message : String(e)}`,
      );
      return null;
    }
  }

  get enabled(): boolean {
    return isEnabled("DRIVE_SYNC");
  }

  private get isSignedIn(): boolean {
    return !!loadTokens();
  }

  /**
   * Pull latest from Drive and merge. Called on launch, on sign-in, and every
   * time the window regains focus. If Drive is ahead, merges and immediately
   * pushes the merged result back.
   *
   * Returns `true` when local data changed as a result of the pull, so callers
   * can refresh the in-memory list store (the DB is updated directly here; the
   * UI store does not observe those writes on its own).
   */
  async checkForUpdates(): Promise<boolean> {
    if (!this.enabled || !this.isSignedIn) return false;

    try {
      const remoteMeta = await driveReadMeta();

      if (!remoteMeta) {
        // First time syncing from this account, just push.
        this.record("info", "checkForUpdates: no remote data, pushing initial copy");
        await this._push();
        return false;
      }

      const db = await getDb();
      const settings = await db.settingsGetAll();
      const localVersion = parseInt(settings["sync.version"] ?? "0", 10);

      if (remoteMeta.sync_version <= localVersion) {
        this.record("info", `checkForUpdates: local (v${localVersion}) is current`);
        return false;
      }

      this.record(
        "info",
        `checkForUpdates: remote v${remoteMeta.sync_version} > local v${localVersion}, pulling`,
      );

      const remoteFile = await driveRead<DriveListFile>("list.json");
      let changed = false;
      if (remoteFile?.entries) {
        const n = await this._applyMerge(
          remoteFile.entries,
          remoteFile.tombstones ?? [],
        );
        changed = true;
        this.record(
          "info",
          `checkForUpdates: merged → ${n.entries} entries, ${n.tombstones} tombstones`,
        );
      }

      // Adopt Drive's version before pushing so our follow-up push supersedes
      // the remote state (remote+1) instead of regressing sync_version back to
      // localVersion+1, which would strand any device that is further ahead.
      await db.settingsSet("sync.version", String(remoteMeta.sync_version));

      // Push the merged result so all devices converge to the same state.
      await this._push();
      return changed;
    } catch (e) {
      if (e instanceof DriveAuthError) {
        this.record("error", `checkForUpdates: auth expired: ${e.message}`);
      } else {
        this.record(
          "error",
          `checkForUpdates: ${e instanceof Error ? e.message : String(e)}`,
        );
      }
      return false;
    }
  }

  /**
   * Serialize and upload the local list. Called automatically after every
   * list mutation (debounced via SyncQueue).
   */
  async pushNow(): Promise<void> {
    if (!this.enabled || !this.isSignedIn) return;
    try {
      await this._push();
    } catch (e) {
      if (e instanceof DriveAuthError) {
        this.record("error", `pushNow: auth expired: ${e.message}`);
      } else {
        this.record(
          "error",
          `pushNow: ${e instanceof Error ? e.message : String(e)}`,
        );
      }
    }
  }

  /**
   * Merge remote data into the local DB: upsert surviving entries, delete the
   * ones a tombstone now wins over, and replace the local tombstone set with the
   * merged result. Returns the post-merge counts. Pure DB I/O, no network.
   */
  /**
   * Run once right after sign-in (including re-login). Probes Drive and local:
   *  - both sides hold data → returns `promptNeeded: true`; the caller shows the
   *    merge/use-drive/use-local prompt and later calls {@link reconcile}.
   *  - otherwise the safe action is unambiguous and applied immediately (pull
   *    Drive when local is empty, push local otherwise).
   * Drive errors are swallowed; the background pull retries on focus.
   */
  async signInSync(): Promise<SignInSyncResult> {
    const empty: SignInSyncResult = {
      promptNeeded: false,
      localCount: 0,
      remoteCount: 0,
    };
    if (!this.enabled || !this.isSignedIn) return empty;

    try {
      const db = await getDb();
      const localCount = (await db.listAll()).length;

      let remoteCount = 0;
      const remoteMeta = await driveReadMeta();
      if (remoteMeta) {
        const remoteFile = await driveRead<DriveListFile>("list.json");
        remoteCount = remoteFile?.entries?.length ?? 0;
      }

      if (localCount > 0 && remoteCount > 0) {
        this.record(
          "info",
          `signInSync: conflict, local ${localCount} vs remote ${remoteCount}, prompting`,
        );
        return { promptNeeded: true, localCount, remoteCount };
      }

      // Unambiguous: take whichever side has data (or no-op if both empty).
      await this.reconcile(remoteCount > 0 ? "use_drive" : "use_local");
      return { promptNeeded: false, localCount, remoteCount };
    } catch (e) {
      this.record(
        "error",
        `signInSync: ${e instanceof Error ? e.message : String(e)}`,
      );
      return empty;
    }
  }

  /**
   * Apply the user's chosen resolution for a sign-in conflict.
   *  - `merge`     → union both sides (tombstone-aware), then push.
   *  - `use_drive` → replace local with Drive's copy (adopt its version).
   *  - `use_local` → overwrite Drive with the local copy.
   */
  async reconcile(strategy: ReconcileStrategy): Promise<void> {
    const db = await getDb();
    const remoteMeta = await driveReadMeta();
    const remoteVersion = remoteMeta?.sync_version ?? 0;

    if (strategy === "use_drive") {
      const remoteFile = remoteMeta
        ? await driveRead<DriveListFile>("list.json")
        : null;
      await db.listReplaceAll(remoteFile?.entries ?? []);
      await db.tombstonesReplaceAll(remoteFile?.tombstones ?? []);
      await db.settingsSet("sync.version", String(remoteVersion));
      this.record(
        "info",
        `reconcile(use_drive): replaced local with ${remoteFile?.entries?.length ?? 0} remote entries`,
      );
      return;
    }

    if (strategy === "use_local") {
      // Match Drive's version so _push supersedes it (remoteVersion + 1).
      await db.settingsSet("sync.version", String(remoteVersion));
      await this._push();
      this.record("info", "reconcile(use_local): overwrote Drive with local list");
      return;
    }

    // merge. A failed Drive read now throws (see drive/client.ts) rather than
    // returning null, so we never silently merge against an empty remote and
    // overwrite Drive with local-only data.
    const remoteFile = remoteMeta
      ? await driveRead<DriveListFile>("list.json")
      : null;
    const remotePulled = remoteFile?.entries?.length ?? 0;
    const n = await this._applyMerge(
      remoteFile?.entries ?? [],
      remoteFile?.tombstones ?? [],
    );
    await db.settingsSet("sync.version", String(remoteVersion));
    await this._push();
    this.record(
      "info",
      `reconcile(merge): pulled ${remotePulled} from Drive → ${n.entries} entries, ${n.tombstones} tombstones`,
    );
  }

  private async _applyMerge(
    remoteEntries: AnimeListEntry[],
    remoteTombstones: DeletionTombstone[],
  ): Promise<{ entries: number; tombstones: number }> {
    const db = await getDb();
    const localEntries = await db.listAll();
    const localTombstones = await db.tombstonesAll();
    const { entries, tombstones } = mergeLists(
      localEntries,
      remoteEntries,
      localTombstones,
      remoteTombstones,
    );
    for (const entry of entries) await db.listUpsert(entry);
    // Drop any local row a tombstone now wins over.
    for (const t of tombstones) await db.listRemove(t.anilist_id);
    await db.tombstonesReplaceAll(tombstones);
    return { entries: entries.length, tombstones: tombstones.length };
  }

  private async _push(): Promise<void> {
    const db = await getDb();
    const entries = await db.listAll();
    const tombstones = await db.tombstonesAll();
    const settings = await db.settingsGetAll();
    const currentVersion = parseInt(settings["sync.version"] ?? "0", 10);
    const newVersion = currentVersion + 1;

    const listFile: DriveListFile = {
      version: 1,
      entries,
      tombstones,
      exported_at: Date.now(),
    };

    await driveWrite("list.json", listFile);

    const meta: DriveMeta = {
      sync_version: newVersion,
      last_device_id: getDeviceId(),
      last_sync_at: Date.now(),
      app_version: APP_VERSION,
    };
    await driveWrite("meta.json", meta);

    await db.settingsSet("sync.version", String(newVersion));
    await db.settingsSet("sync.last_at", String(Date.now()));

    this.record(
      "info",
      `push: ${entries.length} entries → Drive v${newVersion}`,
    );
  }
}

export const syncManager = new SyncManager();
