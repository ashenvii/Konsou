export interface RailSection {
  /** The letter shown on the rail. "#" collects everything non-alphabetic. */
  key: string;
  /** Index of this section's first card in the rendered order. */
  index: number;
}

interface LetterRailProps {
  sections: RailSection[];
  onJump: (groupIndex: number) => void;
}

/**
 * The A-Z index down the right edge, for lists too long to scroll through.
 *
 * Only letters that actually have cards are listed, and they share the rail's
 * height, so a library with eight represented letters gets eight tall targets
 * rather than twenty-six cramped ones. That is the deliberate trade here: an
 * index rail cannot honour the 44px touch minimum (twenty-six of those needs
 * 1100px of screen), so it earns its place by being a recognised pattern with
 * the largest rows the list allows, and by never being the only way to reach
 * anything: sorting and search still work without it.
 *
 * `data-nodrag` keeps the app-wide drag-to-pan handler off the rail, which
 * would otherwise read a tap here as the start of a page drag.
 */
export function LetterRail({ sections, onJump }: LetterRailProps) {
  if (sections.length < 2) return null;

  return (
    <nav className="k-rail" data-nodrag aria-label="Jump to letter">
      {sections.map((s) => (
        <button
          key={s.key}
          type="button"
          className="k-rail__letter"
          onClick={() => onJump(s.index)}
          aria-label={`Jump to ${s.key === "#" ? "titles starting with a number or symbol" : s.key}`}
        >
          {s.key}
        </button>
      ))}
    </nav>
  );
}
