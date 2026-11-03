import { useCallback, useEffect, useRef, useState } from "react";

/**
 * THE COMPLETED BOARD'S TUNER, and why it is not a rig.
 *
 * The comp this card was built from was a standalone HTML rig, and it drifted:
 * its head flowed inline so its own rules never rendered, and its fourteen
 * columns were a constant off a 1040px stage that produced 37px slivers on the
 * 544px card the app actually draws. The replacement rig drifted too, on its
 * first day, in the quieter way that is worse: it read the library's ink tiers
 * instead of the local override this card carries, and reported a label at
 * 4.91:1 that is really 6.02:1. A plausible wrong number is harder to catch
 * than a broken layout.
 *
 * So this drives the REAL card. It writes real custom properties onto the real
 * `.nm-board`, reads its starting values back out of it, and measures contrast
 * off the same composited stack the card actually paints. There is nothing to
 * keep in sync because there is no second implementation.
 *
 * IT NEVER SHIPS. The only import site is guarded by `import.meta.env.DEV` and
 * loads it dynamically, so the production build neither includes nor emits it.
 * Open it with `?tune=board` on the URL.
 */

type Group = "Chit" | "Paper (Lantern)" | "Veil and hole" | "Wall" | "Turn" | "Shutter (Neon)";

interface Knob {
  group: Group;
  /** The custom property this writes, or a synthetic key assembled below. */
  key: string;
  label: string;
  min: number;
  max: number;
  step: number;
  unit: "px" | "%" | "ms" | "";
  /** Which custom property to read the starting value from, when it is direct. */
  from?: string;
}

const KNOBS: Knob[] = [
  { group: "Chit", key: "stubFloor", label: "Chit floor", min: 160, max: 460, step: 4, unit: "px" },
  { group: "Chit", key: "stubPct", label: "Chit share", min: 20, max: 75, step: 1, unit: "%" },
  { group: "Chit", key: "stubMax", label: "Chit ceiling", min: 320, max: 720, step: 10, unit: "px" },
  { group: "Chit", key: "countSize", label: "Count size", min: 48, max: 132, step: 2, unit: "px", from: "--count-size" },

  { group: "Paper (Lantern)", key: "paperWarm", label: "Stock warmth", min: 0, max: 22, step: 1, unit: "%", from: "--paper-warm" },
  { group: "Paper (Lantern)", key: "paperGrain", label: "Grain", min: 0, max: 0.12, step: 0.005, unit: "", from: "--paper-grain" },
  { group: "Paper (Lantern)", key: "paperEdge", label: "Lit cut edge", min: 0, max: 0.7, step: 0.02, unit: "", from: "--paper-edge" },
  { group: "Paper (Lantern)", key: "paperLift", label: "Shadow throw", min: 0, max: 24, step: 1, unit: "px", from: "--paper-lift" },
  { group: "Paper (Lantern)", key: "paperBlur", label: "Shadow blur", min: 0, max: 34, step: 1, unit: "px", from: "--paper-blur" },
  { group: "Paper (Lantern)", key: "paperShade", label: "Shadow depth", min: 0, max: 1, step: 0.02, unit: "", from: "--paper-shade" },
  { group: "Paper (Lantern)", key: "lip", label: "Top lip (both worlds)", min: 0, max: 0.5, step: 0.01, unit: "", from: "--lip" },

  { group: "Veil and hole", key: "veilRest", label: "Veil at rest", min: 0.1, max: 0.95, step: 0.01, unit: "", from: "--veil-rest" },
  { group: "Veil and hole", key: "veilHover", label: "Veil on hover", min: 0.05, max: 0.9, step: 0.01, unit: "", from: "--veil-hover" },
  { group: "Veil and hole", key: "holeR", label: "Hole radius", min: 80, max: 400, step: 5, unit: "px", from: "--hole-r" },
  { group: "Veil and hole", key: "holeDepth", label: "Hole depth", min: 0, max: 1, step: 0.02, unit: "", from: "--hole-depth" },

  { group: "Wall", key: "par", label: "Parallax", min: 0, max: 16, step: 1, unit: "px", from: "--par" },
  { group: "Wall", key: "lineReach", label: "Line reach", min: 60, max: 400, step: 10, unit: "px", from: "--line-reach" },
  { group: "Wall", key: "lineW", label: "Line weight", min: 1, max: 6, step: 0.5, unit: "px", from: "--line-w" },

  { group: "Turn", key: "turnTakes", label: "Turn takes", min: 200, max: 1600, step: 20, unit: "ms", from: "--turn-takes" },

  { group: "Shutter (Neon)", key: "shutDrop", label: "Shutter drop", min: 20, max: 95, step: 1, unit: "%" },
  { group: "Shutter (Neon)", key: "shutDense", label: "Shutter density", min: 30, max: 100, step: 1, unit: "%" },
];

const GROUPS: Group[] = ["Chit", "Paper (Lantern)", "Veil and hole", "Wall", "Turn", "Shutter (Neon)"];

/* A poster's own light region against its own dark one. The same pair both
   review passes used, so the numbers here are comparable to theirs. */
const COVER_HI: RGB = [235, 225, 215];
const COVER_LO: RGB = [28, 22, 30];

type RGB = [number, number, number];

/* ── Colour, solved rather than assumed ──────────────────────────────
   getComputedStyle hands back oklab/oklch, which naive contrast maths cannot
   read, and canvas fillStyle silently keeps its previous value when a colour
   fails to parse. Painting over black and over white recovers both the colour
   and its alpha, and a sentinel catches a parse failure instead of reporting a
   confident wrong number. */
function makeProbe() {
  const cv = document.createElement("canvas");
  cv.width = cv.height = 1;
  const g = cv.getContext("2d", { willReadFrequently: true });

  const paint = (css: string, bg: string): RGB | null => {
    if (!g) return null;
    g.clearRect(0, 0, 1, 1);
    g.fillStyle = bg;
    g.fillRect(0, 0, 1, 1);
    g.fillStyle = "#ff00ff";
    g.fillStyle = css;
    g.fillRect(0, 0, 1, 1);
    const d = g.getImageData(0, 0, 1, 1).data;
    return [d[0], d[1], d[2]];
  };

  return function solve(css: string): { rgb: RGB; a: number } | null {
    const b = paint(css, "#000");
    const w = paint(css, "#fff");
    if (!b || !w) return null;
    const a = 1 - (w[0] - b[0]) / 255;
    if (a < 0.002) return { rgb: [0, 0, 0], a: 0 };
    const clamped = Math.max(0, Math.min(1, a));
    return { rgb: [b[0] / clamped, b[1] / clamped, b[2] / clamped], a: clamped };
  };
}

const lin = (v: number) => {
  const c = v / 255;
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
};
const lum = (c: RGB) => 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2]);
const contrast = (x: RGB, y: RGB) => {
  const a = lum(x);
  const b = lum(y);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
};
const over = (top: RGB, alpha: number, bot: RGB): RGB => [
  top[0] * alpha + bot[0] * (1 - alpha),
  top[1] * alpha + bot[1] * (1 - alpha),
  top[2] * alpha + bot[2] * (1 - alpha),
];

interface Line {
  label: string;
  value: string;
  verdict?: "pass" | "thin" | "fail";
}

function grade(v: number, good: number, ok: number): Line["verdict"] {
  if (v >= good) return "pass";
  if (v >= ok) return "thin";
  return "fail";
}

export default function BoardTuner() {
  const [state, setState] = useState<Record<string, number> | null>(null);
  const [lines, setLines] = useState<Line[]>([]);
  const [dump, setDump] = useState("");
  const [missing, setMissing] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const solveRef = useRef<ReturnType<typeof makeProbe> | null>(null);
  if (!solveRef.current) solveRef.current = makeProbe();

  const board = () => document.querySelector<HTMLElement>(".nm-board");

  /* ── Seed every knob from the card as it actually ships ───────────
     Nothing here restates a value from the stylesheet, so the panel opens on
     the truth even after someone edits night-market.css. */
  useEffect(() => {
    const el = board();
    if (!el) {
      setMissing(true);
      return;
    }
    const cs = getComputedStyle(el);
    const num = (prop: string, fallback: number) => {
      const raw = parseFloat(cs.getPropertyValue(prop));
      return Number.isFinite(raw) ? raw : fallback;
    };
    /* --stub-w ships as a clamp, so its three parts are read out of the
       expression rather than guessed. */
    const stub = cs.getPropertyValue("--stub-w").trim();
    const m = stub.match(/clamp\(\s*([\d.]+)px\s*,\s*([\d.]+)%\s*,\s*([\d.]+)px\s*\)/);
    const seeded: Record<string, number> = {
      stubFloor: m ? parseFloat(m[1]) : 300,
      stubPct: m ? parseFloat(m[2]) : 44,
      stubMax: m ? parseFloat(m[3]) : 460,
      countSize: num("--count-size", 98),
      paperWarm: num("--paper-warm", 5),
      paperGrain: num("--paper-grain", 0.035),
      paperEdge: num("--paper-edge", 0.3),
      paperLift: num("--paper-lift", 7),
      paperBlur: num("--paper-blur", 10),
      paperShade: num("--paper-shade", 0.7),
      lip: num("--lip", 0.22),
      veilRest: num("--veil-rest", 0.5),
      veilHover: num("--veil-hover", 0.38),
      holeR: num("--hole-r", 200),
      holeDepth: num("--hole-depth", 0.4),
      par: num("--par", 7),
      lineReach: num("--line-reach", 130),
      lineW: num("--line-w", 3),
      turnTakes: num("--turn-takes", 800),
      shutDrop: 58,
      shutDense: 92,
    };
    setState(seeded);
  }, []);

  /* ── Write to the real card, then measure what it became ─────────── */
  const applyAndMeasure = useCallback((s: Record<string, number>) => {
    const el = board();
    const solve = solveRef.current;
    if (!el || !solve) {
      setMissing(true);
      return;
    }
    setMissing(false);

    el.style.setProperty("--stub-w", `clamp(${s.stubFloor}px, ${s.stubPct}%, ${s.stubMax}px)`);
    el.style.setProperty("--count-size", `${s.countSize}px`);
    el.style.setProperty("--paper-warm", `${s.paperWarm}%`);
    el.style.setProperty("--paper-grain", String(s.paperGrain));
    el.style.setProperty("--paper-edge", String(s.paperEdge));
    el.style.setProperty("--paper-lift", `${s.paperLift}px`);
    el.style.setProperty("--paper-blur", `${s.paperBlur}px`);
    el.style.setProperty("--paper-shade", String(s.paperShade));
    el.style.setProperty("--lip", String(s.lip));
    el.style.setProperty("--veil-rest", String(s.veilRest));
    el.style.setProperty("--veil-hover", String(s.veilHover));
    el.style.setProperty("--hole-r", `${s.holeR}px`);
    el.style.setProperty("--hole-depth", String(s.holeDepth));
    el.style.setProperty("--par", `${s.par}px`);
    el.style.setProperty("--line-reach", `${s.lineReach}px`);
    el.style.setProperty("--line-w", `${s.lineW}px`);
    el.style.setProperty("--turn-takes", `${s.turnTakes}ms`);

    const cs = getComputedStyle(el);
    const neon = document.documentElement.dataset.theme === "neon";
    const tok = (name: string): RGB => solve(cs.getPropertyValue(name).trim())?.rgb ?? [0, 0, 0];
    const surface = tok("--w-surface");
    const sunk = tok("--w-sunk");
    const wbase = tok("--w-base");
    const whi = tok("--w-highlight");

    const veiled = (cover: RGB, alpha: number) => over(surface, alpha, cover);
    const coverAt = (alpha: number) => contrast(veiled(COVER_HI, alpha), veiled(COVER_LO, alpha));

    /* The ground the head's type lands on, worst case: a bright cover, and in
       Neon the thinnest band of the shutter. */
    const brightWall = veiled(COVER_HI, s.veilRest);
    /* The head's ground in Lantern is the PAPER, and the paper's stock is a
       color-mix in oklab, which is not an alpha blend and cannot be rebuilt
       from `over`. So it is read back off the pseudo-element that paints it:
       the same principle as the rest of this file, measure what the component
       produced rather than what it was asked for. */
    const stubEl = el.querySelector(".nm-board__stub");
    const paperRaw = stubEl
      ? getComputedStyle(stubEl, "::before").backgroundColor
      : "";
    const paper = (paperRaw && solve(paperRaw)?.rgb) || sunk;
    const ground = neon
      ? over(whi, 0.09, over(wbase, s.shutDense / 100, brightWall))
      : over(paper, 0.94, brightWall);

    const inkOn = (sel: string): number | null => {
      const node = el.querySelector(sel);
      if (!node) return null;
      const got = solve(getComputedStyle(node).color);
      if (!got) return null;
      return contrast(over(got.rgb, got.a, ground), ground);
    };

    const r = el.getBoundingClientRect();
    const wall = el.querySelector<HTMLElement>(".nm-board__wall");
    const tile = wall?.firstElementChild as HTMLElement | null;
    const tr = tile?.getBoundingClientRect();
    const headEl = el.querySelector<HTMLElement>(".nm-board__head");
    const ledgerEl = el.querySelector<HTMLElement>(".nm-board__ledger");
    const countEl = el.querySelector<HTMLElement>(".nm-board__n");

    const out: Line[] = [];
    const push = (label: string, value: string, verdict?: Line["verdict"]) =>
      out.push({ label, value, verdict });

    const rest = coverAt(s.veilRest);
    const hover = coverAt(s.veilHover);
    const hole = coverAt(s.veilRest * s.holeDepth);
    push("Cover at rest", `${rest.toFixed(2)}:1`, grade(rest, 4, 3));
    push("Cover on hover", `${hover.toFixed(2)}:1`, grade(hover, 4, 3));
    push("Cover in the hole", `${hole.toFixed(2)}:1`, grade(hole, 8, 6));

    if (!neon) {
      /* Not an AA bar, a character reading: the stock against the brightest
         thing behind it, which is a lit cover under the resting veil. It says
         whether the paper still reads as its own object where the wall is
         loudest. Turning the warmth up closes this gap. */
      const standoff = contrast(ground, brightWall);
      push("Paper against the wall", `${standoff.toFixed(2)}:1`);
    }

    const iss = inkOn(".nm-board__issuer");
    const cnt = inkOn(".nm-board__n");
    const clo = inkOn(".nm-board__closed");
    if (iss !== null) push("Issuer, worst ground", `${iss.toFixed(2)}:1`, grade(iss, 4.5, 4));
    if (cnt !== null) push("Count, worst ground", `${cnt.toFixed(2)}:1`, grade(cnt, 3, 3));
    if (clo !== null) push("Overprint, worst ground", `${clo.toFixed(2)}:1`, grade(clo, 3, 3));

    const headW = headEl ? headEl.getBoundingClientRect().width : 0;
    push("Card", `${Math.round(r.width)} × ${Math.round(r.height)}`);
    push("Chit share", `${((headW / r.width) * 100).toFixed(1)}%`);
    if (tr) {
      const ratio = tr.width / tr.height;
      push(
        "Tile",
        `${Math.round(tr.width)} × ${Math.round(tr.height)}  (${ratio.toFixed(2)})`,
        grade(ratio, 0.66, 0.55),
      );
    }
    push("Columns × tiles", `${cs.getPropertyValue("--nm-cols").trim()} × ${wall?.children.length ?? 0}`);

    if (ledgerEl) {
      const fits = ledgerEl.scrollWidth <= ledgerEl.clientWidth;
      push("Ledger fits", fits ? "yes" : "no", fits ? "pass" : "fail");
    }
    if (countEl && headEl) {
      const fits = countEl.scrollWidth <= headEl.clientWidth - 28;
      push("Count fits the chit", fits ? "yes" : "no", fits ? "pass" : "fail");
    }
    push("Viewport", `${window.innerWidth}px · ${neon ? "Neon" : "Lantern"}`);

    setLines(out);
    setDump(
      [
        `--paper-warm:  ${s.paperWarm}%;`,
        `--paper-grain: ${s.paperGrain.toFixed(3)};`,
        `--paper-edge:  ${s.paperEdge.toFixed(2)};`,
        `--paper-lift:  ${s.paperLift}px;`,
        `--paper-blur:  ${s.paperBlur}px;`,
        `--paper-shade: ${s.paperShade.toFixed(2)};`,
        `--lip:         ${s.lip.toFixed(2)};`,
        `--veil-rest:   ${s.veilRest.toFixed(2)};`,
        `--veil-hover:  ${s.veilHover.toFixed(2)};`,
        `--hole-r:      ${s.holeR}px;`,
        `--hole-depth:  ${s.holeDepth.toFixed(2)};`,
        `--line-reach:  ${s.lineReach}px;`,
        `--line-w:      ${s.lineW}px;`,
        `--par:         ${s.par}px;`,
        `--stub-w:      clamp(${s.stubFloor}px, ${s.stubPct}%, ${s.stubMax}px);`,
        `--count-size:  ${s.countSize}px;`,
        `--turn-takes:  ${s.turnTakes}ms;`,
        `/* Neon shutter: drop ${s.shutDrop}%, density ${s.shutDense}% */`,
      ].join("\n"),
    );
  }, []);

  useEffect(() => {
    if (state) applyAndMeasure(state);
  }, [state, applyAndMeasure]);

  /* Re-measure on resize and on a world switch, because both change every
     number in the readout without touching a slider. */
  useEffect(() => {
    if (!state) return;
    const remeasure = () => applyAndMeasure(state);
    window.addEventListener("resize", remeasure);
    const mo = new MutationObserver(remeasure);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
    return () => {
      window.removeEventListener("resize", remeasure);
      mo.disconnect();
    };
  }, [state, applyAndMeasure]);

  /* Put the card back the way it shipped. */
  const reset = () => {
    const el = board();
    if (!el) return;
    for (const p of [
      "--stub-w", "--count-size", "--veil-rest", "--veil-hover", "--hole-r",
      "--hole-depth", "--par", "--line-reach", "--line-w", "--turn-takes",
      "--paper-warm", "--paper-grain", "--paper-edge", "--paper-lift",
      "--paper-blur", "--paper-shade", "--lip",
    ]) {
      el.style.removeProperty(p);
    }
    setState(null);
    window.setTimeout(() => {
      const cs = getComputedStyle(el);
      const stub = cs.getPropertyValue("--stub-w").trim();
      const m = stub.match(/clamp\(\s*([\d.]+)px\s*,\s*([\d.]+)%\s*,\s*([\d.]+)px\s*\)/);
      setState({
        stubFloor: m ? parseFloat(m[1]) : 300,
        stubPct: m ? parseFloat(m[2]) : 44,
        stubMax: m ? parseFloat(m[3]) : 460,
        countSize: parseFloat(cs.getPropertyValue("--count-size")) || 98,
        paperWarm: parseFloat(cs.getPropertyValue("--paper-warm")) || 5,
        paperGrain: parseFloat(cs.getPropertyValue("--paper-grain")) || 0.035,
        paperEdge: parseFloat(cs.getPropertyValue("--paper-edge")) || 0.3,
        paperLift: parseFloat(cs.getPropertyValue("--paper-lift")) || 7,
        paperBlur: parseFloat(cs.getPropertyValue("--paper-blur")) || 10,
        paperShade: parseFloat(cs.getPropertyValue("--paper-shade")) || 0.7,
        lip: parseFloat(cs.getPropertyValue("--lip")) || 0.22,
        veilRest: parseFloat(cs.getPropertyValue("--veil-rest")) || 0.5,
        veilHover: parseFloat(cs.getPropertyValue("--veil-hover")) || 0.38,
        holeR: parseFloat(cs.getPropertyValue("--hole-r")) || 200,
        holeDepth: parseFloat(cs.getPropertyValue("--hole-depth")) || 0.4,
        par: parseFloat(cs.getPropertyValue("--par")) || 7,
        lineReach: parseFloat(cs.getPropertyValue("--line-reach")) || 130,
        lineW: parseFloat(cs.getPropertyValue("--line-w")) || 3,
        turnTakes: parseFloat(cs.getPropertyValue("--turn-takes")) || 800,
        shutDrop: 58,
        shutDense: 92,
      });
    }, 0);
  };

  if (!state) {
    return (
      <div className="bt bt--empty">
        <style>{CSS}</style>
        {missing ? "No board on this screen. It renders at 720px and up." : "Reading the card…"}
      </div>
    );
  }

  return (
    <div className={`bt${collapsed ? " bt--min" : ""}`}>
      <style>{CSS}</style>
      <div className="bt__bar">
        <span className="bt__name">Board tuner</span>
        <button type="button" onClick={reset}>Reset</button>
        <button type="button" onClick={() => setCollapsed((c) => !c)}>
          {collapsed ? "Open" : "Hide"}
        </button>
      </div>

      {!collapsed && (
        <div className="bt__body">
          {missing && <p className="bt__warn">The board is not on screen right now.</p>}

          <table className="bt__read">
            <tbody>
              {lines.map((l) => (
                <tr key={l.label}>
                  <td>{l.label}</td>
                  <td className="bt__n">{l.value}</td>
                  <td className="bt__v">
                    {l.verdict && <span className={`bt__tag bt__tag--${l.verdict}`}>{l.verdict}</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {GROUPS.map((g) => (
            <section key={g}>
              <p className="bt__eyebrow">{g}</p>
              {KNOBS.filter((k) => k.group === g).map((k) => (
                <div className="bt__ctl" key={k.key}>
                  <label htmlFor={`bt-${k.key}`}>
                    {k.label}
                    <b>
                      {k.step < 1 ? state[k.key].toFixed(2) : state[k.key]}
                      {k.unit}
                    </b>
                  </label>
                  <input
                    id={`bt-${k.key}`}
                    type="range"
                    min={k.min}
                    max={k.max}
                    step={k.step}
                    value={state[k.key]}
                    onChange={(e) =>
                      setState((prev) => (prev ? { ...prev, [k.key]: parseFloat(e.target.value) } : prev))
                    }
                  />
                </div>
              ))}
            </section>
          ))}

          <p className="bt__eyebrow">Paste into night-market.css</p>
          <pre>{dump}</pre>
          <p className="bt__foot">
            Turn cadence is TURN_EVERY_MS in CompletedBoard.tsx, a code constant, not a token.
          </p>
        </div>
      )}
    </div>
  );
}

const CSS = `
.bt {
  position: fixed; top: 12px; right: 12px; z-index: 99999;
  width: 310px; max-height: calc(100vh - 24px);
  display: flex; flex-direction: column;
  background: #151119; border: 1px solid #2f2937; border-radius: 10px;
  color: #e7e4ee; font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 11.5px;
  box-shadow: 0 10px 40px rgb(0 0 0 / 55%);
}
.bt--empty { padding: 12px 14px; width: auto; color: #9c96ab; }
.bt--min { width: auto; }
.bt__bar {
  display: flex; align-items: center; gap: 8px; padding: 9px 11px;
  border-bottom: 1px solid #2f2937; flex: none;
}
.bt--min .bt__bar { border-bottom: 0; }
.bt__name { flex: 1; letter-spacing: 0.14em; text-transform: uppercase; font-size: 9.5px; color: #9c96ab; }
.bt__bar button {
  font: inherit; font-size: 9.5px; letter-spacing: 0.08em; text-transform: uppercase;
  background: transparent; color: #cfc9dc; border: 1px solid #3a3345;
  border-radius: 5px; padding: 4px 8px; cursor: pointer;
}
.bt__bar button:hover { background: #241f2e; }
.bt__body { overflow-y: auto; padding: 11px; display: flex; flex-direction: column; gap: 12px; }
.bt__warn { margin: 0; color: #e0b453; }
.bt__eyebrow {
  margin: 0 0 5px; font-size: 9px; letter-spacing: 0.18em;
  text-transform: uppercase; color: #6d6779;
}
.bt__read { width: 100%; border-collapse: collapse; }
.bt__read td { padding: 3px 0; border-bottom: 1px solid #221d2b; }
.bt__n { text-align: right; padding-right: 8px !important; font-variant-numeric: tabular-nums; }
.bt__v { width: 40px; text-align: right; }
.bt__tag { font-size: 9px; letter-spacing: 0.06em; text-transform: uppercase; }
.bt__tag--pass { color: #74c48a; }
.bt__tag--thin { color: #e0b453; }
.bt__tag--fail { color: #ec6a72; }
.bt__ctl + .bt__ctl { margin-top: 8px; }
.bt__ctl label {
  display: flex; justify-content: space-between; gap: 8px; margin-bottom: 3px;
  font-size: 9px; letter-spacing: 0.11em; text-transform: uppercase; color: #6d6779;
}
.bt__ctl label b { color: #e7e4ee; font-weight: 500; font-variant-numeric: tabular-nums; }
.bt input[type=range] { width: 100%; accent-color: #74c48a; margin: 0; }
.bt pre {
  margin: 0; padding: 9px 10px; background: #0e0c13; border: 1px solid #2f2937;
  border-radius: 6px; overflow-x: auto; font-size: 10.5px; line-height: 1.6; color: #cfc9dc;
}
.bt__foot { margin: 0; color: #6d6779; font-size: 10px; line-height: 1.5; }
`;
