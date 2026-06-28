# Anjali — Audio Recording Specification

This defines how recitation audio is produced for Anjali. Audio is **optional**
and **local only** in v1 — a prayer without audio falls back gracefully to a
timed text (Silent/Chant) experience. Read
[`../CONTENT_GUIDELINES.md`](../CONTENT_GUIDELINES.md) first: pronunciation must
be reviewed by a qualified reviewer **before** recording.

## Technical format

| Property | Value |
| --- | --- |
| Container / codec | **AAC in `.m4a`** |
| Sample rate | **44.1 kHz** |
| Channels | **Stereo** |
| Target loudness | **−16 LUFS** (integrated) |
| True peak | ≤ −1 dBTP |
| Duration | **10–60 seconds** (matches `durationSeconds`) |
| Leading/trailing silence | trimmed to **< 0.3 s** each side |
| Background music | **None in v1** |

## Recording guidance

- **One clean human voice per prayer.** No layering, no music bed, no reverb
  wash. A small natural room tone is fine; aim for clarity over production.
- **Pronunciation reviewed before recording** (see the content review
  checklist). Re-record rather than "fix in post" for mispronunciations.
- Even pacing — unhurried but within the duration budget.
- Edit out clicks, breaths that distract, and long gaps; keep the natural
  rhythm of the mantra.
- Normalise to the loudness target so every prayer feels level in the player.

## Optional bells

A prayer may be topped/tailed with a soft bell. Bells are **separate, shared
assets** (not baked into each recitation), so they can be reused and toggled:

- `bell_start.m4a` — a single soft strike to open.
- `bell_end.m4a` — a single soft strike to close.

Same technical format as above. Keep them short (~1–2 s) and gentle. v1 may ship
without bells; the recitation file alone is sufficient.

## File naming

| File | Meaning |
| --- | --- |
| `prayerID.m4a` | The recitation for that prayer (e.g. `ganesha-gam.m4a`). |
| `prayerID_timing.json` | *Optional* per-line timing for highlight/sync. |
| `bell_start.m4a`, `bell_end.m4a` | Shared optional bells. |

`prayerID` must exactly match the `id` in `prayers.json`. The app resolves audio
by setting that prayer's `audioAssetName` to `prayerID` and bundling the file;
`PlayerController` looks it up (m4a/mp3/caf/wav) and **falls back to timed text**
when the asset is missing — so audio can land prayer-by-prayer.

## Timing JSON schema (optional)

Used later for line-by-line highlighting. An array of line spans, in order:

```json
[
  { "line": "ॐ गं गणपतये नमः", "startSeconds": 0.0, "endSeconds": 4.2 },
  { "line": "ॐ गं गणपतये नमः", "startSeconds": 4.2, "endSeconds": 8.4 }
]
```

| Field | Type | Notes |
| --- | --- | --- |
| `line` | string | The text line (Devanagari), matching the prayer's text. |
| `startSeconds` | number | Start offset, seconds from the audio start. |
| `endSeconds` | number | End offset; must be ≥ `startSeconds`. |

Spans should be ordered and non-overlapping. The field is optional in v1; absent
timing simply means no per-line highlight.

## Pipeline placement

Recording sits in the **audio-ready** stage of the content lifecycle
([`README.md`](README.md)). Track each clip in
[`audio_manifest_template.csv`](audio_manifest_template.csv): `recording_status`,
`pronunciation_reviewer`, `edit_notes`, `approved_by`, `bundled`. Only flip
`bundled` once the asset is in the app and the prayer plays correctly with it.
