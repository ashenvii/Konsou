import { useEffect, useState } from "react";
import { Sparkles } from "lucide-react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { HoldButton } from "@/components/ui/HoldButton";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { markVersionSeen, pendingWhatsNew, splitBold } from "@/lib/changelog";
import type { ChangelogEntry } from "@/lib/changelog";

/** One changelog entry rendered as sections of bullets. Shared by the
 *  post-update popup and the About page's version history. */
export function ChangelogBody({ entry }: { entry: ChangelogEntry }) {
  return (
    <div className="k-changelog">
      {entry.sections.map((s) => (
        <div key={s.title} className="k-changelog__section">
          <span className={`k-changelog__kind k-changelog__kind--${s.title.toLowerCase()}`}>
            {s.title}
          </span>
          <ul className="k-changelog__items">
            {s.items.map((item, i) => (
              <li key={i}>
                {splitBold(item).map((part, j) =>
                  j % 2 === 1 ? <strong key={j}>{part}</strong> : part,
                )}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}

/**
 * Post-update "here's what changed" popup. Shows once per version, on the
 * first launch after an update, and is acknowledged with a hold-to-confirm —
 * the same deliberate gesture with a mouse press or a finger.
 */
export function WhatsNew() {
  const [entry, setEntry] = useState<ChangelogEntry | null>(null);

  useEffect(() => {
    // After boot settles: never race the onboarding overlay on first paint.
    const t = setTimeout(() => setEntry(pendingWhatsNew()), 400);
    return () => clearTimeout(t);
  }, []);

  if (!entry) return null;

  const dismiss = () => {
    markVersionSeen();
    setEntry(null);
  };

  return (
    <BottomSheet open onClose={dismiss} title={`What's new in v${entry.version}`}>
      <div className="k-whatsnew">
        <div className="k-whatsnew__lede">
          <Icon icon={Sparkles} size={16} color="var(--live-ink)" />
          <Text size="sm" color="secondary">
            Konsou updated{entry.date ? ` on ${entry.date}` : ""}. Here is what changed.
          </Text>
        </div>
        <ChangelogBody entry={entry} />
        <HoldButton onConfirm={dismiss} className="k-whatsnew__confirm">
          Hold to continue
        </HoldButton>
      </div>
    </BottomSheet>
  );
}
