import { useState } from "react";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Text } from "@/components/ui/Text";
import { Section, SettingsSubPage } from "@/components/settings/parts";
import { syncManager, type SyncLogEntry } from "@/lib/sync/syncManager";
import { RefreshCw } from "lucide-react";

/** Dot color per log level, so a run of successful syncs and a failure read at a
 *  glance without leaning on the words. */
const LEVEL_COLOR: Record<SyncLogEntry["level"], string> = {
  info: "var(--color-success, #4ade80)",
  warn: "var(--color-warning, #fbbf24)",
  error: "var(--color-danger, #f87171)",
};

function formatWhen(at: number): string {
  const d = new Date(at);
  const today = new Date();
  const sameDay = d.toDateString() === today.toDateString();
  const time = d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  return sameDay ? time : `${d.toLocaleDateString([], { month: "short", day: "numeric" })}, ${time}`;
}

/**
 * The sync log, oldest at the bottom. Every pull, push, merge and failure the
 * sync manager recorded is here, so a user can see what Konsou did with their
 * data and when — the transparency half of a local-first app you trust with
 * your list. The log persists across launches (localStorage) and holds the last
 * 50 events.
 */
export function SyncHistory() {
  // Snapshot on mount; the log is a plain array, not a store. Reversed so the
  // newest event is at the top where the eye lands first.
  const [entries, setEntries] = useState<SyncLogEntry[]>(() =>
    [...syncManager.getDebugLog()].reverse(),
  );

  const refresh = () => setEntries([...syncManager.getDebugLog()].reverse());
  const clear = () => {
    syncManager.clearLog();
    setEntries([]);
  };

  return (
    <SettingsSubPage title="Sync history" subtitle="What Konsou synced, and when">
      <Section>
        {entries.length === 0 ? (
          <EmptyState
            icon={RefreshCw}
            title="No sync activity yet"
            subtitle="Once your list backs up to Google Drive, every pull, push and merge shows up here."
          />
        ) : (
          <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {entries.map((e, i) => (
              <li
                key={`${e.at}-${i}`}
                style={{
                  display: "flex",
                  gap: "var(--space-3, 12px)",
                  alignItems: "flex-start",
                  padding: "var(--space-3, 12px) 0",
                  borderTop: i === 0 ? "none" : "1px solid var(--color-border, rgba(255,255,255,0.08))",
                }}
              >
                <span
                  aria-hidden
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: "50%",
                    marginTop: 6,
                    flexShrink: 0,
                    background: LEVEL_COLOR[e.level],
                  }}
                />
                <span style={{ flex: 1, minWidth: 0 }}>
                  <Text size="sm">{e.msg}</Text>
                  <Text size="xs" color="tertiary">
                    {formatWhen(e.at)}
                    {e.level !== "info" && ` · ${e.level}`}
                  </Text>
                </span>
              </li>
            ))}
          </ul>
        )}
      </Section>

      {entries.length > 0 && (
        <Section>
          <div style={{ display: "flex", gap: "var(--space-2, 8px)" }}>
            <Button variant="secondary" onClick={refresh}>
              Refresh
            </Button>
            <Button variant="ghost" onClick={clear}>
              Clear history
            </Button>
          </div>
        </Section>
      )}
    </SettingsSubPage>
  );
}
