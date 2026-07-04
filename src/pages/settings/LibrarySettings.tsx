import { useState } from "react";
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
        <Row label="Import from AniList" hint="Merge any public AniList into your list">
          <Button variant="secondary" onClick={() => setImportOpen(true)}>
            Import
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
