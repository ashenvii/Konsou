import { useEffect, useRef } from "react";
import { ChevronLeft, Search, X } from "lucide-react";
import { Icon } from "@/components/ui/Icon";
import { goBack } from "@/hooks/useAppBack";
import type { ReactNode } from "react";

/**
 * A room's header: the way back, the room's name, and the room's controls.
 *
 * It used to carry a mono census and a line explaining what the room was for.
 * Both are gone. The counts said things Stats already says better, and a room
 * you walked into on purpose does not need a sentence telling you what it is —
 * that is onboarding copy left permanently on screen. What is left is the name
 * and the controls that act on it.
 *
 * Search is a control here, not a band across the top: the icon opens the field
 * in the header's own row and closing it puts the room back. Same pattern the
 * launcher settled on, for the same reason — an always-on search field is in
 * the way of the thing you came to look at.
 */
export function RoomHeader({
  title,
  actions,
  search,
}: {
  title: string;
  actions?: ReactNode;
  /** Omit entirely on a room with nothing worth searching. */
  search?: {
    value: string;
    onChange: (v: string) => void;
    open: boolean;
    onOpen: () => void;
    onClose: () => void;
    /** e.g. "Search 412 planned titles" */
    placeholder: string;
  };
}) {
  const inputRef = useRef<HTMLInputElement>(null);

  // Opening the field should put the caret in it. A search you have to click
  // twice to use is a search nobody uses.
  useEffect(() => {
    if (search?.open) inputRef.current?.focus();
  }, [search?.open]);

  return (
    // One height, always. useScrollElevation ramps a --bar value on this as the
    // room scrolls and the CSS paints the header's surface and hairline at that
    // opacity, so the rule arrives when there is something under it to rule
    // off. The title no longer resizes: see useHeaderLede for why nothing in
    // the implementations this follows animates type on scroll.
    <header className="k-roomtop" data-collapsing-header>
      <div className="k-roomtop__row">
        <button
          type="button"
          className="k-roomtop__back"
          onClick={goBack}
          aria-label="Back to My List"
        >
          <Icon icon={ChevronLeft} size={20} />
        </button>

        {search?.open ? (
          <div className="k-roomtop__field">
            <Icon icon={Search} size={16} color="var(--ink-label)" />
            <input
              ref={inputRef}
              value={search.value}
              onChange={(e) => search.onChange(e.target.value)}
              placeholder={search.placeholder}
              aria-label={search.placeholder}
              // Escape closes the search rather than falling through to
              // whatever else on the page is listening for it.
              onKeyDown={(e) => {
                if (e.key === "Escape") {
                  e.stopPropagation();
                  search.onClose();
                }
              }}
            />
            <button type="button" onClick={search.onClose} aria-label="Close search">
              <Icon icon={X} size={16} />
            </button>
          </div>
        ) : (
          <h1 className="k-roomtop__title">{title}</h1>
        )}

        {!search?.open && (
          <div className="k-roomtop__actions">
            {search && (
              <button
                type="button"
                className={`k-roomhead__filter${search.value ? " k-roomhead__filter--on" : ""}`}
                onClick={search.onOpen}
                aria-label={`Search ${title}`}
              >
                <Icon icon={Search} size={17} />
                {/* Named alongside its neighbours on a wide window; one bare
                    glyph in a row of labelled controls is the odd one out. */}
                <span className="k-roomhead__btnlabel">Search</span>
              </button>
            )}
            {actions}
          </div>
        )}
      </div>
    </header>
  );
}
