# Anjali — Architecture

## Principles

- **Offline-first, no network.** All content ships in the bundle. There is no
  networking layer in the MVP, by design.
- **Deterministic core.** The logic that decides *what to show* is pure and
  unit-tested, separated from SwiftUI.
- **Robust to bad data.** A single malformed prayer must never crash the app.
- **Small surface area.** Three tabs, one card, one player. Complexity is the
  enemy of a sacred pause.

## Layers

```
┌────────────────────────────────────────────────────────┐
│ Views (SwiftUI)                                          │
│   RootView → Onboarding | MainTabView                    │
│   Today / Moments / Me / PrayerPlayer / Completion       │
├────────────────────────────────────────────────────────┤
│ Coordination & State                                     │
│   AppCoordinator (tabs, deep links, player presentation) │
│   AppSettings (UserDefaults-backed preferences)          │
│   PrayerLibrary (in-memory prayer store)                 │
├────────────────────────────────────────────────────────┤
│ Engine (pure, testable)                                  │
│   TodayContextEngine  TimeBandResolver  PrayerDataLoader │
│   DeepLink  NotificationManager                          │
├────────────────────────────────────────────────────────┤
│ Models                                                   │
│   Prayer + PrayerText (Codable, from JSON)               │
│   PrayerCompletion, FavoritePrayer (SwiftData)           │
│   Enums: TimeContext, Moment, Deity, Intention, PlayMode │
├────────────────────────────────────────────────────────┤
│ Data                                                     │
│   Resources/prayers.json (bundled seed content)          │
│   SwiftData store (user-generated state)                 │
└────────────────────────────────────────────────────────┘
```

## Key components

### TimeBandResolver
Pure mapping from a wall-clock time to a `TimeContext`:
- Dawn 04:30–08:00, Morning 08:00–16:30, Sunset 16:30–20:00, Night 20:00–04:30.
- Midday (12:00–16:30) folds into Morning so the day is fully covered with no gap.
- Exposes a `minutesSinceMidnight` entry point for trivial, clock-free testing.

### PrayerDataLoader
Loads `prayers.json`, validating fields. Decodes leniently: a bad element
decodes to `nil` and is skipped rather than aborting the whole file. Throws only
when the resource is missing/unreadable — never for individual records. This is
how acceptance criterion *"invalid content does not crash"* is met.

### TodayContextEngine
The heart of Today. Given a `TodayEngineInput` (prayers, time band, explicit
moment, preferred deity, favourite moments, prayers completed today) it returns
a `TodayContext` (theme, copy, selected prayer, alternates). Pure function — no
clocks, no globals — so every rule is deterministically unit-tested. Scoring and
exclusions are documented in `PRD.md`.

### PrayerLibrary
`@MainActor ObservableObject` holding all loaded prayers, with lookups by id,
moment, and deity, and the set of moments/deities that actually have content.

### AppCoordinator
Single owner of navigation: which tab is selected, which prayer (if any) is in
the full-screen player, and the moment a deep link wants to open. URLs and
notification taps both funnel through `handle(_:)`.

### AppSettings
`UserDefaults`-backed preferences (onboarding flag, script preference, ishta
devata, favourite moments, enabled reminders). Optionals/lists stored as
raw-value strings.

### NotificationManager
Thin wrapper over `UNUserNotificationCenter`. Three reminders with **stable
identifiers** (`reminder.dawn`, `reminder.sunset`, `reminder.sleep`) so
re-scheduling replaces rather than duplicates. Each carries a deep link in
`userInfo`.

### PlayerController
`@MainActor ObservableObject` driving a single session: a 0.1s timer advances
progress; Listen mode plays bundled audio via `AVAudioPlayer` and **falls back
to timed text** when no asset is found (`audioUnavailable` flag).

## Persistence

- **SwiftData** holds only user-generated state: `PrayerCompletion` and
  `FavoritePrayer`. The container falls back to in-memory if the on-disk store
  can't be created, so the app always runs.
- **`prayers.json`** is immutable reference content — never written at runtime.
- **`UserDefaults`** holds lightweight preferences.

## Project format

The Xcode project uses **file-system synchronized groups** (`objectVersion 77`,
Xcode 16+). Files added under `Anjali/` and `AnjaliTests/` are picked up
automatically; `Info.plist` is excluded from the resources copy via a membership
exception. The test target is a host-based unit test (`TEST_HOST` + `@testable
import Anjali`).

## Testing strategy

Unit tests target the deterministic core:
- `TimeBandResolverTests` — boundary mapping for all four bands and the midnight wrap.
- `PrayerDataLoaderTests` — loads seed data, validates fields, skips malformed records.
- `TodayContextEngineTests` — dawn/sunset/night selection, preferred-deity ranking,
  recently-completed deprioritisation, needsReview/unreviewed/mode-less exclusion,
  explicit-moment override, scoring order, and alternates.
