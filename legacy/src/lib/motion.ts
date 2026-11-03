import type { MotionMode } from "@/types/list";

/**
 * How much motion this device gets, and who decides.
 *
 * THIS EXISTS BECAUSE THERE WAS NO TIER. `main.tsx` added `perf-lite` to the
 * document unconditionally, on every device, and its own comment said so: the
 * win outweighed the flourish. That was the right call while the class was the
 * only lever, but it means a desktop with a discrete GPU has been running the
 * same stripped build as a phone, with every ambient animation and glow held at
 * its end state. There is no way to ask for the full thing.
 *
 * Three values, and only one of them guesses:
 *
 *   full    every effect runs
 *   lite    live compositor effects swap for static equivalents (see perf.css)
 *   system  resolve it from the device
 *
 * `system` is the default, and it resolves to `lite` on a coarse pointer or in
 * the Android WebView, which is where the jank was actually measured, and to
 * `full` everywhere else. Sniffing is a guess, which is exactly why the other
 * two values exist: someone who knows their machine can say so and be believed.
 *
 * REDUCED MOTION IS A SEPARATE AXIS AND IS NOT HANDLED HERE. `prefers-reduced-
 * motion` is answered by media queries in the stylesheets, because it is a
 * statement about motion rather than about paint budget, and a machine that
 * asks for stillness is not necessarily a slow one. Conflating them would mean
 * a fast machine that wants calm also loses its shadows.
 */

/** What `system` means on this device. */
export function resolveMotionMode(mode: MotionMode): "full" | "lite" {
  if (mode === "full" || mode === "lite") return mode;
  if (typeof window === "undefined") return "lite";
  const android = /android/i.test(navigator.userAgent);
  const coarse =
    typeof window.matchMedia === "function" &&
    window.matchMedia("(pointer: coarse)").matches;
  return android || coarse ? "lite" : "full";
}

/** Stamp the resolved tier on the document. `full` carries no class at all,
 *  so the stylesheets' default IS the full build and `perf-lite` stays a
 *  subtraction rather than becoming a thing every rule has to opt out of. */
export function applyMotionMode(mode: MotionMode): void {
  document.documentElement.classList.toggle(
    "perf-lite",
    resolveMotionMode(mode) === "lite",
  );
}

/** Validate what came back from the settings row. Anything unrecognised, and
 *  anything written before this setting existed, lands on `system`. */
export function normalizeMotionMode(raw: string | undefined): MotionMode {
  return raw === "full" || raw === "lite" || raw === "system" ? raw : "system";
}
