import { useEffect, useMemo, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent } from "react";
import { createPortal } from "react-dom";
import { useNavigate } from "react-router-dom";
import { ArrowRight, Search, Settings } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { statusMeta } from "@/components/anime/statusMeta";
import { normalizeForSearch, preferredTitle } from "@/lib/format";
import { similarity } from "@/lib/search/fuzzy";
import { registerSheet } from "@/lib/sheetStack";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { NAV_ITEMS } from "@/components/layout/navConfig";
import type { NavItem } from "@/components/layout/navConfig";
import type { AnimeListEntry } from "@/types/list";

type PaletteItem =
  | { kind: "page"; page: NavItem }
  | { kind: "anime"; entry: AnimeListEntry };

const MAX_ANIME = 8;

/** All destinations the palette can jump to, including the avatar-hidden ones. */
const PAGES: NavItem[] = [
  ...NAV_ITEMS,
  { to: "/settings", label: "Settings", icon: Settings },
];

function entryTitleBlob(e: AnimeListEntry): string {
  return normalizeForSearch(
    `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""}`,
  );
}

/**
 * Ctrl+K / Cmd+K command palette. Jump to any tracked title or app page from
 * the keyboard: type to filter, arrows to move, Enter to go. Local data only,
 * so it works identically offline.
 */
export function CommandPalette() {
  const navigate = useNavigate();
  const entries = useListStore((s) => s.entries);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // Global summon. Deliberately not gated on desktop: anyone with a keyboard
  // (tablet, Android + BT keyboard) gets it, and it costs nothing otherwise.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((o) => !o);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // Reset per open, focus the field, and take a slot on the sheet stack so
  // Android back closes the palette instead of navigating.
  useEffect(() => {
    if (!open) return;
    setQuery("");
    setActive(0);
    inputRef.current?.focus();
    return registerSheet(() => setOpen(false));
  }, [open]);

  const items = useMemo<PaletteItem[]>(() => {
    const q = normalizeForSearch(query.trim());

    if (!q) {
      // Empty query: pages, then what's actively being watched.
      const activeEntries = entries
        .filter((e) => e.status === "watching" || e.status === "rewatching")
        .sort((a, b) => b.updated_at - a.updated_at)
        .slice(0, 5);
      return [
        ...PAGES.map((page): PaletteItem => ({ kind: "page", page })),
        ...activeEntries.map((entry): PaletteItem => ({ kind: "anime", entry })),
      ];
    }

    const pages = PAGES.filter((p) =>
      normalizeForSearch(p.label).includes(q),
    ).map((page): PaletteItem => ({ kind: "page", page }));

    // Same matching language as Discover's offline fallback: prefix beats
    // substring, and when neither hits, the typo-tolerant fuzzy score takes
    // over — so "chansaw man" finds the same thing in both search boxes.
    // Fuzzy hits rank below any literal hit; ties break on recency.
    const scored = entries
      .map((e) => {
        const blob = entryTitleBlob(e);
        const idx = blob.indexOf(q);
        if (idx === 0) return { e, score: 0 };
        if (idx > 0) return { e, score: 1 };
        const fuzz = similarity(q, blob);
        return fuzz >= 0.5 ? { e, score: 3 - fuzz } : null;
      })
      .filter((x): x is { e: AnimeListEntry; score: number } => x !== null)
      .sort((a, b) => a.score - b.score || b.e.updated_at - a.e.updated_at)
      .slice(0, MAX_ANIME)
      .map(({ e }): PaletteItem => ({ kind: "anime", entry: e }));

    return [...pages, ...scored];
  }, [query, entries]);

  // Clamp the cursor when the result set shrinks under it.
  useEffect(() => {
    if (active >= items.length) setActive(Math.max(0, items.length - 1));
  }, [items.length, active]);

  if (!open) return null;

  const select = (item: PaletteItem) => {
    setOpen(false);
    if (item.kind === "page") navigate(item.page.to, { replace: true });
    else navigate(`/anime/${item.entry.anilist_id}`, { replace: true });
  };

  const onKeyDown = (e: ReactKeyboardEvent) => {
    if (e.key === "Escape") {
      e.preventDefault();
      setOpen(false);
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      setActive((a) => Math.min(items.length - 1, a + 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((a) => Math.max(0, a - 1));
    } else if (e.key === "Enter" && items[active]) {
      e.preventDefault();
      select(items[active]);
    }
    // Keep the active row in view while arrowing through a long list.
    requestAnimationFrame(() => {
      listRef.current
        ?.querySelector(".k-palette__item--active")
        ?.scrollIntoView({ block: "nearest" });
    });
  };

  return createPortal(
    <div className="k-palette-overlay" role="presentation">
      <div className="k-palette-backdrop" onClick={() => setOpen(false)} />
      <div
        className="k-palette"
        role="dialog"
        aria-modal="true"
        aria-label="Catalogue lookup"
        onKeyDown={onKeyDown}
      >
        <div className="k-palette__field">
          <Icon icon={Search} size={16} color="var(--ink-label)" />
          <input
            ref={inputRef}
            className="k-palette__input"
            placeholder="Look up a specimen or section…"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setActive(0);
            }}
            aria-label="Look up a specimen or section"
          />
          <kbd className="k-palette__kbd">esc</kbd>
        </div>

        <div className="k-palette__list konsou-scroll" ref={listRef}>
          {items.length === 0 && (
            <p className="k-palette__none">Nothing in the catalogue matches.</p>
          )}
          {items.map((item, i) => {
            const isActive = i === active;
            const cls = `k-palette__item${isActive ? " k-palette__item--active" : ""}`;
            if (item.kind === "page") {
              return (
                <button
                  key={`p:${item.page.to}`}
                  type="button"
                  className={cls}
                  onMouseEnter={() => setActive(i)}
                  onClick={() => select(item)}
                >
                  <span className="k-palette__pageicon">
                    <Icon icon={item.page.icon} size={16} />
                  </span>
                  <Text size="sm" weight={600}>
                    {item.page.label}
                  </Text>
                  <span className="k-palette__go" aria-hidden>
                    <Icon icon={ArrowRight} size={14} />
                  </span>
                </button>
              );
            }
            const e = item.entry;
            const meta = statusMeta(e.status);
            return (
              <button
                key={`a:${e.anilist_id}`}
                type="button"
                className={cls}
                onMouseEnter={() => setActive(i)}
                onClick={() => select(item)}
              >
                <span className="k-palette__cover">
                  <AnimeCover
                    src={e.cover_url ?? undefined}
                    alt=""
                    decorative
                    radius="var(--radius-sm)"
                  />
                </span>
                <span className="k-palette__body">
                  <Text size="sm" weight={600} clamp={1} className="k-palette__spec">
                    {preferredTitle(
                      {
                        romaji: e.title_romaji,
                        english: e.title_english,
                        native: e.title_native,
                      },
                      titleLanguage,
                    )}
                  </Text>
                  <span className="k-palette__meta" style={{ color: meta.color }}>
                    {meta.label}
                    <span className="k-palette__dim">
                      {" "}
                      · {e.episodes_watched} / {e.total_episodes ?? "?"}
                    </span>
                  </span>
                </span>
                <span className="k-palette__go" aria-hidden>
                  <Icon icon={ArrowRight} size={14} />
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>,
    document.body,
  );
}
