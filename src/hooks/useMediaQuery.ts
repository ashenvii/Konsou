import { useEffect, useState } from "react";

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(
    () => typeof window !== "undefined" && window.matchMedia(query).matches,
  );

  useEffect(() => {
    const mql = window.matchMedia(query);
    const onChange = () => setMatches(mql.matches);
    onChange();
    mql.addEventListener("change", onChange);
    return () => mql.removeEventListener("change", onChange);
  }, [query]);

  return matches;
}

/** Konsou breakpoints: mobile 0–1023, desktop 1024+, wide 1280+. */
export function useBreakpoint() {
  const isDesktop = useMediaQuery("(min-width: 1024px)");
  const isWide = useMediaQuery("(min-width: 1280px)");
  return { isMobile: !isDesktop, isDesktop, isWide };
}

/**
 * The one condition that decides sheet vs anchored popover, the same split DIM
 * makes. It is deliberately NOT the desktop breakpoint: a tablet, or a phone
 * turned sideways, has room beside a card for a popover to point at, and only
 * a narrow upright screen genuinely has nowhere to put one.
 */
export function useIsPhonePortrait(): boolean {
  return useMediaQuery("(max-width: 719px) and (orientation: portrait)");
}
