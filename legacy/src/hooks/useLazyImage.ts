import { useEffect, useRef, useState } from "react";

/**
 * IntersectionObserver-based lazy loading. Replaces native `loading="lazy"`,
 * which Tauri's Android WebView ignores (Trap 4). Harmless on desktop.
 *
 * ONE observer for the whole app, not one per cover. A virtualized list
 * recycles rows constantly, so a per-cover observer meant constructing and
 * tearing down an IntersectionObserver every time a row scrolled in or out —
 * on a fling that is hundreds of observer lifecycles a second, all of it on
 * the main thread, competing with the scroll it is supposed to be serving.
 * A shared observer is registered once and only ever gains and loses targets.
 */

/** Generous lookahead: start fetching well before the card scrolls into view so
 *  covers are usually decoded by the time they appear. Fetching early costs a
 *  little network, not render time — unlike overscan, which costs paint work
 *  every frame. */
const ROOT_MARGIN = "600px";

let observer: IntersectionObserver | null = null;
const pending = new WeakMap<Element, () => void>();

function shared(): IntersectionObserver {
  if (!observer) {
    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          const fire = pending.get(entry.target);
          if (!fire) continue;
          // Unobserve before firing: this target has done its one job, and
          // leaving it registered keeps handing us entries to walk on every
          // subsequent intersection change.
          pending.delete(entry.target);
          observer?.unobserve(entry.target);
          fire();
        }
      },
      { rootMargin: ROOT_MARGIN },
    );
  }
  return observer;
}

export function useLazyImage(src: string | null | undefined) {
  const [visibleSrc, setVisibleSrc] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setLoaded(false);
    setVisibleSrc(null);
    if (!src || !ref.current) return;

    const el = ref.current;
    const io = shared();
    pending.set(el, () => setVisibleSrc(src));
    io.observe(el);
    return () => {
      pending.delete(el);
      io.unobserve(el);
    };
  }, [src]);

  return { ref, visibleSrc, loaded, onLoad: () => setLoaded(true) };
}
