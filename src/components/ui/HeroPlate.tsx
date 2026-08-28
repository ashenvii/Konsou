import { AnimeCover } from "@/components/anime/AnimeCover";
import { accentHalo, accentSurface, useCoverAccent } from "@/hooks/useCoverAccent";
import type { CSSProperties, ReactNode } from "react";

interface HeroPlateProps {
  /** Wide art, when the record has any. Used sharp, as a real backdrop. */
  banner?: string | null;
  /** The poster. Floats sharp on top, and when there is no banner its own
   *  colour becomes the bed. */
  cover?: string | null;
  alt: string;
  /** Everything laid over the art: title, meta, actions. */
  children: ReactNode;
  /** Extra classes for the caller's own sizing and behaviour. */
  className?: string;
  style?: CSSProperties;
  onClick?: () => void;
}

/**
 * One title, made large.
 *
 * The poster floats sharp over a bed built from its own colour, under a scrim
 * that keeps ink legible whatever the art is doing.
 *
 * THE BED IS NOT A BLURRED COPY OF THE POSTER, and that was the mistake worth
 * writing down. A poster is 2:3; a plate is wide. `background-size: cover`
 * therefore shows one thin horizontal slice of the art blown up several times,
 * which on most covers is a single flat region — so the "blurred artwork" bed
 * had almost no picture in it, and heavy blur plus a brightness cut finished
 * the job and left flat grey. It was also expensive: `useCoverAccent`'s own
 * note says a `filter: blur()` on a surface this size is a full-surface raster
 * every frame it changes, which is the last thing a crossfade needs.
 *
 * So the bed is the art's clamped dominant colour plus a soft radial halo,
 * which is the device this app already ships for exactly this problem. It has
 * real colour from the artwork, it costs one gradient, and its lightness is
 * fixed by the same clamp that guarantees ink stays legible on it.
 *
 * Deliberately not a button or a link: the surfaces using it carry several
 * actions over the art, and a plate that is itself one control cannot hold
 * them.
 */
export function HeroPlate({
  banner,
  cover,
  alt,
  children,
  className,
  style,
  onClick,
}: HeroPlateProps) {
  const accent = useCoverAccent(cover);
  const bed = accentSurface(accent);
  const halo = accentHalo(accent);

  return (
    <div
      className={`k-heroplate${className ? ` ${className}` : ""}`}
      style={
        {
          ...style,
          // Falls back to the world's recessed ground, so a cover that has not
          // loaded (or cannot be read) still gives a deliberate surface rather
          // than a hole.
          ...(bed ? { "--plate-bed": bed } : null),
          ...(halo ? { "--plate-halo": halo } : null),
        } as CSSProperties
      }
      onClick={onClick}
    >
      {banner ? (
        <div
          className="k-heroplate__bg"
          style={{ backgroundImage: `url("${banner}")` }}
          aria-hidden
        />
      ) : (
        <div className="k-heroplate__bed" aria-hidden />
      )}
      <div className="k-heroplate__scrim" aria-hidden />
      <div className="k-heroplate__body">
        <div className="k-heroplate__poster">
          <AnimeCover src={cover ?? null} alt={alt} decorative radius="var(--radius-md)" />
        </div>
        <div className="k-heroplate__text">{children}</div>
      </div>
    </div>
  );
}
