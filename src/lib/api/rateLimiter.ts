/**
 * Client-side token bucket. Built before any API call is made — not optional.
 * AniList: 90 req/min. Jikan: 60 req/min. On a 429, read `Retry-After` and call
 * `backoff()` with that exact value — never a fixed wait.
 */
export const delay = (ms: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

export class TokenBucket {
  private tokens: number;
  private readonly capacity: number;
  private readonly refillPerMs: number;
  private lastRefill: number;
  private pausedUntil = 0;

  constructor(opts: { capacity: number; refillPerMinute: number }) {
    this.capacity = opts.capacity;
    this.tokens = opts.capacity;
    this.refillPerMs = opts.refillPerMinute / 60_000;
    this.lastRefill = Date.now();
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
  async acquire(): Promise<void> {
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
