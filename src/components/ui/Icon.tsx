import type { ForwardRefExoticComponent, RefAttributes } from "react";
import type { IconProps as PhosphorIconProps } from "@phosphor-icons/react";

/** The exact shape of a Phosphor icon component, so the named icon imports
 *  (List, Bell, …) are assignable without friction. */
export type IconComponent = ForwardRefExoticComponent<
  PhosphorIconProps & RefAttributes<SVGSVGElement>
>;

interface IconProps {
  icon: IconComponent;
  /** Standard 24px. Compact 20px. Hero 32px. */
  size?: number;
  /** Konsou uses ONLY regular (inactive) and fill (active). */
  weight?: "regular" | "fill";
  color?: string;
  className?: string;
  label?: string;
}

export function Icon({
  icon: IconCmp,
  size = 24,
  weight = "regular",
  color,
  className,
  label,
}: IconProps) {
  return (
    <IconCmp
      size={size}
      weight={weight}
      color={color ?? "currentColor"}
      className={className}
      aria-hidden={label ? undefined : true}
    />
  );
}
