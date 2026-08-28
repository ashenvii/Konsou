import { AnchoredPopover } from "./AnchoredPopover";
import type { PopoverSize } from "./AnchoredPopover";
import { BottomSheet } from "./BottomSheet";
import { useIsPhonePortrait } from "@/hooks/useMediaQuery";
import type { ReactNode } from "react";

/**
 * Where a card's details open.
 *
 * One decision, made in one place, the way DIM makes it: an upright phone gets
 * the drag-to-dismiss sheet, and every wider window gets a popover anchored to
 * the card you clicked. Nothing else in the app should be re-deciding this, so
 * every quick menu goes through here.
 *
 * Both are non-modal. Neither traps focus, neither dims the page, and both
 * close on Escape or hardware back — so a run down a list is one click per
 * item instead of open, read, close, open.
 *
 * The `verbs` slot is the other half of that promise. DIM splits its popup the
 * same way and for the same reason: the panel is what you READ and the verbs
 * are what you PRESS, and mixing them is what makes a quick menu read as a form.
 * On a desktop the verbs become a rail beside the panel, on the side facing the
 * card; on a phone, where there is no beside, they become a bar pinned under
 * the body. Callers hand over the same buttons either way.
 */
export function ItemSurface({
  anchor,
  opener,
  open,
  onClose,
  ariaLabel,
  size = { width: 460, maxHeight: 720 },
  verbs,
  children,
}: {
  /** The element the popover points at. Ignored on a phone. */
  anchor: HTMLElement | null;
  /** The whole card that opened it, when that is bigger than the anchor — a
   *  full-width row whose poster is the anchor. Pressing it again has to close
   *  the panel rather than being treated as a click on the page behind. */
  opener?: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  ariaLabel?: string;
  size?: PopoverSize;
  /** The acts. A rail on desktop, a pinned bar on a phone. */
  verbs?: ReactNode;
  children: ReactNode;
}) {
  const phone = useIsPhonePortrait();

  if (phone) {
    // DIM's phone sheet is `aria-modal="false"` and drag-to-dismiss, and this
    // one now matches: same surface, same rules, whichever card opened it. The
    // scrim stays, because on a phone the panel does cover the page and
    // pretending otherwise just makes the covers behind it look active.
    return (
      <BottomSheet
        open={open}
        onClose={onClose}
        ariaLabel={ariaLabel}
        modeless
        footer={verbs}
      >
        {children}
      </BottomSheet>
    );
  }

  return (
    <AnchoredPopover
      anchor={anchor}
      opener={opener}
      open={open}
      onClose={onClose}
      ariaLabel={ariaLabel}
      size={size}
      sidecar={verbs}
    >
      {children}
    </AnchoredPopover>
  );
}
