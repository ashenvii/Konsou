import type { ButtonHTMLAttributes, ReactNode } from "react";

type Variant = "primary" | "secondary" | "ghost" | "danger";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  block?: boolean;
  iconOnly?: boolean;
  children?: ReactNode;
}

export function Button({
  variant = "secondary",
  size = "md",
  block,
  iconOnly,
  className,
  children,
  type = "button",
  ...rest
}: ButtonProps) {
  const classes = [
    "k-btn",
    `k-btn--${variant}`,
    `k-btn--${size}`,
    block ? "k-btn--block" : "",
    iconOnly ? "k-btn--icon" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button type={type} className={classes} {...rest}>
      {children}
    </button>
  );
}
