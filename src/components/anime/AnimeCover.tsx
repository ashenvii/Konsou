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
      {!loaded && (
        <div
          className="k-cover__placeholder"
          style={
            initial
              ? {
                  background: `linear-gradient(155deg, oklch(34% 0.055 ${hue}), oklch(21% 0.04 ${(hue + 50) % 360}))`,
                }
              : undefined
          }
        >
          {initial ? (
            <span className="k-cover__initial" aria-hidden>
              {initial}
            </span>
          ) : (
            <Icon icon={Image} size={20} color="var(--color-text-tertiary)" />
          )}
        </div>
      )}
      {visibleSrc && (
        <img
          src={visibleSrc}
          alt={decorative ? "" : alt}
          role={decorative ? "presentation" : undefined}
          onLoad={onLoad}
          className="k-cover__img"
          style={{ opacity: loaded ? 1 : 0 }}
          draggable={false}
        />
      )}
    </div>
  );
}
