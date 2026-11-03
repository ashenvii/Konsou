import { Image } from "lucide-react";
import { useLazyImage } from "@/hooks/useLazyImage";
import { Icon } from "@/components/ui/Icon";

interface AnimeCoverProps {
  src: string | null | undefined;
  alt: string;
  /** Title is visible adjacent (list/compact) → cover is decorative. */
  decorative?: boolean;
  className?: string;
  radius?: string;
}

/** Deterministic hue from the title so every fallback tile gets its own color
 *  instead of a uniform grey hole in a wall of art. Exported for the detail
 *  banner's no-art fallback, which uses the same identity color. */
export function hueFromTitle(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 360;
  return h;
}

/** Lazy, placeholder-backed cover image. Always 2:3 unless overridden by parent.
 *  While loading (and when the image never arrives) the tile shows the title's
 *  first letter on a hue derived from the title, so covers-as-hero survives
 *  missing art. */
export function AnimeCover({
  src,
  alt,
  decorative,
  className,
  radius = "var(--radius-md)",
}: AnimeCoverProps) {
  const { ref, visibleSrc, loaded, onLoad } = useLazyImage(src);

  const initial = alt?.trim().charAt(0).toUpperCase() ?? "";
  const hue = initial ? hueFromTitle(alt.trim()) : 0;

  return (
    <div
      ref={ref}
      className={`k-cover${className ? ` ${className}` : ""}`}
      style={{ borderRadius: radius }}
    >
      {/* The placeholder stays MOUNTED and fades out. Unmounting it the moment
          each image arrived meant a DOM removal per cover, and during a fling
          that is a stream of node removals — each one layout work the browser
          has to do on the same thread that is running the scroll. Fading a
          node that is already there is a compositor job and costs the scroll
          nothing. */}
      <div
        className={`k-cover__placeholder${loaded ? " k-cover__placeholder--done" : ""}`}
        style={
          initial
            ? {
                background: `linear-gradient(155deg, oklch(34% 0.055 ${hue}), oklch(21% 0.04 ${(hue + 50) % 360}))`,
              }
            : undefined
        }
        aria-hidden
      >
        {initial ? (
          <span className="k-cover__initial">{initial}</span>
        ) : (
          <Icon icon={Image} size={20} color="var(--ink-label)" />
        )}
      </div>
      {visibleSrc && (
        <img
          src={visibleSrc}
          alt={decorative ? "" : alt}
          role={decorative ? "presentation" : undefined}
          onLoad={onLoad}
          className="k-cover__img"
          style={{ opacity: loaded ? 1 : 0 }}
          draggable={false}
          /* Decode off the main thread. Without this the browser decodes the
             bitmap synchronously at paint time, which is the single biggest
             per-image cost and lands squarely inside the scroll frame. */
          decoding="async"
          /* Covers are never the page's LCP element and never urgent: they can
             wait behind whatever the app is actually doing. */
          fetchPriority="low"
        />
      )}
    </div>
  );
}
