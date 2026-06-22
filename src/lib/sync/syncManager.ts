/**
 * Drive sync orchestrator. Owns the pull/push cycle; never blocks the UI —
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

type LogLevel = "info" | "warn" | "error";
interface LogEntry {
  at: number;
  level: LogLevel;
  msg: string;
}

class SyncManager {
  private log: LogEntry[] = [];

  private record(level: LogLevel, msg: string): void {
    this.log.push({ at: Date.now(), level, msg });
    if (this.log.length > 50) this.log.shift();
    if (level === "error") console.warn(`[sync] ${msg}`);
  }

  /** Last 50 sync events — surfaced in Settings dev mode. */
  getDebugLog(): readonly LogEntry[] {
    return this.log;
  }

  get enabled(): boolean {
    return isEnabled("DRIVE_SYNC");
  }

  private get isSignedIn(): boolean {
    return !!loadTokens();
  }

  /**
   * Pull latest from Drive and merge. Called on launch and every 6 hours while open.
   * If Drive is ahead, merges and immediately pushes the merged result back.
   */
  async checkForUpdates(): Promise<void> {
    if (!this.enabled || !this.isSignedIn) return;

    try {
      const remoteMeta = await driveReadMeta();

      if (!remoteMeta) {
        // First time syncing from this account — just push.
        this.record("info", "checkForUpdates: no remote data, pushing initial copy");
        await this._push();
        return;
      }

      const db = await getDb();
      const settings = await db.settingsGetAll();
      const localVersion = parseInt(settings["sync.version"] ?? "0", 10);

      if (remoteMeta.sync_version <= localVersion) {
        this.record("info", `checkForUpdates: local (v${localVersion}) is current`);
        return;
      }

      this.record(
        "info",
        `checkForUpdates: remote v${remoteMeta.sync_version} > local v${localVersion}, pulling`,
      );

      const remoteFile = await driveRead<DriveListFile>("list.json");
      if (remoteFile?.entries) {
        const localEntries = await db.listAll();
        const merged = mergeLists(localEntries, remoteFile.entries);
        for (const entry of merged) {
          await db.listUpsert(entry);
        }
        this.record(
          "info",
          `checkForUpdates: merged ${merged.length} entries (local ${localEntries.length} + remote ${remoteFile.entries.length})`,
        );
      }

      // Push the merged result so all devices converge to the same state.
      await this._push();
    } catch (e) {
      if (e instanceof DriveAuthError) {
        this.record("error", `checkForUpdates: auth expired — ${e.message}`);
      } else {
        this.record(
          "error",
          `checkForUpdates: ${e instanceof Error ? e.message : String(e)}`,
        );
      }
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
        this.record("error", `pushNow: auth expired — ${e.message}`);
      } else {
        this.record(
          "error",
          `pushNow: ${e instanceof Error ? e.message : String(e)}`,
        );
      }
    }
  }

  private async _push(): Promise<void> {
    const db = await getDb();
    const entries = await db.listAll();
    const settings = await db.settingsGetAll();
    const currentVersion = parseInt(settings["sync.version"] ?? "0", 10);
    const newVersion = currentVersion + 1;

    const listFile: DriveListFile = {
      version: 1,
      entries,
      exported_at: Date.now(),
    };

    await driveWrite("list.json", listFile);

    const meta: DriveMeta = {
      sync_version: newVersion,
      last_device_id: getDeviceId(),
      last_sync_at: Date.now(),
      app_version: "0.1.0",
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
