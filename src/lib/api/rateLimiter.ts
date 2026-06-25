/**
 * Client-side token bucket. Built before any API call is made — not optional.
 * AniList: 90 req/min. Jikan: 60 req/min. On a 429, read `Retry-After` and call
 * `backoff()` with that exact value — never a fixed wait.
 */
export const delay = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Request priority. `high` = anything the user is waiting on (search, browse,
 * opening a detail page). `low` = background maintenance (sequel-radar relation
 * fetches). Low-priority requests always yield to any waiting high-priority one
 * and only draw from a reserved-headroom slice of the bucket, so a background
 * scan can never starve the user's first few taps when the app opens.
 */
export type Priority = "high" | "low";

export class TokenBucket {
  private tokens: number;
  private readonly capacity: number;
  private readonly refillPerMs: number;
  private lastRefill: number;
  private pausedUntil = 0;
  /** How many high-priority acquirers are currently waiting for a token. */
  private highWaiting = 0;
  /** Tokens a low-priority request must leave behind (foreground headroom). */
  private readonly lowReserve: number;

  constructor(opts: {
    capacity: number;
    refillPerMinute: number;
    /** Fraction of capacity kept free for foreground bursts (default 25%). */
    lowReserveRatio?: number;
  }) {
    this.capacity = opts.capacity;
    this.tokens = opts.capacity;
    this.refillPerMs = opts.refillPerMinute / 60_000;
    this.lastRefill = Date.now();
    this.lowReserve = Math.ceil(opts.capacity * (opts.lowReserveRatio ?? 0.25));
  }

  private refill(): void {
    const now = Date.now();
    const elapsed = now - this.lastRefill;
    if (elapsed > 0) {
      this.tokens = Math.min(this.capacity, this.tokens + elapsed * this.refillPerMs);
      this.lastRefill = now;
    }
  }

  /** Resolves once a token is available. Requests queue; they never drop. */
  async acquire(priority: Priority = "high"): Promise<void> {
    return priority === "low" ? this.acquireLow() : this.acquireHigh();
  }

  private async acquireHigh(): Promise<void> {
    this.highWaiting++;
    try {
      for (;;) {
        const now = Date.now();
        if (now < this.pausedUntil) {
          await delay(this.pausedUntil - now);
          continue;
        }
        this.refill();
        if (this.tokens >= 1) {
          this.tokens -= 1;
          return;
        }
        const waitMs = (1 - this.tokens) / this.refillPerMs;
        await delay(Math.max(50, Math.ceil(waitMs)));
      }
    } finally {
      this.highWaiting--;
    }
  }

  private async acquireLow(): Promise<void> {
    for (;;) {
      const now = Date.now();
      if (now < this.pausedUntil) {
        await delay(this.pausedUntil - now);
        continue;
      }
      // Always let foreground go first.
      if (this.highWaiting > 0) {
        await delay(250);
        continue;
      }
      this.refill();
      // Only consume above the reserved headroom so a foreground burst that
      // arrives a moment later still finds tokens waiting for it.
      if (this.tokens >= this.lowReserve + 1) {
        this.tokens -= 1;
        return;
      }
      const waitMs = (this.lowReserve + 1 - this.tokens) / this.refillPerMs;
      await delay(Math.max(100, Math.ceil(waitMs)));
    }
  }

  /** Pause the bucket for the exact Retry-After duration on a 429. */
  backoff(retryAfterSeconds: number): void {
    this.pausedUntil = Date.now() + retryAfterSeconds * 1000;
    this.tokens = 0;
  }
}

// Singletons — one limiter per upstream.
export const anilistLimiter = new TokenBucket({ capacity: 90, refillPerMinute: 90 });
export const jikanLimiter = new TokenBucket({ capacity: 60, refillPerMinute: 60 });
