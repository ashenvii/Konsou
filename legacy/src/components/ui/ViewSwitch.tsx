import { useRef, useState } from "react";
import { Check, LayoutGrid, Rows2, Rows3 } from "lucide-react";
import { Icon } from "./Icon";
import type { IconComponent } from "./Icon";
import { ItemSurface } from "./ItemSurface";
import { useSettingsStore } from "@/lib/store/settingsStore";
import type { ViewMode } from "@/types/list";

/**
 * Change how a room is drawn, from the room.
 *
 * The three densities existed only as a preference buried in Settings >
 * Appearance, which meant switching them cost a trip out of the collection and
 * back — so in practice nobody switched, and two of the three renditions went
 * unseen. Density is a reading decision, not a configuration one: you want the
 * dense list *while looking for something* and the plate grid while browsing.
 *
 * It writes the same stored setting the Appearance page does, deliberately.
 * A per-room override would mean the app answered "how do I look at my list"
 * differently depending on which room you were standing in, and the setting
 * page would then be lying about the current state.
 */

/** "Ledger" and "Index" were the world's own words for these two, and they
 *  read as jargon at the moment of choosing — you should not have to know the
 *  design language to pick how your list looks. Plain names, with the
 *  description carrying what each actually shows. */
const VIEWS: { key: ViewMode; label: string; hint: string; icon: IconComponent }[] = [
  { key: "grid", label: "Plates", hint: "Mounted covers", icon: LayoutGrid },
  { key: "list", label: "List", hint: "Cover, title and progress", icon: Rows2 },
  { key: "compact", label: "Compact", hint: "One line each", icon: Rows3 },
];

export function ViewSwitch() {
  const view = useSettingsStore((s) => s.defaultView);
  const setView = useSettingsStore((s) => s.setDefaultView);
  const [open, setOpen] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);

  const current = VIEWS.find((v) => v.key === view) ?? VIEWS[0];

  return (
    <>
      <button
        ref={btnRef}
        type="button"
        className="k-roomhead__filter"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        aria-label={`View: ${current.label}. Change how this room is shown`}
      >
        <Icon icon={current.icon} size={17} />
        {/* On a wide window the button states which rendition is on, so the
            room says how it is being drawn rather than making you open a menu
            to find out. */}
        <span className="k-roomhead__btnlabel">{current.label}</span>
      </button>

      <ItemSurface
        anchor={btnRef.current}
        open={open}
        onClose={() => setOpen(false)}
        ariaLabel="How to show this room"
        size={{ width: 280, maxHeight: 420 }}
      >
        <div className="k-fm">
          <section className="k-fm__section">
            <h3 className="k-fm__label">View</h3>
            <div className="k-fm__rows">
              {VIEWS.map((v) => (
                <button
                  key={v.key}
                  type="button"
                  className={`k-fm__row${view === v.key ? " k-fm__row--on" : ""}`}
                  aria-pressed={view === v.key}
                  onClick={() => {
                    setView(v.key);
                    setOpen(false);
                  }}
                >
                  <Icon icon={v.icon} size={16} className="k-fm__rowicon" />
                  <span className="k-fm__rowname">
                    {v.label}
                    <span className="k-fm__rowhint">{v.hint}</span>
                  </span>
                  {view === v.key && <Icon icon={Check} size={15} />}
                </button>
              ))}
            </div>
          </section>
        </div>
      </ItemSurface>
    </>
  );
}
