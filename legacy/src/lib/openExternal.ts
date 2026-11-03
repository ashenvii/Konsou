import { openUrl } from "@tauri-apps/plugin-opener";
import { isTauri } from "./platform";

/** Open a URL in the system browser (never inside the app WebView). The opener
 *  plugin works on desktop and Android; the shell plugin's `open` does not open
 *  URLs on Android (it fails with a scoped shell IO error). */
export async function openExternal(url: string): Promise<void> {
  if (isTauri()) {
    await openUrl(url);
  } else {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}
