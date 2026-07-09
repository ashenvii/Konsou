import { useEffect, useState } from "react";
import type { ReactNode } from "react";
import { ChevronDown } from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { formatLabel } from "@/lib/format";
import type { CountryCode } from "@/lib/api/anilist/client";
import type { AniListMediaStatus, MediaFormat } from "@/types/anime";

/** Everything the Discover panel can narrow on. Kept flat and serializable so
 *  it round-trips through session uiState untouched. */
export interface DiscoverFilters {
  genres: string[];
  themes: string[];
  formats: MediaFormat[];
  status: AniListMediaStatus | null;
  country: CountryCode | null;
  yearFrom: number | null;
  yearTo: number | null;
}

export const EMPTY_FILTERS: DiscoverFilters = {
  genres: [],
  themes: [],
  formats: [],
  status: null,
  country: null,
  yearFrom: null,
  yearTo: null,
};

/** How many filters are set; drives the count badge on the Filters button. */
export function countActiveFilters(f: DiscoverFilters): number {
  return (
    f.genres.length +
    f.themes.length +
    f.formats.length +
    (f.status ? 1 : 0) +
    (f.country ? 1 : 0) +
    (f.yearFrom || f.yearTo ? 1 : 0)
  );
}

export const GENRES = [
  "Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance",
  "Sci-Fi", "Slice of Life", "Sports", "Supernatural", "Mystery", "Thriller",
  "Horror", "Psychological", "Music", "Mecha",
];

// AniList calls these "tags"; to users they're themes. Exact AniList tag names.
export const THEMES = [
  "Isekai", "Reincarnation", "Time Travel", "School", "Magic", "Mecha",
  "Psychological", "Demons", "Vampire", "Historical", "Space",
  "Martial Arts", "Cyberpunk", "Samurai", "Post-Apocalyptic", "Gods",
];

const FORMATS: MediaFormat[] = ["TV", "TV_SHORT", "MOVIE", "SPECIAL", "OVA", "ONA"];

const STATUSES: { id: AniListMediaStatus; label: string }[] = [
  { id: "RELEASING", label: "Airing" },
  { id: "FINISHED", label: "Finished" },
  { id: "NOT_YET_RELEASED", label: "Not yet aired" },
];

const COUNTRIES: { id: CountryCode; label: string }[] = [
  { id: "JP", label: "Japan" },
  { id: "CN", label: "China" },
  { id: "KR", label: "Korea" },
  { id: "TW", label: "Taiwan" },
];

const NOW_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: NOW_YEAR + 1 - 1960 + 1 }, (_, i) => NOW_YEAR + 1 - i);

function toggle<T>(list: T[], value: T): T[] {
  return list.includes(value) ? list.filter((v) => v !== value) : [...list, value];
}

interface SectionProps {
  title: string;
  count?: number;
  defaultOpen?: boolean;
  children: ReactNode;
}

function Section({ title, count, defaultOpen = false, children }: SectionProps) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className={`k-filsec${open ? " k-filsec--open" : ""}`}>
      <button
        type="button"
        className="k-filsec__head"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
      >
        <span className="k-filsec__title">
          {title}
          {count ? <span className="k-filsec__count">{count}</span> : null}
        </span>
        <Icon icon={ChevronDown} size={18} className="k-filsec__chev" />
      </button>
      {open && <div className="k-filsec__body">{children}</div>}
    </div>
  );
}

interface Props {
  open: boolean;
  onClose: () => void;
  value: DiscoverFilters;
  onApply: (next: DiscoverFilters) => void;
}

export function DiscoverFilterSheet({ open, onClose, value, onApply }: Props) {
  // Edit a draft so a big multi-toggle session fires one query on Apply, not
  // one per tap. Re-seed whenever the sheet reopens with the live filters.
  const [draft, setDraft] = useState<DiscoverFilters>(value);
  useEffect(() => {
    if (open) setDraft(value);
  }, [open, value]);

  const set = <K extends keyof DiscoverFilters>(key: K, v: DiscoverFilters[K]) =>
    setDraft((d) => ({ ...d, [key]: v }));

  const activeCount = countActiveFilters(draft);

  return (
    <BottomSheet open={open} onClose={onClose} title="Filters">
      <div className="k-filters">
        <Section title="Genre" count={draft.genres.length} defaultOpen>
          <div className="k-chipwrap">
            {GENRES.map((g) => (
              <Chip
                key={g}
                active={draft.genres.includes(g)}
                onClick={() => set("genres", toggle(draft.genres, g))}
              >
                {g}
              </Chip>
            ))}
          </div>
        </Section>

        <Section title="Theme" count={draft.themes.length}>
          <div className="k-chipwrap">
            {THEMES.map((t) => (
              <Chip
                key={t}
                active={draft.themes.includes(t)}
                onClick={() => set("themes", toggle(draft.themes, t))}
              >
                {t}
              </Chip>
            ))}
          </div>
        </Section>

        <Section title="Format" count={draft.formats.length}>
          <div className="k-chipwrap">
            {FORMATS.map((f) => (
              <Chip
                key={f}
                active={draft.formats.includes(f)}
                onClick={() => set("formats", toggle(draft.formats, f))}
              >
                {formatLabel(f)}
              </Chip>
            ))}
          </div>
        </Section>

        <Section title="Status" count={draft.status ? 1 : 0}>
          <div className="k-chipwrap">
            {STATUSES.map((s) => (
              <Chip
                key={s.id}
                active={draft.status === s.id}
                onClick={() => set("status", draft.status === s.id ? null : s.id)}
              >
                {s.label}
              </Chip>
            ))}
          </div>
        </Section>

        <Section title="Year" count={draft.yearFrom || draft.yearTo ? 1 : 0}>
          <div className="k-filyear">
            <label className="k-filyear__field">
              <span>From</span>
              <select
                value={draft.yearFrom ?? ""}
                onChange={(e) =>
                  set("yearFrom", e.target.value ? Number(e.target.value) : null)
                }
              >
                <option value="">Any</option>
                {YEARS.map((y) => (
                  <option key={y} value={y}>{y}</option>
                ))}
              </select>
            </label>
            <label className="k-filyear__field">
              <span>To</span>
              <select
                value={draft.yearTo ?? ""}
                onChange={(e) =>
                  set("yearTo", e.target.value ? Number(e.target.value) : null)
                }
              >
                <option value="">Any</option>
                {YEARS.map((y) => (
                  <option key={y} value={y}>{y}</option>
                ))}
              </select>
            </label>
          </div>
        </Section>

        <Section title="Country" count={draft.country ? 1 : 0}>
          <div className="k-chipwrap">
            {COUNTRIES.map((c) => (
              <Chip
                key={c.id}
                active={draft.country === c.id}
                onClick={() => set("country", draft.country === c.id ? null : c.id)}
              >
                {c.label}
              </Chip>
            ))}
          </div>
        </Section>

        <div className="k-filters__footer">
          <button
            type="button"
            className="k-btn k-btn--md k-btn--ghost"
            onClick={() => setDraft(EMPTY_FILTERS)}
            disabled={activeCount === 0}
          >
            Reset
          </button>
          <button
            type="button"
            className="k-btn k-btn--md k-btn--primary k-btn--block"
            onClick={() => {
              onApply(draft);
              onClose();
            }}
          >
            {activeCount > 0 ? `Show results (${activeCount})` : "Show results"}
          </button>
        </div>
      </div>
    </BottomSheet>
  );
}
