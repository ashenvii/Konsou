import type { ReactNode } from "react";
import { Icon } from "./Icon";
import type { IconComponent } from "./Icon";
import { dailyTip } from "@/lib/trivia";

interface EmptyStateProps {
  icon?: IconComponent;
  title: string;
  subtitle?: string;
  action?: ReactNode;
  /** Show today's app tip under the message. Nice on the big idle screens
   *  (empty library, nothing tracked yet); off by default so it never crowds
   *  small inline empties. */
  showTip?: boolean;
}

export function EmptyState({ icon, title, subtitle, action, showTip }: EmptyStateProps) {
  const tip = showTip ? dailyTip() : null;
  return (
    <div className="k-empty">
      {icon && (
        <div className="k-empty__icon">
          <Icon icon={icon} size={40} color="var(--color-text-tertiary)" />
        </div>
      )}
      <p className="k-empty__title">{title}</p>
      {subtitle && <p className="k-empty__subtitle">{subtitle}</p>}
      {action && <div className="k-empty__action">{action}</div>}
      {tip && (
        <p className="k-empty__tip">
          <span aria-hidden>{tip.glyph ?? "✧"}</span> {tip.text}
        </p>
      )}
    </div>
  );
}
