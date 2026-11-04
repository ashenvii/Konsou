-- Migration 14: copy the old list (migrations 1 to 12) into the new tables.
--
-- Runs on every database. On a fresh install the old tables are empty, so
-- nothing is copied. On an upgrade they hold the user's list. Every insert is
-- INSERT OR IGNORE, so running it again changes nothing.
--
-- The old tables are left untouched. A later migration drops them, after a
-- release has shipped. Until then anime_list.franchise_root_id is also where
-- the first launch reads the placeholder roots to copy into details.db.

-- Entries. Ids are derived from the old AniList id so two devices that each
-- upgrade their own copy produce the same ids.
INSERT OR IGNORE INTO entry
  (entry_id, name, status, episodes_watched, score, notes, plan_rank,
   added_at, updated_at, started_at)
SELECT
  'legacy-' || anilist_id,
  CASE (SELECT value FROM settings WHERE key = 'title_language')
    WHEN 'english' THEN COALESCE(NULLIF(title_english, ''), title_romaji, title_native)
    WHEN 'native'  THEN COALESCE(NULLIF(title_native, ''), title_romaji, title_english)
    ELSE COALESCE(title_romaji, NULLIF(title_english, ''), title_native)
  END,
  status,
  episodes_watched,
  CASE WHEN score IS NULL THEN NULL ELSE CAST(ROUND(score) AS INTEGER) END,
  notes,
  plan_rank,
  added_at,
  updated_at,
  started_at
FROM anime_list;

INSERT OR IGNORE INTO entry_reference (entry_id, provider, provider_id)
SELECT 'legacy-' || anilist_id, 'anilist', anilist_id FROM anime_list;

INSERT OR IGNORE INTO entry_reference (entry_id, provider, provider_id)
SELECT 'legacy-' || anilist_id, 'mal', mal_id FROM anime_list WHERE mal_id IS NOT NULL;

-- Finished watches. The name comes from the entry so it follows the user's
-- title language; the old copy is the fallback for ghost records.
INSERT OR IGNORE INTO completion
  (entry_id, watch_number, completed_at, episodes_watched,
   minutes_per_episode, is_estimated, name)
SELECT
  'legacy-' || c.anilist_id,
  c.rewatch_index,
  c.completed_at,
  c.episodes_at_completion,
  c.episode_duration,
  c.estimated,
  COALESCE(
    (SELECT e.name FROM entry e WHERE e.entry_id = 'legacy-' || c.anilist_id),
    NULLIF(c.title_english, ''),
    c.title_romaji)
FROM completion_log c;

-- Alerts keep ids and state only. Titles and covers are not carried over.
INSERT OR IGNORE INTO alert
  (entry_id, related_provider, related_provider_id, type, seen, dismissed, created_at)
SELECT 'legacy-' || source_id, 'anilist', related_id, type, seen, dismissed, created_at
FROM notifications;

INSERT OR IGNORE INTO deletion (entry_id, deleted_at)
SELECT 'legacy-' || anilist_id, deleted_at FROM list_tombstones;

-- Preferences only. sync.version, sync.last_at and last_sequel_check are
-- rewritten by the new sync and scan.
INSERT OR IGNORE INTO setting (key, value)
SELECT key, value FROM settings
WHERE key IN ('title_language', 'sidebar_mode', 'default_view',
              'color_theme', 'accent', 'recent_searches');

INSERT OR IGNORE INTO device (device_id)
SELECT device_id FROM sync_state;
