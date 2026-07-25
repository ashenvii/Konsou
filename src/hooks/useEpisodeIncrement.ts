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
}

export function useEpisodeIncrement(
  anilistId: number,
  currentEp: number,
  total?: number | null,
  { undoToast = false }: EpisodeIncrementOptions = {},
) {
  const setEpisodes = useListStore((s) => s.setEpisodes);
  const pendingRef = useRef(0);
  const [pending, setPending] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

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
    // (same rule the Hero +Ep path already uses).
    const reachedFinale = total != null && after >= total;
    if (undoToast && !reachedFinale) {
      recordEpisodeLog(anilistId, before, after);
    }
  }, [anilistId, currentEp, setEpisodes, total, undoToast]);

  const increment = useCallback(() => {
    if (total != null && currentEp + pendingRef.current >= total) return;
    pendingRef.current += 1;
    setPending(pendingRef.current);
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => void flush(), ACCUMULATE_MS);
  }, [flush, total, currentEp]);

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
