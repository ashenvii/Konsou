-- details.db: everything fetched from MAL or worked out from it.
-- Never synced. Safe to delete; it is rebuilt on demand.

CREATE TABLE detail (
  provider     TEXT NOT NULL,
  provider_id  INTEGER NOT NULL,
  fetched_at   INTEGER NOT NULL,
  json         TEXT NOT NULL,
  PRIMARY KEY (provider, provider_id)
);

-- The entry_id values here point into konsou.db (separate file, no foreign key).
CREATE TABLE franchise_link (
  entry_id          TEXT PRIMARY KEY,
  root_provider     TEXT NOT NULL,
  root_provider_id  INTEGER NOT NULL,
  is_placeholder    INTEGER NOT NULL DEFAULT 0   -- 1 until the scan rebuilds it from MAL
);

CREATE INDEX idx_franchise_root ON franchise_link(root_provider, root_provider_id);

CREATE TABLE relation (
  provider      TEXT NOT NULL,
  provider_id   INTEGER NOT NULL,
  json          TEXT NOT NULL,
  checked_at    INTEGER NOT NULL,
  PRIMARY KEY (provider, provider_id)
);

CREATE TABLE scan_schedule (
  entry_id       TEXT PRIMARY KEY,
  last_check_at  INTEGER NOT NULL,
  next_check_at  INTEGER NOT NULL,
  quiet_streak   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_scan_due ON scan_schedule(next_check_at);

CREATE TABLE search_cache (
  query_hash  TEXT PRIMARY KEY,
  query_text  TEXT NOT NULL,
  results     TEXT NOT NULL,
  cached_at   INTEGER NOT NULL
);
