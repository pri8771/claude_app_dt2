# Prayer Content Review Checklist

Work through this before changing a prayer's `review_status` to `reviewed`, and
again before it is `approved_for_release` (bundled). The guiding rule from
[`../CONTENT_GUIDELINES.md`](../CONTENT_GUIDELINES.md): **never fabricate
Sanskrit.** If anything is uncertain, leave `needs_review = true` and do not
bundle.

## 1. Source verification
- [ ] The mantra is a **well-known, attested** text — not generated or invented.
- [ ] `source_title` names a precise citation where possible (e.g. *Ṛgveda
      3.62.10*), or honestly says "traditional" with the tradition named
      (Śaiva, Bhāgavata, etc.).
- [ ] `source_note` captures anything a reader should know (alternate
      attributions, scope of the excerpt).
- [ ] No claim of guaranteed outcomes or sectarian superiority.

## 2. Sanskrit & transliteration
- [ ] Devanagari (`primary_text`) verified character-by-character against a
      trusted source.
- [ ] Transliteration is **IAST** and consistent (`ṃ`, `ṛ`, `ś`, `ṣ`, `ā`, …).
- [ ] Line breaks / daṇḍa (`।`, `॥`) match the source.
- [ ] `short_title` reads cleanly and isn't misleading.

## 3. Meaning
- [ ] Translation is faithful, plain, and brief (a sentence or two).
- [ ] No embellishment or claims the text does not make.

## 4. Classification
- [ ] `deity` is correct (or blank for a universal mantra).
- [ ] `moments`, `intentions`, `time_contexts` are accurate and use valid enum
      values.
- [ ] `rotation_policy` is appropriate — `dailyAnchor` only for true daily
      staples; `occasional` for special-intention prayers; otherwise
      `rotateOften`.
- [ ] `duration_seconds` is realistic for an unhurried recitation (10–60s);
      set `timing_status = measured` once timed against audio.

## 5. Regional variants
- [ ] `regional_note` records meaningful regional/sampradāya differences in
      wording or pronunciation, where they exist.
- [ ] The chosen form is a widely-accepted one; alternatives are noted, not
      silently dropped.

## 6. Audio (only if a recording exists)
- [ ] Clip tracked in `audio_manifest_template.csv` with a `recording_status`.
- [ ] Pronunciation reviewed by a qualified `pronunciation_reviewer`.
- [ ] Audio is clean: no clipping, even levels, minimal noise, natural pacing.
- [ ] `duration_seconds` re-measured against the clip.
- [ ] `approved_by` set; `bundled` flipped only when the asset is in the app.
- [ ] App still works with the audio **removed** (graceful Silent fallback).

## 7. Final approval
- [ ] `review_status = reviewed`, `needs_review = false`, `reviewer_name` set.
- [ ] Row is internally consistent (no enum typos, no empty required fields).
- [ ] After bundling into `prayers.json`:
      `python3 Scripts/validate_prayers.py` passes.
- [ ] Spot-checked in the app (Today card + full-screen player) on device.
