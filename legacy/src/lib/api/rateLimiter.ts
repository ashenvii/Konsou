/**
 * Client-side token bucket. Built before any API call is made -- not optional.
 * AniList: documented 90 req/min, but the API has run in a degraded state for
 * years with the ENFORCED limit at 30 req/min (their docs say so; the
 * X-RateLimit-Limit header still lies and says 90). Budgeting against 90 is
 * what made three detail-page opens in a row end in a 429 wall. Jikan: 60
 * req/min. On a 429, read `Retry-After` and call `backoff()` with that exact
 * value -- never a fixed wait.
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
  /** Minimum gap between two low-priority grants, and when the last one fired. */
  private readonly lowMinIntervalMs: number;
  private lowLastAt = 0;

  constructor(opts: {
    capacity: number;
    refillPerMinute: number;
    /** Fraction of capacity kept free for foreground bursts (default 25%). */
    lowReserveRatio?: number;
    /**
     * Minimum spacing between background (low-priority) requests. Without it,
     * the bucket starts full and a boot-time burst (franchise grooming + the
     * sequel scan on a large list) can fire dozens of requests in seconds,
     * tripping AniList's burst protection into a 429 that then stalls the
     * user's own taps. Spacing caps background to a sustainable trickle so it
     * never saturates the limit; foreground (high) keeps the full bucket.
     */
    lowMinIntervalMs?: number;
  }) {
    this.capacity = opts.capacity;
    this.tokens = opts.capacity;
    this.refillPerMs = opts.refillPerMinute / 60_000;
    this.lastRefill = Date.now();
    this.lowReserve = Math.ceil(opts.capacity * (opts.lowReserveRatio ?? 0.25));
    this.lowMinIntervalMs = opts.lowMinIntervalMs ?? 0;
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
      // Hold the minimum spacing so background can never burst into a 429.
      const sinceLast = now - this.lowLastAt;
      if (sinceLast < this.lowMinIntervalMs) {
        await delay(this.lowMinIntervalMs - sinceLast);
        continue;
      }
      this.refill();
      // Only consume above the reserved headroom so a foreground burst that
      // arrives a moment later still finds tokens waiting for it.
      if (this.tokens >= this.lowReserve + 1) {
        this.tokens -= 1;
        this.lowLastAt = Date.now();
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

  /**
   * Reconcile with the server's own X-RateLimit-Remaining header. Only ever
   * lowers the local count: the server is the authority on how much budget is
   * left in its window, but its "remaining" resets on ITS minute boundary, so
   * raising ours from it could double-spend. Anything else in the app (another
   * window, a previous session's tail) that spent requests we didn't see gets
   * accounted for here instead of surfacing as a surprise 429.
   */
  syncRemaining(remaining: number): void {
    if (!Number.isFinite(remaining) || remaining < 0) return;
    this.refill();
    if (remaining < this.tokens) this.tokens = remaining;
  }
}

// Singletons -- one limiter per upstream. Background work is spaced so a boot
// burst on a large list can't saturate the upstream and stall the user's own
// requests: ~3s between AniList background calls (~20/min, leaving a third of
// the real 30/min budget plus the reserve for foreground), ~2s for Jikan.
export const anilistLimiter = new TokenBucket({
  capacity: 30,
  refillPerMinute: 30,
  lowMinIntervalMs: 3000,
});
export const jikanLimiter = new TokenBucket({
  capacity: 60,
  refillPerMinute: 60,
  lowMinIntervalMs: 2000,
});
