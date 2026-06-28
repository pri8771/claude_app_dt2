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
Pure mapping from a wall-clock time to a `TimeContext` (five bands):
- Dawn 04:30–07:59, Morning 08:00–11:59, Midday 12:00–15:59, Sunset 16:00–19:59,
  Night 20:00–04:29 (wraps past midnight).
- Every minute maps to exactly one band — no gap. Midday is its own band with a
  distinct ivory/saffron theme ("A pause at midday").
- Exposes a `minutesSinceMidnight` entry point for trivial, clock-free testing.

### PrayerDataLoader
Loads `prayers.json`, validating fields. Decodes leniently: a bad element
decodes to `nil` and is skipped rather than aborting the whole file. Throws only
when the resource is missing/unreadable — never for individual records. This is
how acceptance criterion *"invalid content does not crash"* is met.

### TodayContextEngine
The heart of Today. Given a `TodayEngineInput` (prayers, time band, explicit
moment, preferred deity, favourite moments, and a per-prayer
`CompletionRecency` map) it returns a `TodayContext` (theme, copy, selected
prayer, alternates). Pure function — no clocks, no globals — so every rule is
deterministically unit-tested.

Completion **never excludes** a prayer; it applies a graded recency penalty
(this session −90, earlier today −60, yesterday −20, within 3 days −10, then 0)
so the day feels fresh while tomorrow's repetition is allowed. A prayer's
`RotationPolicy` tunes this: `.dailyAnchor` prayers (Gayatri, Om Shanti, a
simple Ganesha invocation, the evening close) are exempt from the "yesterday"
nudge so they return each day. Only `needsReview`/unreviewed prayers are
hard-excluded. Scoring is documented in `PRD.md`.

> **Favourite-moment weighting (implemented in Phase 3B).**
> The favourite-moment signal is now separate from, and lighter than, the
> time-band signal in `TodayContextEngine.score(_:input:)`:
> - time-band inferred moment match: **+60**
> - favourite-moment match: **+20**
> - matched favourite that is *also* compatible with the current band: **+10**
>
> So a favourite never outweighs the time of day on its own, but an aligned
> favourite is gently reinforced.

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
- `TimeBandResolverTests` — boundary mapping for all five bands (dawn/morning/
  midday/sunset/night), the midnight wrap, and full-day coverage.
- `PrayerDataLoaderTests` — loads seed data, validates fields, skips malformed records.
- `TodayContextEngineTests` — dawn/midday/sunset/night selection, preferred-deity
  ranking, graded recency penalties, daily-anchor "yesterday" waiver, completion
  never excluding, needsReview/unreviewed exclusion, text-only prayers still
  selectable (Silent fallback), explicit-moment override, scoring order, alternates.

`Scripts/validate_prayers.py` validates `prayers.json` against the Swift enums
(including `rotationPolicy`) and can gate CI.
