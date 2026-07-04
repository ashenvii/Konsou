/**
 * Session-scoped UI state: search text, chip selections, scroll offsets.
 * Pages read their last state on mount so navigating into a detail page and
 * back lands exactly where you left off. Deliberately memory-only — a fresh
 * launch starts clean, matching how platform apps treat transient UI state.
 * Durable preferences (view mode, sort, theme) stay in the settings store.
 */
const cache = new Map<string, unknown>();

export function getUiState<T>(key: string, fallback: T): T {
  return cache.has(key) ? (cache.get(key) as T) : fallback;
}

export function setUiState(key: string, value: unknown): void {
  cache.set(key, value);
}
