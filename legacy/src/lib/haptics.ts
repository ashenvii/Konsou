/**
 * Light haptic feedback for touch. The Android WebView (Konsou's mobile
 * target) supports navigator.vibrate; iOS WebView and desktop don't, where
 * every call is a safe no-op. Kept deliberately tiny and subtle: a tap should
 * feel confirmed, never buzzy.
 */
type HapticKind = "light" | "medium" | "success" | "warning";

const PATTERNS: Record<HapticKind, number | number[]> = {
  light: 8,
  medium: 15,
  success: [10, 40, 14],
  warning: [12, 30, 12],
};

export function haptic(kind: HapticKind = "light"): void {
  try {
    // Feature-detected each call: some Androids expose it, others (and every
    // desktop) don't. Never throws, never blocks.
    navigator.vibrate?.(PATTERNS[kind]);
  } catch {
    // Ignore — haptics are a nicety, never a requirement.
  }
}
