# Open

## Must not change
People already use the app. These keep their updates and their data working.

- App identifier: `com.konsou.app`
- Database file: `konsou.db` (SQLite, in the same app data folder)
- Updater endpoint: `https://github.com/ashenvii/Konsou/releases/latest/download/latest.json`
- Updater signing key: the `TAURI_SIGNING_PRIVATE_KEY` secret and the public key in `tauri.conf.json` are a pair. A new key means old installs can never update.
- Public pages: `docs/privacy.html` and `docs/terms.html` are served by GitHub Pages and linked from Google sign-in.
- Drive backup location and Google sign-in scope, so old backups can still be found.

## Undecided
- Search over the entries: is SQLite full-text search (FTS5) enough, or do we need a separate index.
- Existing data: upgrade the database in place, import from a backup, or both. The decision is to support both, the design comes with the new schema.
- Does the new app keep writing backups in the old format so a user can go back.
- Android in the first release or later.

## Local only (git ignores these)
- `.env`
- `legacy/src-tauri/gen/android/keystore.properties`
