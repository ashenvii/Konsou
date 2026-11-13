# Product

Konsou is an offline-first anime tracker. This file is the short entry point that Impeccable reads. The full record stays where it already lives: words in `GLOSSARY.md`, decisions in `notes/DECISIONS.md`, the plan in `notes/PLAN.md`. Nothing here may contradict them.

## Platform

adaptive: Windows desktop and Android, one Flutter codebase. Desktop is built first and perfected; Android gets its own layer on top and never limits desktop.

## Stack

Flutter and Dart, Riverpod, go_router, two SQLite files (`konsou.db` for the user's record, `details.db` for fetched facts). Tokens live in `lib/design/tokens.dart` and are mirrored in `notes/design/tokens.md`. `.\check` is the gate.

## Users

One person tracking their own list of anime, often a long one (hundreds to thousands of entries), on a desktop at a desk and on a phone in bed. They use it daily in short sessions and they care about their record more than the app.

## Product Purpose

Own your record: the list is the user's, kept locally, backed up to their own Drive, and survives the provider disappearing. Know what to watch next: sequels, seasons and watch order are surfaced so a finished show points at the next one.

## Positioning

A calm, fast, local tool, not a social network and not a storefront. Titles, covers and scores come from MyAnimeList, with credit, and nothing sits behind a payment.

## Operating Context

Operate mode. The user is completing small tasks (change a status, add an episode, find a title) and scanning long lists. Scanability, consistency and keyboard speed outrank expression. Windows has its own title bar and window controls; Android keeps the system bars.

## Capabilities and Constraints

- Offline first. Every screen works with no network; fetches trickle in behind it.
- MAL API only, 0.5 s between requests.
- Windows and Android only. No telemetry, no system notifications in v1.
- Old installs keep their app id, updater key and data (see `notes/OPEN.md`, "Must not change").

## Brand Commitments

- The Nekomimi is a logo and mascot, not an icon. It keeps its own painting and must not be redrawn by an icon pass.
- Square corners, one flat dark ground, amber for the chosen thing, mint for live things. The owner's approved screenshots in `notes/design/` are the visual source.

## Evidence on Hand

Screenshots of the previous app in `notes/design/`, the old code in `legacy/` (read only), rendered screens in `shots/`.

## Product Principles

- The record outlives the app. Never write anything that could cost the user their list.
- Quiet by default. Color is rare and means something; motion shows state, nothing else.
- Desktop speed: every common action has a key, and keys are user-changeable.
- A second hand-built copy of a visual device is a bug. Build once, reuse everywhere.

## Accessibility & Inclusion

- Nothing carries meaning by color alone. Every status or state has a shape, text or position cue too.
- Text 4.5:1 or better on its own fill. Muted ink is for text on the ground only until it is lifted.
- Touch targets at least 48 by 48 on Android, with a visible focus ring everywhere.
- Text follows the system font scale without clipping.
- Reduce motion is honored: state still changes, the animation does not.
- An accessibility mode (other looks for people who cannot see the app's colors, offered at first start) is planned and not designed yet. See `notes/OPEN.md`.
