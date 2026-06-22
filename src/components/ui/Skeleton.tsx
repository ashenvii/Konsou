import type { CSSProperties } from "react";

interface SkeletonProps {
  width?: number | string;
  height?: number | string;
  radius?: string;
  className?: string;
  style?: CSSProperties;
}

/** Shimmer placeholder. Matches the exact dimensions of the content it replaces. */
export function Skeleton({
  width = "100%",
  height = 16,
  radius = "var(--radius-md)",
  className,
  style,
}: SkeletonProps) {
  return (
    <div
      className={`k-skeleton${className ? ` ${className}` : ""}`}
      style={{ width, height, borderRadius: radius, ...style }}
      aria-hidden
    />
  );
}
