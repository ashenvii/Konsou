import { open } from "@tauri-apps/plugin-shell";
import { isTauri } from "./platform";

/** Open a URL in the system browser (never inside the app WebView). */
export async function openExternal(url: string): Promise<void> {
  if (isTauri()) {
    await open(url);
  } else {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}
