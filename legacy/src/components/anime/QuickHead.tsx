import { AnimeCover } from "./AnimeCover";
import { Icon } from "@/components/ui/Icon";
import { getCoverUrl } from "@/lib/format";
import type { IconComponent } from "@/components/ui/Icon";

/**
 * The top of a quick menu: the thing you opened, at a size that says so.
 *
 * Every quick menu used to open with a 56px thumbnail beside a title — the same
 * object weight as the rows underneath it, so the panel began with a list and
 * never had a start. The complaint was that it "only feels like a long list,
 * nothing is disconnected in colour or accent", and that is exactly what a head
 * built to the same scale as its body produces.
 *
 * This is the Overview's own subject plate, moved inside the panel: art bleeding
 * off the right behind a scrim, the name at the display step, one mono line of
 * state, and one filled seal for the act. Reusing the page's hero language here
 * is the point — the panel is the card you touched, enlarged, so the two read as
 * the same object rather than as a page and a dialog about a page.
 *
 * One component for both quick menus. They had two different heads before, which
 * is where a good share of the duplicated wording came from: one said
 * "15 / 40 episodes", the other said "15 / 40", "38%" and "3 of 7 on your list"
 * in three stacked lines.
 */
export function QuickHead({
  cover,
  kicker,
  title,
  state,
  seal,
}: {
  cover: string | null | undefined;
  /** Mono, uppercase, one or two words: what kind of thing this is right now
   *  ("Watching", "Paused", "Franchise"). Never a sentence. */
  kicker: string;
  title: string;
  /** The one line of state under the name. Already formatted; the head does no
   *  arithmetic and states one fact, not three. */
  state: string | null;
  /** The single act this panel exists for. Absent when there isn't one — a
   *  finished franchise has nothing to press, and an inert disabled seal is
   *  worse than no seal. */
  seal?: {
    icon: IconComponent;
    /** The full sentence a screen reader hears. */
    label: string;
    onAct: () => void;
    /** Solid rather than outlined, for the glyphs that are shapes (Play,
     *  Check) rather than marks (Plus). */
    fill?: boolean;
    disabled?: boolean;
  } | null;
}) {
  const src = getCoverUrl({ medium: cover ?? undefined });
  return (
    <header className="k-qhead">
      <span className="k-qhead__art" aria-hidden>
        <AnimeCover src={src} alt="" decorative radius="inherit" />
      </span>
      <div className="k-qhead__body">
        <p className="k-qhead__kicker">{kicker}</p>
        {/* h2, not h1: the page underneath owns the h1 and this panel is a
            region of it, not a document of its own. */}
        <h2 className="k-qhead__title">{title}</h2>
        {(state || seal) && (
          <div className="k-qhead__foot">
            {seal && (
              <button
                type="button"
                className="k-qhead__seal"
                onClick={seal.onAct}
                disabled={seal.disabled}
                aria-label={seal.label}
                title={seal.label}
              >
                <Icon icon={seal.icon} size={20} weight={seal.fill ? "fill" : undefined} />
              </button>
            )}
            {state && <span className="k-qhead__state">{state}</span>}
          </div>
        )}
      </div>
    </header>
  );
}
