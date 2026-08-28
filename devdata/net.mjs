// Shared throttled AniList GraphQL fetcher for the devdata scripts.
// Stays under the real 30/min cap (memory: degraded-mode limit, not the
// documented 90) and honors the rate headers the app's limiter syncs to.

const MIN_GAP_MS = 2400; // ~25/min
let lastRequestAt = 0;
let requestCount = 0;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export function getRequestCount() {
  return requestCount;
}

export async function gql(query, variables) {
  for (let attempt = 0; ; attempt++) {
    const wait = lastRequestAt + MIN_GAP_MS - Date.now();
    if (wait > 0) await sleep(wait);
    lastRequestAt = Date.now();
    requestCount++;

    let res;
    try {
      res = await fetch("https://graphql.anilist.co", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(variables ? { query, variables } : { query }),
      });
    } catch (e) {
      if (attempt >= 4) throw e;
      await sleep([5000, 15000, 45000, 90000][attempt]);
      continue;
    }

    if (res.status === 429) {
      const retryAfter = parseInt(res.headers.get("Retry-After") ?? "60", 10);
      await sleep((retryAfter + 2) * 1000);
      continue;
    }

    // AniList returns HTTP 404 WITH partial data when some aliased ids are
    // missing; that body is usable, so parse before judging the status code.
    let json = null;
    try {
      json = await res.json();
    } catch {
      json = null;
    }

    if (!json?.data && res.status >= 500) {
      if (attempt >= 4) throw new Error(`AniList ${res.status} after retries`);
      await sleep([5000, 15000, 45000, 90000][attempt]);
      continue;
    }

    const remaining = parseInt(res.headers.get("X-RateLimit-Remaining") ?? "99", 10);
    if (remaining <= 2) await sleep(45000);

    return { status: res.status, json };
  }
}
