# Anjali — Project Documentation

_Updated 2026-06-30 to match the shipped product and launch scope. See [LAUNCH_READINESS.md](../LAUNCH_READINESS.md)._

GitHub is the source of truth for this project documentation. Notion indexes this file in the Priyansh App Factory Command Center. This document describes the **actual product in the repo**, not an earlier concept — earlier drafts referenced a generic "offering / intention / streak / history" ritual, which the real app does not implement.

## 00. Executive Summary
Anjali is a Hindu short-form **micro-prayer** iOS app — "a sacred pause, not a session." The user opens it, receives a single prayer chosen for the moment and the time of day, completes it in 10–60 seconds (Listen / Chant / Silent), and closes the app a little steadier. It is a daily ritual object, not a puja guide, meditation library, bhajan player, astrology app, or content feed. The product is a working SwiftUI app (iOS 17+, ~33 Swift files) with a real Xcode project, 22 reviewed bundled prayers, a content pipeline, and unit tests. The portfolio decision is **Continue** toward TestFlight; it is the most launch-shaped app in the set.

## 01. Product
**MVP scope (as built):** two-screen first-run onboarding; three tabs (Today, Moments, Me); a single contextual Today prayer card themed by five time bands (Dawn / Morning / Midday / Sunset / Night); a full-screen Prayer Player with Listen / Chant / Silent and graceful audio fallback; a completion moment ("May this action be steady." with Done / Repeat / Save); Moments browsing by moment and by deity; Me preferences (script, mode, ishta devata, favourite moments), opt-in local reminders, and saved prayers; `anjali://` deep links; fully offline. **Acceptance criteria:** the one-minute pause is clear and singular (one card, not a feed); content is respectfully and honestly sourced; the core loop runs end-to-end. Full, testable criteria are in [LAUNCH_READINESS.md §2 and §5](../LAUNCH_READINESS.md).

## 02. Design
Warm, reverent, minimal. Each of the five time bands has its own gradient, accent, and copy; the same flame motif recurs on the player progress ring, the completion screen, and (planned) the app icon. No gamification, no badges, no flashy motion (Reduce Motion is honoured). Screens that exist in code: Onboarding (welcome + preferences), Today (single card), Prayer Player (audio layout + distinct Silent reading layout), Completion overlay, Moments (browse), prayer lists, and Me (settings + saved). The app icon is still a placeholder (see [app_icon_spec.md](../AppStore/app_icon_spec.md)).

## 03. Frontend Technical
SwiftUI, iOS 17+, Swift 5.0 language mode. Core types: `Prayer` / `PrayerText` (immutable, Codable, from `Resources/prayers.json`); enums `TimeContext`, `Moment`, `Deity`, `Intention`, `PlayMode`, `ScriptPreference`, `RotationPolicy`; SwiftData `@Model`s `PrayerCompletion` and `FavoritePrayer`. The deterministic core (`TodayContextEngine`, `TimeBandResolver`, `PrayerDataLoader`) is pure and unit-tested, separated from the views. `AppCoordinator` owns navigation (tab, deep link, full-screen player); `AppSettings` is UserDefaults-backed; `PlayerController` drives a single session over AVFoundation with timed-text fallback. Navigation surfaces: Today, Moments, Me. See [ARCHITECTURE.md](../ARCHITECTURE.md).

## 04. Backend Technical
**No backend, by design.** There is no networking layer in the MVP. All prayer content ships in the bundle; user state is on-device only (SwiftData + UserDefaults). Future, out-of-scope services could include optional iCloud sync of favourites/preferences or downloadable audio packs — none are built and any would be opt-in.

## 05. Business
Trust-first spiritual product. v1 is free, no account, no ads, no tracking, no in-app purchases (confirmed by `privacy_policy.md` / `terms_of_service.md` and the absence of any StoreKit config). Any future monetization (premium recorded-audio packs, family features) must pass the north-star test: deepen *the pause*, never pull toward *the session*.

## 06. Marketing
Positioning: "A sacred pause, not a session — one short Hindu prayer for the moment you're in." Organic-only plan: temples, cultural centres, yoga communities, diaspora networks, and Product Hunt; **no paid advertising for MVP**. Marketing language deliberately avoids "feed", "for you", and "discover" to stay aligned with the no-recommendation principle. See [AppStore/marketing_plan.md](../AppStore/marketing_plan.md) (note: that file's Markdown formatting needs cleanup) and [AppStore/README.md](../AppStore/README.md) for listing copy.

## 07. User Acquisition
Beta with cultural advisors, diaspora users, students, and community contacts (see [AppStore/beta_testing_plan.md](../AppStore/beta_testing_plan.md)). Because nothing leaves the device, success signals are **local/beta-observable only**: prayer-completion rate, next-day return, and qualitative "does this feel authentic to your practice?" feedback. No remote analytics. Do **not** optimize time-in-app.

## 08. Execution
Plan: (1) build + test on macOS — the project has never been compiled (`./Scripts/build.sh`); (2) run the `SETUP.md` smoke test; (3) close the content-provenance gate (named human reviewer sign-off enforced in data + validator, not the hardcoded `"seed"`); (4) add the real app icon; (5) add a `PrivacyInfo.xcprivacy` manifest; (6) verify accessibility on device; (7) decide whether to trim the Me tab; (8) screenshots + App Store Connect metadata; (9) archive → TestFlight → submit. The ordered, percentage-tracked path is in [LAUNCH_READINESS.md §8](../LAUNCH_READINESS.md).

## 09. QA
Tested today (XCTest, 6 suites): the Today selection engine, time-band resolver, content loader/validation, prayer model, theme palette, and deep links. **Not yet tested:** the SwiftUI views, audio/timer playback, notification scheduling, SwiftData persistence, onboarding permission branching, and all accessibility behaviour. CI runs **content validation only** — no macOS runner builds or runs the Xcode tests, so even the unit tests are unproven until run locally. Manual QA must cover: ritual start/completion, saved prayers, reminder permission, offline content, reset state, Dynamic Type, VoiceOver, Reduce Motion, and contrast on all five bands. See [LAUNCH_READINESS.md §8 test-coverage summary](../LAUNCH_READINESS.md).

## 10. Legal / Compliance
Local-only data storage and opt-in local reminders are documented in [privacy_policy.md](../AppStore/privacy_policy.md). The App Privacy label is **Data Not Collected**; a `PrivacyInfo.xcprivacy` manifest declaring the UserDefaults required-reason API is still **outstanding** and is required for submission. Religious content must be reviewed for respectful, accurate, non-sectarian presentation, with honest sourcing and **no fabricated Sanskrit** ([CONTENT_GUIDELINES.md](../CONTENT_GUIDELINES.md)); a named reviewer sign-off should gate release.

## 11. Operations
Release process: build/test on macOS → content sign-off → icon + privacy manifest → accessibility verification → internal/cultural-advisor beta → TestFlight → submit ([AppStore/RELEASE_CHECKLIST.md](../AppStore/RELEASE_CHECKLIST.md)). Post-launch: record and bundle the 20 hero audio clips ([Content/hero_prayers.md](../Content/hero_prayers.md)), watch crash reports and feedback, and expand the seed set from 22 toward 80–120 prayers through the existing content workflow. Festival/regional Today themes and additional scripts are reserved for later versions.
