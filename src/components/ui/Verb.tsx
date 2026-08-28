import { Icon } from "@/components/ui/Icon";
import type { IconComponent } from "@/components/ui/Icon";

/**
 * One act, as a mark.
 *
 * The whole argument for the verb rail is that a quick menu should be something
 * you read with a column of things you can do to it, rather than a form with
 * five labelled sections. That only pays off if a verb costs an icon and
 * nothing else — the moment it carries a visible word it is back to being a row
 * in a form, and the panel is back to being long.
 *
 * So the word moves to two places that cost no layout: `title`, which the
 * platform draws as a tooltip on hover, and `aria-label`, which is what a
 * screen reader announces. Nobody loses the label; it just stops taking space
 * from the artwork.
 *
 * Lives in ui/ rather than beside either quick menu because both of them use
 * it, and a second hand-built copy of the same control is how two surfaces that
 * are supposed to be one thing drift apart. That already happened once here:
 * QuickMenu and FranchiseSheet spent a release answering the same question in
 * two different shapes.
 */
export function Verb({
  icon,
  label,
  onClick,
  active = false,
  danger = false,
  disabled = false,
  tint,
}: {
  icon: IconComponent;
  /** Said out loud by a screen reader, drawn as the tooltip on hover. Write it
   *  as the act ("Mark completed"), not the noun ("Status"). */
  label: string;
  onClick: () => void;
  /** This verb's state is currently true — the status the entry is in. */
  active?: boolean;
  /** Destructive. Sits below the rule at the bottom of the rail. */
  danger?: boolean;
  disabled?: boolean;
  /** The glyph's own colour, for the verbs that carry a status hue. The plate
   *  behind it stays neutral: colour identifies the act, it does not draw the
   *  box. */
  tint?: string;
}) {
  return (
    <button
      type="button"
      className={`k-verb${active ? " k-verb--on" : ""}${danger ? " k-verb--danger" : ""}`}
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      aria-pressed={active || undefined}
      title={label}
    >
      <Icon
        icon={icon}
        size={19}
        weight={active ? "fill" : "regular"}
        color={tint}
      />
    </button>
  );
}

/** The rule between the reading verbs and the destructive one. A press at the
 *  bottom of the column should not feel like the same gesture as a press at
 *  the top. */
export function VerbRule() {
  return <span className="k-verbrule" aria-hidden />;
}
