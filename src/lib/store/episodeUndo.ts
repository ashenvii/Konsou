import { toast, useToastStore } from "./toastStore";

/**
 * One snackbar for a run of episode logs.
 *
 * Logging used to raise a toast per commit: tap four cards and four toasts
 * stack up, each racing its own short timer, and none of them can undo more
 * than the single tap that spawned it. Here every log inside a rolling window
 * joins ONE batch that owns ONE snackbar. The snackbar's countdown restarts on
 * each new log, so the Undo stays reachable for as long as you keep logging,
 * and Undo rolls every entry the batch touched back to where it started.
 *
 * The batch records the episode count each entry had BEFORE the batch first
 * touched it, so repeated taps on the same card still revert to the original
 * number rather than stepping back one at a time.
 */

/** How long the batch stays open after the last log, and the snackbar's life. */
const BATCH_MS = 5000;

interface LogBatch {
  /** 0 until the snackbar has been raised. */
  toastId: number;
  /** anilist_id -> episode count before this batch first touched that entry. */
  before: Map<number, number>;
  /** Total episodes added across the batch. */
  episodes: number;
  /** Latest resulting count, used for the single-entry message. */
  lastAfter: number;
}

let batch: LogBatch | null = null;
let closeTimer: ReturnType<typeof setTimeout> | null = null;

function closeBatch(): void {
  batch = null;
  if (closeTimer) {
    clearTimeout(closeTimer);
    closeTimer = null;
  }
}

async function undoBatch(): Promise<void> {
  if (!batch) return;
  const revert = [...batch.before.entries()];
  closeBatch();
  // Lazy import: listStore raises logs through this module, so importing it at
  // the top would close a cycle.
  const { useListStore } = await import("./listStore");
  const setEpisodes = useListStore.getState().setEpisodes;
  for (const [anilistId, before] of revert) {
    await setEpisodes(anilistId, before);
  }
}

function messageFor(b: LogBatch): string {
  // One show keeps the informative "where am I now" number; several shows
  // report the count, since no single episode number describes the run.
  if (b.before.size === 1) return `Ep ${b.lastAfter} logged`;
  return `${b.episodes} episodes logged`;
}

/**
 * Record a committed episode log. Raises the shared snackbar on the first call
 * and updates it in place afterwards. Callers pass the counts around their own
 * write so a revert never has to guess.
 */
export function recordEpisodeLog(
  anilistId: number,
  before: number,
  after: number,
): void {
  if (after <= before) return;

  if (!batch) {
    batch = { toastId: 0, before: new Map(), episodes: 0, lastAfter: after };
  }
  if (!batch.before.has(anilistId)) batch.before.set(anilistId, before);
  batch.episodes += after - before;
  batch.lastAfter = after;

  const message = messageFor(batch);
  const stillLive =
    batch.toastId !== 0 &&
    useToastStore.getState().update(batch.toastId, { message, duration: BATCH_MS });

  if (!stillLive) {
    batch.toastId = toast.action({
      message,
      actionLabel: "Undo",
      duration: BATCH_MS,
      onAction: () => void undoBatch(),
    });
  }

  if (closeTimer) clearTimeout(closeTimer);
  closeTimer = setTimeout(closeBatch, BATCH_MS);
}
