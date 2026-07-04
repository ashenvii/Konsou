import { ChevronRight } from "lucide-react";
import type { ReactNode } from "react";
import { Icon } from "@/components/ui/Icon";
import type { IconComponent } from "@/components/ui/Icon";
import { PageHeader } from "@/components/layout/PageHeader";
import { Text } from "@/components/ui/Text";
import { goBack } from "@/hooks/useAppBack";

/** Standard chrome for a Settings sub-page: header with back + scroll body. */
export function SettingsSubPage({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  return (
    <div className="k-page">
      <PageHeader title={title} subtitle={subtitle} onBack={goBack} />
      <div className="k-settings konsou-scroll">{children}</div>
    </div>
  );
}

export function Section({ title, children }: { title?: string; children: ReactNode }) {
  return (
    <section className="k-settings__section">
      {title && (
        <Text size="xs" weight={600} color="tertiary" className="k-settings__sectiontitle">
          {title.toUpperCase()}
        </Text>
      )}
      <div className="k-settings__card">{children}</div>
    </section>
  );
}

export function Row({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children?: ReactNode;
}) {
  return (
    <div className="k-settings__row">
      <div className="k-settings__rowlabel">
        <Text size="base" weight={500}>
          {label}
        </Text>
        {hint && (
          <Text size="xs" color="tertiary">
            {hint}
          </Text>
        )}
      </div>
      {children}
    </div>
  );
}

export function Toggle({ on, onChange }: { on: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      className={`k-toggle${on ? " k-toggle--on" : ""}`}
      onClick={() => onChange(!on)}
    >
      <span className="k-toggle__knob" />
    </button>
  );
}

export type HubTone =
  | "account"
  | "appearance"
  | "library"
  | "notifications"
  | "about";

/** A tappable category row on the Settings hub: icon, label/hint, chevron.
 *  Each destination carries its own icon color so the hub reads as places,
 *  not a list of identical rows. */
export function HubRow({
  icon,
  label,
  hint,
  onClick,
  accent,
  tone,
}: {
  icon: IconComponent;
  label: string;
  hint?: string;
  onClick: () => void;
  accent?: boolean;
  tone?: HubTone;
}) {
  return (
    <button
      type="button"
      className={`k-hubrow${accent ? " k-hubrow--support" : ""}`}
      onClick={onClick}
    >
      <span className={`k-hubrow__icon${tone ? ` k-hubrow__icon--${tone}` : ""}`}>
        <Icon icon={icon} size={20} />
      </span>
      <span className="k-hubrow__text">
        <Text size="base" weight={600}>
          {label}
        </Text>
        {hint && (
          <Text size="xs" color="tertiary">
            {hint}
          </Text>
        )}
      </span>
      <Icon icon={ChevronRight} size={18} color="var(--color-text-tertiary)" />
    </button>
  );
}
