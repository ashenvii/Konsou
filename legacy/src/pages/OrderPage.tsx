import { useCallback, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { GripVertical, Plus, Search, X } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { RoomHeader } from "@/components/list/RoomHeader";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
import { useReorderDrag } from "@/hooks/useReorderDrag";
import { getCoverUrl, normalizeForSearch, preferredTitle } from "@/lib/format";
import { useListStore, UP_NEXT_CAP } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import { toast } from "@/lib/store/toastStore";
import type { AnimeListEntry, TitleLanguage } from "@/types/list";

/**
 * The watch order, as a page.
 *
 * It used to be a sheet with a hand-rolled pointer drag inside it, and the two
 * fought each other the whole time: dragging a row DOWN is the same gesture as
 * swiping the sheet closed. Every workaround that drag grew was a workaround
 * for being in a sheet. On a page none of them exist, so the drag is a real
 * drag again — see useReorderDrag for the conflicts that ARE real (the app's
 * drag-anywhere-to-scroll, native touch scrolling, and fifteen rows being
 * taller than a phone) and what answers each.
 *
 * The up/down buttons this replaced were the honest fallback while the gesture
 * was broken, and they are gone because the grip keeps everything they were
 * good for: it is a real button, so Space picks a row up and the arrows move
 * it. Nothing here is mouse-only.
 *
 * Adding and removing say what they did. Silently failing at the cap is what
 * made the old one feel broken: you pressed add and nothing happened.
 */

const MAX_RESULTS = 25;

function nameOf(e: AnimeListEntry, lang: TitleLanguage): string {
  return preferredTitle(
    { romaji: e.title_romaji, english: e.title_english, native: e.title_native },
    lang,
  );
}

export function OrderPage() {
  const navigate = useNavigate();
  const entries = useListStore((s) => s.entries);
  const reorderPlan = useListStore((s) => s.reorderPlan);
  const setPlanNumber = useListStore((s) => s.setPlanNumber);
  const addToPlanOrder = useListStore((s) => s.addToPlanOrder);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);

  const [query, setQuery] = useState("");
  const scrollerRef = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLOListElement>(null);

  /** The numbered set, in order. */
  const ordered = useMemo(
    () =>
      entries
        .filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
        .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0)),
    [entries],
  );

  const byId = useMemo(
    () => new Map(ordered.map((e) => [e.anilist_id, e])),
    [ordered],
  );

  const orderedIds = useMemo(() => ordered.map((e) => e.anilist_id), [ordered]);

  const labelOf = useCallback(
    (id: number) => {
      const e = byId.get(id);
      return e ? nameOf(e, titleLanguage) : "This title";
    },
    [byId, titleLanguage],
  );

  const onCommit = useCallback(
    (ids: number[], previous: number[]) => {
      void reorderPlan(ids);
      // Remove and add both got an undo toast; a completed drag or keyboard
      // drop didn't, though it is the easiest of the three to mis-time (drop
      // a row one slot off the intended spot, notice, have no way back except
      // re-dragging it by hand).
      toast.action({
        message: "Reordered",
        actionLabel: "Undo",
        duration: 5000,
        onAction: () => void reorderPlan(previous),
      });
    },
    [reorderPlan],
  );

  const reorder = useReorderDrag({
    ids: orderedIds,
    scrollerRef,
    listRef,
    onCommit,
    labelOf,
  });

  /** The rows to draw: the gesture's working order while one is in hand, the
   *  store's order the rest of the time. */
  const rows = useMemo(
    () => reorder.order.map((id) => byId.get(id)).filter((e): e is AnimeListEntry => !!e),
    [reorder.order, byId],
  );

  /** Everything planned that is not in the order yet. Shown as a real list,
   *  not only as search results: at a small cap the thing you want is often
   *  something you added recently, and you should not have to name it first. */
  const candidates = useMemo(() => {
    const q = normalizeForSearch(query.trim());
    const out: AnimeListEntry[] = [];
    for (const e of entries) {
      if (e.status !== "plan_to_watch" || e.plan_rank != null) continue;
      if (q) {
        const hay = normalizeForSearch(
          `${e.title_romaji} ${e.title_english ?? ""} ${e.title_native ?? ""}`,
        );
        if (!hay.includes(q)) continue;
      }
      out.push(e);
    }
    // Newest first when browsing; a search is already narrow enough.
    if (!q) out.sort((a, b) => b.added_at - a.added_at);
    return out.slice(0, MAX_RESULTS);
  }, [entries, query]);

  const full = ordered.length >= UP_NEXT_CAP;

  const add = (e: AnimeListEntry) => {
    if (addToPlanOrder(e.anilist_id)) {
      setQuery("");
      return;
    }
    // The old version returned false here and showed nothing at all, which is
    // most of why this screen felt broken.
    toast.error(
      full
        ? `Your order is full at ${UP_NEXT_CAP}. Remove one to add another.`
        : "That title is already in your order.",
    );
  };

  const remove = (e: AnimeListEntry) => {
    const at = e.plan_rank;
    void setPlanNumber(e.anilist_id, null);
    toast.action({
      message: `Removed "${nameOf(e, titleLanguage)}" from your order`,
      actionLabel: "Undo",
      duration: 5000,
      onAction: () => {
        // Back at the number it held, with everything below it shifted down
        // again — the same dense insert the number picker uses.
        void setPlanNumber(e.anilist_id, at ?? ordered.length + 1);
      },
    });
  };

  return (
    <div className="k-page k-page--room k-page--order">
      <RoomHeader title="My order" />

      <div className="k-orderpage konsou-scroll" ref={scrollerRef}>
        {rows.length === 0 ? (
          <EmptyState
            title="Nothing numbered yet"
            subtitle="Pick what you want to watch next, in the order you want to watch it. Everything else stays in the plan room, unnumbered."
            action={
              <Button
                variant="secondary"
                onClick={() => navigate("/list/plan", { replace: true })}
              >
                Back to Planned
              </Button>
            }
          />
        ) : (
          <>
            <p className="k-ord__how">
              Drag a row by its number to move it. By keyboard, press Space on
              one, move it with the arrows (Home or End jumps to either end),
              and press Enter to drop it.
            </p>
            <ol className="k-ord" ref={listRef}>
              {rows.map((e, i) => {
                const row = reorder.rowProps(i);
                const name = nameOf(e, titleLanguage);
                return (
                  <li
                    key={e.anilist_id}
                    data-reorder-row=""
                    className={`k-ord__row${row.className ? ` ${row.className}` : ""}`}
                    style={row.style}
                  >
                    {/* The number IS the grip. It is the one thing on the row
                        you are actually moving, so making it a separate handle
                        beside itself would be two controls for one idea. The
                        ruled bars are the affordance; the mono figure is the
                        record. */}
                    <button
                      type="button"
                      className="k-ord__grip"
                      aria-label={`${name}, number ${i + 1} of ${rows.length}. Press Space to pick up, then use the arrow keys`}
                      {...reorder.gripProps(i)}
                    >
                      <span className="k-ord__n">{i + 1}</span>
                      <Icon icon={GripVertical} size={15} />
                    </button>
                    <span className="k-ord__cover">
                      <AnimeCover
                        src={getCoverUrl({ medium: e.cover_url ?? undefined })}
                        alt=""
                        decorative
                        radius="var(--plate-radius)"
                      />
                    </span>
                    <span className="k-ord__title">{name}</span>
                    <span className="k-ord__meta">
                      {e.total_episodes != null ? `${e.total_episodes} ep` : "? ep"}
                    </span>
                    <button
                      type="button"
                      className="k-ord__remove"
                      onClick={() => remove(e)}
                      aria-label={`Remove ${name} from your order`}
                    >
                      <Icon icon={X} size={16} />
                    </button>
                  </li>
                );
              })}
            </ol>
          </>
        )}

        <section className="k-ordadd">
          <h2 className="k-ordadd__label">Add to the order</h2>
          <p className="k-ordadd__hint">
            {full
              ? `Full at ${UP_NEXT_CAP}. Remove one above to make room.`
              : `${UP_NEXT_CAP - ordered.length} ${UP_NEXT_CAP - ordered.length === 1 ? "place" : "places"} left. Anything planned can take one.`}
          </p>

          <div className="k-ordadd__search">
            <Icon icon={Search} size={15} color="var(--ink-label)" />
            <input
              value={query}
              onChange={(ev) => setQuery(ev.target.value)}
              placeholder="Search your planned titles…"
              aria-label="Search a planned anime to add to your order"
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
              className="k-ordadd__row"
              onClick={() => add(e)}
              disabled={full}
            >
              <span className="k-ord__cover">
                <AnimeCover
                  src={getCoverUrl({ medium: e.cover_url ?? undefined })}
                  alt=""
                  decorative
                  radius="var(--plate-radius)"
                />
              </span>
              <span className="k-ord__title">{nameOf(e, titleLanguage)}</span>
              <span className="k-ordadd__plus" aria-hidden>
                <Icon icon={Plus} size={15} />
              </span>
            </button>
          ))}

          {candidates.length === 0 && (
            <p className="k-ordadd__none">
              {query.trim()
                ? `Nothing planned matches “${query.trim()}”.`
                : "Everything you have planned is already in the order."}
            </p>
          )}
        </section>
      </div>

      {/* Every move is spoken, because the visible result of a drag is a
          rearrangement you cannot see if you are not looking at it. */}
      <p className="sr-only" role="status" aria-live="polite">
        {reorder.announcement}
      </p>
    </div>
  );
}
