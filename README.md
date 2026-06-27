# Anjali

> A sacred pause, not a session.

Anjali is a digital temple for Hindus worldwide, built entirely around
short-form **micro-prayers** (10–60 seconds). It is an iOS-native daily ritual
object — not a puja guide, not a meditation app, not a bhajan player, not an
astrology app, not a content library.

## North Star

**A sacred pause, not a session.** Open the app, receive a single prayer that
fits the moment, complete it in under a minute, and close the app feeling
steadier. No feeds, no streaks-as-pressure, no recommendations engine pulling
for attention.

## What it does

- **Today** — one contextual prayer card that changes with the time of day
  (Dawn / Morning / Sunset / Night), each with its own colour theme and copy.
- **Prayer Player** — a full-screen, calm experience with three modes:
  - **Listen** (audio, when available — falls back gracefully when not)
  - **Chant** (text with a gentle progress flame)
  - **Silent** (text only)
  - Completion shows a flame and *"May this action be steady."* with
    **Done / Repeat / Save this prayer**.
- **Moments** — browse prayers by moment (Dawn, Leaving home, Before work,
  Meeting, Study, Travel, Anxiety, Gratitude, Protection, Sunset, Sleep) or by
  deity (Ganesha, Shiva, Vishnu, Krishna, Hanuman, Devi, Lakshmi, Saraswati,
  Surya).
- **Me** — script preference (Devanagari / Transliteration / Both), ishta
  devata, favourite moments, local reminders, and saved prayers.

## Tech

- SwiftUI, Swift, **iOS 17+**
- SwiftData (completions & favourites), `UserDefaults` (preferences)
- AVFoundation (optional local audio), UserNotifications (local reminders)
- XCTest unit tests
- **No third-party dependencies. Offline-first. No network for the MVP.**

## Project layout

```
Anjali/
  Anjali.xcodeproj/            # Xcode project (file-system synchronized groups)
  Anjali/
    AnjaliApp.swift            # App entry, SwiftData container, notifications
    AppCoordinator.swift       # Tab + deep-link + player presentation state
    Models/                    # Prayer, enums, SwiftData models
    Engine/                    # TodayContextEngine, TimeBandResolver, loaders
    Theme/                     # Colour + copy themes per time band
    Views/                     # Today, Player, Moments, Me, Onboarding, shared
    Resources/prayers.json     # Seed content (22 reviewed prayers)
    Assets.xcassets            # App icon + accent colour
    Info.plist                 # Bundle config + anjali:// URL scheme
  AnjaliTests/                 # Engine, loader, and time-band unit tests
README.md  PRD.md  ARCHITECTURE.md  CONTENT_GUIDELINES.md
```

## Build & run

Requirements: **Xcode 16+** (the project uses file-system synchronized groups,
`objectVersion 77`) and an iOS 17 simulator or device.

```bash
# Open in Xcode
open Anjali/Anjali.xcodeproj

# Or build from the command line
cd Anjali
xcodebuild -project Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run the unit tests
xcodebuild -project Anjali.xcodeproj -scheme Anjali \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

In Xcode: select the **Anjali** scheme and an iOS 17 simulator, then ⌘R to run
or ⌘U to test.

## Deep links

- `anjali://moment/{id}` — open the Moments flow for a moment (e.g.
  `anjali://moment/dawn`)
- `anjali://prayer/{id}` — open a specific prayer (e.g.
  `anjali://prayer/shiva-namah`)

Local reminders (`reminder.dawn`, `reminder.sunset`, `reminder.sleep`) carry
these deep links so a tap lands in the right place.

## Content & sourcing

All prayers are well-known, traditional mantras with honest source notes. We do
**not** generate Sanskrit. See [CONTENT_GUIDELINES.md](CONTENT_GUIDELINES.md).
