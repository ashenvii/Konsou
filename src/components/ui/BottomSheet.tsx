import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import type { PointerEvent, ReactNode } from "react";

interface BottomSheetProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  /** Disable swipe/backdrop dismissal (e.g. while a keyboard is open inside). */
  dismissable?: boolean;
}

/**
 * The container for all modal interactions. Bottom sheet on mobile, centered
 * dialog on desktop (CSS-switched). Dismiss via backdrop tap, the handle drag,
 * or Escape. Slide-down dismissal is disabled when `dismissable` is false.
 */
export function BottomSheet({
  open,
  onClose,
  title,
  children,
  dismissable = true,
}: BottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);
  const dragStart = useRef<number | null>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && dismissable) onClose();
    };
    window.addEventListener("keydown", onKey);
    sheetRef.current?.focus();
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose, dismissable]);

  if (!open) return null;

  const onPointerDown = (e: PointerEvent) => {
    if (!dismissable) return;
    dragStart.current = e.clientY;
  };
  const onPointerUp = (e: PointerEvent) => {
    if (dragStart.current == null) return;
    const dy = e.clientY - dragStart.current;
    dragStart.current = null;
    if (dy > 80) onClose(); // dragged down far enough
  };

  return createPortal(
    <div className="k-sheet-overlay crossfade" role="presentation">
      <div
        className="k-sheet-backdrop"
        onClick={() => dismissable && onClose()}
      />
      <div
        className="k-sheet"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        ref={sheetRef}
      >
        <div
          className="k-sheet__handle-area"
          onPointerDown={onPointerDown}
          onPointerUp={onPointerUp}
        >
          <div className="k-sheet__handle" />
        </div>
        {title && <div className="k-sheet__title">{title}</div>}
        <div className="k-sheet__body konsou-scroll">{children}</div>
      </div>
    </div>,
    document.body,
  );
}
