/**
 * Debounced write queue. Coalesces rapid list mutations into one Drive push, and
 * exposes `flushNow()` so the lifecycle layer can force a flush before Android
 * suspends the app (Trap 5) — never lose an in-flight write.
 */
const DEBOUNCE_MS = 5000;

class SyncQueue {
  private debounceTimer: ReturnType<typeof setTimeout> | null = null;
  private pendingWrite: (() => Promise<void>) | null = null;

  scheduleWrite(writeFn: () => Promise<void>): void {
    this.pendingWrite = writeFn;
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => void this.execute(), DEBOUNCE_MS);
  }

  async flushNow(): Promise<void> {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
    if (this.pendingWrite) await this.execute();
  }

  private async execute(): Promise<void> {
    if (!this.pendingWrite) return;
    const fn = this.pendingWrite;
    this.pendingWrite = null;
    await fn();
  }
}

export const syncQueue = new SyncQueue();
