//! Migration tests.
//!
//! These exist because of a specific, expensive failure: a migration can only
//! ever be wrong on a real device. The browser dev shim has no schema, so it
//! accepts anything, and `tauri dev` on a machine that already ran the previous
//! version never replays the upgrade path from scratch. Migration 10 was written
//! to undo exactly that kind of bug (a frozen status CHECK that made "not
//! interested" fail to save on devices while working fine in the browser).
//!
//! Every test here applies the real SQL from `migrations()` to a throwaway
//! database, both fresh-install and upgrade-from-old-version.

use crate::migrations;
use rusqlite::Connection;

/// Apply every migration whose version falls in `range`, in order.
fn apply(conn: &Connection, range: std::ops::RangeInclusive<i64>) {
    for m in migrations() {
        let v = m.version as i64;
        if range.contains(&v) {
            conn.execute_batch(m.sql)
                .unwrap_or_else(|e| panic!("migration {v} ({}) failed: {e}", m.description));
        }
    }
}

/// A database at the newest schema, as a fresh install would produce.
fn fresh() -> Connection {
    let conn = Connection::open_in_memory().unwrap();
    apply(&conn, 1..=i64::MAX);
    conn
}

fn columns(conn: &Connection, table: &str) -> Vec<String> {
    let mut stmt = conn
        .prepare(&format!("SELECT name FROM pragma_table_info('{table}')"))
        .unwrap();
    let rows = stmt.query_map([], |r| r.get::<_, String>(0)).unwrap();
    rows.map(|r| r.unwrap()).collect()
}

fn indexes(conn: &Connection, table: &str) -> Vec<String> {
    let mut stmt = conn
        .prepare("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ?1")
        .unwrap();
    let rows = stmt.query_map([table], |r| r.get::<_, String>(0)).unwrap();
    rows.map(|r| r.unwrap()).collect()
}

fn count(conn: &Connection, sql: &str) -> i64 {
    conn.query_row(sql, [], |r| r.get(0)).unwrap()
}

// ---------------------------------------------------------------------------
// The list itself
// ---------------------------------------------------------------------------

#[test]
fn every_migration_applies_to_a_fresh_database() {
    // The panic message in `apply` names the migration, so a failure here points
    // straight at the offending SQL.
    fresh();
}

#[test]
fn versions_are_unique_and_ascending() {
    let versions: Vec<i64> = migrations().iter().map(|m| m.version as i64).collect();
    let mut sorted = versions.clone();
    sorted.sort_unstable();
    sorted.dedup();
    assert_eq!(versions, sorted, "migration versions must be unique and in order");
    assert_eq!(versions[0], 1, "the list has to start at version 1");
}

#[test]
fn migrations_are_all_forward_only() {
    for m in migrations() {
        assert!(
            matches!(m.kind, tauri_plugin_sql::MigrationKind::Up),
            "migration {} is not an Up migration",
            m.version
        );
    }
}

// ---------------------------------------------------------------------------
// Fresh-install schema
// ---------------------------------------------------------------------------

#[test]
fn fresh_install_has_every_column_the_app_writes() {
    let conn = fresh();
    let cols = columns(&conn, "anime_list");
    for expected in [
        "anilist_id",
        "mal_id",
        "title_romaji",
        "title_english",
        "title_native",
        "cover_url",
        "total_episodes",
        "status",
        "episodes_watched",
        "score",
        "notes",
        "added_at",
        "updated_at",
        "started_at",
        "completed_at",
        "has_dub",
        "franchise_root_id",
        "airing_status",
        "episode_duration",
        "rewatch_count",
        "aired_episodes",
        "plan_rank",
    ] {
        assert!(cols.contains(&expected.to_string()), "anime_list is missing {expected}");
    }
}

#[test]
fn fresh_install_keeps_the_indexes_the_list_queries_rely_on() {
    let conn = fresh();
    let list = indexes(&conn, "anime_list");
    for expected in ["idx_list_status", "idx_list_updated", "idx_list_franchise"] {
        assert!(list.contains(&expected.to_string()), "missing index {expected}");
    }
    assert!(indexes(&conn, "scan_schedule").contains(&"idx_scan_schedule_due".to_string()));
    assert!(indexes(&conn, "notifications").contains(&"idx_notifications_active".to_string()));
}

#[test]
fn fresh_install_creates_every_table_the_contract_expects() {
    let conn = fresh();
    for table in [
        "anime_list",
        "anime_cache",
        "search_cache",
        "relation_snapshots",
        "notifications",
        "settings",
        "sync_state",
        "list_tombstones",
        "scan_schedule",
        "completion_log",
    ] {
        let found = count(
            &conn,
            &format!("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='{table}'"),
        );
        assert_eq!(found, 1, "table {table} was never created");
    }
}

// ---------------------------------------------------------------------------
// The status vocabulary — the bug migration 10 was written for
// ---------------------------------------------------------------------------

#[test]
fn the_status_column_accepts_values_added_after_v1() {
    let conn = fresh();
    // "not_interested" postdates the v1 CHECK. On a device that still had the
    // frozen constraint this INSERT is what failed with "Couldn't add to your
    // list", while the browser shim accepted it happily.
    for status in [
        "watching",
        "completed",
        "plan_to_watch",
        "on_hold",
        "dropped",
        "rewatching",
        "not_interested",
    ] {
        conn.execute(
            "INSERT INTO anime_list (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at)
             VALUES (?1, 'x', ?2, 0, 1, 1)",
            rusqlite::params![status.len() as i64 * 1000 + status.as_bytes()[0] as i64, status],
        )
        .unwrap_or_else(|e| panic!("status '{status}' was rejected by the schema: {e}"));
    }
}

#[test]
fn the_score_range_is_still_enforced() {
    let conn = fresh();
    let insert = |score: f64| {
        conn.execute(
            "INSERT INTO anime_list (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at, score)
             VALUES (?1, 'x', 'watching', 0, 1, 1, ?2)",
            rusqlite::params![(score * 100.0) as i64, score],
        )
    };
    assert!(insert(8.5).is_ok(), "a valid score must be accepted");
    assert!(insert(11.0).is_err(), "a score above 10 must be rejected");
    assert!(insert(0.0).is_err(), "a score below 1 must be rejected");
}

// ---------------------------------------------------------------------------
// Upgrade paths — an existing user's data has to come through intact
// ---------------------------------------------------------------------------

#[test]
fn upgrading_from_v1_preserves_the_users_list() {
    let conn = Connection::open_in_memory().unwrap();
    apply(&conn, 1..=1);

    conn.execute(
        "INSERT INTO anime_list
           (anilist_id, mal_id, title_romaji, title_english, cover_url, total_episodes,
            status, episodes_watched, score, notes, added_at, updated_at, started_at, completed_at)
         VALUES (1535, 1535, 'Death Note', 'Death Note', 'cover.jpg', 37,
                 'completed', 37, 9.0, 'still good', 100, 200, 150, 199)",
        [],
    )
    .unwrap();

    apply(&conn, 2..=i64::MAX);

    let (title, status, watched, score, notes, added, plan_rank): (
        String,
        String,
        i64,
        f64,
        String,
        i64,
        Option<i64>,
    ) = conn
        .query_row(
            "SELECT title_romaji, status, episodes_watched, score, notes, added_at, plan_rank
             FROM anime_list WHERE anilist_id = 1535",
            [],
            |r| {
                Ok((
                    r.get(0)?,
                    r.get(1)?,
                    r.get(2)?,
                    r.get(3)?,
                    r.get(4)?,
                    r.get(5)?,
                    r.get(6)?,
                ))
            },
        )
        .expect("the v1 row did not survive the upgrade");

    assert_eq!(title, "Death Note");
    assert_eq!(status, "completed");
    assert_eq!(watched, 37);
    assert_eq!(score, 9.0);
    assert_eq!(notes, "still good");
    assert_eq!(added, 100);
    // Never ranked, so the plan queue falls back to date-added. No backfill.
    assert_eq!(plan_rank, None);
}

#[test]
fn the_v10_table_rebuild_copies_columns_into_the_right_places() {
    // Migration 10 rebuilds anime_list with `INSERT ... SELECT *`, which is
    // positional: if the new table declares the post-v1 columns in a different
    // order than the ALTERs added them, every value lands in the wrong column
    // and nothing errors. This is the test that catches that.
    let conn = Connection::open_in_memory().unwrap();
    apply(&conn, 1..=9);

    conn.execute(
        "INSERT INTO anime_list
           (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at,
            has_dub, title_native, franchise_root_id, airing_status,
            episode_duration, rewatch_count, aired_episodes)
         VALUES (21, 'One Piece', 'watching', 1000, 1, 2,
                 1, 'ワンピース', 21, 'RELEASING',
                 24, 3, 1100)",
        [],
    )
    .unwrap();

    apply(&conn, 10..=i64::MAX);

    let (has_dub, native, root, airing, duration, rewatches, aired): (
        i64,
        String,
        i64,
        String,
        i64,
        i64,
        i64,
    ) = conn
        .query_row(
            "SELECT has_dub, title_native, franchise_root_id, airing_status,
                    episode_duration, rewatch_count, aired_episodes
             FROM anime_list WHERE anilist_id = 21",
            [],
            |r| {
                Ok((
                    r.get(0)?,
                    r.get(1)?,
                    r.get(2)?,
                    r.get(3)?,
                    r.get(4)?,
                    r.get(5)?,
                    r.get(6)?,
                ))
            },
        )
        .unwrap();

    assert_eq!(has_dub, 1);
    assert_eq!(native, "ワンピース");
    assert_eq!(root, 21);
    assert_eq!(airing, "RELEASING");
    assert_eq!(duration, 24);
    assert_eq!(rewatches, 3);
    assert_eq!(aired, 1100);
}

#[test]
fn the_v8_notifications_rebuild_keeps_existing_alerts() {
    let conn = Connection::open_in_memory().unwrap();
    apply(&conn, 1..=7);

    conn.execute(
        "INSERT INTO notifications
           (source_id, related_id, type, related_title, related_status, created_at)
         VALUES (1, 2, 'sequel', 'Season 2', 'RELEASING', 500)",
        [],
    )
    .unwrap();

    apply(&conn, 8..=i64::MAX);

    assert_eq!(count(&conn, "SELECT COUNT(*) FROM notifications"), 1);
    // And the new alert type the rebuild was for now inserts.
    conn.execute(
        "INSERT INTO notifications
           (source_id, related_id, type, related_title, related_status, created_at)
         VALUES (1, 3, 'started_airing', 'Now airing', 'RELEASING', 600)",
        [],
    )
    .expect("started_airing must be accepted after v8");
}

#[test]
fn the_plan_queue_rank_is_writable_and_survives() {
    // Migration 11 has never run against real SQLite in the field. This proves
    // the column exists, takes a value, and reads back on both paths.
    for from_v1 in [true, false] {
        let conn = Connection::open_in_memory().unwrap();
        if from_v1 {
            apply(&conn, 1..=1);
            conn.execute(
                "INSERT INTO anime_list (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at)
                 VALUES (5, 'Planned', 'plan_to_watch', 0, 1, 1)",
                [],
            )
            .unwrap();
            apply(&conn, 2..=i64::MAX);
        } else {
            apply(&conn, 1..=i64::MAX);
            conn.execute(
                "INSERT INTO anime_list (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at)
                 VALUES (5, 'Planned', 'plan_to_watch', 0, 1, 1)",
                [],
            )
            .unwrap();
        }

        conn.execute("UPDATE anime_list SET plan_rank = 3 WHERE anilist_id = 5", [])
            .expect("plan_rank must be writable");
        let rank: Option<i64> = conn
            .query_row("SELECT plan_rank FROM anime_list WHERE anilist_id = 5", [], |r| {
                r.get(0)
            })
            .unwrap();
        assert_eq!(rank, Some(3), "fresh install: {}", !from_v1);
    }
}

// ---------------------------------------------------------------------------
// The completion log (v12)
// ---------------------------------------------------------------------------

#[test]
fn the_completion_log_backfills_one_row_per_finished_watch() {
    let conn = Connection::open_in_memory().unwrap();
    apply(&conn, 1..=11);

    // Finished once. Two rewatches on top of that. Currently rewatching (so the
    // run in progress has NOT been finished yet). Never finished at all.
    conn.execute_batch(
        "INSERT INTO anime_list
           (anilist_id, title_romaji, status, episodes_watched, added_at, updated_at,
            completed_at, total_episodes, rewatch_count, episode_duration)
         VALUES
           (1, 'Once',      'completed',     12, 1, 2, 500, 12, 0, 24),
           (2, 'Thrice',    'completed',     24, 1, 2, 600, 24, 2, 23),
           (3, 'Mid-again', 'rewatching',     3, 1, 2, 700, 13, 1, 24),
           (4, 'Watching',  'watching',       5, 1, 2, NULL, 12, 0, 24);",
    )
    .unwrap();

    apply(&conn, 12..=i64::MAX);

    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log WHERE anilist_id = 1"), 1);
    // One first watch plus the two rewatches it counted.
    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log WHERE anilist_id = 2"), 3);
    // Rewatching: only the finished prior run is an event; the current one isn't.
    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log WHERE anilist_id = 3"), 1);
    // Never finished, so it has no place in the ledger.
    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log WHERE anilist_id = 4"), 0);

    // Indices are 0..n, so "x2" on the timeline means the second watch.
    let indices: Vec<i64> = {
        let mut stmt = conn
            .prepare("SELECT rewatch_index FROM completion_log WHERE anilist_id = 2 ORDER BY rewatch_index")
            .unwrap();
        let rows = stmt.query_map([], |r| r.get(0)).unwrap();
        rows.map(|r| r.unwrap()).collect()
    };
    assert_eq!(indices, vec![0, 1, 2]);

    // The snapshot is what lets a removed entry still render on the timeline.
    let (title, at, eps, estimated): (String, i64, i64, i64) = conn
        .query_row(
            "SELECT title_romaji, completed_at, episodes_at_completion, estimated
             FROM completion_log WHERE anilist_id = 1",
            [],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
        )
        .unwrap();
    assert_eq!(title, "Once");
    assert_eq!(at, 500);
    assert_eq!(eps, 12);
    assert_eq!(estimated, 1, "backfilled dates are reconstructed, not recorded");
}

#[test]
fn a_completion_row_outlives_the_entry_it_came_from() {
    let conn = fresh();
    conn.execute(
        "INSERT INTO completion_log
           (anilist_id, rewatch_index, completed_at, episodes_at_completion, title_romaji)
         VALUES (99, 0, 1000, 12, 'Gone')",
        [],
    )
    .unwrap();
    conn.execute("DELETE FROM anime_list WHERE anilist_id = 99", []).unwrap();
    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log"), 1);
}

#[test]
fn the_same_completion_event_cannot_land_twice() {
    // The union merge replays rows from other devices. The Nth completion of a
    // title is one event, so a repeat has to collapse rather than double-count.
    let conn = fresh();
    let insert = || {
        conn.execute(
            "INSERT OR IGNORE INTO completion_log
               (anilist_id, rewatch_index, completed_at, episodes_at_completion, title_romaji)
             VALUES (7, 1, 1000, 12, 'Twice')",
            [],
        )
    };
    insert().unwrap();
    insert().unwrap();
    assert_eq!(count(&conn, "SELECT COUNT(*) FROM completion_log"), 1);
}

#[test]
fn upgrading_is_stepwise_from_every_starting_version() {
    // Someone can be on any released version, so every partial-then-finish path
    // has to work, not just v1 → newest.
    let latest = migrations().last().unwrap().version as i64;
    for start in 1..=latest {
        let conn = Connection::open_in_memory().unwrap();
        apply(&conn, 1..=start);
        apply(&conn, (start + 1)..=i64::MAX);
        assert!(
            columns(&conn, "anime_list").contains(&"plan_rank".to_string()),
            "upgrading from v{start} did not reach the newest schema"
        );
    }
}
