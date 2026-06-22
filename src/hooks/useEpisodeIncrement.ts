import { useCallback, useEffect, useRef, useState } from "react";
import { useListStore } from "@/lib/store/listStore";

/**
 * The AniHyou IncrementOneButton pattern: accumulate rapid +1 taps for 2s, then
 * fire a single update. Prevents 10 writes during an episode catch-up session.
 * The button shows "+N" while the window is open.
 */
const ACCUMULATE_MS = 2000;

export function useEpisodeIncrement(
  anilistId: number,
  currentEp: number,
  total?: number | null,
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
    await setEpisodes(anilistId, currentEp + add);
  }, [anilistId, currentEp, setEpisodes]);

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
