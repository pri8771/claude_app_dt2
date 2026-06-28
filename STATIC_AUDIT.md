# Static Audit — Phase 4 (no-compiler review)

A manual "compile-in-my-head" pass over all Swift sources, since this
environment has no Swift toolchain. Scope: catch the things a compiler/linker
would reject (missing imports, async/actor mismatches, protocol-conformance
gaps, non-exhaustive switches, bad `ForEach`/`Identifiable` usage), **not** to
refactor style. Only clearly-wrong issues were fixed; everything else is a note.

**Files reviewed:** all 27 app sources under `Anjali/Anjali/`.

## Result

**No compile-blocking issues found.** One definite threading/async issue was
fixed; the remaining notes are non-blocking observations.

## Checks performed

| Area | Finding |
| --- | --- |
| **Imports** | All present. `Combine` where `AnyCancellable`/`ObservableObject` used (`PlayerController`, `AppSettings`); `AVFoundation` in `PlayerController`; `UserNotifications` in `NotificationManager`/`AnjaliApp`; `Foundation` in `Components.swift` for `sin`. ✅ |
| **Exhaustive switches** | All `switch` over `TimeContext` (in `Enums.displayName`, `Enums.inferredMoments`, `Theme.palette`) handle the five cases including `.midday`. `CompletionRecency` switch handles all 5. Enum self-switches for `Moment`/`Deity`/`Intention`/`PlayMode`/`ScriptPreference`/`ReminderSlot` are complete. `Int`/`String` switches have `default`. ✅ |
| **`ForEach` / `Identifiable`** | Every `ForEach` without an explicit `id:` iterates an `Identifiable` type (`ScriptPreference`, `PlayMode`, `Deity`, `Moment`, `ReminderSlot`, `TimeContext`, `Prayer`, `MomentsView.BrowseMode`, `OnboardingView.OnboardingMoment`). ✅ |
| **Protocol conformances** | `Prayer`/`PrayerText` `Codable`+`Hashable`+`Identifiable`; SwiftData `@Model`s; `ThemePalette: Equatable` (all stored props Equatable). `fullScreenCover(item:)` uses `Prayer: Identifiable`. ✅ |
| **Actor / async** | `@MainActor` on `PlayerController`, `NotificationManager`, `AppSettings`, `AppCoordinator`, `PrayerLibrary`. `async` notification calls awaited correctly. **One fix applied** — see below. |
| **iOS 17 APIs** | Two-param `onChange`, `@Query`, `NavigationStack`, `AccessibilityNotification.Announcement`, `scenePhase` — all available at the 17.0 floor. ✅ |
| **Construction sites** | `ThemePalette(...)` only in `palette(for:)`; `PrayerPlayerView(prayer:forcedMode:)` only in `RootView`; `PrayerCardView(...)` only in `TodayView` — all match current signatures. ✅ |

## Fixed (clearly wrong)

1. **`MeView.loadState()` — `@State` mutated off the main thread.**
   A bare `Task { … notificationsDenied = … }` resumed its continuation after
   `await notifications.authorizationStatus()` on a non-main executor, then
   mutated `@State`. SwiftUI requires state mutations on the main thread.
   **Fix:** `Task { @MainActor in … }`. (The other `Task`s are already
   `@MainActor`, or call the `@MainActor`-isolated `setReminder`, so they were
   correct.)

## Notes (non-blocking, not changed — out of "fix only clearly wrong" scope)

- **`AnjaliApp` uses `try! ModelContainer(...)`** as the in-memory fallback.
  Safe in practice (a static, valid schema cannot fail to create in memory);
  documented previously. Left as-is.
- **`AppSettings` change-notification is coarse.** It exposes computed
  `UserDefaults`-backed properties and bumps a single `@Published changeToken`,
  so any change re-renders all observers rather than fine-grained per-property.
  Correct, just not maximally efficient. Acceptable for this app's size.
- **`Combine` `sink` calls `@MainActor tick()`** in `PlayerController`. Valid in
  Swift 5 language mode (the project's mode) because the timer publishes on
  `.main`; a future move to Swift 6 mode would want an explicit hop.
- **Swift language mode is 5.0.** A later switch to 6.0 (strict concurrency)
  would surface the two items above as warnings/errors; revisit then.

## Caveat

This is a manual review, not a compile. The authoritative check remains
`./Scripts/build.sh` on macOS. If it reports errors, send them and they'll be
fixed directly.
