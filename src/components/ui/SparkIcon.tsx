import type { CSSProperties } from "react";
import { Icon } from "./Icon";
import type { IconComponent } from "./Icon";

/**
 * An icon that beats.
 *
 * One component, used everywhere the mark appears — the desktop rail and the
 * phone brand strip both render this, so there is a single place to change how
 * it looks and a single place for it to be wrong. It replaces two hand-built
 * copies whose rings were centred against different boxes (a 34px button in one
 * shell, a 22px icon well in the other), which is exactly why one of them sat
 * off-centre.
 *
 * The wrapper is always exactly the glyph's own box and everything else is
 * derived from `--spark-size`, so the rings cannot drift out of register no
 * matter what the surrounding shell is.
 *
 * The motion is layered on purpose, because a single quiet pulse was easy to
 * miss entirely:
 *   1. the outline glyph beats (a double thump, like a real heart),
 *   2. a solid copy of the same glyph inks IN on the beat and fades back out,
 *      which is the stamp pressing and lifting,
 *   3. two hairline rings leave on a stagger, so the impression spreads.
 * All of it is transform and opacity only, so it composites on its own layer,
 * and it is mostly stillness: the cycle spends about two thirds of its length
 * doing nothing at all.
 */
export function SparkIcon({
  icon,
  size = 22,
  className,
}: {
  icon: IconComponent;
  size?: number;
  className?: string;
}) {
  return (
    <span
      className={`k-spark${className ? ` ${className}` : ""}`}
      style={{ "--spark-size": `${size}px` } as CSSProperties}
      aria-hidden
    >
      {/* Two rings, staggered by the CSS, so the beat leaves a spreading mark
          rather than a single ping. */}
      <span className="k-spark__ring" />
      <span className="k-spark__ring k-spark__ring--late" />
      <span className="k-spark__glyph">
        <Icon icon={icon} size={size} />
      </span>
      {/* The inked copy: same glyph, filled, revealed on the beat. */}
      <span className="k-spark__ink">
        <Icon icon={icon} size={size} fill />
      </span>
    </span>
  );
}
