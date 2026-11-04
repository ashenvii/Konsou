-- konsou.db: the user's own record. Everything here except the two `name`
-- columns is written to the Drive backup.

CREATE TABLE entry (
  entry_id          TEXT PRIMARY KEY,
  name              TEXT,                      -- local only, never synced
  status            TEXT NOT NULL CHECK (status IN (
                      'watching', 'completed', 'plan_to_watch', 'on_hold',
                      'dropped', 'rewatching', 'not_interested')),
  episodes_watched  INTEGER NOT NULL DEFAULT 0 CHECK (episodes_watched >= 0),
  score             INTEGER CHECK (score IS NULL OR (score >= 1 AND score <= 10)),
  notes             TEXT,
  plan_rank         INTEGER,
  added_at          INTEGER NOT NULL,          -- Unix milliseconds
  updated_at        INTEGER NOT NULL,
  started_at        INTEGER
);

CREATE INDEX idx_entry_status  ON entry(status);
CREATE INDEX idx_entry_updated ON entry(updated_at);

CREATE TABLE entry_reference (
  entry_id     TEXT NOT NULL REFERENCES entry(entry_id) ON DELETE CASCADE,
  provider     TEXT NOT NULL CHECK (provider IN ('mal', 'anilist')),
  provider_id  INTEGER NOT NULL,
  PRIMARY KEY (entry_id, provider)
);

-- Not unique: two entries can point at the same provider page.
CREATE INDEX idx_reference_lookup ON entry_reference(provider, provider_id);

CREATE TABLE completion (
  entry_id             TEXT NOT NULL,
  watch_number         INTEGER NOT NULL,       -- 0 first watch, 1 first rewatch
  completed_at         INTEGER NOT NULL,
  episodes_watched     INTEGER NOT NULL DEFAULT 0,
  minutes_per_episode  INTEGER,                -- null: stats use 24
  is_estimated         INTEGER NOT NULL DEFAULT 0,
  name                 TEXT,                   -- local only, never synced
  PRIMARY KEY (entry_id, watch_number)
);

CREATE INDEX idx_completion_date ON completion(completed_at);

CREATE TABLE alert (
  entry_id             TEXT NOT NULL,
  related_provider     TEXT NOT NULL CHECK (related_provider IN ('mal', 'anilist')),
  related_provider_id  INTEGER NOT NULL,
  type                 TEXT NOT NULL CHECK (type IN (
                         'sequel', 'side_story', 'spin_off', 'movie', 'started_airing')),
  seen                 INTEGER NOT NULL DEFAULT 0,
  dismissed            INTEGER NOT NULL DEFAULT 0,
  created_at           INTEGER NOT NULL,
  PRIMARY KEY (entry_id, related_provider, related_provider_id, type)
);

CREATE TABLE deletion (
  entry_id    TEXT PRIMARY KEY,
  deleted_at  INTEGER NOT NULL
);

CREATE TABLE setting (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);

CREATE TABLE device (
  device_id  TEXT PRIMARY KEY
);
