# Anjali — Local Build & Validation Guide

This is the handoff guide for building and validating Anjali on a Mac. The CI
agent that authored the code **cannot compile Swift**, so this document captures
everything needed to validate the build locally.

## Prerequisites

- **macOS** with **Xcode 16 or newer** (the project uses file-system
  synchronized groups, `objectVersion 77`, which requires Xcode 16+).
- An **iOS 17+ simulator** (e.g. iPhone 15). Install via
  *Xcode → Settings → Components* if missing.
- Command Line Tools selected: `sudo xcode-select -s /Applications/Xcode.app`.

## Project facts (audited)

| Setting | Value |
| --- | --- |
| Project | `Anjali/Anjali.xcodeproj` |
| Scheme | `Anjali` (shared, in `xcshareddata/xcschemes/`) |
| App bundle id | `app.anjali.Anjali` |
| Test bundle id | `app.anjali.AnjaliTests` |
| Deployment target | iOS 17.0 |
| Swift language mode | 5.0 (`SWIFT_VERSION = 5.0`) |
| Info.plist | `Anjali/Info.plist` (URL scheme `anjali://`) |
| Tests | host-based unit tests (`TEST_HOST` + `@testable import Anjali`) |

> **About "Swift version".** `SWIFT_VERSION` is the *language mode*, whose valid
> values are `4.0 / 4.2 / 5.0 / 6.0` — there is no "5.9". The compiler is
> whatever ships with Xcode 16 (Swift 6.x). We deliberately stay in **5.0
> language mode**: switching to 6.0 turns on strict concurrency checking, which
> would require re-auditing the `@MainActor` annotations before it builds
> cleanly. 5.0 mode compiles on the modern toolchain today.

### Why there are no per-file references in the project

The project uses **`PBXFileSystemSynchronizedRootGroup`** for both `Anjali/` and
`AnjaliTests/`. Xcode includes every file in those folders automatically, so:
- there is **no list of individual Swift files** to drift out of sync, and
- there are **no dangling file references** (only the two build products are
  `PBXFileReference`s). Adding a `.swift` file to the folder adds it to the
  target with no `.pbxproj` edit.

`Info.plist` is excluded from the app's *Copy Resources* phase via a
`PBXFileSystemSynchronizedBuildFileExceptionSet` (it is consumed by
`INFOPLIST_FILE` instead).

## Opening the project

```bash
open Anjali/Anjali.xcodeproj
```

Select the **Anjali** scheme and an **iOS 17** simulator, then **⌘R** to run or
**⌘U** to test.

## Building from the command line

A convenience script prints the environment, validates content, lists the
project, then runs a clean build followed by the tests:

```bash
./Scripts/build.sh
```

**Override the simulator** with the `DESTINATION` env var (default is
`platform=iOS Simulator,name=iPhone 15`):

```bash
DESTINATION="platform=iOS Simulator,name=iPhone 16" ./Scripts/build.sh
```

**Logs.** The script writes the *full* (untruncated) logs to:
- `BuildReports/build.log` — the clean build
- `BuildReports/test.log` — the test run

`BuildReports/` is git-ignored. The script uses `set -euo pipefail` (with
`pipefail` before each `xcodebuild | tee`), so it **exits non-zero** if the
build or tests fail, and prints `=== Success ===` only when both complete.

Or run the commands directly:

```bash
# Clean build
xcodebuild -project Anjali/Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' clean build

# Unit tests
xcodebuild -project Anjali/Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

If `iPhone 15` is not installed, list available simulators with
`xcrun simctl list devices available` and substitute a name.

### Content validation (no Xcode needed)

```bash
python3 Scripts/validate_prayers.py   # validates prayers.json against the enums
python3 Scripts/export_catalog.py     # regenerates Content/ CSVs from the JSON
```

## What success looks like

- **Build:** the `xcodebuild … build` run ends with **`** BUILD SUCCEEDED **`**.
- **Tests:** the `xcodebuild … test` run ends with **`** TEST SUCCEEDED **`**.
  Expect the three suites to pass:
  - `TimeBandResolverTests` (five-band boundaries + full-day coverage)
  - `PrayerDataLoaderTests` (loads seed, validates fields, skips malformed,
    empty-modes is valid)
  - `TodayContextEngineTests` (selection, deity/mode ranking, recency,
    daily-anchor waiver, exclusions, alternates)
- **Run:** the app launches into onboarding on a fresh simulator.

## Smoke test checklist

Run on a **fresh** simulator (erase first: *Device → Erase All Content and
Settings*, or `xcrun simctl erase all`).

### Onboarding
- [ ] Fresh install launches into **onboarding** (not the tabs).
- [ ] Screen 1 shows the **Anjali** wordmark and tagline
      *"A sacred pause for everyday life"*.
- [ ] Screen 2 **scrolls** and never feels blocked; **Enter** is reachable with
      nothing selected.
- [ ] With the reminder toggle **OFF**, tapping Enter goes straight into the app
      **without** any notification-permission prompt.
- [ ] With the reminder toggle **ON**, the notification-permission prompt appears
      **only then**; denying it shows "You can always enable reminders later in
      Me" and still enters the app.

### Preferences persist across relaunch
(Set in onboarding or Me, then force-quit and relaunch.)
- [ ] **Script** preference persists.
- [ ] **Preferred mode** persists.
- [ ] **Ishta devata** persists.
- [ ] **Favourite moments** persist.

### Today & player
- [ ] Today shows **one** contextual prayer card with a time-band background.
- [ ] **Begin** opens the full-screen player.
- [ ] The player opens in the **preferred mode** when the prayer supports it.
- [ ] A prayer with **no audio** falls back gracefully (timed text, no crash);
      Listen shows the "audio isn't available" note.
- [ ] Reaching the end **records a completion** (no crash) and shows the flame +
      *"May this action be steady."*
- [ ] **Done** returns to Today.
- [ ] **Repeat** restarts the same prayer.
- [ ] **Save this prayer** creates a favourite.

### Moments & Me
- [ ] Moments browses by **moment** and by **deity**.
- [ ] **Me** lists saved prayers; tapping one reopens the player.
- [ ] Reminder toggles in Me **schedule/cancel** without crashing.

### Resilience
- [ ] App works after **force-quit / relaunch** (state preserved).
- [ ] App works fully in **airplane mode** (offline-first; no network calls).

### Deep links
With the app installed and the simulator **booted**, trigger the `anjali://`
URL scheme from the terminal:

```bash
xcrun simctl openurl booted anjali://moment/dawn
xcrun simctl openurl booted anjali://prayer/ganesha-gam
```

- [ ] `anjali://moment/dawn` opens the **Moments** tab on the Dawn moment.
- [ ] `anjali://prayer/ganesha-gam` opens the **player** for that prayer.
- [ ] An unknown id (e.g. `anjali://prayer/does-not-exist`) is ignored
      gracefully (no crash).

### Accessibility
- [ ] **Large Dynamic Type:** in *Settings → Accessibility → Display & Text
      Size → Larger Text* (or the simulator's Environment Overrides), raise the
      text size to the largest setting — the Today card, player text, and
      onboarding remain readable and don't clip badly.
- [ ] **VoiceOver labels:** with VoiceOver on, the **Begin** button, the
      **Listen / Chant / Silent** mode picker, and the **Done / Repeat / Save
      this prayer** completion buttons are announced with clear, correct labels.
- [ ] **Reduce Motion:** in *Settings → Accessibility → Motion → Reduce Motion*,
      the flame/progress and transitions degrade gracefully (no jarring or
      excessive animation).
- [ ] **Contrast across all five time bands:** check Dawn, Morning, Midday,
      Sunset, and Night — foreground text and the accent meet a comfortable
      contrast on each background (Midday/Morning are light; Dawn/Sunset/Night
      are dark).

## Known follow-ups before TestFlight

- **Favourite-moment scoring needs tuning** (see `ARCHITECTURE.md`): a favourite
  moment currently earns the full inferred-moment bonus, equal to a time-band
  match. It should likely be weighted lighter than the time-band signal.
- **App icon** is a placeholder (empty `AppIcon` set) — add artwork before any
  external build.
- **Audio** assets are not bundled in the MVP; Listen falls back to timed text.
