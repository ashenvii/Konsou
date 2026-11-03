import { createElement } from "react";
import type { CSSProperties, JSX, ReactNode } from "react";

type TextSize =
  | "2xs"
  | "xs"
  | "sm"
  | "base"
  | "lg"
  | "xl"
  | "2xl"
  | "3xl";
type TextColor = "primary" | "secondary" | "tertiary" | "accent" | "onCover";
type TextWeight = 400 | 500 | 600 | 700 | 800;

interface TextProps {
  as?: keyof JSX.IntrinsicElements;
  size?: TextSize;
  weight?: TextWeight;
  color?: TextColor;
  /** Clamp to N lines with an ellipsis. 1 = single-line truncate. */
  clamp?: number;
  className?: string;
  style?: CSSProperties;
  title?: string;
  id?: string;
  children?: ReactNode;
  onClick?: () => void;
}

const colorVar: Record<TextColor, string> = {
  primary: "var(--ink-body)",
  secondary: "var(--ink-meta)",
  tertiary: "var(--ink-label)",
  accent: "var(--filed-ink)",
  // Fixed light for text sitting over cover art / a dark scrim on any theme.
  onCover: "oklch(100% 0 0 / 96%)",
};

/** Typographic primitive — the single place font sizing/weight/color is decided. */
export function Text({
  as = "span",
  size = "base",
  weight = 500,
  color = "primary",
  clamp,
  className,
  style,
  title,
  children,
  ...rest
}: TextProps) {
  // Single-line truncate needs a block box: text-overflow/overflow are ignored
  // on the default inline span, which is why long anime titles used to clip
  // straight out of their row instead of ending in an ellipsis.
  const clampStyle: CSSProperties =
    clamp === 1
      ? {
          display: "block",
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }
      : clamp && clamp > 1
        ? {
            display: "-webkit-box",
            WebkitLineClamp: clamp,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
          }
        : {};

  // Any truncated string title keeps its full text reachable on hover/long-press
  // without a trip to the detail page. Explicit `title` always wins.
  const resolvedTitle =
    title ?? (clamp && typeof children === "string" ? children : undefined);

  return createElement(
    as,
    {
      className,
      title: resolvedTitle,
      style: {
        fontSize: `var(--text-${size})`,
        lineHeight: `var(--leading-${size})`,
        fontWeight: weight,
        color: colorVar[color],
        ...clampStyle,
        ...style,
      },
      ...rest,
    },
    children,
  );
}
