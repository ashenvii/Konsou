import type { LucideIcon, LucideProps } from "lucide-react";

/** The shape of a Lucide icon component, so the named icon imports
 *  (List, Bell, …) are assignable without friction. */
export type IconComponent = LucideIcon;

interface IconProps {
  icon: IconComponent;
  /** Standard 24px. Compact 20px. Hero 32px. */
  size?: number;
  /** Back-compat with the old icon API. Lucide is outline-only, so "fill"
   *  renders a heavier stroke for an "active" look. For glyphs that should be
   *  genuinely solid (Star, Bookmark) pass `fill` instead. */
  weight?: "regular" | "fill";
  color?: string;
  className?: string;
  label?: string;
  strokeWidth?: number;
  /** Paint the glyph solid with the current color. */
  fill?: boolean;
}

export function Icon({
  icon: IconCmp,
  size = 24,
  weight = "regular",
  color,
  className,
  label,
  strokeWidth,
  fill = false,
}: IconProps) {
  const props: LucideProps = {
    size,
    color: color ?? "currentColor",
    className,
    strokeWidth: strokeWidth ?? (weight === "fill" ? 2.4 : 2),
    "aria-hidden": label ? undefined : true,
  };
  if (label) props["aria-label"] = label;
  if (fill) props.fill = "currentColor";
  return <IconCmp {...props} />;
}
