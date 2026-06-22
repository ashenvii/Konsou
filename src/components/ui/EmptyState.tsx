import type { ReactNode } from "react";
import { Icon } from "./Icon";
import type { IconComponent } from "./Icon";

interface EmptyStateProps {
  icon?: IconComponent;
  title: string;
  subtitle?: string;
  action?: ReactNode;
}

export function EmptyState({ icon, title, subtitle, action }: EmptyStateProps) {
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
    </div>
  );
}
