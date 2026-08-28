import { useCallback, useEffect, useMemo, useRef } from "react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { statusMeta } from "@/components/anime/statusMeta";
import { useMediaQuery } from "@/hooks/useMediaQuery";
import { preferredTitle } from "@/lib/format";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { FranchiseGroup } from "@/lib/franchise/grouping";

/** Past four this stops being "what you are in the middle of" and starts being
 *  the room, which is one click away and better at it. It was twelve, and
 *  twelve was twelve MOUNTED, not four visible with eight in reserve. */
export const DRAWER_ITEMS = 4;

/** One lap of the wave. Lantern runs this alone; Neon runs it and faults. */
const LAP_MS = 6000;

/** Neon only, and rare on purpose. Every five to nine laps, so most passes of
 *  the wave complete untouched: a fault you can predict is a metronome, and a
 *  frequent one stops reading as a room that is alive and starts reading as a
 *  component that is broken. */
const FAULT_LAPS: [number, number] = [5, 9];
const FAULT_SHAPES = ["nm-draw--split", "nm-draw--slip", "nm-draw--drop"] as const;

/** Above this a card cannot give one cell per episode a legible width. At 24 on
 *  a 320px phone the cells measured 5.8px wide, which is a record you cannot
 *  count; the narrowest card the layout allows is 208px, and 13 cells is what
 *  fits there at 8.2px each. Past the cap the record becomes a bar, which is
 *  the same fallback Tonight's own record makes and for the same reason. */
const CELL_CAP = 13;

function rnd(a: number, b: number): number {
  return a + Math.random() * (b - a);
}

/**
 * What else you are in the middle of, under the thing you are watching tonight.
 *
 * THIS IS NOT A CAROUSEL, AND IT REPLACES ONE. The billboard rotated five
 * slides while showing four of them in a shelf beside the stage, so the
 * rotation revealed nothing you could not already read, and it paid for that
 * with a dwell timer, a pause control, hover and focus suspend, and the whole
 * of WCAG 2.2.2. Four cards that sit still say more and cost none of it.
 *
 * The block has no plate. It is flush to Tonight with no gap, inset from both
 * page edges, and its ground starts at zero opacity, so the wash Tonight throws
 * keeps falling through the top of it instead of stopping dead at a border.
 * Measured before this was built: the wash is at full strength through y352 and
 * does not die until y660, and the old plate ran y300 to y588 and hid all of
 * it. That overlap is the whole reason the block used to read as another room.
 *
 * MOTION BELONGS TO THE WORLD, not to this component. Lantern's wave is pure
 * CSS and lives in night-market.css. Neon runs the same wave and additionally
 * faults, and the fault is scheduled HERE because CSS cannot be random: a
 * keyframe loop repeats identically and nth-child delays are fixed, so the same
 * card would fault at the same instant forever, which is the opposite of alive.
 */
export function WatchDrawer({
  groups,
  count,
  onOpenRoom,
  onOpen,
}: {
  /** Everything running that is not Tonight's subject, already capped. */
  groups: FranchiseGroup[];
  /** Every watching title, Tonight's included, for the door's count. */
  count: number;
  onOpenRoom: () => void;
  onOpen: (anilistId: number) => void;
}) {
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const colorTheme = useSettingsStore((s) => s.colorTheme);
  const incrementEpisodes = useListStore((s) => s.incrementEpisodes);
  const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
  const railRef = useRef<HTMLUListElement>(null);
  const lastFaulted = useRef(-1);

  const faults = colorTheme === "neon" && !reducedMotion && groups.length > 0;

  /* One fault: a random card, a random shape, a random amplitude, a random
     length, and an offset off the lap boundary so it never lands at the same
     point in the wave. Never the same card twice running. */
  const fault = useCallback(() => {
    const cards = railRef.current?.querySelectorAll<HTMLElement>(".nm-draw__card");
    if (!cards || cards.length === 0) return;
    let i = Math.floor(Math.random() * cards.length);
    if (cards.length > 1 && i === lastFaulted.current) {
      i = (i + 1 + Math.floor(Math.random() * (cards.length - 1))) % cards.length;
    }
    lastFaulted.current = i;

    const card = cards[i];
    const amp = Math.round(rnd(3, 6));
    const shape = FAULT_SHAPES[Math.floor(Math.random() * FAULT_SHAPES.length)];
    const ms = Math.round(rnd(260, 620));

    /* Whole lengths, never a calc() multiplier: calc(9px * var(--n)) is
       silently inert in the webviews this ships to. */
    card.style.setProperty("--nm-gx", amp + "px");
    card.style.setProperty("--nm-gx2", -Math.round(amp * 0.7) + "px");
    card.style.setProperty("--nm-gx3", Math.round(amp * 0.4) + "px");
    card.style.setProperty("--nm-gdur", ms + "ms");

    FAULT_SHAPES.forEach((s) => card.classList.remove(s));
    void card.offsetWidth;
    card.classList.add(shape);
    window.setTimeout(() => card.classList.remove(shape), ms + 40);
  }, []);

  useEffect(() => {
    if (!faults) return;
    let timer = 0;
    const arm = () => {
      timer = window.setTimeout(
        () => {
          fault();
          arm();
        },
        rnd(FAULT_LAPS[0], FAULT_LAPS[1]) * LAP_MS + rnd(-0.4, 0.4) * LAP_MS,
      );
    };
    arm();
    return () => window.clearTimeout(timer);
  }, [faults, fault]);

  const cards = useMemo(
    () =>
      groups.map((g) => {
        const e = g.displayEntry;
        const total = e.total_episodes ?? null;
        const aired = e.aired_episodes ?? null;
        return {
          key: g.rootId,
          id: e.anilist_id,
          cover: e.cover_url,
          title: preferredTitle(
            {
              romaji: e.title_romaji,
              english: e.title_english,
              native: e.title_native,
            },
            titleLanguage,
          ),
          watched: e.episodes_watched,
          total,
          aired,
          state: statusMeta(e.status),
          /* Aired and not yours yet. The one number here a percentage cannot
             express, and the reason a card earns its room. */
          waiting:
            aired != null && aired > e.episodes_watched ? aired - e.episodes_watched : 0,
        };
      }),
    [groups, titleLanguage],
  );

  return (
    <section className="nm-draw" aria-label="Watching">
      {/* The whole header is the door. */}
      <button type="button" className="nm-draw__head" onClick={onOpenRoom}>
        <span className="nm-draw__name">Watching</span>
        <span className="nm-draw__n">{count.toLocaleString()}</span>
        <span className="nm-draw__door">
          <span className="nm-draw__doorword">Open room</span>
          <span className="nm-draw__chev" aria-hidden>
            &rsaquo;
          </span>
        </span>
      </button>

      <ul className="nm-draw__rail" ref={railRef}>
        {cards.map((c) => (
          <li key={c.key} className="nm-draw__slot">
            {/* The card is the OPENER and the poster is the ANCHOR, which is the
                split usePressAnchor documents and what a quick menu will need
                later: a panel has nowhere to go beside a full-width row, so it
                points at the art instead. The poster keeps clearance on both
                sides for exactly that. */}
            <button
              type="button"
              className="nm-draw__card"
              onClick={() => onOpen(c.id)}
              aria-label={"Open " + c.title}
            >
              <span className="nm-draw__rim" aria-hidden />
              <span className="nm-draw__art">
                <AnimeCover src={c.cover} alt="" decorative radius="var(--radius-sm)" />
              </span>
              <span className="nm-draw__text">
                <span className="nm-draw__title">{c.title}</span>
                <span className="nm-draw__ep">
                  Ep {c.watched}
                  {c.total ? " / " + c.total : ""}
                </span>
                <Record watched={c.watched} total={c.total} aired={c.aired} />
                {c.waiting > 0 && (
                  <span className="nm-draw__waiting">{c.waiting} waiting</span>
                )}
              </span>
            </button>
            {/* Its own control, outside the card, because a button inside a
                button is not a thing and nesting them is how you get a log
                action that also opens the detail page. */}
            <button
              type="button"
              className="nm-draw__log"
              onClick={() => void incrementEpisodes(c.id, 1)}
              aria-label={"Log episode " + (c.watched + 1) + " of " + c.title}
            >
              +1
            </button>
          </li>
        ))}
      </ul>
    </section>
  );
}

/** The same four states Tonight's record uses, at drawer scale, from the same
 *  tokens, so the two can never drift into different vocabularies. */
function Record({
  watched,
  total,
  aired,
}: {
  watched: number;
  total: number | null;
  aired: number | null;
}) {
  if (total == null || total <= 0) return null;
  if (total > CELL_CAP) {
    const pct = Math.min(100, Math.round((watched / total) * 100));
    return (
      <span
        className="nm-draw__bar"
        role="img"
        aria-label={watched + " of " + total + " episodes watched"}
      >
        <i style={{ width: pct + "%" }} />
      </span>
    );
  }
  return (
    <span
      className="nm-draw__cells"
      role="img"
      aria-label={watched + " of " + total + " episodes watched"}
    >
      {Array.from({ length: total }, (_, i) => {
        const done = i < watched;
        const next = i === watched;
        const airedYet = aired == null || i < aired;
        return (
          <i
            key={i}
            data-state={
              done ? "done" : next && airedYet ? "next" : airedYet ? "waiting" : "unaired"
            }
          />
        );
      })}
    </span>
  );
}
