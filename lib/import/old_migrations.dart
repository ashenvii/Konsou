/// The old Tauri app's migrations 1 to 12, copied as they were. Running the
/// missing ones on a copy brings any old file to version 12, so one import
/// query reads every old list.
const oldMigrations = <int, String>{
  // initial schema
  1: r'''
CREATE TABLE IF NOT EXISTS anime_list (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  anilist_id       INTEGER NOT NULL UNIQUE,
  mal_id           INTEGER,
  title_romaji     TEXT NOT NULL,
  title_english    TEXT,
  cover_url        TEXT,
  total_episodes   INTEGER,
  status           TEXT NOT NULL CHECK(status IN (
                     'watching', 'completed', 'plan_to_watch',
                     'on_hold', 'dropped', 'rewatching'
                   )),
  episodes_watched INTEGER NOT NULL DEFAULT 0,
  score            REAL CHECK(score IS NULL OR (score >= 1 AND score <= 10)),
  notes            TEXT,
  added_at         INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL,
  started_at       INTEGER,
  completed_at     INTEGER
);

CREATE INDEX IF NOT EXISTS idx_list_status  ON anime_list(status);
CREATE INDEX IF NOT EXISTS idx_list_updated ON anime_list(updated_at);

CREATE TABLE IF NOT EXISTS anime_cache (
  anilist_id  INTEGER PRIMARY KEY,
  data_json   TEXT NOT NULL,
  cached_at   INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS search_cache (
  query_hash   TEXT PRIMARY KEY,
  query_text   TEXT NOT NULL,
  results_json TEXT NOT NULL,
  cached_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS relation_snapshots (
  anilist_id     INTEGER PRIMARY KEY,
  relations_json TEXT NOT NULL,
  checked_at     INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id      INTEGER NOT NULL,
  related_id     INTEGER NOT NULL,
  type           TEXT NOT NULL CHECK(type IN (
                   'sequel', 'side_story', 'spin_off', 'movie'
                 )),
  related_title  TEXT NOT NULL,
  related_cover  TEXT,
  related_status TEXT NOT NULL,
  airing_at      INTEGER,
  seen           INTEGER NOT NULL DEFAULT 0,
  dismissed      INTEGER NOT NULL DEFAULT 0,
  created_at     INTEGER NOT NULL,
  UNIQUE(source_id, related_id)
);

CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_state (
  id               INTEGER PRIMARY KEY CHECK(id = 1),
  last_sync_at     INTEGER,
  last_sync_result TEXT,
  device_id        TEXT NOT NULL
);
''',
  // add has_dub to anime_list
  2: r'''
ALTER TABLE anime_list ADD COLUMN has_dub INTEGER;
''',
  // deletion tombstones for sync
  3: r'''
CREATE TABLE IF NOT EXISTS list_tombstones (
  anilist_id INTEGER PRIMARY KEY,
  deleted_at INTEGER NOT NULL
);
''',
  // add native title to anime_list
  4: r'''
ALTER TABLE anime_list ADD COLUMN title_native TEXT;
''',
  // per-seed sequel scan schedule
  5: r'''
CREATE TABLE IF NOT EXISTS scan_schedule (
  anilist_id    INTEGER PRIMARY KEY,
  last_check_at INTEGER NOT NULL,
  next_check_at INTEGER NOT NULL,
  quiet_streak  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_scan_schedule_due ON scan_schedule(next_check_at);
''',
  // franchise grouping root id
  6: r'''
ALTER TABLE anime_list ADD COLUMN franchise_root_id INTEGER;
CREATE INDEX IF NOT EXISTS idx_list_franchise ON anime_list(franchise_root_id);
''',
  // airing status for status validation and plan-to-watch alerts
  7: r'''
ALTER TABLE anime_list ADD COLUMN airing_status TEXT;
''',
  // started_airing alert type
  8: r'''
CREATE TABLE IF NOT EXISTS notifications_new (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id      INTEGER NOT NULL,
  related_id     INTEGER NOT NULL,
  type           TEXT NOT NULL CHECK(type IN (
                   'sequel', 'side_story', 'spin_off', 'movie', 'started_airing'
                 )),
  related_title  TEXT NOT NULL,
  related_cover  TEXT,
  related_status TEXT NOT NULL,
  airing_at      INTEGER,
  seen           INTEGER NOT NULL DEFAULT 0,
  dismissed      INTEGER NOT NULL DEFAULT 0,
  created_at     INTEGER NOT NULL,
  UNIQUE(source_id, related_id, type)
);
INSERT OR IGNORE INTO notifications_new SELECT * FROM notifications;
DROP TABLE notifications;
ALTER TABLE notifications_new RENAME TO notifications;
CREATE INDEX IF NOT EXISTS idx_notifications_active ON notifications(dismissed, seen);
''',
  // time accounting: per-episode duration, rewatch count, aired episodes
  9: r'''
ALTER TABLE anime_list ADD COLUMN episode_duration INTEGER;
ALTER TABLE anime_list ADD COLUMN rewatch_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE anime_list ADD COLUMN aired_episodes INTEGER;
''',
  // drop frozen status CHECK (not_interested inserts failed)
  10: r'''
CREATE TABLE IF NOT EXISTS anime_list_new (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  anilist_id        INTEGER NOT NULL UNIQUE,
  mal_id            INTEGER,
  title_romaji      TEXT NOT NULL,
  title_english     TEXT,
  cover_url         TEXT,
  total_episodes    INTEGER,
  status            TEXT NOT NULL,
  episodes_watched  INTEGER NOT NULL DEFAULT 0,
  score             REAL CHECK(score IS NULL OR (score >= 1 AND score <= 10)),
  notes             TEXT,
  added_at          INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  started_at        INTEGER,
  completed_at      INTEGER,
  has_dub           INTEGER,
  title_native      TEXT,
  franchise_root_id INTEGER,
  airing_status     TEXT,
  episode_duration  INTEGER,
  rewatch_count     INTEGER NOT NULL DEFAULT 0,
  aired_episodes    INTEGER
);
INSERT OR IGNORE INTO anime_list_new SELECT * FROM anime_list;
DROP TABLE anime_list;
ALTER TABLE anime_list_new RENAME TO anime_list;
CREATE INDEX IF NOT EXISTS idx_list_status    ON anime_list(status);
CREATE INDEX IF NOT EXISTS idx_list_updated   ON anime_list(updated_at);
CREATE INDEX IF NOT EXISTS idx_list_franchise ON anime_list(franchise_root_id);
''',
  // plan queue: persisted manual rank
  11: r'''
ALTER TABLE anime_list ADD COLUMN plan_rank INTEGER;
''',
  // completion log: one row per completion event
  12: r'''
CREATE TABLE IF NOT EXISTS completion_log (
  anilist_id             INTEGER NOT NULL,
  rewatch_index          INTEGER NOT NULL DEFAULT 0,
  completed_at           INTEGER NOT NULL,
  episodes_at_completion INTEGER NOT NULL DEFAULT 0,
  episode_duration       INTEGER,
  total_episodes         INTEGER,
  title_romaji           TEXT NOT NULL,
  title_english          TEXT,
  title_native           TEXT,
  cover_url              TEXT,
  franchise_root_id      INTEGER,
  estimated              INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (anilist_id, rewatch_index)
);
CREATE INDEX IF NOT EXISTS idx_completion_at ON completion_log(completed_at);

WITH RECURSIVE watches(anilist_id, idx, events) AS (
  SELECT anilist_id,
         0,
         CASE WHEN status = 'rewatching'
              THEN rewatch_count
              ELSE rewatch_count + 1
         END
    FROM anime_list
   WHERE status = 'completed' OR status = 'rewatching' OR completed_at IS NOT NULL
  UNION ALL
  SELECT anilist_id, idx + 1, events FROM watches WHERE idx + 1 < events
)
INSERT OR IGNORE INTO completion_log (
  anilist_id, rewatch_index, completed_at, episodes_at_completion,
  episode_duration, total_episodes, title_romaji, title_english, title_native,
  cover_url, franchise_root_id, estimated
)
SELECT a.anilist_id,
       w.idx,
       COALESCE(a.completed_at, a.updated_at),
       COALESCE(a.total_episodes, a.episodes_watched, 0),
       a.episode_duration,
       a.total_episodes,
       a.title_romaji,
       a.title_english,
       a.title_native,
       a.cover_url,
       a.franchise_root_id,
       1
  FROM watches w
  JOIN anime_list a ON a.anilist_id = w.anilist_id;
''',
};
