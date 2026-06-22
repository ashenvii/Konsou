import { Icon } from "@/components/ui/Icon";
import type { ListStatus } from "@/types/list";
import { statusMeta } from "./statusMeta";

interface StatusBadgeProps {
  status: ListStatus;
  /** Pill with icon + label (default) or just a coloured dot. */
  variant?: "pill" | "dot";
  onClick?: () => void;
  size?: number;
}

export function StatusBadge({
  status,
  variant = "pill",
  onClick,
  size = 16,
}: StatusBadgeProps) {
  const meta = statusMeta(status);

  if (variant === "dot") {
    return (
      <span
        className="k-status-dot"
        style={{ background: meta.color }}
        aria-label={meta.label}
        title={meta.label}
      />
    );
  }

  const content = (
    <>
      <Icon icon={meta.icon} size={size} weight="fill" color={meta.color} />
      <span className="k-status-badge__label">{meta.label}</span>
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        className="k-status-badge k-status-badge--button"
        style={{ color: meta.color }}
        onClick={onClick}
        aria-label={`Change status, currently ${meta.label}`}
        aria-haspopup="dialog"
      >
        {content}
      </button>
    );
  }

  return (
    <span className="k-status-badge" style={{ color: meta.color }}>
      {content}
    </span>
  );
}
