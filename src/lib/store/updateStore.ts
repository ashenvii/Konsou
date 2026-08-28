import { create } from "zustand";
import { APP_NAME } from "@/lib/version";
import type { AvailableUpdate, PendingUpdate } from "@/lib/updater";

/**
 * Whether there is a newer Konsou than the one you are running, and how loudly
 * to say so.
 *
 * Before this the answer lived nowhere. A found update fired a toast with
 * `duration: 0` at boot, which is a banner that sits over the app until it is
 * dismissed and then is gone for good — so the two possible outcomes were "in
 * your way" and "you will never hear about it again". The same check also ran
 * from About behind a button that fired its own toast, so the one fact had two
 * unrelated presentations and no home.
 *
 * It has one home now: What's New. This store is what the sidebar and the
 * header read to put a mark on that door, and what the page itself reads to
 * offer the install.
 *
 * ## The nudge
 *
 * A permanent tag is the thing to avoid — a badge that never leaves stops being
 * information within a day. So the mark stays (it is one dot, and it is true
 * until you update), and the *tooltip* is the part that is rationed: it opens
 * itself once when the update is first found, then once per launch, capped at
 * three times, and never again for that version. Insistent enough to be
 * noticed, and it stops before it becomes nagging.
 *
 * The count is stored against the version it belongs to, so shipping a new
 * release starts a fresh three rather than inheriting a spent budget.
 */

const NUDGE_KEY = "konsou.update_nudges";
/** How many times the tooltip may open itself for one version. */
const NUDGE_CAP = 3;

interface NudgeRecord {
  version: string;
  count: number;
}

function readNudges(): NudgeRecord | null {
  try {
    const raw = localStorage.getItem(NUDGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as NudgeRecord;
    return typeof parsed?.version === "string" ? parsed : null;
  } catch {
    // A corrupt record is not worth a crash, and the cost of getting it wrong
    // is one extra tooltip.
    return null;
  }
}

function writeNudges(rec: NudgeRecord) {
  try {
    localStorage.setItem(NUDGE_KEY, JSON.stringify(rec));
  } catch {
    // Private mode, quota, an embedded webview with storage off. The nudge
    // budget resetting is not a failure worth surfacing.
  }
}

interface UpdateState {
  /** The update that is waiting, or null when you are current. */
  update: PendingUpdate | AvailableUpdate | null;
  /** The tooltip is open right now. */
  nudging: boolean;
  /** What to call the app in the notice. Read from the manifest rather than
   *  written into a string, so a rename carries. */
  appName: string;
  /** Called by the boot check when it finds something. */
  found: (update: PendingUpdate | AvailableUpdate) => void;
  /** Open the tooltip if this version still has budget. Called once at boot
   *  after `found`, and never on a timer — a notice that reappears while you
   *  are working is the thing being avoided here. */
  nudge: () => void;
  /** Dismiss the tooltip. Pointing at it, opening What's New, or simply
   *  clicking anywhere else all count. */
  hush: () => void;
  /** The update was installed or the user went and dealt with it. */
  clear: () => void;
}

export const useUpdateStore = create<UpdateState>((set, get) => ({
  update: null,
  nudging: false,
  appName: APP_NAME,

  found: (update) => set({ update }),

  nudge: () => {
    const { update } = get();
    if (!update) return;
    const rec = readNudges();
    const count = rec && rec.version === update.version ? rec.count : 0;
    if (count >= NUDGE_CAP) return;
    writeNudges({ version: update.version, count: count + 1 });
    set({ nudging: true });
  },

  hush: () => set({ nudging: false }),

  clear: () => set({ update: null, nudging: false }),
}));

/** The one sentence the notice says. Named the app from the manifest, so a
 *  rename carries; states the version, because "an update is available" with
 *  no number is not something you can check against what you have. */
export function updateNotice(
  appName: string,
  update: PendingUpdate | AvailableUpdate,
): string {
  return `Update for ${appName} available — v${update.version}`;
}
