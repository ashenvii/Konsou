import { ChevronLeft } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { goBack } from "@/hooks/useAppBack";
import type { ReactNode } from "react";

/**
 * A room's header, built like the launcher's: the room's name engraved, a mono
 * census under it, and the room's controls on the right.
 *
 * The rooms used to keep a bare back-arrow-title-count bar from before the
 * rework, so walking in from the launcher felt like leaving the app and landing
 * in an older one. The census line is the part that matters: it says what this
 * room holds and what it is FOR, which is the thing a wall of covers cannot.
 */
export function RoomHeader({
  title,
  census,
  purpose,
  actions,
}: {
  title: string;
  /** The counts, in mono. Already-formatted fragments, joined with middots. */
  census: (string | null)[];
  /** One plain line saying what the room is for. */
  purpose: string;
  actions?: ReactNode;
}) {
  const parts = census.filter((c): c is string => !!c);
  return (
    <header className="k-roomtop">
      <div className="k-roomtop__row">
        <button
          type="button"
          className="k-roomtop__back"
          onClick={goBack}
          aria-label="Back to My List"
        >
          <Icon icon={ChevronLeft} size={20} />
        </button>
        <h1 className="k-roomtop__title">{title}</h1>
        {actions && <div className="k-roomtop__actions">{actions}</div>}
      </div>
      <p className="k-roomtop__census">
        {parts.map((p, i) => (
          <span key={p}>
            {i > 0 && <span className="k-roomtop__sep"> · </span>}
            {p}
          </span>
        ))}
      </p>
      <p className="k-roomtop__purpose">{purpose}</p>
    </header>
  );
}
