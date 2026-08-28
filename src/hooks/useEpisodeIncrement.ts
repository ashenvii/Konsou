import { useCallback, useEffect, useRef, useState } from "react";
import { useListStore } from "@/lib/store/listStore";
import { recordEpisodeLog } from "@/lib/store/episodeUndo";

/**
 * The AniHyou IncrementOneButton pattern: accumulate rapid +1 taps for 2s, then
 * fire a single update. Prevents 10 writes during an episode catch-up session.
 * The button shows "+N" while the window is open.
 */
const ACCUMULATE_MS = 2000;

interface EpisodeIncrementOptions {
  /** After the batch commits, raise an "Undo" toast that reverts the whole
   *  batch in one tap. On for quick-tap surfaces (cards), where a stray tap
   *  while scrolling is easy to make; off for the deliberate stepper, which
   *  already has its own -1 and a cancel affordance. Matches the Hero +Ep
   *  path so accidental logging is reversible everywhere. */
  undoToast?: boolean;
  /** The real stopping point for a rapid-tap batch, when it differs from the
   *  show's eventual total — a still-airing show can't be tapped past what
   *  has actually released. Deliberately separate from `total`: `total` still
   *  drives the "reached the finale" prompt below, which must only fire once
   *  the real run is over, not once the batch catches up to today's episode. */
  ceiling?: number | null;
  /** Fires when a tap is blocked by `ceiling` (not by `total` — reaching the
   *  real finale has its own toast below). `increment` guards BEFORE calling
   *  `setEpisodes` at all, which is what makes the accumulator safe against a
   *  burst of taps — but it also means the store's own "only N have aired"
   *  toast never gets a chance to run, since the store never sees the tap.
   *  Without this callback a blocked tap on a still-airing show did nothing
   *  visible whatsoever. */
  onBlocked?: () => void;
}

export function useEpisodeIncrement(
  anilistId: number,
  currentEp: number,
  total?: number | null,
  { undoToast = false, ceiling, onBlocked }: EpisodeIncrementOptions = {},
) {
  const setEpisodes = useListStore((s) => s.setEpisodes);
  const pendingRef = useRef(0);
  const [pending, setPending] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const cap = ceiling ?? total;

  const flush = useCallback(async () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    const add = pendingRef.current;
    if (add === 0) return;
    pendingRef.current = 0;
    setPending(0);
    const before = currentEp;
    const after = before + add;
    await setEpisodes(anilistId, after);
    // Reaching the finale hands the toast to setEpisodes' mark-complete action;
    // a stacked Undo would fight it, so only offer undo short of the finale
    // (same rule the Hero +Ep path already uses). Keyed to the real total,
    // not the aired ceiling -- catching up to today's episode is not a finale.
    const reachedFinale = total != null && after >= total;
    if (undoToast && !reachedFinale) {
      recordEpisodeLog(anilistId, before, after);
    }
  }, [anilistId, currentEp, setEpisodes, total, undoToast]);

  const increment = useCallback(() => {
    if (cap != null && currentEp + pendingRef.current >= cap) {
      onBlocked?.();
      return;
    }
    pendingRef.current += 1;
    setPending(pendingRef.current);
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => void flush(), ACCUMULATE_MS);
  }, [flush, cap, currentEp, onBlocked]);

  const cancel = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    pendingRef.current = 0;
    setPending(0);
  }, []);

  useEffect(
    () => () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    },
    [],
  );

  return {
    increment,
    cancel,
    flush,
    pending,
    isPending: pending > 0,
    displayEp: currentEp + pending,
  };
}
