import { useEffect, useRef } from "react";
import { updateNotice, useUpdateStore } from "@/lib/store/updateStore";

/**
 * The dot on the What's New door, and the notice that opens itself.
 *
 * One component for both shells. The sidebar draws this inside a rail row and
 * the phone header draws it inside a strip mark, and the only difference
 * between them is which side the notice comes out of — so that is a prop and
 * everything else is shared. Two hand-built copies of a signal is how the two
 * platforms end up disagreeing about whether there is an update.
 *
 * ## Why a dot and not a tag
 *
 * A tag reading "Update available" that sits there until you act on it stops
 * being information within a day; it becomes part of the furniture, and then
 * the one time it matters it is invisible. The dot is the permanent part
 * because it is small enough to stay honest, and the *sentence* is the rationed
 * part: it opens itself a few times and then stops for good on that version.
 * See updateStore for the exact budget.
 *
 * The notice is `role="status"` rather than an alert. An available update is
 * not an emergency, and an alert interrupts whatever a screen reader was in the
 * middle of saying to announce that a piece of software has a newer build.
 */
export function UpdateMark({ side }: { side: "rail" | "strip" }) {
  const update = useUpdateStore((s) => s.update);
  const nudging = useUpdateStore((s) => s.nudging);
  const appName = useUpdateStore((s) => s.appName);
  const hush = useUpdateStore((s) => s.hush);
  const hushRef = useRef(hush);
  hushRef.current = hush;

  // Anything the user does next puts it away. A notice that opened itself has
  // to close itself just as readily — it was not asked for, so it does not get
  // to require a dismissal.
  useEffect(() => {
    if (!nudging) return;
    const away = () => hushRef.current();
    // Capture, so a card's own handler cannot swallow it.
    window.addEventListener("pointerdown", away, true);
    window.addEventListener("keydown", away, true);
    return () => {
      window.removeEventListener("pointerdown", away, true);
      window.removeEventListener("keydown", away, true);
    };
  }, [nudging]);

  if (!update) return null;

  return (
    <>
      <span className="k-updot" aria-hidden />
      {nudging && (
        <span className={`k-upnote k-upnote--${side}`} role="status">
          {updateNotice(appName, update)}
        </span>
      )}
    </>
  );
}
