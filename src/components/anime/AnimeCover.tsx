import { Image } from "@phosphor-icons/react";
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

/** Lazy, placeholder-backed cover image. Always 2:3 unless overridden by parent. */
export function AnimeCover({
  src,
  alt,
  decorative,
  className,
  radius = "var(--radius-md)",
}: AnimeCoverProps) {
  const { ref, visibleSrc, loaded, onLoad } = useLazyImage(src);

  return (
    <div
      ref={ref}
      className={`k-cover${className ? ` ${className}` : ""}`}
      style={{ borderRadius: radius }}
    >
      {!loaded && (
        <div className="k-cover__placeholder">
          <Icon icon={Image} size={20} color="var(--color-text-tertiary)" />
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
