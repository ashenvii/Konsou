import { useRef, useState } from "react";
import { BottomSheet } from "./BottomSheet";
import { Button } from "./Button";
import { Text } from "./Text";
import { Spinner } from "./Spinner";
import { anilist } from "@/lib/api/anilist/client";
import { parseMalExport, readMalFile } from "@/lib/api/mal/parseExport";
import { useListStore } from "@/lib/store/listStore";
import { toast } from "@/lib/store/toastStore";
import type { AnimeListEntry } from "@/types/list";

interface Props {
  open: boolean;
  onClose: () => void;
}

type Source = "anilist" | "mal";
type Phase = "input" | "preview" | "importing";

interface Preview {
  entries: AnimeListEntry[];
  counts: Record<string, number>;
  /** MAL titles that couldn't be matched to AniList (empty for AniList imports). */
  unmatched: { mal_id: number; title: string }[];
  total: number;
  label: string;
}

const STATUS_LABELS: Record<string, string> = {
  watching: "Watching",
  completed: "Completed",
  plan_to_watch: "Plan to Watch",
  on_hold: "On Hold",
  dropped: "Dropped",
  rewatching: "Rewatching",
};

function countByStatus(entries: AnimeListEntry[]): Record<string, number> {
  const c: Record<string, number> = {};
  for (const e of entries) c[e.status] = (c[e.status] ?? 0) + 1;
  return c;
}

export function ImportSheet({ open, onClose }: Props) {
  const [source, setSource] = useState<Source>("anilist");
  const [phase, setPhase] = useState<Phase>("input");
  const [userName, setUserName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loadingMsg, setLoadingMsg] = useState("Fetching list…");
  const [preview, setPreview] = useState<Preview | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const importEntries = useListStore((s) => s.importEntries);

  const reset = () => {
    setPhase("input");
    setUserName("");
    setError(null);
    setPreview(null);
  };

  const handleClose = () => {
    reset();
    setSource("anilist");
    onClose();
  };

  // ── AniList: by username ───────────────────────────────────
  const fetchAniList = async () => {
    const name = userName.trim();
    if (!name) return;
    setError(null);
    setLoadingMsg("Fetching list…");
    setPhase("preview");
    try {
      const entries = await anilist.importUserList(name);
      if (entries.length === 0) {
        setError("That list is empty or not public.");
        setPhase("input");
        return;
      }
      setPreview({
        entries,
        counts: countByStatus(entries),
        unmatched: [],
        total: entries.length,
        label: `@${name}`,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to fetch list.");
      setPhase("input");
    }
  };

  // ── MyAnimeList: from export file ──────────────────────────
  const onPickFile = async (file: File | undefined) => {
    if (!file) return;
    setError(null);
    setLoadingMsg("Matching your list to AniList…");
    setPhase("preview");
    try {
      const raw = parseMalExport(await readMalFile(file));
      if (raw.length === 0) {
        setError("No anime found in that export file.");
        setPhase("input");
        return;
      }
      const { entries, unmatched, total } = await anilist.resolveMalEntries(raw);
      setPreview({
        entries,
        counts: countByStatus(entries),
        unmatched,
        total,
        label: file.name,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldn't read that file.");
      setPhase("input");
    }
  };

  const doImport = async () => {
    if (!preview) return;
    setPhase("importing");
    try {
      const count = await importEntries(preview.entries);
      toast.success(`Imported ${count} anime`);
      handleClose();
    } catch {
      toast.error("Import failed — please try again.");
      setPhase("preview");
    }
  };

  const copyUnmatched = () => {
    if (!preview?.unmatched.length) return;
    void navigator.clipboard
      ?.writeText(preview.unmatched.map((u) => u.title).join("\n"))
      .then(() => toast.success("Copied unmatched titles"));
  };

  return (
    <BottomSheet open={open} onClose={handleClose} title="Import your list">
      <div className="k-import">
        {phase === "input" && (
          <>
            <div className="k-segmented">
              <button
                className={`k-segmented__btn${source === "anilist" ? " k-segmented__btn--active" : ""}`}
                onClick={() => { setSource("anilist"); setError(null); }}
              >
                AniList
              </button>
              <button
                className={`k-segmented__btn${source === "mal" ? " k-segmented__btn--active" : ""}`}
                onClick={() => { setSource("mal"); setError(null); }}
              >
                MyAnimeList
              </button>
            </div>

            {source === "anilist" ? (
              <>
                <Text size="sm" color="secondary">
                  Enter an AniList username to import their public list. Existing
                  entries are merged — your progress and notes are never replaced.
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
                    onKeyDown={(e) => e.key === "Enter" && void fetchAniList()}
                  />
                  <Button
                    variant="primary"
                    onClick={() => void fetchAniList()}
                    disabled={!userName.trim()}
                  >
                    Fetch
                  </Button>
                </div>
              </>
            ) : (
              <>
                <Text size="sm" color="secondary">
                  Import from a MyAnimeList export file. On MAL: your profile →
                  Settings → <strong>Export</strong> → download the anime list,
                  then choose the <code>.xml.gz</code> (or <code>.xml</code>) here.
                </Text>
                <input
                  ref={fileRef}
                  type="file"
                  accept=".xml,.gz,application/gzip,text/xml"
                  style={{ display: "none" }}
                  onChange={(e) => void onPickFile(e.target.files?.[0])}
                />
                <Button variant="primary" onClick={() => fileRef.current?.click()}>
                  Choose export file…
                </Button>
                <Text size="xs" color="tertiary">
                  We match every title to AniList by ID, then by name. The handful
                  that can't be matched are listed so you can add them manually.
                </Text>
              </>
            )}

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
            <Text size="sm" color="secondary">{loadingMsg}</Text>
          </div>
        )}

        {phase === "preview" && preview && (
          <>
            <Text size="sm" color="secondary">
              Matched <strong>{preview.entries.length}</strong>
              {preview.total !== preview.entries.length && <> of {preview.total}</>}{" "}
              anime from <strong>{preview.label}</strong>:
            </Text>
            <div className="k-import__counts">
              {Object.entries(preview.counts).map(([status, n]) => (
                <div key={status} className="k-import__count">
                  <Text size="sm" weight={600}>{n}</Text>
                  <Text size="xs" color="tertiary">
                    {STATUS_LABELS[status] ?? status}
                  </Text>
                </div>
              ))}
            </div>

            {preview.unmatched.length > 0 && (
              <div className="k-import__unmatched">
                <div className="k-import__unmatched-head">
                  <Text size="sm" weight={600}>
                    {preview.unmatched.length} couldn’t be matched
                  </Text>
                  <button className="k-import__copy" onClick={copyUnmatched}>
                    Copy
                  </button>
                </div>
                <Text size="xs" color="tertiary">
                  These have no AniList entry under the same ID or title — normal
                  for some specials/OVAs and cross-site naming differences. Add them
                  manually via Search.
                </Text>
                <ul className="k-import__unmatched-list konsou-scroll">
                  {preview.unmatched.map((u) => (
                    <li key={u.mal_id}>{u.title}</li>
                  ))}
                </ul>
              </div>
            )}

            <Text size="xs" color="tertiary">
              Entries already in your list are merged — your score, notes, and
              progress are never replaced.
            </Text>
            <div className="k-import__actions">
              <Button variant="ghost" onClick={reset}>Back</Button>
              <Button
                variant="primary"
                onClick={() => void doImport()}
                disabled={preview.entries.length === 0}
              >
                Import {preview.entries.length}
              </Button>
            </div>
          </>
        )}

        {phase === "importing" && (
          <div className="k-import__loading">
            <Spinner size={24} />
            <Text size="sm" color="secondary">Importing…</Text>
          </div>
        )}
      </div>
    </BottomSheet>
  );
}
