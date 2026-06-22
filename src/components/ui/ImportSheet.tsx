import { useRef, useState } from "react";
import { BottomSheet } from "./BottomSheet";
import { Button } from "./Button";
import { Text } from "./Text";
import { Spinner } from "./Spinner";
import { anilist } from "@/lib/api/anilist/client";
import { useListStore } from "@/lib/store/listStore";
import { toast } from "@/lib/store/toastStore";
import type { AnimeListEntry } from "@/types/list";

interface Props {
  open: boolean;
  onClose: () => void;
}

type Phase = "input" | "preview" | "importing" | "done";

interface Preview {
  entries: AnimeListEntry[];
  counts: Record<string, number>;
  userName: string;
}

const STATUS_LABELS: Record<string, string> = {
  watching: "Watching",
  completed: "Completed",
  plan_to_watch: "Plan to Watch",
  on_hold: "On Hold",
  dropped: "Dropped",
  rewatching: "Rewatching",
};

export function ImportSheet({ open, onClose }: Props) {
  const [phase, setPhase] = useState<Phase>("input");
  const [userName, setUserName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [preview, setPreview] = useState<Preview | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const importEntries = useListStore((s) => s.importEntries);

  const reset = () => {
    setPhase("input");
    setUserName("");
    setError(null);
    setPreview(null);
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const fetchList = async () => {
    const name = userName.trim();
    if (!name) return;
    setError(null);
    setPhase("preview");
    try {
      const entries = await anilist.importUserList(name);
      if (entries.length === 0) {
        setError("That list is empty or not public.");
        setPhase("input");
        return;
      }
      const counts: Record<string, number> = {};
      for (const e of entries) {
        counts[e.status] = (counts[e.status] ?? 0) + 1;
      }
      setPreview({ entries, counts, userName: name });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to fetch list.");
      setPhase("input");
    }
  };

  const doImport = async () => {
    if (!preview) return;
    setPhase("importing");
    try {
      const count = await importEntries(preview.entries);
      toast.success(`Imported ${count} anime from ${preview.userName}`);
      handleClose();
    } catch {
      toast.error("Import failed — please try again.");
      setPhase("preview");
    }
  };

  return (
    <BottomSheet open={open} onClose={handleClose} title="Import from AniList">
      <div className="k-import">
        {phase === "input" && (
          <>
            <Text size="sm" color="secondary">
              Enter an AniList username to import their public anime list. Existing
              entries are merged — your progress and notes are never overwritten.
            </Text>
            <div className="k-import__row">
              <input
                ref={inputRef}
                className="k-input"
                type="text"
                placeholder="AniList username"
                value={userName}
                autoComplete="off"
                autoCapitalize="off"
                spellCheck={false}
                onChange={(e) => setUserName(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && void fetchList()}
              />
              <Button
                variant="primary"
                onClick={() => void fetchList()}
                disabled={!userName.trim()}
              >
                Fetch
              </Button>
            </div>
            {error && (
              <p style={{ color: "var(--color-error)", fontSize: "var(--text-sm)" }}>
                {error}
              </p>
            )}
          </>
        )}

        {phase === "preview" && !preview && (
          <div className="k-import__loading">
            <Spinner size={24} />
            <Text size="sm" color="secondary">
              Fetching list…
            </Text>
          </div>
        )}

        {phase === "preview" && preview && (
          <>
            <Text size="sm" color="secondary">
              Found <strong>{preview.entries.length} anime</strong> from{" "}
              <strong>{preview.userName}</strong>:
            </Text>
            <div className="k-import__counts">
              {Object.entries(preview.counts).map(([status, n]) => (
                <div key={status} className="k-import__count">
                  <Text size="sm" weight={600}>
                    {n}
                  </Text>
                  <Text size="xs" color="tertiary">
                    {STATUS_LABELS[status] ?? status}
                  </Text>
                </div>
              ))}
            </div>
            <Text size="xs" color="tertiary">
              Entries already in your list will be merged — your score, notes, and
              progress are never replaced.
            </Text>
            <div className="k-import__actions">
              <Button variant="ghost" onClick={reset}>
                Back
              </Button>
              <Button variant="primary" onClick={() => void doImport()}>
                Import all
              </Button>
            </div>
          </>
        )}

        {phase === "importing" && (
          <div className="k-import__loading">
            <Spinner size={24} />
            <Text size="sm" color="secondary">
              Importing…
            </Text>
          </div>
        )}
      </div>
    </BottomSheet>
  );
}
