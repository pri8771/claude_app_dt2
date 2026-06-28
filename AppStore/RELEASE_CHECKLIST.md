# Anjali — Pre-Submission Release Checklist

Work top to bottom before submitting to the App Store. Don't advance a stage
until its boxes are checked. Companion docs: [`../SETUP.md`](../SETUP.md) (build +
smoke tests), [`README.md`](README.md) (listing copy),
[`privacy_policy.md`](privacy_policy.md), [`app_icon_spec.md`](app_icon_spec.md),
[`../Content/`](../Content/) (content + audio pipeline).

> The authoring agent cannot compile Swift — the build/test stage **must** be run
> on a Mac.

## 1. Local build validation (macOS — required gate)

- [ ] Xcode 16+ and an iOS 17+ simulator installed.
- [ ] `./Scripts/build.sh` ends with **`** BUILD SUCCEEDED **`** and
      **`** TEST SUCCEEDED **`** (full logs in `BuildReports/`).
- [ ] No new warnings of concern in `BuildReports/build.log`.
- [ ] `python3 Scripts/validate_prayers.py` passes; CI is green on the release commit.

## 2. Smoke test completion

- [ ] The full smoke-test checklist in [`../SETUP.md`](../SETUP.md) passes on a
      **fresh** simulator: onboarding (2 screens, scrollable, skippable), reminder
      opt-in with no forced permission, the four persistence checks, Today card,
      Begin/Silent/Change, player Listen/Chant/Silent + graceful no-audio
      fallback, completion Done/Repeat/Save, Moments, Me saved prayers, deep
      links, accessibility (Dynamic Type, VoiceOver, Reduce Motion, contrast),
      force-quit relaunch, and airplane mode.

## 3. Content review sign-off

- [ ] **All 22 prayers approved** — every shipping prayer is `isReviewed: true`
      and `needsReview: false`; sources honest, no fabricated Sanskrit
      (see [`../CONTENT_GUIDELINES.md`](../CONTENT_GUIDELINES.md) and
      [`../Content/content_review_checklist.md`](../Content/content_review_checklist.md)).
- [ ] `python3 Scripts/export_catalog.py` shows no `Content/` drift.

## 4. Audio status check

- [ ] **20 hero prayers recorded** and bundled per
      [`../Content/hero_prayers.md`](../Content/hero_prayers.md) and
      [`../Content/audio_spec.md`](../Content/audio_spec.md) (AAC/m4a, −16 LUFS),
      each manifest row `approved_by` + `bundled: true`.
- [ ] The 2 text-only prayers (`vishnu-shantakaram`, `hanuman-manojavam`)
      verified to play correctly in Silent/Chant (no audio expected).
- [ ] Audio gracefully falls back where absent — no crash, no error.
      *(Note: audio is optional; the app may ship text-only and add audio later.)*

## 5. Version & build bump

- [ ] `MARKETING_VERSION` set (e.g. `1.0`).
- [ ] `CURRENT_PROJECT_VERSION` (build number) incremented — unique, higher than
      any prior upload.
- [ ] `Info.plist` `CFBundleShortVersionString` / `CFBundleVersion` agree.
- [ ] Bundle id `app.anjali.Anjali` matches the App Store Connect record.

## 6. App icon & screenshots

- [ ] Real **app icon** added (not the placeholder) per
      [`app_icon_spec.md`](app_icon_spec.md); no missing-icon warnings.
- [ ] **Screenshots** captured for all required device sizes, including the five
      time-band backgrounds (Dawn, Morning, Midday, Sunset, Night).

## 7. App Store Connect metadata review

- [ ] **Description** and **subtitle** from [`README.md`](README.md) entered
      (subtitle ≤30, description ≤4000), ending with
      "No data collected. No account required. Just you, the moment, and the prayer."
- [ ] **Keywords** entered (≤100 chars).
- [ ] **Promotional text** entered.
- [ ] **What's New** entered.
- [ ] **Categories set: Health & Fitness (primary) + Lifestyle (secondary).**
- [ ] **Age rating set: 4+** (questionnaire answered "None" throughout).
- [ ] **In-app purchases: none** — confirm no IAP/subscriptions configured;
      the app is free with no purchases.

## 8. Privacy & export compliance

- [ ] **Export compliance:** `ITSAppUsesNonExemptEncryption = NO` is in
      `Info.plist` (committed) — confirm no encryption prompt on upload.
- [ ] **App Privacy label:** Data **Not** Collected; no tracking; no third-party
      SDKs (app makes no network calls).
- [ ] **Privacy Policy URL is live** (`https://anjali.app/privacy`) and matches
      [`privacy_policy.md`](privacy_policy.md).
- [ ] **Support URL is live** (`https://anjali.app/support`).

## 9. Archive in Xcode

- [ ] Scheme **Anjali**, destination **Any iOS Device (arm64)**, Release config.
- [ ] `Product → Archive`; the Organizer validation passes with no errors.

## 10. TestFlight upload

- [ ] Distribute → App Store Connect → Upload; build processes successfully.
- [ ] Install from TestFlight on a **real device**; re-run the core path
      (launch → onboarding → Today → Begin → complete → Done) and verify deep
      links, reminders firing, and offline behavior.

## 11. Submit for review

- [ ] **Review notes draft:**
      > Anjali is an offline-first, accountless app. No login or account is
      > required and no data is collected or transmitted. All prayer content is
      > bundled and works in airplane mode. Reminders are local notifications and
      > permission is requested only if the user turns reminders on in onboarding
      > or the Me tab. There are no in-app purchases.
- [ ] Listing, screenshots, and metadata finalised; submit and monitor status.

## 12. Post-release

- [ ] Tag the release commit (`git tag v1.0 && git push --tags`).
- [ ] Record the shipped build number so the next build increments cleanly.
- [ ] Watch crash reports / feedback; triage into the next cycle.

---

### Quick commands

```bash
python3 Scripts/validate_prayers.py     # content integrity
python3 Scripts/export_catalog.py       # refresh Content/ CSVs (expect no diff)
./Scripts/build.sh                       # clean build + tests (macOS); logs -> BuildReports/
```
