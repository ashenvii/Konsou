# Cross-Platform Parity and Fix Log

This is the working source of truth for the round of changes, fixes, and open bugs recorded on 2026-07-09. It exists for two jobs:

1. Track everything we need to explore and fix in Konsou across mobile and desktop.
2. Serve as a reusable double-check for any future app. Most of these are not Konsou-specific bugs, they are the traps that show up whenever one codebase has to behave correctly on both a phone and a desktop. When I build a different app later, I run down the "General rule" lines here and confirm each one holds.

Each item below has three parts:
- **Problem** what is actually wrong today.
- **Target** what it should do instead.
- **General rule** the portable lesson, phrased so it applies to any app.

Status legend: `open` (not started), `wip` (in progress), `done` (shipped and verified).

---

## 1. Mobile navigation and the back gesture

### 1.1 Back exits the app instead of going back `wip`
- **Problem** On mobile, when any menu other than the main page of the current tab is open (for example a quick menu reached from a card), pressing back immediately closes the whole app instead of dismissing the menu or returning to the previous view.
- **Target** Back should peel one layer at a time: close the open menu or sheet first, then walk back through the in-app stack, and only exit the app when there is genuinely nothing left to go back to on the root tab.
- **General rule** The hardware/system back button must be wired into the app's own navigation stack, not left to the platform default. Every openable layer (sheet, menu, modal, sub-page) registers itself as a back target. Exiting the app is the last resort, never the first response.

**Diagnosis + fix (2026-07-09).** The JS back policy in `hooks/useAppBack.ts` was already correct (sheet → tab stack → double-tap exit) and sheets already register via `lib/sheetStack`. The break was native: Tauri's `WryActivity` handles Android back itself — `if (mWebView.canGoBack()) goBack() else finish()` — and our router deliberately pins webview history to one entry (`lib/navStacks`, every navigate is `replace:true`), so `canGoBack()` is always false and every press hit `finish()` and exited. The `tauri://back` event we were listening for is never emitted by this Tauri version, so JS never ran. Fixed by overriding `MainActivity.kt`: `handleBackNavigation = false` to drop Tauri's default, plus an `OnBackPressedCallback` that forwards every press into `window.__konsouBack()`, which `useAppBack` now points at `goBack()`. Verified the JS half end-to-end in the web preview by calling `window.__konsouBack()` (exactly what the native handler runs): closes an open sheet, else pops one sub-page, else arms the exit toast. **Confirmed on-device 2026-07-10:** hardware back (`KEYCODE_BACK`) reliably closes an open sheet without exiting the app.

### 1.2 Menus need an overscroll-to-close, not just a grab handle `wip`
- **Problem** A sheet/menu (quick menu type) can only be swiped down to close if the swipe starts on the drag handle at the top ("invisible tab"). Once the menu's own content is scrolled to the very top and cannot scroll up any further, a continued downward swipe does nothing, when it should hand off to closing the sheet.
- **Target** When the menu content is already at the top and the user keeps pulling down, that overscroll should behave exactly like pulling the top grab handle and dismiss the menu. The pull distance needed to trigger the close is a threshold we tune until it feels natural, not too twitchy, not too stubborn.
- **General rule** Bottom sheets close two ways that feel like one: drag the handle, or overscroll past the top of the content. Wire the content scroll's "at top and still pulling" state into the same dismiss logic as the handle. Keep the close threshold a single tunable value.

**Touch rework (2026-07-10).** The first attempt (pointer events) worked with a mouse but NOT on the phone: on real touch, Android hands a downward body drag to the native scroller and cancels the pointer stream before the engage check runs, so it never triggered (the handle works only because it has `touch-action: none`). Reworked to native `touchstart/touchmove/touchend` listeners attached via `useEffect` with `{ passive: false }` — React's own touch handlers are passive, where `preventDefault()` is a no-op. Once the body is at `scrollTop <= 0` and the finger passes the slop, the move handler calls `preventDefault()` to take the gesture from the scroller and drives the same settle path. Thresholds loosened for feel: `PULL_ENGAGE_SLOP` 8→6, `CLOSE_FRACTION` 0.35→0.3, `FLICK_VELOCITY` 0.6→0.55. Verified in preview with synthetic TouchEvents: pull tracks + closes with every touchmove preventDefault'd, a tap and a sub-slop jiggle do not close, handle drag still closes. **Confirmed on-device 2026-07-10:** an `adb input swipe` down on the sheet body (not the handle) closes it. **Portable rule:** pull-to-dismiss from inside a scroll view must use non-passive native touch listeners + preventDefault; React touch handlers and pointer events both fail because the browser claims the scroll first.

**Superseded first attempt (2026-07-09).** `components/ui/BottomSheet.tsx`: pulled the drag-start out into a shared `beginDrag`, then added pointer handlers on the scroll body. They watch for a candidate gesture and engage a real sheet drag only when the body is already at `scrollTop <= 0` and the finger has moved down past `PULL_ENGAGE_SLOP` (8px); otherwise the gesture stays a normal scroll, or is abandoned if the user pulls up. Once engaged it reuses the exact same track/settle path as the handle, so the close threshold stays the single existing tunable (`CLOSE_FRACTION = 0.35` of sheet height, or a flick past `FLICK_VELOCITY`). Desktop (>=1024px, centered dialog, no handle) opts out. Added `overscroll-behavior: contain` on the body so an over-pull never chains to the page behind. Verified in the mobile preview: a downward drag started inside the body (not the handle) tracks the sheet and closes it; at desktop width the same pull does nothing and the sheet stays open; the original handle drag still closes (no regression). Tunable to revisit for on-device feel: `PULL_ENGAGE_SLOP` and `CLOSE_FRACTION`.

### 1.3 Back inside Settings closes the app `wip`
- **Problem** Tapping or swiping back to leave Settings, or to move between Settings sub-pages, closes the entire app instead of returning to the previous page.
- **Target** Back inside Settings navigates Settings' own history: sub-page to Settings root, then Settings root back to wherever Settings was opened from. Never a full app exit.
- **General rule** Any section with internal navigation (Settings, a wizard, a multi-step flow) owns its own back stack that plugs into the global one. Related to 1.1: this is the same wiring, applied to a nested section.

**Fix (2026-07-09).** Same root cause and same fix as 1.1 — this was never a Settings-specific bug, just the native back handler exiting the app before JS ran. With the `MainActivity.kt` forward in place, verified in preview that back steps appearance → settings → tab root one level at a time, then arms the exit toast at the root. Confirm on-device with the APK.

---

## 2. Settings experience

### 2.1 Settings should feel like a separate mode `done`
- **Problem** Opening Settings does not feel exclusive. The main app navigation still shows, so it feels like just another page rather than a distinct place.
- **Target** Settings should feel like stepping backstage, into the back end or the hardware. Main navigation is hidden while in Settings, so the mode is unmistakable.
- **General rule** "Settings" is a mode, not a page. When you enter it, drop the primary app chrome (tab bar, nav) so the user knows they have left the main surface and entered configuration.

**Fix (2026-07-09).** `AppShell.tsx` gains an `isBackstage` flag (any `/settings` route), following the existing `isImmersive` pattern the detail page uses. Backstage suppresses the Sidebar (desktop), TopBar and BottomNav (mobile), and stamps `k-shell--backstage` on the shell. On desktop the content column, which used to anchor against the sidebar, becomes a centered 768px column (`layout.css`), so settings reads as one focused surface instead of a page hugging the edge where the sidebar was. The way out is the pages' own back arrow or hardware back, both of which run the same `goBack()` policy from 1.1. Verified in preview at both breakpoints: chrome gone inside settings and sub-pages, restored on exit, content centered on desktop, no console errors.

### 2.2 Appearance page rebuilt for mobile `done`
- **Problem** The Appearance page is squished on mobile, hard to navigate and tap compared with the rest of the app, and text is bundled tightly to the left.
- **Target** Rebuild it to read on mobile as cleanly as it does on desktop: proper spacing, tap targets that match the rest of the app, text that breathes instead of crushing to the left edge.
- **General rule** Every settings sub-page gets the same responsive treatment as the main app. A settings screen is not exempt from touch-target sizing, padding, and layout rules just because it is "just settings."

**Fix (2026-07-09).** Root cause: `.k-settings__row` is a side-by-side flex (label left, control right), and wide controls (three-button segmented pickers, six accent swatches) crushed the label into a narrow left column on a 375px screen, with ~26px-tall buttons and 28px swatches well under thumb size. Fix: `Row` in `components/settings/parts.tsx` gains a `stack` prop; on mobile (`max-width: 1023px`) stacked rows go column with the label on top and the control full-width, segmented buttons stretch to `flex:1` at 42px min-height, swatches grow to 38px and spread evenly, and the four theme cards become an even 4-up grid with fluid previews. The Sidebar setting (desktop-only functionality) no longer renders on mobile at all. Desktop keeps the original side-by-side layout untouched. Verified in preview at both widths: no horizontal overflow, targets measured at 42px/38px, desktop reverts to inline rows with the Sidebar row present.

**Portable addition.** When a settings row holds a wide control, side-by-side label+control does not survive a phone width; design rows to stack. And never show a setting on a platform where its feature does not exist.

### 2.3 About page needs real content and a personal note `open`
- **Problem** The About page is thin.
- **Target** A presentable About section that includes why I made this app, followed by something more personal from me. Exact wording to be drafted with my input; creative adjustment of my words is fine.
- **General rule** An About page is a chance for voice, not boilerplate. Reserve room for a genuine "why this exists" statement. (Open input needed from me: the personal blurb. Draft together before building.)

### 2.4 Check for updates, reworked `wip`
- **Problem** Update handling is desktop-only via version detection. Mobile has no update awareness. The changelog is not surfaced in the app.
- **Target**
  - **Desktop** keep detecting new versions the way it does now.
  - **Mobile** add an equivalent detection that tells the user an update is available. It does not need to auto-update yet, just notify.
  - **Changelog in-app** pull the changelog (reading the file straight from GitHub or similar) and present the version log, changes, fixes, and additions. Presentable and neat, clear for the user, rendering only the most recent entry with an option to load more of the document.
  - **Update popup** when the version updates, show a new menu/popup that lists what changed, was fixed, or was added. Really presentable. It uses a hold-to-confirm interaction on both mobile and desktop.
- **General rule** Update flow is three separable pieces: detection (per platform), a human-readable changelog surface fed from a single source of truth, and a confirm-on-update dialog. Notify-only is a valid first stage before auto-update. Hold-to-confirm is the deliberate-action pattern for the "I have read what changed" acknowledgement, used identically on both platforms.

**Built (2026-07-09).** All four pieces are in:
- **Source of truth** `lib/changelog.ts` parses the Keep-a-Changelog format. The file ships inside the bundle (`CHANGELOG.md?raw` import), so the popup and version history work offline and always match the installed build exactly. `fetchRemoteChangelog()` exists for reading notes newer than the build (falls back to the bundle); this was a deliberate deviation from "read the file on GitHub", bundling is strictly more reliable for the shipped version's own notes.
- **Mobile detection** Android has no updater plugin, but the desktop updater's own manifest (`latest.json` on the latest GitHub release) is a static file with the version in it, so mobile fetches that same single source and compares (`updater.ts`, now returns `install` on desktop / `notify` on Android). Boot and the About page both show a "vX is available → View" toast linking to the release. No auto-update yet, exactly per spec.
- **What's New popup** `components/WhatsNew.tsx` + `konsou.last_seen_version` in localStorage: first launch after a version change shows that version's notes in a sheet; first-ever install records silently and shows nothing. Acknowledged with hold-to-confirm; version marker only advances on confirm.
- **Hold-to-confirm** `components/ui/HoldButton.tsx`: 650ms press with a linear fill sweep, identical semantics for mouse press, finger, or held Enter/Space (desktop and mobile function the same, only the input adapts). Fill transition is excepted from the global reduced-motion kill in `global.css` because it is progress feedback, not decoration; without the exception the button reads "done" 650ms early on machines with animation effects off.
- **About page history** renders the newest entry expanded with "Show older versions" revealing 3 more per tap.

Verified in preview: simulated update (seen=0.6.0, running 0.7.0) fires the popup with all three section chips; early release keeps it open and unmarks nothing; full hold closes it, advances the marker, and it never re-shows; About history pages correctly. Outstanding: the Android `latest.json` fetch + notify toast needs an on-device run (web preview can't exercise `isTauri`).

---

## 3. Iconography

### 3.1 Confirm the icon system is unified `done`
- **Problem** Need to confirm what icon set the app actually uses everywhere.
- **Target** Verify it is Lucide (per prior migration off Phosphor) and that it is used consistently across the app body, settings, and navigation with nothing left on the old set.
- **General rule** One icon library, no mixing. Audit periodically that no stragglers from a previous set survived a migration.

**Audited (2026-07-10).** Lucide is the only icon library: 31 files import `lucide-react`, zero Phosphor remnants anywhere (source or package.json), no other icon packages, no stray inline `<svg>` icons in components. Settings, navigation, and app body all included in the sweep.

---

## 4. Library and Sync

### 4.1 Import wording is misleading `done`
- **Problem** The Import section wording talks only about AniList, but the app can import from any compatible list type (for example MAL) and convert it in. The current description misleads users about what is supported.
- **Target** Reword so it reflects importing from any compatible source and converting into the app. Also review whether we are missing any settings that would help on this page.
- **General rule** Feature copy must match actual capability. If the engine supports N sources, do not let the copy name only one. When touching a page, ask "what obvious setting is missing here."

**Fix (2026-07-10).** The ImportSheet itself already had AniList + MyAnimeList tabs; only the entry points lied. Library & Sync row is now "Import list — From an AniList username or a MyAnimeList export; merges into what's here", and the My List empty state reads "Coming from AniList or MyAnimeList?". Missing-setting review found a real gap: Export produced a JSON no one could load back. Added "Restore backup" to Library & Sync — picks a Konsou JSON export, validates the shape, and merges through the same `importEntries` path as every other import (progress never clobbered).

---

## 5. Episode tracking

### 5.1 Fast episode entry for very long series `wip`
- **Problem** Setting the current episode on a long series (One Piece, 1000+ episodes) means tapping the increment roughly 700 times. Absurd.
- **Target** A quick way to jump straight to an episode number for long series instead of incrementing one at a time.
- **General rule** Any counter that can legitimately reach into the hundreds or thousands needs a direct-entry path, not increment-only. Design the control for the largest real value, not the typical one.

**Built (2026-07-10).** `EpisodeCounter.tsx`: the number itself is now a button (dashed underline as the affordance). Tap → inline numeric input (`inputMode="numeric"` brings the phone keypad), preselected; Enter or blur commits, Escape cancels; the value clamps to 0..total (unknown total only bounds at zero) and routes through `setEpisodes`, so the centralized complete-at-max prompt still fires. Identical with mouse or touch. Needs a visual pass + on-device feel check (preview pane was down when built; typecheck/lint green).

---

## 6. Desktop install vs dev build (data/auth breakage)

### 6.1 Installed build signs out and only Discovery works `wip`
- **Problem** The desktop app works fully in dev mode, but the actual installed build (especially after installing a newer version) signs the user out. After signing back in, only Discovery works. My List, Alerts, and everything else are empty, and nothing can be added.
- **Target** The installed, production build must behave like dev: session persists across updates, the list/alerts data loads, and adds work.
- **General rule** This is the classic dev-vs-packaged divergence. Suspects to check on any Tauri/desktop app: identifier or data-directory differences between dev and packaged builds (so the DB/appdata path moves and looks "empty"), token/secret storage that only resolves in dev, updater swapping the app identity between versions, and env/config that is present in dev but missing in the bundle. Verify the packaged build reads and writes the same data location across versions before shipping any release.

**Diagnosis (2026-07-09).** Ruled out the installer and permissions: `installer.nsi` is the stock Tauri template with its appdata wipe correctly guarded behind `$UpdateMode <> 1` plus an opt-in checkbox, and `capabilities/default.json` grants all the `sql:*` permissions. The real mechanism is in `src/main.tsx bootstrap()`: `await getDb()` was the first statement in a single try/catch, and `useAuthStore.restore()` ran *after* it. So one `Database.load("sqlite:konsou.db")` failure did three things at once: auth never restored (looks **signed out**), the list/notification stores never hydrated (**empty list and alerts**), and every later `addFromSummary` re-hit the failing `getDb()` (**nothing can be added**). Discover survived because it is pure react-query against AniList and never touches the DB. "Dev works" because `npm run dev` runs the web shim (`isTauri()` is false), so the real SQLite driver is only ever exercised once the app is installed. The old catch swallowed the error, so nothing was visible.

**What was fixed.** Reordered `bootstrap()` so auth restore runs first and on its own guard (a storage failure can no longer fake a sign-out), isolated `getDb()` in its own try/catch, and stopped swallowing the error. Added `src/lib/store/storageStore.ts` + `src/components/ui/StorageBanner.tsx` (wired into `AppShell`): on a DB-open failure a fatal banner now shows the real error with a copy button, instead of the app silently degrading to a Discover-only shell.

**Still needed (needs a packaged build to capture).** The above makes the failure legible and keeps the user signed in, but does not yet explain *why* `Database.load` fails on the installed build. Next step: build + install once, reproduce, and read the banner's copied error. That error names the true root cause (most likely a migration failing over an existing older DB, or an appdata path/permission issue) which we then fix directly. Cannot be reproduced in the web preview.

---

## 7. Anime info / detail page

### 7.1 Similar tab ignores title-language preference `done`
- **Problem** On the Similar tab, titles fall back to the anime's own native language name instead of the user's preferred title language.
- **Target** Similar respects the user's title-language preference like the rest of the app.
- **General rule** Title-language preference is global. Every surface that renders a title routes through the same preference resolver. No surface gets to fall back to raw native title on its own.

**Fix (2026-07-10).** `preferredTitle(title)` silently defaults to romaji when the preference argument is omitted, and `RecommendationsRow` (the Similar tab) omitted it. Swept every `preferredTitle(` call site in the app for the same omission and found three more: the sequel detector (alert titles are snapshotted at scan time — now reads the preference at snapshot), and two removal/completion toasts in `listStore` (also missing the `native` field entirely). All four now pass the user's preference. Everything else already complied.

### 7.2 Cast shows sub only, and titles overlap on mobile `wip`
- **Problem** The cast section only shows the sub cast, never the dub cast. On mobile the "titles" for people and characters overlap each other when long and become unreadable.
- **Target** Allow switching between sub and dub cast, or simply show both. Redesign the section on mobile so long names/roles never overlap and stay readable.
- **General rule** If data has multiple facets (sub vs dub), expose all of them. For any list of paired labels (name + role), the mobile layout must handle the longest realistic strings without collision.

**Built (2026-07-10).** Went with "show both" (no switching state to manage, works identically on both platforms). The detail query now fetches `dubActors: voiceActors(language: ENGLISH)` alongside the Japanese cast; each character card lists both, tagged with small JP/EN chips — and the JP tag only appears when the title actually has a dub somewhere, so all-sub shows don't get pointless labels. Old cached payloads simply lack the field until their 24h TTL refreshes. Overlap fix: the collision was long unbreakable romanized names painting over the neighboring card — cards widened 84→92px, `overflow: hidden` on the card, `overflow-wrap: anywhere` on all card text, and VA lines ellipsize (full name in the tooltip). The same hardening covers the Staff row (shared class). Needs on-device visual pass.

### 7.3 Info page alignment and button-boundary bugs on mobile `wip`
- **Problem** On any anime info page on mobile, details are misaligned. "Copy Title" visually overflows outside its button boundary. Information is repeated (episode count appears both in the header/title and again in the Release section). Lower details are too far down, requiring browsing through the release squares to reach other info.
- **Target** Fix alignment. Keep label text inside button bounds. Merge already-shown info so nothing is said twice (fold episode count into the header, and reconcile it with the Release section). Bring the lower details closer to view so the page presents its info easily without hunting.
- **General rule** No text escapes its container. Say each fact once. Order the page so the most-wanted details are reachable without scrolling past decorative blocks.

**Built (2026-07-10).** Copy-title overflow fixed under 7.6 (nowrap + whole-button wrapping). Say-it-once: the facts grid dropped Status, Episodes, Season, and Studio — all four already live in the hero (meta line + status row) — leaving Next episode (accented), MAL score, First aired, Episode length, and Source; renamed "Release" → "Details" to match. With four squares gone and the reorder (7.4), the lower page content sits far closer to view. Residual alignment nits need the on-device pass.

### 7.4 Reorganize the info page by importance `wip`
- **Problem** The info page order does not follow importance.
- **Target** Reorganize like movie apps and trackers do, in order of importance, closer to a wiki layout.
- **General rule** Detail/info pages are ranked, not arbitrary. Lead with identity and the most-checked facts, then progressively less-critical sections, wiki-style.

**Built (2026-07-10).** Overview order was facts-grid → synopsis → genres → trailer → availability; the grid opened the page and pushed what readers actually came for below the fold. New order: **genres** (identity chips, one line) → **synopsis** (the most-read block, 3-line clamp with Show more) → **Details** (the slimmed grid from 7.3, Next-episode fact stays accented at its head) → **Availability** (where to watch — high value in a tracker) → **Trailer**. Cast/Related/Similar tabs unchanged. Needs on-device eyes.

### 7.5 Missing cover/background images (edge case) `wip`
- **Problem** Some anime, even popular ones, have no background image on mobile, and some cards show "No image" because there is no cover photo.
- **Target** Handle the missing-image case gracefully instead of a bare "No image."
- **General rule** Every remote image is an edge case. Design the no-image and no-background fallbacks as first-class states (placeholder art, color from palette, graceful text), not an afterthought.

**Fix (2026-07-10).** Two separate causes. (1) The "No image" card text was never ours — AniList's CDN serves a literal grey "No Image" JPEG (`…/default.jpg`) for missing covers, which sailed straight through `getCoverUrl` and covered up our designed fallback tile (title initial on a deterministic per-title hue). `getCoverUrl` now filters default-placeholder URLs to null so the designed tile always renders. (2) The detail hero was empty when `bannerImage` is null (common on AniList). New fallback chain: banner art → the cover blurred and scaled into an ambient backdrop → a gradient in the title's own identity hue (the same hue the cover tile uses). On `perf-lite` (Android) the blur is swapped for a plain dimmed cover per the established convention, since the banner layer moves with the parallax scroll. Needs a visual pass on device.

### 7.6 Copy Title and Google buttons feel off-theme `wip`
- **Problem** The "Copy Title" and "Google" actions feel out of place against the app theme.
- **Target** Either blend them into the page as native-feeling functions or restyle them to fit the theme.
- **General rule** Utility actions still obey the design system. Nothing reads as a raw default control dropped onto a themed page.

**Fix (2026-07-10).** Restyled as deliberately quiet utility chips: transparent background, hairline border, tertiary text (brightening on press), same pill language as the SUB/DUB badge beside them — conveniences, not actions the hero should be selling. Also fixed the 7.3 overflow here: labels get `white-space: nowrap` + `flex: none` and the row wraps whole buttons to the next line, so "Copy title" can never spill out of its 28px pill in the narrow hero column. Needs the on-device visual pass.

---

## 8. Cards

### 8.1 Redundant arrow/stack affordance on cards `wip`
- **Problem** Cards in grid view (and elsewhere) show an arrow/stack icon that serves no purpose: there is already a stack icon indicating seasons, and it is obvious a card is tappable, so the arrow adds nothing.
- **Target** Clean up the card. Remove the redundant affordance. Maximize function while reducing clutter, keeping the card as clean as possible without losing prettiness.
- **Approach** Use `/distill` on the cards to decide how to use the space for a maximally clean look while staying pretty. Use `/layout` (which pulls in `/adapt` as a side effect) to check the composition.
- **General rule** Do not draw an affordance for something the user already knows. Remove decoration that repeats information already shown. Every element on a card earns its place or leaves.

**Distilled (2026-07-10).** Ran the /distill pass element-by-element against the card's one job (recognize + read standing + tap). Removed: the FranchiseCard grid corner button (Layers/Chevron — it called `onOpen(rootId)`, byte-for-byte the card's own tap, and the top-left badge already marks the franchise with the same icon), the FranchiseCard list-row chevron (same duplication), and the list row's "N done" caption (the season bar segments already draw completion; chip + caption + bar said it three times). Kept deliberately: AnimeCard's `+1`/`+` quick button (a *different* action from tapping — increment/add vs open) and every information element (status marker, EP count, score, dub tag, season bar). Layout check: the grid button was absolutely positioned (no reflow) and rows are flex (meta column now ends the row cleanly). Orphaned CSS removed (`k-card__quick--sheet` + its perf-lite override). Verified structurally in preview DOM: zero corner buttons/chevrons across 8 rendered cards, +1 path untouched. Visual polish check on device.

---

## 9. Whole-app passes

### 9.1 Optimize the entire app `open`
- **Approach** Run `/optimize` across the app: loading speed, rendering, animations, images, bundle size.
- **General rule** Schedule periodic whole-app performance passes, not just per-feature tuning.

### 9.2 Harden where needed `open`
- **Approach** Run `/harden` on the parts of the app that need it.
- **General rule** Security and robustness get a deliberate pass, targeted at the surfaces that actually handle input, auth, and external data.

---

## 10. Auth

### 10.1 Infinite login when the user backs out of the browser `wip`
- **Problem** If you tap Sign In and then immediately back out of the browser before completing, the app gets stuck in a perpetual "logging in" state because it never notices the user abandoned the sign-in.
- **Target** Detect that the browser/sign-in flow was dismissed or abandoned and reset back to a clean signed-out state so the user can try again.

**Built (2026-07-10), three layers in `googleAuth.ts` + `authStore.ts`:**
1. **Abandon detection (Android).** Opening the consent browser hides the webview; backing out makes it visible again. Visible-after-hidden with no callback inside a 3s grace = abandoned → the flow rejects with `AuthCancelledError` and the UI resets with a quiet "Sign-in cancelled" toast (not an error). Desktop never goes `hidden` when a browser window opens, so the path stays dormant there by construction.
2. **Manual cancel (both platforms).** The Connect button flips to "Cancel" while waiting instead of sitting disabled — `cancelGoogleOAuth()` rejects the pending flow. Wired in Account settings and Onboarding.
3. **Shorter ceiling.** Blanket timeout 5min → 2min, and the Tauri `oauth-callback` listener is now released when a flow ends instead of leaking into the next one.
Needs on-device confirmation of the visibility path (depends on the Android webview lifecycle).
- **General rule** Every externally-handed-off flow (OAuth in a browser, a system picker, a share sheet) needs a cancel/abandon path. On returning to the app without a completion signal, time out or detect the dismissal and reset state. Never leave a spinner that can only be escaped by killing the app.

**Related finding (2026-07-10) — background rate-limit burst stalls foreground.** On-device, opening any anime detail page spun forever (from Discovery too), while search "worked". Diagnosed live over adb: on a **fresh** launch Discover and detail both loaded fine; the stall only appeared **after the app had run a minute** on a **126-item list**. The things that kept working (franchise sheet, the list) are all local DB data, not network. Real root cause: the token bucket starts full (90 tokens) and boot-time franchise grooming (`resolveOrphanRoots` in `listStore.ts` loops EVERY unresolved entry doing a network chain-walk each, uncapped) plus the sequel scan fire a burst of dozens of relation queries in seconds. That trips AniList's burst protection → 429 → the limiter's `backoff()` pauses the whole bucket → the user's own taps stall behind it, appearing as an infinite spinner. Fixes: (1) `rateLimiter.ts` now spaces low-priority (background) grants — `lowMinIntervalMs` 1500ms for AniList (~40/min, well under the 90 cap), foreground stays unspaced/instant (verified: 4 low grants at 0/1515/3025/4526ms, 5 high grants in 1ms); (2) `resolveOrphanRoots` capped to 25 entries/launch, leftovers resolve next launch; (3) safety net: `REQUEST_TIMEOUT_MS = 15s` in `request()` (own AbortController forwarding the caller signal; timeout aborts as `TimeoutError` ≠ `AbortError`, so it retries) + react-query's signal threaded through `getById`, so even a genuine hang can't spin forever. **Portable rules:** a client-side rate limiter must cap background BURST, not just sustained rate (a full bucket = a free burst that trips upstream 429s); background maintenance must be spaced and capped per launch so it never starves foreground; every network request gets a timeout; any `isLoading`-gated screen needs a path to an error state.

---

## 11. My List chrome and scroll behavior (added 2026-07-10)

### 11.1 Scroll-reactive chrome `wip`
- **Problem** The My List top section (brand bar + toolbar + persistent Tonight strip) eats a large slice of a phone screen at all times, and nothing reacts to what the user is doing.
- **Target** The Spotify/Instagram pattern: scrolling down means reading, so non-functional chrome (brand top bar, Tonight strip) folds away and gives content the screen; any real scroll up, or nearing the top, brings it straight back. The functional toolbar (search/filter/sort/view) stays. Bottom nav stays (Instagram keeps its tabs too). Desktop is untouched — it has a sidebar and no space problem.
- **General rule** Chrome earns its pixels by direction: reading (scroll down) sheds it, seeking (scroll up) restores it. Keep the functional row, shed the decorative ones. Each page shows only what its job needs.

**Built (2026-07-10).** `useScrollElevation` (already the app-wide scroll listener) now also tracks direction with hysteresis — hide after 24px of accumulated downward travel past a 48px top zone, show after 12px up or on entering the top zone — and toggles `data-chrome-hidden` on `<html>`. Sheet scrollers are excluded (scrolling an overlay says nothing about the page). Route changes reset to full chrome (AppShell effect). CSS (mobile-only): the top bar slides up by its 52px content height (its safe-area strip stays, so content never collides with the status bar) with contents fading; Tonight collapses via bounded max-height. One cascade trap fixed: pages.css declares `transition: box-shadow` on `.k-tonight` and loads after list.css, so the collapse transitions had to merge into that declaration or be silently dropped. State machine verified end-to-end in preview via synthetic scroll events (hide on down, show on up, top-zone override, elevation intact); the visual side was blocked by a frozen preview renderer and needs the next on-device build to feel.

## 12. Franchise grouping + quick menu overhaul (added 2026-07-11)

### 12.1 Jobless Reincarnation split cards `wip`
- **Problem** Mushoku Tensei showed as split cards on My List, again, after the earlier multi-head fix.
- **Diagnosis (live AniList reproduction).** All 5 TV seasons resolved one root (108465) consistently; the Eris SPECIAL resolved *itself* as a one-member root. Its only franchise link is a **PARENT** edge, which the BFS never followed, and the split-root self-heal's "suspect" test (PREQUEL/OTHER only) could never catch it. Any side entry resolved starting from itself strands as its own card.
- **Fix, four layers.** `isFranchiseParent` in relatedness.ts (PARENT + the same name-gate as OTHER, so branded spin-offs like Prisma Illya still stay separate); the cascade BFS follows it; `findRootId` now prefers **backbone heads** (heads owning a SEQUEL edge in-map) so a pre-S1 special can never out-date S1 into the root slot; the self-heal suspect test and the sequel-radar walk both include it. **Re-verified live: all six MT entries resolve to one root.** Existing split DBs self-heal on next launch.
- **General rule** A franchise walker must traverse every edge type that can be a member's ONLY link (here: PARENT for specials), gated by identity (shared name), and the self-heal must recognize every stranding shape the walker can produce. Test resolvers from EVERY member as the start node, not just the root.

### 12.2 Quick menu (FranchiseSheet) overhaul `wip`
- **Problem** Couldn't tell what's on the list from the sheet; felt broken; visually inconsistent.
- **Diagnosis.** The sheet ran a *second, different* grouping algorithm (SEQUEL-only walk, no OTHER/PARENT gates) — three sources of truth: card grouping, sheet chain, sheet side-list. Tracked vs untracked rows were near-identical. Six chip vocabularies in one row region. A destructive trash button on every row plus an unconfirmed one-tap "Remove whole franchise".
- **Rework (user approved: unified list + no per-row trash).** ONE list in watch order (same `orderForWatching` as the Related tab), S-numbers on the backbone (walked with the same SEQUEL+gated-OTHER edges as the card resolver), kind chips (OVA/Movie/Side story) on side members. Ownership is the loudest signal: tracked rows solid with status wash; untracked rows hollow (dashed, muted) with an explicit "NOT ON YOUR LIST" label and one Add button; the header leads with "X of Y on your list". Per-row trash removed (Remove lives in the row's status sheet); franchise removal is hold-to-confirm (shared HoldButton, danger variant). All prior features preserved: stepper on active rows, score, status pill → StatusSheet, Up next frontier, airing/unaired chips, not-interested dimming, skeletons, offline ledger gating.
- **General rule** A summary surface must derive from the same algorithm as the surface it summarizes — never re-derive with a weaker copy. Ownership/membership is a primary visual dimension, not a chip. Destructive actions never repeat per row.

### 12.4 DanMachi: catch-up asks about future side stories; Related ≠ quick menu `wip`
- **Problem** Adding DanMachi Season 1 prompted "have you also watched…?" for side stories that air AFTER S1 (2016 OVA, Sword Oratoria, Arrow of the Orion). And with only S1 tracked, the quick menu and the Related tab showed different franchises — both wrong, differently.
- **Diagnosis.** Catch-up: `priorSideEntries` included the added entry's OWN side entries (adding S1 → chain empty → it offered S1's sides, all of which come after S1). Surfaces: the quick menu only ever fetched relations for TRACKED ids, so its season walk literally stopped at S2 (S2 untracked → relations undefined) while the Related tab walked all ~13 entries recursively. Three walkers total, all different.
- **Fix.** (1) Catch-up now offers only content attached to the prequel chain (never the added entry's own sides) that finished airing AND started before the added entry — so adding any first season asks nothing, by construction. The feature stays: adding S3 first still offers S1/S2-era content in one tap. (2) One shared member walker: `walkFranchise` in chain.ts, consumed by BOTH the Related tab and the quick menu through the same react-query cache key — they cannot disagree anymore. (3) Presentation per the aniwave reference (user-supplied): one flat list, #1..#N watch-order position on every row, format/kind chips, year.
- **General rule** When two surfaces present the same domain object, they must consume one shared derivation — a summary that re-derives is a bug factory. "Catch-up" style prompts must be provably empty for the first element of any sequence. The full domain contract now lives in docs/FRANCHISE_MODEL.md with a live-API test protocol and canonical fixtures; check every walker change against it.

### 12.3 App-wide visual consistency pass `open`
- **Problem** Inconsistencies across the app are compounding ("the mess is growing").
- **Target** One component vocabulary (chips, pills, buttons, rows), one status-color language, consistent spacing and typography per the design system. The sheet rework established the chip vocabulary; sweep the rest of the app against it.
- **Plan** Run /impeccable audit + polish across pages once the current batch is verified on device; fix by vocabulary consolidation, not per-screen tweaks.

## Portable checklist (the short version for the next app)

When I build a different app that runs on both mobile and desktop, walk this list:

- [ ] Hardware/system back is wired into the app's own stack; it peels one layer at a time and exits only as a last resort. (1.1, 1.3)
- [ ] Every nested section (settings, wizards) owns a back stack that plugs into the global one. (1.3)
- [ ] Bottom sheets close by dragging the handle AND by overscrolling past the top of their content, sharing one tunable threshold. (1.2)
- [ ] Settings (or equivalent config) is a distinct mode that hides primary nav chrome. (2.1)
- [ ] Every settings sub-page follows the same responsive/touch-target rules as the main app. (2.2)
- [ ] Update flow is split into detection (per platform), a human-readable changelog fed from one source, and a hold-to-confirm acknowledgement. Notify-only is a valid first stage. (2.4)
- [ ] One icon library, no mixed sets after a migration. (3.1)
- [ ] Feature copy matches actual capability (do not name one source when N are supported). (4.1)
- [ ] Any counter that can reach the hundreds/thousands has direct entry, not increment-only. (5.1)
- [ ] Packaged/installed build reads and writes the same data location and keeps its session across version updates, verified before every release. (6.1)
- [ ] A single global resolver renders every title/label per user preference; no surface falls back on its own. (7.1)
- [ ] Multi-facet data (sub/dub, variants) is all exposed, and paired labels never collide at the longest realistic length on mobile. (7.2)
- [ ] No text overflows its container; each fact is stated once; most-wanted info is reachable without scrolling past decoration. (7.3, 7.4)
- [ ] Missing-image and missing-background are first-class designed states. (7.5)
- [ ] Utility actions obey the design system; nothing reads as a raw default control. (7.6)
- [ ] Cards carry no affordance that repeats what is already shown or already obvious. (8.1)
- [ ] Whole-app performance and hardening passes are scheduled, not just per-feature. (9.1, 9.2)
- [ ] Every external hand-off flow (OAuth, pickers) has a cancel/abandon path that resets state on return; no unescapable spinners. (10.1)
