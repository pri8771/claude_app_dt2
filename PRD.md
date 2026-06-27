# Anjali — Product Requirements

## Product thesis

Most spiritual apps are built like media platforms: long sessions, libraries to
binge, streaks that turn devotion into a chore. Anjali rejects that. It is a
**ritual object**, not a content destination.

> A sacred pause, not a session.

The core loop is intentionally tiny: **open → receive one fitting prayer →
complete it in 10–60 seconds → close, steadier.** Success is measured by how
quickly and calmly a person can return to their life, not by time-in-app.

Anjali is for Hindus worldwide who want a small, dignified, daily touchpoint
with prayer — on the way out the door, before a meeting, in a moment of anxiety,
at sunset, before sleep.

## What Anjali is NOT

- ❌ A puja/ritual how-to guide
- ❌ A meditation app
- ❌ A bhajan / music streaming app
- ❌ An astrology or horoscope app
- ❌ A bottomless content library or social feed
- ❌ A recommendations engine optimising for engagement

## MVP scope

1. **Onboarding** (first launch only)
   - Screen 1: wordmark **Anjali** + tagline *"A sacred pause for everyday life"*.
   - Screen 2: a few gentle preferences (script, ishta devata).
2. **Three tabs:** Today, Moments, Me. Exactly three. No more.
3. **Today**
   - A single contextual prayer card.
   - Background and copy change by time band: Dawn, Morning, Sunset, Night.
   - Card: eyebrow label, headline, prayer title, duration chip, mode chips
     (Listen/Chant/Silent), meaning, and a **Begin** CTA.
   - Selection is deterministic via `TodayContextEngine`.
4. **Prayer Player**
   - Full-screen. Sanskrit text large (28–36pt), transliteration, meaning.
   - Three modes: Listen (AVFoundation), Chant (text + progress), Silent (text).
   - Progress shown as a subtle flame/ring.
   - Completion: flame, *"May this action be steady."*, **Done / Repeat / Save**.
   - **No recommendations** after completion.
5. **Moments** — browse by moment and by deity. Explicit shelves only.
6. **Me** — script picker, ishta devata, favourite moments, local reminders,
   saved prayers.
7. **Notifications** — local only, stable identifiers, deep links into the app.
8. **Offline** — all content from bundled JSON; audio optional and local.

## Acceptance criteria

1. App launches.
2. Onboarding appears on first launch only.
3. Exactly three tabs: Today / Moments / Me.
4. Today shows a single contextual prayer card.
5. Background changes by time band.
6. **Begin** opens the prayer player.
7. Player supports Listen / Chant / Silent with graceful fallback when audio is
   missing.
8. Completion records in SwiftData and offers Done / Repeat / Save.
9. Moments is browseable by moment and by deity.
10. Me exposes preferences.
11. Local notifications can be scheduled.
12. Works fully offline.
13. `TodayContextEngine` is unit-tested.
14. Invalid content never crashes the app.
15. `needsReview` prayers are excluded from selection.

## Microcopy rules

- **Begin** (never "Play")
- **Done** (never "Next")
- **Repeat**, **Save this prayer**, **Silent prayer**
- *"May this action be steady"* (completion)
- *"A sacred pause for everyday life"* (onboarding tagline)

## Today selection model

`TodayContextEngine` is pure and deterministic. Scoring per prayer:

| Signal | Score |
| --- | --- |
| Matches an explicitly chosen moment | +100 |
| Matches an inferred moment (time band or favourite) | +60 |
| Time contexts include the current band | +35 |
| Deity matches the user's ishta devata | +40 |
| Needs review | −100 |
| Already completed today | −50 |
| No available mode | −1000 |

`needsReview`, unreviewed, and mode-less prayers are additionally **hard-excluded**
from candidacy, so they can never surface. Ties break by featured → sortOrder →
id, for stable, reproducible output.

## V2 ideas (explicitly out of MVP)

- Curated, professionally recorded audio for Listen mode.
- A gentle, pressure-free "thread" of completed pauses (not a streak).
- Additional scripts (Tamil, Telugu, Bengali, Gujarati, etc.).
- Regional/festival-aware Today themes (with the same one-card discipline).
- Family/shared altar (one device, multiple quiet profiles).
- Apple Watch complication for a single tap-to-pause.
- Optional iCloud sync of favourites and preferences.

Every V2 idea must pass the north-star test: does it deepen *the pause*, or does
it pull toward *the session*? If the latter, it does not ship.
