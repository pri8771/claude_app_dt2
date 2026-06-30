# Anjali — Content Guidelines

Anjali presents sacred text. Getting it right is a matter of respect, not just
correctness. These rules are non-negotiable.

## The first rule: do not fabricate Sanskrit

- **Never** generate, invent, "complete", or paraphrase Sanskrit (or any
  liturgical language). AI models hallucinate plausible-looking Devanagari and
  transliteration; that is unacceptable for prayer.
- Only include mantras that are **well-known and traditionally attested**.
- Every prayer must carry an honest `sourceTitle` describing where the text
  comes from (a named scripture/verse where possible, or "traditional" when it
  is a widely-used invocation without a single canonical citation).

## Sourcing rules

1. **Prefer a precise citation.** e.g. *Ṛgveda 3.62.10 (Gāyatrī mantra)*,
   *Bṛhadāraṇyaka Upaniṣad 1.3.28*.
2. **Use "traditional" honestly.** Bija mantras and common namaḥ formulae
   (e.g. *Oṃ Namaḥ Śivāya*) may be marked as traditional with the tradition
   named (Śaiva, Bhāgavata, etc.).
3. **Do not overstate.** If you are unsure a citation is exact, describe the
   tradition rather than inventing a verse number.
4. **Transliteration uses IAST** consistently (e.g. `ṃ`, `ṛ`, `ś`, `ṣ`, `ā`).

## The review flags

Each `Prayer` carries two booleans:

- `isReviewed` — a knowledgeable human has checked the Devanagari,
  transliteration, meaning, and source. Only reviewed prayers ship to users.
- `needsReview` — set `true` for anything uncertain: a shaky source, an unusual
  spelling, a meaning that needs a second opinion, or machine-touched text
  awaiting human verification.

**The Today engine excludes any prayer with `needsReview == true` or
`isReviewed == false`.** When in doubt, set `needsReview: true` and leave
`isReviewed: false` — it simply will not appear until a human signs off.

## Meanings

- Translations should be **plain, faithful, and brief** — a sentence or two.
- Convey the sense and feeling; do not embellish with claims the text does not
  make. No promises of outcomes.

## Tone & framing

- Anjali is a quiet, dignified space. Copy is calm and non-commercial.
- No fear-based or transactional framing ("chant this or else", "guaranteed
  results").
- Respect that users come from many sampradāyas. Present mantras plainly; avoid
  sectarian claims of superiority.

## Adding a prayer (checklist)

- [ ] Text is a known, attested mantra — **not generated**.
- [ ] Devanagari verified character-by-character.
- [ ] IAST transliteration verified and consistent.
- [ ] Meaning is faithful and brief.
- [ ] `sourceTitle` is honest and as precise as the text allows.
- [ ] `durationSeconds` is realistic for an unhurried recitation (10–60s).
- [ ] `deity`, `moments`, `intentions`, `timeContexts` are accurate.
- [ ] `availableModes` reflects what truly works (omit `listen` only if you also
      want to forbid the graceful audio fallback — usually leave it in).
- [ ] `rotationPolicy` is set: `dailyAnchor` only for true daily staples
      (Gayatri, Om Shanti, a simple Ganesha invocation, the evening close);
      `occasional` for special-intention prayers; otherwise `rotateOften`.
- [ ] If anything is uncertain: `isReviewed: false`, `needsReview: true`.
- [ ] `python3 Scripts/validate_prayers.py` passes.

## Audio

- Audio is **optional and local only** in the MVP. A missing asset must degrade
  gracefully to a timed text experience — never an error.
- Any future audio must be a faithful, respectful recitation, clearly sourced.

---

## Provenance & sign-off (enforced 2026-06-30)

Every prayer carries a `provenance` block in `Anjali/Anjali/Resources/prayers.json`:

```json
"provenance": {
  "sourceReference": "Mahāmṛtyuñjaya / Tryambakam mantra (Ṛgveda 7.59.12)",
  "reviewer": "",        // set to the NAMED human who reviewed and approved this text
  "reviewedOn": ""       // set to the ISO date (YYYY-MM-DD) of that sign-off
}
```

- `sourceReference` is **required** and validated structurally (CI `validate_prayers.py`).
- A prayer is only **cleared to ship** when a *named* human sets both `reviewer` (not empty / not
  `"seed"`) and a valid `reviewedOn` date. The release gate (`validate_prayers.py --require-signoff`,
  run by `.github/workflows/release-gate.yml`) blocks release until **all** prayers are signed off.
- This makes the "named human sign-off that blocks release" rule executable rather than aspirational.
  Do not bulk-fill `reviewer` to satisfy the gate — each sign-off must represent a real review of that
  prayer's text, transliteration, translation, and attribution.
