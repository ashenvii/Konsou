import { useEffect, useState } from "react";
import { Check } from "lucide-react";
import { AnimeCover } from "@/components/anime/AnimeCover";
import { formatChipMeta, relationChipMeta } from "@/components/anime/relationMeta";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Text } from "@/components/ui/Text";
import { formatLabel, getCoverUrl, preferredTitle } from "@/lib/format";
import { useCatchUpStore } from "@/lib/store/catchUpStore";
import { useListStore } from "@/lib/store/listStore";
import { useSettingsStore } from "@/lib/store/settingsStore";

/**
 * "What have you already watched?" — shown when a user adds a later season of a
 * franchise whose earlier entries aren't tracked. Replaces the old silent
 * cascade that marked every prior season/movie/OVA as completed, so unwatched
 * side entries no longer drag a whole card into the wrong state.
 */
export function CatchUpSheet() {
  const request = useCatchUpStore((s) => s.queue[0] ?? null);
  const close = useCatchUpStore((s) => s.close);
  const addWatchedPrior = useListStore((s) => s.addWatchedPrior);
  const titleLanguage = useSettingsStore((s) => s.titleLanguage);
  const [checked, setChecked] = useState<Set<number>>(new Set());

  // Default the main seasons ticked: someone on a later season usually did
  // watch what came before. Side entries (OVAs, movies off the chain) start
  // unticked — those are the ones people actually skip.
  useEffect(() => {
    if (request) {
      setChecked(
        new Set(
          request.candidates
            .filter((c) => c.relationType === "PREQUEL")
            .map((c) => c.id),
        ),
      );
    }
  }, [request]);

  const candidates = request?.candidates ?? [];
  const count = checked.size;

  const toggle = (id: number) =>
    setChecked((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const confirm = () => {
    if (!request) return;
    const picked = candidates.filter((c) => checked.has(c.id));
    void addWatchedPrior(request.rootId, picked);
    close();
  };

  return (
    <BottomSheet
      open={request != null}
      onClose={close}
      title="Already caught up?"
      // A forced choice, not a passing sheet: it holds the answer to "what did
      // you already watch" and a stray swipe/backdrop tap used to lose it for
      // good mid-scroll. Only the Skip and Mark buttons below dismiss it.
      dismissable={false}
    >
      <div className="k-catchup">
        <Text size="sm" color="secondary" className="k-catchup__intro">
          {request?.primaryTitle
            ? `“${request.primaryTitle}” sits later in this series. Tick anything you've already finished — only those get marked complete, and the rest stay off your list.`
            : "Tick anything you've already finished — only those get marked complete, and the rest stay off your list."}
        </Text>

        <div className="k-catchup__list konsou-scroll">
          {candidates.map((c) => {
            const on = checked.has(c.id);
            // Side entries (OVAs, movies, spin-offs) wear their kind so the
            // list reads at a glance; plain prequel seasons stay chipless.
            const relChip =
              c.relationType !== "PREQUEL" ? relationChipMeta(c.relationType) : null;
            const fmtChip = formatChipMeta(c.format);
            const meta = [
              fmtChip ? null : formatLabel(c.format),
              c.episodes ? `${c.episodes} eps` : null,
            ]
              .filter(Boolean)
              .join(" · ");
            return (
              <button
                key={c.id}
                type="button"
                role="checkbox"
                aria-checked={on}
                className={`k-catchup__row${on ? " k-catchup__row--on" : ""}`}
                onClick={() => toggle(c.id)}
              >
                <span className="k-catchup__cover">
                  <AnimeCover
                    src={getCoverUrl(c.coverImage)}
                    alt=""
                    decorative
                    radius="var(--radius-sm)"
                  />
                </span>
                <span className="k-catchup__body">
                  <Text size="sm" weight={600} clamp={2}>
                    {preferredTitle(c.title, titleLanguage)}
                  </Text>
                  <span className="k-catchup__chips">
                    {relChip && (
                      <span className="k-chip-kind">{relChip.label}</span>
                    )}
                    {fmtChip && (
                      <span className="k-chip-kind">{fmtChip.label}</span>
                    )}
                    {meta && (
                      <Text size="xs" color="tertiary">
                        {meta}
                      </Text>
                    )}
                  </span>
                </span>
                <span
                  className={`k-catchup__check${on ? " k-catchup__check--on" : ""}`}
                  aria-hidden
                >
                  {on && <Icon icon={Check} size={14} strokeWidth={3} />}
                </span>
              </button>
            );
          })}
        </div>

        <div className="k-catchup__actions">
          <Button variant="ghost" onClick={close}>
            Skip
          </Button>
          <Button variant="primary" onClick={confirm} disabled={count === 0}>
            {count === 0
              ? "Mark complete"
              : count === 1
                ? "Mark 1 complete"
                : `Mark ${count} complete`}
          </Button>
        </div>
      </div>
    </BottomSheet>
  );
}
