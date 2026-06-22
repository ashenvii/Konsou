import { useEffect, useRef, useState } from "react";

/**
 * IntersectionObserver-based lazy loading. Replaces native `loading="lazy"`,
 * which Tauri's Android WebView ignores (Trap 4). Harmless on desktop.
 */
export function useLazyImage(src: string | null | undefined) {
  const [visibleSrc, setVisibleSrc] = useState<string | null>(null);
  const [loaded, setLoaded] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setLoaded(false);
    setVisibleSrc(null);
    if (!src || !ref.current) return;

    const el = ref.current;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          setVisibleSrc(src);
          observer.disconnect();
        }
      },
      { rootMargin: "200px" },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [src]);

  return { ref, visibleSrc, loaded, onLoad: () => setLoaded(true) };
}
