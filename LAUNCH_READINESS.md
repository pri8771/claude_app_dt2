# Anjali — Launch Readiness (v1)

> _Updated 2026-06-30 to match the shipped product and launch scope. This file is the canonical launch-scope artifact for Anjali._

> **Anjali** is a Hindu short-form micro-prayer app for iOS — "a sacred pause, not a session." You open it, receive a single prayer chosen for the moment and the time of day, complete it in 10–60 seconds in Listen / Chant / Silent mode, and close the app a little steadier. It is a daily ritual object, not a meditation library, puja guide, bhajan player, astrology app, or content feed. **Implementation maturity: a working SwiftUI app** — 33 Swift files (~3.5k LOC), a real Xcode 16 project (`objectVersion 77`, file-system synchronized groups), 22 reviewed bundled prayers in `prayers.json`, a content pipeline (CSV catalog + Python validator), 6 XCTest suites covering the deterministic core, and a full App Store doc set. The core loop (open → Today card → Begin → player → completion → record) is wired end-to-end in code. **The one caveat that gates everything: the project has never been compiled** — it was authored by an agent without a Swift toolchain, so the build/test pass (`./Scripts/build.sh`) must be run on a Mac before any other launch step. There is no app icon, no bundled audio, and no privacy manifest yet.

---

## 1. PRD / Launch Scope

**Problem & insight.** Most spiritual apps are built like media platforms: long sessions, libraries to binge, streaks that turn devotion into a chore. That posture is wrong for prayer. The insight: a devotional touchpoint should be *small and complete* — one fitting prayer, finished in under a minute, with no feed and no pressure mechanics. Success is how quickly and calmly a person returns to their life, not time-in-app.

**Target user.**
- **Primary:** Practising Hindus worldwide (home-country and diaspora) who want a small, dignified, daily touchpoint with prayer — on the way out the door, before a meeting, in a wave of anxiety, at sunset, before sleep.
- **Secondary:** Heritage learners and students reconnecting with tradition; interfaith practitioners drawn to Hindu wisdom; anyone wanting a brief, non-commercial calm pause that respects the source material.

**Value proposition (one sentence).** One short prayer, suited to the moment and the time of day, that you can complete in under a minute — offline and private.

**Positioning / category & pitch.** Category: Lifestyle (primary) with Health & Fitness as the calm/mindful secondary. Pitch: *"A sacred pause, not a session — one short Hindu prayer for the moment you're in."*

**Platform & tech baseline (verified against the repo).**
- iOS **17.0+**, SwiftUI, Swift **5.0 language mode** (compiled by the Xcode 16 / Swift 6.x toolchain).
- **SwiftData** for user-generated state only (`PrayerCompletion`, `FavoritePrayer`); container falls back to in-memory if the on-disk store can't be created (`AnjaliApp.swift`).
- **UserDefaults** for preferences (`AppSettings.swift`).
- **AVFoundation** for optional local audio (`PlayerController.swift`); **UserNotifications** for local reminders (`NotificationManager.swift`).
- **No third-party dependencies. No networking layer. Offline-first** — all content ships in `Resources/prayers.json`.
- URL scheme `anjali://` for deep links (`Info.plist`).

**Business model.** Free, no in-app purchases, no account, no ads, no tracking — confirmed by `privacy_policy.md`, `terms_of_service.md`, and the absence of any StoreKit configuration. Any future monetization (premium audio packs, optional sync) is explicitly out of v1 and must pass the "deepen the pause, don't pull toward a session" test.

**North-star / success signals (privacy-respecting, local/beta-observable only).** No data leaves the device, so v1 has no remote analytics by design. Observable signals:
- **Completion rate** of a started prayer (does the pause actually close?) — derivable on-device from `PrayerCompletion`.
- **Return-after-first-session** (next-day re-open) — local only.
- **Beta-qualitative:** "does this feel authentic to your practice?" via TestFlight feedback (see `AppStore/beta_testing_plan.md`).
- Anti-signal we explicitly do **not** optimize: time-in-app or session length.

---

## 2. MVP Feature List (with acceptance criteria)

Status legend: **Built** = implemented in code; **Partial** = present but incomplete/needs an external asset or verification; **Not built** = deferred.

### F1. First-run onboarding — **Built**
Two-screen first-launch flow: wordmark + tagline, then gentle preferences. (`Views/Onboarding/OnboardingView.swift`, `RootView.swift`.)
- Given a fresh install, when the app launches, then `OnboardingView` is shown (not the tabs), gated by `settings.hasCompletedOnboarding == false`.
- Screen 1 shows the **Anjali** wordmark and the tagline *"A sacred pause for everyday life"*.
- Screen 2 is a `ScrollView` exposing script, preferred mode, ishta devata, optional favourite moments, and an optional reminder toggle; **Enter** is reachable with nothing selected.
- With the reminder toggle **OFF**, tapping Enter enters the app with **no** notification-permission prompt; with it ON, permission is requested only then, and a denial shows "You can always enable reminders later in Me" and still enters.
- On finish, all chosen preferences persist and `hasCompletedOnboarding` becomes `true`, so onboarding never shows again.

### F2. Today — single contextual prayer card — **Built**
One card chosen by time band, over a time-of-day theme. (`Views/Today/TodayView.swift`, `PrayerCardView.swift`, `Engine/TodayContextEngine.swift`, `TimeBandResolver.swift`, `Theme/Theme.swift`.)
- Given a populated library, when Today appears, then exactly **one** prayer card is shown (selection = top-ranked; alternates reachable only via "Change").
- The background, eyebrow, headline, and subheadline change with the resolved band (Dawn / Morning / Midday / Sunset / Night) per `ThemePalette.palette(for:)`.
- The card shows: optional deity chip, duration chip, title, transliteration, playable-mode chips, meaning, and `Source: <sourceTitle>`.
- Three actions work: **Begin** (preferred mode), **Silent** (forces silent), **Change** (next contextual prayer, shown only when `prayers.count > 1`).
- The band is re-resolved on `onAppear` and on `scenePhase == .active`.

### F3. Today selection engine (deterministic) — **Built**
Pure, unit-tested scoring/ranking that decides *which* prayer surfaces. (`Engine/TodayContextEngine.swift`, `TodayContext.swift`.)
- Scoring matches the documented weights: explicit moment +100, inferred moment +60, favourite moment +20, favourite-also-in-band +10, time-context +35, ishta deity +40, preferred mode +15, needsReview −100.
- Recency penalties (this session −90, earlier today −60, yesterday −20, within 3 days −10, else 0); `.dailyAnchor` prayers waive the **yesterday** penalty only.
- Completion **never excludes** a prayer; only `needsReview`/unreviewed are hard-excluded (`isEligibleForToday`).
- Ties break deterministically: featured → sortOrder → id. Empty/invalid library yields no selection without crashing.
- All of the above is asserted in `AnjaliTests/TodayContextEngineTests.swift`.

### F4. Prayer Player — Listen / Chant / Silent — **Built** (Listen audio asset = Partial)
Full-screen session with three modes and graceful audio fallback. (`Views/Player/PrayerPlayerView.swift`, `PlayerController.swift`.)
- Given a prayer, when the player opens, then it opens in the forced mode if set, else the user's preferred mode when supported, else the first playable mode (Silent guaranteed).
- Listen/Chant use the audio layout with a `FlameProgressView`; Silent uses a distinct minimal reading layout with a thin progress bar and a **Complete** CTA.
- In Listen, when `audioAssetName` resolves to a bundled file, audio plays via `AVAudioPlayer`; when it does not, `audioUnavailable` is set, a "Audio isn't available — follow along in silence" note shows, and the session advances on a timer (**no crash, no error**).
- Progress advances on a 0.1s timer (or real audio time when available) and reaching the end sets `isFinished`, which records a completion and presents the completion overlay.
- _Partial:_ **no audio is bundled** — all 22 prayers have `audioAssetName: null`, so Listen currently always falls back to timed text. The fallback is correct; the recordings are the missing asset (`Content/hero_prayers.md` plans 20).

### F5. Completion moment — **Built**
A felt close: flame, *"May this action be steady."*, Done / Repeat / Save. (`Views/Player/CompletionView.swift`, `PrayerPlayerView.swift`.)
- On finish, a `PrayerCompletion(prayerID, mode, completedAt)` is inserted into SwiftData and saved.
- The overlay shows the flame and the exact copy *"May this action be steady."* with **no recommendations**.
- **Done** records a session completion (so Today moves on) and dismisses to Today.
- **Repeat** restarts the same prayer and is **not** recorded as a session completion (so Today does not deprioritise it).
- **Save this prayer** inserts a `FavoritePrayer` (de-duplicated via a `#Predicate` fetch) and dismisses.

### F6. Moments — browse by moment or deity — **Built**
Calm, explicit shelves; no recommendations. (`Views/Moments/MomentsView.swift`, `PrayerListView.swift`.)
- A segmented control switches between **Moment** and **Deity** browse modes.
- Only moments/deities that actually have ≥1 reviewed prayer are listed (`library.availableMoments` / `availableDeities`).
- Tapping a shelf pushes a `PrayerListView`; tapping a row opens the player for that prayer.
- A `pendingMoment` (from a deep link) routes into the correct moment list on appear/change.

### F7. Me — preferences, reminders, saved prayers — **Built** (trim candidate)
Settings surface. (`Views/Me/MeView.swift`.)
- Exposes script, preferred mode, ishta devata, favourite moments (all persisted to `AppSettings`), three reminder toggles, saved prayers (tap to reopen, swipe to delete), and an about row.
- Toggling a reminder requests notification permission on first enable; a denial sets a "Notifications are turned off in Settings" note and the toggle stays off.
- _Note:_ the product conversation flagged **Me** as the surface most likely to be trimmed before TestFlight (it is the least "pause"-shaped). It is fully built; the open question is product, not engineering. See §6.

### F8. Local reminders — **Built** (off by default)
Three opt-in daily local notifications with stable IDs and deep links. (`Engine/NotificationManager.swift`, `AnjaliApp.swift`.)
- Reminders are **off by default**; permission is requested only when the user enables one.
- Each slot (`reminder.dawn` 06:30, `reminder.sunset` 18:30, `reminder.sleep` 21:30) uses a **stable identifier**, so re-scheduling replaces rather than duplicates.
- Each carries a `deepLink` in `userInfo`; tapping the notification routes through `AppCoordinator.handleNotificationUserInfo` into the right moment.
- `sync(enabledSlots:)` reconciles scheduled requests with the enabled set.

### F9. Deep links (`anjali://`) — **Built**
URL- and notification-driven navigation. (`Engine/DeepLink.swift`, `AppCoordinator.swift`, `Info.plist`.)
- `anjali://moment/{id}` opens the Moments tab on that moment; `anjali://prayer/{id}` opens the player for that prayer.
- Unknown scheme, unknown kind, unknown/empty moment id, and empty prayer id are all rejected without crashing; an unknown but well-formed prayer id is ignored gracefully (no matching prayer ⇒ no-op).
- Round-trips are asserted in `AnjaliTests/DeepLinkTests.swift`.

### F10. Offline-first content loading & resilience — **Built**
Robust bundled-content load. (`Engine/PrayerDataLoader.swift`, `PrayerLibrary.swift`.)
- All content loads from `Resources/prayers.json`; the app makes no network calls and works in airplane mode.
- A single malformed record decodes to `nil` and is skipped (per-element `FailablePrayer`); the loader throws only when the resource is missing/unreadable.
- Field validation requires non-empty id/title/devanagari/meaning/sourceTitle and `durationSeconds > 0`; empty `availableModes` is valid (Silent fallback).
- On total load failure, `PrayerLibrary.loadError` is set and Today shows an empty state instead of crashing.

### F11. Theming across five time bands — **Built**
Distinct palette + copy per band. (`Theme/Theme.swift`, `Views/Shared/Components.swift`.)
- Each of the five bands has a distinct multi-stop gradient, accent, eyebrow/headline/subheadline, and a `prefersDarkForeground` flag driving text contrast.
- Backgrounds crossfade on band change; Reduce Motion disables the animation.
- Distinctness and foreground polarity are asserted in `AnjaliTests/ThemePaletteTests.swift`.

### F12. Accessibility & Dynamic Type — **Partial**
Accessibility affordances are coded but unverified on-device. (Throughout the views.)
- VoiceOver labels/hints/traits exist on Begin, mode chips, Done/Repeat/Save, progress, and durations (`accessibleDuration` spells out "12 seconds").
- Reduce Motion is honoured for the flame pulse, background crossfade, and transitions.
- Dynamic Type uses semantic font styles with `minimumScaleFactor` on headlines.
- _Partial:_ none of this is verified on a device/simulator (largest-text clipping, VoiceOver reading order, contrast on all five bands). It is in the smoke-test checklist (`SETUP.md`) but not yet executed.

### F13. Bundled prayer content — 22 reviewed prayers — **Built** (provenance enforcement = Partial)
The seed set. (`Resources/prayers.json`, `Content/`.)
- 22 prayers, all `isReviewed: true` / `needsReview: false`, covering all 9 deities + universal śānti mantras and all five time bands, each with Devanagari, IAST transliteration, plain meaning, and an honest `sourceTitle`.
- _Partial / risk:_ there is **no per-prayer reviewer-identity or provenance field** in the `Prayer` model or `prayers.json`. The pipeline tracks `reviewer_name` in CSV, but `export_catalog.py` hardcodes it to `"seed"` and `validate_prayers.py` does **not** require it. So the conversation's central trust gate (named human sign-off that blocks release) is **process-only, not enforced**. See §7 BLK-2.

---

## 3. Out of Scope (v1 non-goals)

Explicitly **not** in v1, by product principle, guardrail, or deferral:
- **No content feed / infinite scroll / recommendations engine.** Today is one card; Moments are explicit shelves. The marketing copy deliberately avoids "for you", "discover", "feed" (`AppStore/README.md` notes).
- **No streaks, points, badges, or pressure mechanics.** Completion records a quiet trace, never a streak to protect.
- **No generated Sanskrit, ever.** Only well-known, attested mantras with honest sourcing (`CONTENT_GUIDELINES.md`). No AI completion or paraphrase of liturgical text.
- **No account, no sign-in, no cloud sync, no analytics, no network calls.** Fully offline; nothing leaves the device.
- **No professionally recorded audio in v1.** Listen falls back to timed text; recordings ship later prayer-by-prayer (`Content/hero_prayers.md`, `audio_spec.md`).
- **No additional scripts** (Tamil, Telugu, Bengali, Gujarati) beyond Devanagari + IAST transliteration.
- **No festival/regional Today themes** (`RotationPolicy.festivalSpecific` is reserved but unused).
- **No puja how-to, meditation timers, astrology, or bhajan streaming.**
- **No iPad-optimized layout, Apple Watch complication, or widgets** (the app builds for iPad but is portrait-phone-shaped).
- **No in-app purchases or subscriptions.**
- **No per-reminder custom time/UI** — reminders fire at fixed default times (06:30 / 18:30 / 21:30); custom scheduling is deferred.

---

## 4. User Flows

Screen names below correspond to real SwiftUI views in the repo.

**Flow A — First run / onboarding**
1. Fresh launch → `RootView` sees `hasCompletedOnboarding == false` → shows `OnboardingView`.
2. **Screen 1 (welcome):** Anjali wordmark + *"A sacred pause for everyday life"* → tap **Continue**.
3. **Screen 2 (preferences):** choose script, preferred mode, ishta devata; optionally pick favourite moments; optionally toggle reminders.
4. Tap **Enter** → preferences commit to `AppSettings`. If reminders OFF, enter immediately. If ON, request notification permission; on grant, schedule dawn+sunset; on denial, show the gentle note and enter anyway.
5. `hasCompletedOnboarding = true` → `MainTabView` (Today selected).

**Flow B — Core loop (the sacred pause)**
1. `MainTabView` → **Today** tab → `TodayView` resolves the band via `TimeBandResolver`, builds recency from `PrayerCompletion`, and runs `TodayContextEngine` → one `PrayerCardView`.
2. Tap **Begin** (or **Silent**) → `AppCoordinator.play(...)` presents `PrayerPlayerView` full-screen.
3. Player opens in the resolved mode; user taps **Begin** to run (Silent auto-runs its quiet timer). Progress fills; Listen plays audio or falls back to timed text.
4. On completion → `recordCompletion()` inserts a `PrayerCompletion` → `CompletionView` overlay: flame + *"May this action be steady."*
5. **Done** (move on) / **Repeat** (same prayer again) / **Save this prayer** (favourite) → dismiss to Today; the Today card advances because the completion is noted for the session.

**Flow C — Browse (Moments)**
1. **Moments** tab → `MomentsView`; pick **Moment** or **Deity** segmented mode.
2. Tap a shelf (e.g. "Anxiety" or "Shiva") → `PrayerListView` of reviewed prayers.
3. Tap a row → player opens for that prayer → same completion loop as Flow B.

**Flow D — Settings & privacy (Me)**
1. **Me** tab → `MeView` (`Form`) loads current settings on appear.
2. Change script / mode / ishta / favourite moments → writes straight to `AppSettings` (persisted).
3. Toggle a reminder → first enable requests permission; on grant, `NotificationManager.sync(...)` schedules; on denial, the off-state note shows.
4. View **Saved prayers** → tap to reopen in the player; swipe to delete a favourite.

**Flow E — Reminder / deep link entry**
1. A scheduled local reminder fires (e.g. 06:30 "Begin with light") carrying `anjali://moment/dawn`.
2. Tap → `NotificationDelegate` → `AppCoordinator.handleNotificationUserInfo` → `DeepLink` → Moments tab routes to the Dawn moment list. (`anjali://prayer/{id}` opens the player directly.)

---

## 5. Acceptance Criteria Summary

Each MVP feature maps to a single launch gate (full criteria in §2).

| ID | Feature | Pass/fail gate for launch |
| --- | --- | --- |
| F1 | Onboarding | Fresh install shows 2-screen onboarding once; reminders opt-in, never forced; prefs persist. |
| F2 | Today card | Exactly one contextual card over the correct band theme; Begin/Silent/Change work. |
| F3 | Selection engine | Documented scoring + recency hold; needsReview excluded; deterministic ties; tests green. |
| F4 | Player (3 modes) | Listen/Chant/Silent run; missing audio falls back to timed text with no crash. |
| F5 | Completion | Completion persists; flame + "May this action be steady"; Done/Repeat/Save behave correctly. |
| F6 | Moments | Browse by moment and deity; only populated shelves; row → player. |
| F7 | Me | Prefs/reminders/saved prayers all functional and persisted. |
| F8 | Reminders | Off by default; opt-in; stable IDs; deep-linked; no duplicates. |
| F9 | Deep links | Valid links route; invalid/unknown ids rejected gracefully. |
| F10 | Offline load | Loads bundled JSON; skips bad records; works in airplane mode; no crash on load failure. |
| F11 | Theming | Five distinct band palettes + correct foreground polarity; tests green. |
| F12 | Accessibility | VoiceOver/Dynamic Type/Reduce Motion/contrast verified on device (**gate not yet met**). |
| F13 | Content | 22 reviewed prayers, honest sources, validator passes; **named provenance gate not yet met**. |

**Hard launch gates that are not yet met:** a real device/simulator build+test pass (§7 BLK-1), enforced per-prayer provenance/sign-off (BLK-2), F12 accessibility verification, a real app icon (BLK-3), and a privacy manifest (BLK-4).

---

## 6. Known Limitations

- **Never compiled.** All Swift was authored without a toolchain; `STATIC_AUDIT.md` is a manual "compile-in-my-head" pass, not a build. `./Scripts/build.sh` has not been run on macOS. Until it passes, "Built" means "written and statically reviewed," not "verified to compile/run."
- **No audio shipped.** Every prayer's `audioAssetName` is `null`; the "Listen" mode is real but currently always degrades to timed text. The first 20 recordings are planned but unrecorded (`Content/hero_prayers.md`).
- **App icon is an empty placeholder.** `AppIcon.appiconset/Contents.json` has a 1024 slot with no `filename`; the build will warn and the App Store will reject without artwork.
- **No privacy manifest.** There is no `PrivacyInfo.xcprivacy`, yet the app uses `UserDefaults` (an Apple "required-reason" API). Required for App Store submission as of 2024.
- **Provenance is process-only.** Reviewer identity and source provenance live in docs/CSV (`reviewer_name` hardcoded to `"seed"`), not in the shipping data model, and are not enforced by the validator or the app.
- **Reminder times are fixed.** 06:30 / 18:30 / 21:30 only; no per-user custom time UI.
- **`Me` may be over-scoped.** It is a settings page, not a "pause"; the conversation flagged it as a trim candidate before TestFlight.
- **Today is time-band deterministic, not truly daily-rotating.** Selection re-resolves on appearance/foreground using on-device completion recency; there is no notion of "today's anchor as of midnight" beyond the recency buckets.
- **Recency bucketing is coarse for clock skew.** A completion timestamped in the future (device clock change) buckets to `.earlierToday` (safe, but imprecise).
- **iPad/large-screen layout is unoptimized.** Builds for iPad in all orientations but is designed portrait-phone-first.
- **Some App Store docs are aspirational/inconsistent.** `beta_testing_plan.md` claims content "verified by Sanskrit scholars" (not yet true — provenance is `"seed"`); README vs RELEASE_CHECKLIST disagree on primary category; `marketing_plan.md` has badly mangled Markdown list nesting.

---

## 7. Bug & Risk Triage

### Launch-blocking (must fix before TestFlight / App Store)

- **BLK-1 — The app has never been built or tested.** *Where:* whole project; `STATIC_AUDIT.md`, `Scripts/build.sh`. *Why blocking:* nothing is verified to compile, link, or run; SwiftData schema creation, AVFoundation session setup, and `@MainActor` isolation are only manually reviewed. Run `./Scripts/build.sh` on macOS (Xcode 16+, iOS 17 sim) to `** BUILD SUCCEEDED **` + `** TEST SUCCEEDED **` and execute the `SETUP.md` smoke test before anything else.
- **BLK-2 — Content provenance / reviewer sign-off is not enforced.** *Where:* `Models/Prayer.swift` (no provenance fields), `Resources/prayers.json`, `Scripts/validate_prayers.py`, `Scripts/export_catalog.py` (line 61 hardcodes `reviewer_name = "seed"`). *Why blocking:* the single biggest trust risk for a devotional app is a mis-sourced or culturally flattened prayer, and the conversation's explicit release bar — per-prayer attribution + translation provenance + a named human reviewer sign-off that blocks release if empty — is documented but **not** wired into the data or the validator. A real (named) reviewer must sign off each of the 22 prayers, and that sign-off should be a required, validated field that gates release. Until then, "22 reviewed" is an unverifiable claim.
- **BLK-3 — No app icon.** *Where:* `Assets.xcassets/AppIcon.appiconset/Contents.json` (placeholder, no image). *Why blocking:* App Store submission and even a clean archive require a real 1024 icon; `app_icon_spec.md` defines the brief.
- **BLK-4 — No privacy manifest (`PrivacyInfo.xcprivacy`).** *Where:* absent from the app target. *Why blocking:* the app accesses `UserDefaults` (NSPrivacyAccessedAPICategoryUserDefaults, a required-reason API); Apple requires a privacy manifest declaring the reason. The App Privacy "nutrition label" (Data Not Collected) is documented but the on-device manifest is missing. (Not currently listed in `RELEASE_CHECKLIST.md` — add it.)
- **BLK-5 — Accessibility unverified on device.** *Where:* F12; all views. *Why blocking for a calm/reverent app:* VoiceOver reading order, largest-Dynamic-Type clipping, and text contrast on all five band backgrounds are coded but never checked. A devotional app that is unreadable at large type or silent to VoiceOver fails its own dignity bar. Verify per the `SETUP.md` accessibility checklist.

### Non-blocking (ship-with, fix in a fast-follow)

- **NB-1 — `MeView.deleteSaved` can delete the wrong favourite.** *Where:* `Views/Me/MeView.swift` `deleteSaved(at:)`. *Rationale:* offsets come from `savedPrayers` (which is `favorites.compactMap { library.prayer(withID:) }`), but deletion is matched back to `favorites`. If a favourited prayer id no longer resolves (e.g. a prayer was removed from `prayers.json`), the two arrays desync and swipe-to-delete maps the wrong row. With the current 1:1 seed it cannot trigger, so it can ship — but fix by carrying the `FavoritePrayer` id through the row. Low likelihood today.
- **NB-2 — No bundled audio for "Listen."** *Where:* all prayers `audioAssetName: null`. *Rationale:* the fallback is correct and the listing copy says "where audio is available"; recordings land prayer-by-prayer post-launch (`hero_prayers.md`). Acceptable for v1.
- **NB-3 — No "Open Settings" affordance when notifications are denied.** *Where:* `MeView` shows static text only. *Rationale:* purely additive convenience; reminders are optional. Defer.
- **NB-4 — App Store category inconsistency.** *Where:* `AppStore/README.md` (Lifestyle primary) vs `RELEASE_CHECKLIST.md` §7 (Health & Fitness primary). *Rationale:* pick one before submission; trivial doc fix, no code impact.
- **NB-5 — `beta_testing_plan.md` overclaims "verified by Sanskrit scholars."** *Rationale:* aspirational copy that should match reality once BLK-2 is closed; not a code risk. Tighten wording.
- **NB-6 — `marketing_plan.md` has malformed Markdown.** *Where:* `AppStore/marketing_plan.md` lines ~10–150 (broken nested-list indentation). *Rationale:* cosmetic; content is fine; reformat when convenient.
- **NB-7 — `try! ModelContainer` in-memory fallback.** *Where:* `AnjaliApp.swift`. *Rationale:* documented as safe (a static schema cannot fail to create in memory); leave as-is but revisit under Swift 6 strict concurrency.
- **NB-8 — Coarse `AppSettings` change notification.** *Where:* `AppSettings.swift` single `changeToken`. *Rationale:* re-renders all observers on any change; correct, just not fine-grained. Fine at this app's size.
- **NB-9 — iPad layout unoptimized.** *Rationale:* portrait-phone design; acceptable for a v1 phone-first launch; a true iPad layout can follow.

---

## 8. Production-Readiness Assessment

**Current estimated readiness: ~70%.**

Justification: the product is sharply defined and the code is complete and coherent for the core loop, with a real Xcode project, a serious content pipeline, and meaningful unit tests on the deterministic core — well past "Planning." But it crosses no launch gate that requires a machine or a human reviewer: it has **never been compiled or run** (BLK-1), provenance/sign-off is **not enforced** (BLK-2), and it is missing an **icon** (BLK-3) and a **privacy manifest** (BLK-4), with accessibility **unverified** (BLK-5). Those are the difference between "well-built on paper" and "shippable," which is why this is ~70%, not higher. Closing the ordered checklist below moves it to 80–90%.

**Ordered remaining-work checklist to reach 80–90% production-ready:**
1. **Build & test on macOS.** Run `./Scripts/build.sh` (Xcode 16+, iOS 17 sim) to BUILD + TEST SUCCEEDED; fix any compiler/linker errors the static audit missed. *(Closes BLK-1; gets to ~78%.)*
2. **Execute the `SETUP.md` smoke test** on a fresh simulator (onboarding, persistence ×4, Today/Begin/Silent/Change, player + no-audio fallback, completion Done/Repeat/Save, Moments, Me, deep links, force-quit, airplane mode).
3. **Enforce content provenance (BLK-2).** Add reviewer/provenance fields (e.g. `reviewerName`, `sourceProvenance`) to the `Prayer` model + `prayers.json`, make `validate_prayers.py` (and CI) fail on empty/`"seed"` values, and have a named human reviewer actually sign off all 22 prayers. *(Closes the top trust risk; ~83%.)*
4. **Add the app icon (BLK-3).** Produce the 1024 master per `app_icon_spec.md`, drop it into `AppIcon.appiconset`, confirm no missing-icon warnings.
5. **Add `PrivacyInfo.xcprivacy` (BLK-4).** Declare the UserDefaults required-reason API; confirm the App Privacy label (Data Not Collected) matches. Add this line to `RELEASE_CHECKLIST.md` §8.
6. **Verify accessibility (BLK-5).** VoiceOver pass, largest Dynamic Type (no clipping), Reduce Motion, and contrast on all five bands.
7. **Product decision on `Me` and reminders scope.** Decide whether `Me` ships as-is or trims to essentials; confirm fixed reminder times are acceptable for v1.
8. **Fix NB-1** (carry the `FavoritePrayer` id into delete) and **reconcile docs** (NB-4/NB-5/NB-6 — category, scholar claim, marketing Markdown).
9. **Capture screenshots** for all required device sizes including the five band backgrounds; finalize App Store Connect metadata.
10. *(Optional for 90%+, not required for first TestFlight)* record and bundle the 20 hero audio clips per `audio_spec.md`.

**Test coverage summary.**
- **Tested (unit, XCTest, 6 suites):** `TodayContextEngineTests` (selection, deity/mode ranking, favourite-vs-band weighting, full recency matrix, daily-anchor waiver, completion-never-excludes, needsReview/unreviewed exclusion, silent fallback selectability, explicit-moment override, alternates, empty library); `TimeBandResolverTests` (all five band boundaries, midnight wrap, full-day coverage, all-bands-reachable, date path); `PrayerDataLoaderTests` (loads ≥20 seed, required-field validation, empty-modes valid, malformed-element skipping, empty data, null/empty title & meaning skipping); `PrayerModelTests` (playableModes/Silent guarantee, eligibility vs review, duration label); `ThemePaletteTests` (per-band copy/gradient, distinctness, midday≠morning, foreground polarity); `DeepLinkTests` (valid/invalid parsing, round-trips). Content is gated by `validate_prayers.py` in CI.
- **Not tested / not automatable here:** all SwiftUI views (no UI/snapshot tests), `PlayerController` audio + timer behaviour (AVFoundation), `NotificationManager` scheduling, SwiftData persistence and the `MeView.deleteSaved` path, onboarding permission branching, deep-link → coordinator → navigation end-to-end, and every accessibility/Dynamic-Type behaviour. CI runs **content validation only** — no macOS runner builds or runs the Xcode tests, so even the unit tests are unproven until run locally.

---

## 9. Launch Checklist (Anjali-specific)

**Build & QA**
- [ ] `./Scripts/build.sh` → `** BUILD SUCCEEDED **` and `** TEST SUCCEEDED **` (logs in `BuildReports/`).
- [ ] `python3 Scripts/validate_prayers.py` passes; `python3 Scripts/export_catalog.py` shows no `Content/` drift; CI green.
- [ ] Full `SETUP.md` smoke test passes on a fresh simulator, including airplane-mode and force-quit relaunch.

**Content & safety (the trust gate)**
- [ ] All 22 prayers carry honest `sourceTitle`; **no fabricated Sanskrit** (`CONTENT_GUIDELINES.md`).
- [ ] **Named human reviewer has signed off every prayer** and the sign-off is an enforced, validated field (BLK-2) — not `"seed"`.
- [ ] `beta_testing_plan.md`'s "verified by Sanskrit scholars" claim is true or softened to match reality.
- [ ] Tone audit: no fear-based / transactional / sectarian framing; meanings plain and faithful.

**App Store / privacy**
- [ ] Real **app icon** added (BLK-3); no missing-icon warnings.
- [ ] **`PrivacyInfo.xcprivacy`** present declaring the UserDefaults required-reason API (BLK-4).
- [ ] **App Privacy label: Data Not Collected**; no tracking; no third-party SDKs; matches `privacy_policy.md`.
- [ ] **Export compliance:** `ITSAppUsesNonExemptEncryption = NO` (already in `Info.plist`).
- [ ] **Age rating 4+** (questionnaire all "None"); **no in-app purchases** configured.
- [ ] **Category** reconciled to one primary (resolve README vs RELEASE_CHECKLIST).
- [ ] Privacy Policy URL (`https://anjali.app/privacy`) and Support URL (`https://anjali.app/support`) are **live**.
- [ ] Listing copy, keywords (≤100 chars), promo text, What's New entered; screenshots for all device sizes incl. the five band backgrounds.

**Notifications & permissions**
- [ ] Reminders confirmed **off by default**; permission requested only on opt-in; denial handled gracefully in onboarding and Me.

**Versioning & submission**
- [ ] `MARKETING_VERSION` (1.0) and a unique, incremented `CURRENT_PROJECT_VERSION`; `Info.plist` strings agree; bundle id `app.anjali.Anjali` matches App Store Connect.
- [ ] Accessibility verified on device (BLK-5): VoiceOver, largest Dynamic Type, Reduce Motion, contrast on all five bands.
- [ ] Archive (Any iOS Device, Release) validates clean; TestFlight upload processes; core path + deep links + reminders + offline verified on a real device.
- [ ] Review notes filled in (offline, accountless, no data collected, local-only reminders, no IAP); submit and monitor.
