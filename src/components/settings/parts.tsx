import { ArrowUpRight, ChevronRight } from "lucide-react";
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
  stack,
  children,
}: {
  label: string;
  hint?: string;
  /** Wide control (segmented, swatches): stack it under the label on mobile
   *  instead of crushing both into one side-by-side line. No-op on desktop. */
  stack?: boolean;
  children?: ReactNode;
}) {
  return (
    <div className={`k-settings__row${stack ? " k-settings__row--stack" : ""}`}>
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

/**
 * A ruled row that takes you somewhere: a settings page, or out to the web.
 *
 * Shared so "this row goes somewhere" looks the same wherever it appears —
 * About's doors into What's New and Support, and Support's own outbound links.
 * The trailing mark is the only difference between the two, and it is the mark
 * that says which kind of trip it is: a chevron stays in the app, the outbound
 * arrow leaves it.
 */
export function LinkRow({
  icon,
  title,
  hint,
  external,
  onClick,
}: {
  icon: IconComponent;
  title: string;
  hint: string;
  /** Leaves the app (opens a browser), so it carries the outbound mark. */
  external?: boolean;
  onClick: () => void;
}) {
  return (
    <button type="button" className="k-linkrow" onClick={onClick}>
      <span className="k-linkrow__icon">
        <Icon icon={icon} size={17} />
      </span>
      <span className="k-linkrow__text">
        <Text size="base" weight={600}>
          {title}
        </Text>
        <Text size="xs" color="tertiary">
          {hint}
        </Text>
      </span>
      <Icon
        icon={external ? ArrowUpRight : ChevronRight}
        size={16}
        className="k-linkrow__mark"
      />
    </button>
  );
}

export type HubTone =
  | "account"
  | "appearance"
  | "library"
  | "notifications"
  | "whatsnew"
  | "support"
  | "about";

/** A tappable category row on the Settings hub: icon, label/hint, chevron.
 *  Each destination carries its own icon color so the hub reads as places,
 *  not a list of identical rows. */
export function HubRow({
  icon,
  label,
  hint,
  onClick,
  tone,
}: {
  icon: IconComponent;
  label: string;
  hint?: string;
  onClick: () => void;
  tone?: HubTone;
}) {
  return (
    <button type="button" className="k-hubrow" onClick={onClick}>
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
      <Icon icon={ChevronRight} size={18} color="var(--ink-label)" />
    </button>
  );
}
