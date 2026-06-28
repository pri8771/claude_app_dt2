# Anjali — Release Checklist

A step-by-step gate for shipping a build to TestFlight and the App Store. Run
top to bottom; do not advance a stage until its boxes are checked. Cross-links:
[`SETUP.md`](SETUP.md) (build + smoke tests), [`AppStore/`](AppStore/)
(listing/privacy/icon), [`Content/`](Content/) (content + audio pipeline).

---

## 0. Pre-flight (anytime)

- [ ] On a clean checkout of `main`.
- [ ] `python3 Scripts/validate_prayers.py` passes.
- [ ] `python3 Scripts/export_catalog.py` produces no `Content/` diff.
- [ ] CI (GitHub Actions content-validation) is green on the commit being shipped.

## 1. Code & content freeze

- [ ] All intended changes merged to `main`; no WIP on the release commit.
- [ ] `STATIC_AUDIT.md` reviewed; no open compile-blocking items.
- [ ] Content sign-off: every shipping prayer is `isReviewed: true` /
      `needsReview: false`; sources honest (see
      [`CONTENT_GUIDELINES.md`](CONTENT_GUIDELINES.md) and
      [`Content/content_review_checklist.md`](Content/content_review_checklist.md)).
- [ ] Any bundled audio passed [`Content/audio_spec.md`](Content/audio_spec.md)
      and its manifest row is `approved_by` + `bundled: true`. (Audio is
      optional — text-only prayers are fine.)

## 2. Build & test (macOS — required gate)

> The authoring agent cannot compile Swift; this stage must run on a Mac.

- [ ] Xcode 16+ and an iOS 17+ simulator installed.
- [ ] `./Scripts/build.sh` ends with **`** BUILD SUCCEEDED **`** and
      **`** TEST SUCCEEDED **`** (logs in `BuildReports/`).
- [ ] No new warnings of concern in `BuildReports/build.log`.
- [ ] Full **smoke test checklist** in [`SETUP.md`](SETUP.md) passes on a fresh
      simulator (onboarding, reminder opt-in, persistence ×4, Today/player,
      completion Done/Repeat/Save, Moments, Me, deep links, accessibility,
      force-quit relaunch, airplane mode).

## 3. Assets & metadata

- [ ] **App icon** added (not the placeholder) per
      [`AppStore/app_icon_spec.md`](AppStore/app_icon_spec.md); no
      missing-icon warnings.
- [ ] Screenshots captured for required device sizes, including the five
      time-band backgrounds.
- [ ] App Store listing fields filled from [`AppStore/README.md`](AppStore/README.md)
      (name, subtitle ≤30, description ≤4000, keywords ≤100, category, URLs).
- [ ] **Support** and **Privacy Policy** URLs are live and reachable
      (`/support`, `/privacy`); privacy page matches
      [`AppStore/privacy_policy.md`](AppStore/privacy_policy.md).

## 4. Version & identifiers

- [ ] `MARKETING_VERSION` (e.g. `1.0`) set in project build settings.
- [ ] `CURRENT_PROJECT_VERSION` (build number) bumped — unique and higher than
      any previous upload.
- [ ] `CFBundleShortVersionString` / `CFBundleVersion` in `Info.plist` agree
      with the above.
- [ ] Bundle id `app.anjali.Anjali` matches the App Store Connect app record.

## 5. Compliance answers (pre-answered / verify)

- [ ] **Export compliance:** `ITSAppUsesNonExemptEncryption = NO` is in
      `Info.plist` (already committed) — confirm no encryption prompt on upload.
- [ ] **App Privacy ("nutrition label"):** **Data Not Collected**, no tracking,
      no third-party SDKs (the app makes no network calls).
- [ ] **Age rating:** complete the questionnaire → expected **4+** (answer
      "None" throughout).
- [ ] **Content rights:** prayers are traditional/attributed; no third-party
      assets requiring license.

## 6. Archive & upload

- [ ] Select **Any iOS Device (arm64)**; `Product → Archive` (Release config).
- [ ] Validate the archive in the Organizer (no validation errors).
- [ ] Distribute → App Store Connect → Upload.
- [ ] Build appears in App Store Connect and finishes processing.

## 7. TestFlight

- [ ] Build assigned to internal testers; export-compliance shows resolved.
- [ ] Install from TestFlight on a **real device**; re-run the core smoke path
      (launch → onboarding → Today → Begin → complete → Done).
- [ ] Verify on device: deep links open the app, reminders fire at the set time,
      offline/airplane-mode works, no crash on first launch.

## 8. Submit for review

- [ ] Listing, screenshots, and "What's New" finalised.
- [ ] **App Review notes:** state it's an offline, accountless app; no login
      needed; reminders are local-only and permission is requested only if the
      user enables them.
- [ ] Submit. Monitor status; be ready to answer reviewer questions.

## 9. Post-release

- [ ] Tag the release commit (e.g. `git tag v1.0 && git push --tags`).
- [ ] Record the build number shipped so the next build increments cleanly.
- [ ] Watch for crash reports / feedback; triage into the next cycle.

---

### Quick command reference

```bash
python3 Scripts/validate_prayers.py     # content integrity
python3 Scripts/export_catalog.py       # refresh Content/ CSVs (expect no diff)
./Scripts/build.sh                       # clean build + tests (macOS); logs in BuildReports/
```
