import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ChevronDown, ChevronUp, Plus, Search, X } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { RoomHeader } from "@/components/list/RoomHeader";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { EmptyState } from "@/components/ui/EmptyState";
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
 * swiping the sheet closed, so the sheet had to disable its own dismissal
 * mid-drag, rows were absolutely positioned and moved by transform to stop
 * React re-parenting them out from under the pointer capture, and the row
 * height had to be a constant so a Y position could become an index. Every one
 * of those is a workaround for being in a sheet. On a page none of them exist.
 *
 * Reordering is buttons now, not a drag. That is the same call the plan cards
 * already made ("buttons work by touch and keyboard, and never fight the
 * app's drag-anywhere-to-scroll") and it is the one that survives: a move is a
 * tap, it works with a keyboard, and it cannot half-commit.
 *
 * Adding and removing say what they did. Silently failing at the cap is what
 * made the old one feel broken — you pressed add and nothing happened.
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

  /** The numbered set, in order. */
  const ordered = useMemo(
    () =>
      entries
        .filter((e) => e.status === "plan_to_watch" && e.plan_rank != null)
        .sort((a, b) => (a.plan_rank ?? 0) - (b.plan_rank ?? 0)),
    [entries],
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

  const hours = useMemo(
    () =>
      Math.round(
        ordered.reduce(
          (m, e) => m + (e.total_episodes ?? 0) * (e.episode_duration ?? 24),
          0,
        ) / 60,
      ),
    [ordered],
  );

  /** Swap a row with its neighbour. The whole order is rewritten through the
   *  store's dense committer, so the numbers can never drift out of 1..N. */
  const move = (index: number, dir: -1 | 1) => {
    const next = [...ordered];
    const target = index + dir;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    void reorderPlan(next.map((e) => e.anilist_id));
  };

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
      <RoomHeader
        title="My order"
        census={[
          `${ordered.length} of ${UP_NEXT_CAP}`,
          ordered[0] ? `next: ${nameOf(ordered[0], titleLanguage)}` : null,
          hours > 0 ? `${hours.toLocaleString()} hours` : null,
        ]}
        purpose={`The next ${UP_NEXT_CAP} titles, in the order you mean to watch them.`}
      />

      <div className="k-orderpage konsou-scroll">
        {ordered.length === 0 ? (
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
          <ol className="k-ord">
            {ordered.map((e, i) => (
              <li className="k-ord__row" key={e.anilist_id}>
                <span className="k-ord__n">{i + 1}</span>
                <span className="k-ord__cover">
                  <AnimeCover
                    src={getCoverUrl({ medium: e.cover_url ?? undefined })}
                    alt=""
                    decorative
                    radius="var(--radius-plate)"
                  />
                </span>
                <span className="k-ord__title">{nameOf(e, titleLanguage)}</span>
                <span className="k-ord__meta">
                  {e.total_episodes != null ? `${e.total_episodes} ep` : "? ep"}
                </span>
                {/* Move by tap: works by keyboard, works with one thumb, and
                    cannot half-commit the way the old drag could. */}
                <span className="k-ord__moves">
                  <button
                    type="button"
                    onClick={() => move(i, -1)}
                    disabled={i === 0}
                    aria-label={`Move ${nameOf(e, titleLanguage)} up`}
                  >
                    <Icon icon={ChevronUp} size={16} />
                  </button>
                  <button
                    type="button"
                    onClick={() => move(i, 1)}
                    disabled={i === ordered.length - 1}
                    aria-label={`Move ${nameOf(e, titleLanguage)} down`}
                  >
                    <Icon icon={ChevronDown} size={16} />
                  </button>
                </span>
                <button
                  type="button"
                  className="k-ord__remove"
                  onClick={() => remove(e)}
                  aria-label={`Remove ${nameOf(e, titleLanguage)} from your order`}
                >
                  <Icon icon={X} size={16} />
                </button>
              </li>
            ))}
          </ol>
        )}

        <section className="k-ordadd">
          <h2 className="k-ordadd__label">Add to the order</h2>
          <p className="k-ordadd__hint">
            {full
              ? `Full at ${UP_NEXT_CAP}. Remove one above to make room.`
              : `${UP_NEXT_CAP - ordered.length} ${UP_NEXT_CAP - ordered.length === 1 ? "place" : "places"} left. Anything planned can take one.`}
          </p>

          <div className="k-ordadd__search">
            <Icon icon={Search} size={15} color="var(--color-text-tertiary)" />
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
                  radius="var(--radius-plate)"
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
    </div>
  );
}
