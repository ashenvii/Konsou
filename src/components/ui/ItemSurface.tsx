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
 */
export function ItemSurface({
  anchor,
  open,
  onClose,
  ariaLabel,
  size = { width: 460, maxHeight: 720 },
  children,
}: {
  /** The element the popover points at. Ignored on a phone. */
  anchor: HTMLElement | null;
  open: boolean;
  onClose: () => void;
  ariaLabel?: string;
  size?: PopoverSize;
  children: ReactNode;
}) {
  const phone = useIsPhonePortrait();

  if (phone) {
    return (
      <BottomSheet open={open} onClose={onClose} ariaLabel={ariaLabel}>
        {children}
      </BottomSheet>
    );
  }

  return (
    <AnchoredPopover
      anchor={anchor}
      open={open}
      onClose={onClose}
      ariaLabel={ariaLabel}
      size={size}
    >
      {children}
    </AnchoredPopover>
  );
}
