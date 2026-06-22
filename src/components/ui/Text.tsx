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
type TextColor = "primary" | "secondary" | "tertiary" | "accent";
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
  primary: "var(--color-text-primary)",
  secondary: "var(--color-text-secondary)",
  tertiary: "var(--color-text-tertiary)",
  accent: "var(--color-accent)",
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
  ...rest
}: TextProps) {
  const clampStyle: CSSProperties =
    clamp === 1
      ? { whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }
      : clamp && clamp > 1
        ? {
            display: "-webkit-box",
            WebkitLineClamp: clamp,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
          }
        : {};

  return createElement(as, {
    className,
    style: {
      fontSize: `var(--text-${size})`,
      lineHeight: `var(--leading-${size})`,
      fontWeight: weight,
      color: colorVar[color],
      ...clampStyle,
      ...style,
    },
    ...rest,
  });
}
