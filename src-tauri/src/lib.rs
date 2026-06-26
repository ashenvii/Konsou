use tauri::Emitter;
use tauri_plugin_sql::{Migration, MigrationKind};

// ---------------------------------------------------------------------------
// Database migrations
//
// Migrations are versioned and append-only. NEVER edit an existing migration;
// always add a new one with the next version number. The JS shim used in the
// browser-only dev build mirrors this same schema in src/lib/db/schema.ts.
// ---------------------------------------------------------------------------
const MIGRATION_1_INITIAL: &str = r#"
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
"#;

// ---------------------------------------------------------------------------
// OAuth localhost redirect server
//
// JS calls `oauth_listen`, gets back the port, builds the Google auth URL
// pointing at http://localhost:{port}/callback, then opens the browser.
// The system browser redirects back to that port; Rust captures the request,
// serves a "you can close this tab" page, and emits an `oauth-callback` event
// with the raw callback path (including the ?code=&state= query string).
// ---------------------------------------------------------------------------
#[tauri::command]
async fn oauth_listen(window: tauri::WebviewWindow) -> Result<u16, String> {
    use std::io::{Read, Write};
    use std::net::TcpListener;

    let listener = TcpListener::bind("127.0.0.1:0").map_err(|e| e.to_string())?;
    let port = listener
        .local_addr()
        .map_err(|e| e.to_string())?
        .port();

    // Accept exactly one connection in a background thread so we don't block
    // the Tauri async runtime. The listener is dropped after that one request.
    std::thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = vec![0u8; 8192];
            let n = stream.read(&mut buf).unwrap_or(0);
            let request = String::from_utf8_lossy(&buf[..n]).to_string();

            // Extract the request path from "GET /callback?code=...&state=... HTTP/1.1"
            let path = request
                .lines()
                .next()
                .and_then(|line| line.split_whitespace().nth(1))
                .unwrap_or("")
                .to_string();

            let html = concat!(
                "<!DOCTYPE html><html><head><title>Konsou</title>",
                "<style>",
                "body{font-family:system-ui,sans-serif;text-align:center;",
                "padding:80px 24px;background:#0d0d12;color:#e8e6f0}",
                "h2{color:#a78bfa;margin-bottom:8px}",
                "p{color:#9ca3af;margin:0}",
                "</style></head><body>",
                "<h2>Signed in to Konsou</h2>",
                "<p>You can close this tab and return to the app.</p>",
                "<script>setTimeout(()=>window.close(),800)</script>",
                "</body></html>"
            );
            let _ = write!(
                stream,
                "HTTP/1.1 200 OK\r\n\
                 Content-Type: text/html; charset=utf-8\r\n\
                 Content-Length: {}\r\n\
                 Connection: close\r\n\
                 \r\n\
                 {}",
                html.len(),
                html
            );
            let _ = stream.flush();

            // Emit the raw callback path to the JS layer.
            let _ = window.emit("oauth-callback", path);
        }
    });

    Ok(port)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let migrations = vec![
        Migration {
            version: 1,
            description: "initial schema",
            sql: MIGRATION_1_INITIAL,
            kind: MigrationKind::Up,
        },
        Migration {
            version: 2,
            description: "add has_dub to anime_list",
            sql: "ALTER TABLE anime_list ADD COLUMN has_dub INTEGER;",
            kind: MigrationKind::Up,
        },
        Migration {
            version: 3,
            description: "deletion tombstones for sync",
            sql: r#"
CREATE TABLE IF NOT EXISTS list_tombstones (
  anilist_id INTEGER PRIMARY KEY,
  deleted_at INTEGER NOT NULL
);
"#,
            kind: MigrationKind::Up,
        },
        Migration {
            version: 4,
            description: "add native title to anime_list",
            sql: "ALTER TABLE anime_list ADD COLUMN title_native TEXT;",
            kind: MigrationKind::Up,
        },
        Migration {
            version: 5,
            description: "per-seed sequel scan schedule",
            sql: r#"
CREATE TABLE IF NOT EXISTS scan_schedule (
  anilist_id    INTEGER PRIMARY KEY,
  last_check_at INTEGER NOT NULL,
  next_check_at INTEGER NOT NULL,
  quiet_streak  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_scan_schedule_due ON scan_schedule(next_check_at);
"#,
            kind: MigrationKind::Up,
        },
        Migration {
            version: 6,
            description: "franchise grouping root id",
            sql: r#"
ALTER TABLE anime_list ADD COLUMN franchise_root_id INTEGER;
CREATE INDEX IF NOT EXISTS idx_list_franchise ON anime_list(franchise_root_id);
"#,
            kind: MigrationKind::Up,
        },
        Migration {
            version: 7,
            description: "airing status for status validation and plan-to-watch alerts",
            sql: "ALTER TABLE anime_list ADD COLUMN airing_status TEXT;",
            kind: MigrationKind::Up,
        },
        Migration {
            version: 8,
            description: "started_airing alert type",
            sql: r#"
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
"#,
            kind: MigrationKind::Up,
        },
    ];

    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![oauth_listen])
        .plugin(tauri_plugin_deep_link::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_process::init())
        .plugin(
            tauri_plugin_sql::Builder::default()
                .add_migrations("sqlite:konsou.db", migrations)
                .build(),
        )
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
