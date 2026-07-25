import { useEffect, useMemo, useRef, useState } from "react";
import type { PointerEvent as ReactPointerEvent } from "react";
import { GripVertical, Plus, Search, X } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl, preferredTitle } from "@/lib/format";
import { normalizeForSearch } from "@/lib/format";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { AnimeListEntry } from "@/types/list";

interface OrderSheetProps {
  open: boolean;
  onClose: () => void;
}

/** Row height in px. Fixed so the drag can turn a Y position into an index
 *  without measuring every row on each pointer move. */
const ROW_H = 60;
const MAX_RESULTS = 20;

/**
 * The watch-order dashboard: everything you have numbered, in order, in one
 * place.
 *
 * This exists because stamping a number on a card only works if you can FIND
 * the card. At a thousand-plus planned titles you cannot scroll to the one you
 * want, so the order has to be reachable and editable without touching the
 * list at all: open it, search by name to add, drag to rearrange, remove, done.
 *
 * Dragging is the right interaction here precisely BECAUSE the set is capped at
 * ten. Dragging across a thousand entries is what made the old queue unusable;
 * dragging within ten is a single short gesture.
 */
export function OrderSheet({ open, onClose }: OrderSheetProps) {
  const entries = useListStore((s) => s.entries);
  const reorderPlan = useListStore((s) => s.reorderPlan);
  const setPlanNumber = useListStore((s) => s.setPlanNumber);
  const addToPlanOrder = useListStore((s) => s.addToPlanOrder);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [query, setQuery] = useState("");
  // The live drag lives in a ref as well as state. State alone is not enough:
  // pointermove fires before React has re-rendered, so a handler reading the
  // state variable sees the previous value and drops the first moves. That is
  // what made the grip feel like it needed a long press before it responded,
  // and why a quick flick scrolled the sheet instead of dragging the row.
  // pointerId is tracked so exactly one finger can be dragging: a second touch,
  // a double tap, or a stray palm cannot start a competing drag or feed
  // positions into the one already running.
  const dragRef = useRef<
    { from: number; to: number; pointerId: number; y: number } | null
  >(null);
  const [drag, setDrag] = useState<{ from: number; to: number; y: number } | null>(null);
  const listRef = useRef<HTMLOListElement>(null);
  const dragCleanup = useRef<(() => void) | null>(null);
  // The commit reads the order through a ref: the handlers are created once per
  // gesture, so a captured array would be whatever it was at grab time.
  const orderedRef = useRef<AnimeListEntry[]>([]);

  useEffect(() => () => dragCleanup.current?.(), []);

  const nameOf = (e: AnimeListEntry) =>
    preferredTitle(
      { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
      titleLanguage,
    );

  /** The numbered set, in order. */
  const ordered = useMemo(
    () =>
      entries
        .filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
        .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0)),
    [entries],
  );
  orderedRef.current = ordered;

  /** Planned titles not yet in the order, matching the search. */
  const candidates = useMemo(() => {
    const q = normalizeForSearch(query.trim());
    if (!q) return [];
    const out: AnimeListEntry[] = [];
    for (const e of entries) {
      if (e.status !== "plan_to_watch" || e.plan_rank != null) continue;
      const hay = normalizeForSearch(
        `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""}`,
      );
      if (hay.includes(q)) out.push(e);
      if (out.length >= MAX_RESULTS) break;
    }
    return out;
  }, [entries, query]);

  const full = ordered.length >= UP_NEXT_CAP;

  // One layout read per render, and only while a drag is live. The lifted row
  // is the only thing that needs it, and the list does not move during a drag.
  const listTop = drag ? (listRef.current?.getBoundingClientRect().top ?? 0) : 0;

  /** Apply a drag to the order without mutating it. */
  const applyDrag = (list: AnimeListEntry[], from: number, to: number) => {
    if (from === to) return list;
    const next = [...list];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    return next;
  };

  /**
   * Where a row sits on screen during a drag.
   *
   * The DOM order never changes while dragging: rows are absolutely positioned
   * and only their transform moves. Reordering the list mid-drag made React
   * re-parent the `<li>` nodes, which silently dropped the grip's pointer
   * capture and released the row the moment it crossed a neighbour. Moving
   * transforms instead means the element under the finger is the same element
   * from grab to drop.
   */
  const displayIndex = (i: number): number => {
    if (!drag) return i;
    const { from, to } = drag;
    if (i === from) return to;
    if (from < to && i > from && i <= to) return i - 1;
    if (from > to && i >= to && i < from) return i + 1;
    return i;
  };

  const indexFromY = (clientY: number): number => {
    const el = listRef.current;
    if (!el) return 0;
    const top = el.getBoundingClientRect().top;
    // Measure from the row's centre so a row swaps when you pass its middle,
    // not when you clip its top edge.
    const raw = Math.round((clientY - top - ROW_H / 2) / ROW_H);
    return Math.max(0, Math.min(ordered.length - 1, raw));
  };

  /**
   * Start a drag, and own the finger from here until release.
   *
   * The move/up handlers live on the WINDOW and are created here, so they close
   * over stable refs and keep one identity for the whole gesture. Listening on
   * the grip element instead is what made the row drop out: React moves those
   * nodes as the preview shifts, pointer capture goes with them, and the drag
   * ended the moment the row crossed a neighbour. The window always sees the
   * finger, so the row survives re-renders and can be taken anywhere on screen.
   */
  const startDrag = (ev: ReactPointerEvent, entry: AnimeListEntry) => {
    // One drag at a time, first finger only. Without this a second touch
    // mid-drag hijacks the row to wherever that finger happens to be.
    if (dragRef.current || !ev.isPrimary) return;
    const from = orderedRef.current.findIndex((o) => o.anilist_id === entry.anilist_id);
    if (from < 0) return;
    ev.preventDefault();

    const pointerId = ev.pointerId;
    dragRef.current = { from, to: from, pointerId, y: ev.clientY };
    setDrag({ from, to: from, y: ev.clientY });

    const onMove = (e: globalThis.PointerEvent) => {
      const d = dragRef.current;
      if (!d || e.pointerId !== d.pointerId) return;
      e.preventDefault();
      const to = indexFromY(e.clientY);
      if (to === d.to && Math.abs(e.clientY - d.y) < 1) return;
      dragRef.current = { ...d, to, y: e.clientY };
      setDrag({ from: d.from, to, y: e.clientY });
    };

    const finish = (e?: globalThis.PointerEvent) => {
      const d = dragRef.current;
      if (e && d && e.pointerId !== d.pointerId) return;
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", finish);
      window.removeEventListener("pointercancel", finish);
      dragCleanup.current = null;
      if (!d) return;
      dragRef.current = null;
      setDrag(null);
      if (d.from === d.to) return;
      const next = applyDrag(orderedRef.current, d.from, d.to);
      void reorderPlan(next.map((x) => x.anilist_id));
    };

    window.addEventListener("pointermove", onMove, { passive: false });
    window.addEventListener("pointerup", finish);
    window.addEventListener("pointercancel", finish);
    // Held so an unmount mid-drag cannot strand these on the window.
    dragCleanup.current = () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", finish);
      window.removeEventListener("pointercancel", finish);
    };
  };

  const add = (e: AnimeListEntry) => {
    // Lowest FREE number, not count+1: with a gap in the order, count+1 lands
    // on a number somebody already holds and silently unnumbers them.
    if (!addToPlanOrder(e.anilist_id)) return;
    setQuery("");
  };

  return (
    // While a row is being dragged the sheet stops being dismissable, which
    // locks the handle drag, the pull-to-close from the body, and the backdrop
    // tap all at once. Dragging a row DOWN is otherwise indistinguishable from
    // the swipe-down-to-dismiss gesture, so the sheet used to close underneath
    // the drag. Everywhere outside a live drag, dismissal behaves normally.
    <BottomSheet
      open={open}
      onClose={onClose}
      title="My order"
      dismissable={drag == null}
    >
      <div className="k-order">
        <p className="k-order__count">
          {ordered.length} of {UP_NEXT_CAP}
        </p>

        {ordered.length === 0 ? (
          <p className="k-order__empty">
            Nothing numbered yet. Search below to pick what you want to watch
            next, in the order you want to watch it.
          </p>
        ) : (
          <ol className="k-order__list" ref={listRef} style={{ height: ordered.length * ROW_H }}>
            {/* Rendered in the STABLE order and positioned by transform. The
                lifted row is pinned to the finger; the others slide to open a
                gap where it will land. */}
            {ordered.map((e, i) => {
              const lifted = drag?.from === i;
              const slot = displayIndex(i);
              // listTop is read ONCE per render above, not per row: calling
              // getBoundingClientRect inside the map forced a synchronous
              // layout for every row on every pointermove.
              const y = lifted && drag ? drag.y - listTop - ROW_H / 2 : slot * ROW_H;
              return (
              <li
                key={e.anilist_id}
                className={`k-order__row${lifted ? " k-order__row--dragging" : ""}`}
                style={{ transform: `translateY(${y}px)` }}
              >
                <span className="k-order__n">{slot + 1}</span>
                <span className="k-order__cover">
                  <AnimeCover
                    src={getCoverUrl({ medium: e.cover_url ?? undefined })}
                    alt={nameOf(e)}
                    decorative
                    radius="var(--radius-sm)"
                  />
                </span>
                <span className="k-order__title">{nameOf(e)}</span>
                <button
                  type="button"
                  className="k-order__remove"
                  onClick={() => void setPlanNumber(e.anilist_id, null)}
                  aria-label={`Remove ${nameOf(e)} from the order`}
                >
                  <Icon icon={X} size={16} />
                </button>
                {/* Drag lives on a handle, not the row, so scrolling the sheet
                    never turns into an accidental reorder. */}
                <button
                  type="button"
                  className="k-order__grip"
                  // The sheet bails out of any gesture starting here, so the
                  // row drag owns the finger outright instead of racing the
                  // pull-to-close.
                  data-sheet-nodrag
                  aria-label={`Reorder ${nameOf(e)}`}
                  // Only the start lives here. Move and release are tracked on
                  // the window, so losing this element (or leaving it) cannot
                  // drop the row mid-drag.
                  onPointerDown={(ev) => startDrag(ev, e)}
                >
                  <Icon icon={GripVertical} size={18} />
                </button>
              </li>
              );
            })}
          </ol>
        )}

        <div className="k-order__add">
          {/* Says what it DOES, not what it searches. "Search your planned
              list" described the haystack; this describes the outcome. */}
          <h3 className="k-order__addlabel">Add to my order</h3>
          <p className="k-order__hint">
            Or press and hold any card in your list to add it here.
          </p>
          <div className="k-order__search">
            <Icon icon={Search} size={15} color="var(--color-text-tertiary)" />
            <input
              value={query}
              onChange={(ev) => setQuery(ev.target.value)}
              placeholder={
                full ? "Full — remove one to add another" : "Search a planned anime by name…"
              }
              aria-label="Search a planned anime to add to your order"
              disabled={full}
            />
            {query && (
              <button type="button" onClick={() => setQuery("")} aria-label="Clear search">
                <Icon icon={X} size={14} />
              </button>
            )}
          </div>

          {candidates.map((e) => (
            <button
              key={e.anilist_id}
              type="button"
              className="k-order__candidate"
              onClick={() => add(e)}
            >
              <span className="k-order__cover">
                <AnimeCover
                  src={getCoverUrl({ medium: e.cover_url ?? undefined })}
                  alt={nameOf(e)}
                  decorative
                  radius="var(--radius-sm)"
                />
              </span>
              <span className="k-order__title">{nameOf(e)}</span>
              <Icon icon={Plus} size={16} color="var(--color-accent-glow)" />
            </button>
          ))}

          {query.trim() && candidates.length === 0 && (
            <p className="k-order__none">Nothing planned matches “{query.trim()}”.</p>
          )}
        </div>
      </div>
    </BottomSheet>
  );
}
