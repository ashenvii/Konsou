import type { ReactNode } from "react";

interface ChipProps {
  active?: boolean;
  onClick?: () => void;
  onRemove?: () => void;
  removeLabel?: string;
  children: ReactNode;
  className?: string;
}

export function Chip({
  active,
  onClick,
  onRemove,
  removeLabel = "Remove",
  children,
  className,
}: ChipProps) {
  return (
    <span
      className={`k-chip${active ? " k-chip--active" : ""}${onClick ? " k-chip--clickable" : ""}${className ? ` ${className}` : ""}`}
    >
      <button
        type="button"
        className="k-chip__label"
        onClick={onClick}
        disabled={!onClick}
      >
        {children}
      </button>
      {onRemove && (
        <button
          type="button"
          className="k-chip__remove"
          onClick={onRemove}
          aria-label={removeLabel}
        >
          ×
        </button>
      )}
    </span>
  );
}
