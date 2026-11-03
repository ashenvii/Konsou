/** Runtime platform detection. The whole app branches on `isTauri` exactly once,
 *  inside the DB driver — everywhere else stays platform-agnostic. */

export const isTauri = (): boolean =>
  typeof window !== "undefined" &&
  // Tauri v2 exposes this internal on the window object.
  "__TAURI_INTERNALS__" in window;

export const isAndroidUA = (): boolean =>
  typeof navigator !== "undefined" && /android/i.test(navigator.userAgent);

/** A stable per-install id used for sync conflict attribution. */
export function getDeviceId(): string {
  const KEY = "konsou.device_id";
  let id = localStorage.getItem(KEY);
  if (!id) {
    id = `${isTauri() ? "app" : "web"}-${crypto.randomUUID().slice(0, 12)}`;
    localStorage.setItem(KEY, id);
  }
  return id;
}
