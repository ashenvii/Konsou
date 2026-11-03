import { useEffect, useRef, useState } from "react";
import type { CSSProperties, ReactNode } from "react";
import { haptic } from "@/lib/haptics";

/** How long the press must be held before the action commits. */
const HOLD_MS = 650;

/**
 * Press-and-hold confirmation button. A fill sweeps across while held; letting
 * go early cancels. Works the same with a finger, a mouse press, or a held
 * Enter/Space, so desktop and mobile share one deliberate-action gesture.
 */
export function HoldButton({
  onConfirm,
  children,
  className,
  ariaLabel,
}: {
  onConfirm: () => void;
  children: ReactNode;
  className?: string;
  /** Required when `children` is a bare glyph. In the verb rail this button is
   *  an icon and nothing else, which leaves it with no accessible name at all
   *  unless one is passed here. */
  ariaLabel?: string;
}) {
  const [holding, setHolding] = useState(false);
  const timer = useRef(0);
  const done = useRef(false);

  const start = () => {
    if (done.current || timer.current) return;
    setHolding(true);
    timer.current = window.setTimeout(() => {
      timer.current = 0;
      done.current = true;
      setHolding(false);
      haptic("success");
      onConfirm();
    }, HOLD_MS);
  };

  const cancel = () => {
    if (timer.current) {
      clearTimeout(timer.current);
      timer.current = 0;
    }
    setHolding(false);
  };

  useEffect(() => () => cancel(), []);

  return (
    <button
      type="button"
      className={`k-holdbtn${holding ? " k-holdbtn--holding" : ""}${className ? ` ${className}` : ""}`}
      style={{ "--hold-ms": `${HOLD_MS}ms` } as CSSProperties}
      aria-label={ariaLabel}
      title={ariaLabel}
      onPointerDown={start}
      onPointerUp={cancel}
      onPointerLeave={cancel}
      onPointerCancel={cancel}
      onKeyDown={(e) => {
        if ((e.key === "Enter" || e.key === " ") && !e.repeat) {
          e.preventDefault();
          start();
        }
      }}
      onKeyUp={(e) => {
        if (e.key === "Enter" || e.key === " ") cancel();
      }}
      // The browser fires click on release; a released hold must not re-fire.
      onClick={(e) => e.preventDefault()}
      // Long-press context menu on Android would interrupt the hold.
      onContextMenu={(e) => e.preventDefault()}
    >
      <span className="k-holdbtn__fill" aria-hidden />
      <span className="k-holdbtn__label">{children}</span>
    </button>
  );
}
