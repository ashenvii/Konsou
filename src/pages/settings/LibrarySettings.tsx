import { useRef, useState } from "react";
import { Trash2 } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { ConfirmSheet } from "@/components/ui/ConfirmSheet";
import { Icon } from "@/components/ui/Icon";
import { ImportSheet } from "@/components/ui/ImportSheet";
import { Section, Row, SettingsSubPage } from "@/components/settings/parts";
import { syncManager } from "@/lib/sync/syncManager";
import { toast } from "@/lib/store/toastStore";
import { useAuthStore } from "@/lib/store/authStore";
import { useListStore } from "@/lib/store/listStore";

export function LibrarySettings() {
  const account = useAuthStore((s) => s.account);
  const clearAll = useListStore((s) => s.clearAll);
  const entryCount = useListStore((s) => s.entries.length);
  const [importOpen, setImportOpen] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const restoreRef = useRef<HTMLInputElement>(null);

  // Restore a Konsou JSON export (the exact file "Export list" produces).
  // Merged through the same path as any other import, so existing progress
  // is never clobbered.
  const restoreBackup = async (file: File | undefined) => {
    if (!file) return;
    try {
      const parsed: unknown = JSON.parse(await file.text());
      if (!Array.isArray(parsed)) throw new Error("not a list");
      const entries = parsed.filter(
        (e): e is (typeof parsed)[number] & {
          anilist_id: number;
          title_romaji: string;
          status: string;
        } =>
          !!e &&
          typeof e === "object" &&
          typeof (e as { anilist_id?: unknown }).anilist_id === "number" &&
          typeof (e as { title_romaji?: unknown }).title_romaji === "string" &&
          typeof (e as { status?: unknown }).status === "string",
      );
      if (entries.length === 0) throw new Error("no entries");
      const count = await useListStore.getState().importEntries(entries);
      toast.success(`Restored ${count} anime from backup`);
    } catch {
      toast.error("That file doesn't look like a Konsou export");
    } finally {
      if (restoreRef.current) restoreRef.current.value = "";
    }
  };

  const exportJson = () => {
    const entries = useListStore.getState().entries;
    const blob = new Blob([JSON.stringify(entries, null, 2)], { type: "application/json" });
    const filename = `konsou-list-${new Date().toISOString().slice(0, 10)}.json`;
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
    toast.success(`Saved "${filename}" to your Downloads folder`);
  };

  const syncNow = async () => {
    setSyncing(true);
    try {
      await syncManager.pushNow();
      toast.success("List backed up to Google Drive");
    } catch {
      toast.error("Couldn't sync right now. Check your connection and try again");
    }
    setSyncing(false);
  };

  return (
    <SettingsSubPage title="Library & Sync">
      <Section title="Sync">
        {account ? (
          <Row label="Backup" hint={`Synced to Google Drive as ${account.email}`}>
            <Button variant="secondary" onClick={() => void syncNow()} disabled={syncing}>
              {syncing ? "Syncing…" : "Sync now"}
            </Button>
          </Row>
        ) : (
          <Row
            label="Backup"
            hint="Sign in on the Account page to back up and sync your list across devices."
          />
        )}
      </Section>

      <Section title="Your data">
        <Row label="Export list" hint="Download your list as JSON">
          <Button variant="secondary" onClick={exportJson}>
            Export
          </Button>
        </Row>
        <Row
          label="Import list"
          hint="From an AniList username or a MyAnimeList export; merges into what's here"
        >
          <Button variant="secondary" onClick={() => setImportOpen(true)}>
            Import
          </Button>
        </Row>
        <Row label="Restore backup" hint="Load a Konsou JSON export">
          <input
            ref={restoreRef}
            type="file"
            accept="application/json,.json"
            hidden
            onChange={(e) => void restoreBackup(e.target.files?.[0])}
          />
          <Button variant="secondary" onClick={() => restoreRef.current?.click()}>
            Restore
          </Button>
        </Row>
        <Row
          label={account ? "Clear synced list" : "Clear local list"}
          hint={
            account
              ? "Erases every entry here and on Google Drive"
              : "Erases every entry stored on this device"
          }
        >
          <Button variant="danger" disabled={entryCount === 0} onClick={() => setConfirmClear(true)}>
            <Icon icon={Trash2} size={15} /> Clear
          </Button>
        </Row>
      </Section>

      <ImportSheet open={importOpen} onClose={() => setImportOpen(false)} />

      <ConfirmSheet
        open={confirmClear}
        onClose={() => setConfirmClear(false)}
        icon={Trash2}
        danger
        title={account ? "Clear synced list?" : "Clear local list?"}
        message={
          account
            ? `This permanently removes all ${entryCount} ${entryCount === 1 ? "entry" : "entries"} from this device and your Google Drive. This can't be undone.`
            : `This permanently removes all ${entryCount} ${entryCount === 1 ? "entry" : "entries"} stored on this device. This can't be undone.`
        }
        confirmLabel="Clear everything"
        onConfirm={() => {
          void clearAll({ propagateToDrive: !!account });
          toast.show(account ? "List cleared everywhere" : "Local list cleared");
        }}
      />
    </SettingsSubPage>
  );
}
