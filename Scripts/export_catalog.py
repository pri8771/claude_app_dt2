#!/usr/bin/env python3
"""Export the bundled prayers.json into the Content/ CSV pipeline format.

Writes:
  * Content/prayer_catalog_template.csv  (headers only)
  * Content/prayer_catalog_seed.csv      (all current prayers)
  * Content/audio_manifest_template.csv  (headers only)

The seed CSV is the single source of truth editors expand. Run:
    python3 Scripts/export_catalog.py
"""

import csv
import json
import re
from pathlib import Path

CATALOG_HEADERS = [
    "id", "title", "short_title", "deity", "moments", "intentions",
    "time_contexts", "duration_seconds", "rotation_policy", "available_modes",
    "primary_script", "primary_text", "transliteration", "meaning",
    "source_title", "source_note", "regional_note", "reviewer_name",
    "review_status", "needs_review", "audio_status", "audio_asset_name",
    "timing_status", "tags", "sort_order",
]

AUDIO_HEADERS = [
    "prayer_id", "audio_asset_name", "duration_seconds", "recording_status",
    "pronunciation_reviewer", "edit_notes", "approved_by", "bundled",
]

MULTI = ";"  # multi-value separator inside a single CSV cell


def short_title(title: str) -> str:
    """Trim the common 'Om … Namah' wrapper to a compact label."""
    s = re.sub(r"^(O[mṃ])\s+", "", title)
    s = re.sub(r"\s+(Namah|Namaḥ)$", "", s)
    return s.strip() or title


def row_for(prayer: dict) -> dict:
    return {
        "id": prayer["id"],
        "title": prayer["title"],
        "short_title": short_title(prayer["title"]),
        "deity": prayer.get("deity") or "",
        "moments": MULTI.join(prayer.get("moments", [])),
        "intentions": MULTI.join(prayer.get("intentions", [])),
        "time_contexts": MULTI.join(prayer.get("timeContexts", [])),
        "duration_seconds": prayer.get("durationSeconds", ""),
        "rotation_policy": prayer.get("rotationPolicy", ""),
        "available_modes": MULTI.join(prayer.get("availableModes", [])),
        "primary_script": "devanagari",
        "primary_text": prayer.get("primaryText", {}).get("devanagari", ""),
        "transliteration": prayer.get("transliteration", ""),
        "meaning": prayer.get("meaning", ""),
        "source_title": prayer.get("sourceTitle", ""),
        "source_note": "",
        "regional_note": "",
        "reviewer_name": "seed",
        "review_status": "reviewed" if prayer.get("isReviewed") else "draft",
        "needs_review": str(prayer.get("needsReview", False)).lower(),
        "audio_status": "recorded" if prayer.get("audioAssetName") else "none",
        "audio_asset_name": prayer.get("audioAssetName") or "",
        "timing_status": "estimated",
        "tags": "",
        "sort_order": prayer.get("sortOrder", ""),
    }


def write_csv(path: Path, headers: list[str], rows: list[dict]) -> None:
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    prayers = json.loads(
        (root / "Anjali" / "Anjali" / "Resources" / "prayers.json").read_text()
    )
    content = root / "Content"
    content.mkdir(exist_ok=True)

    write_csv(content / "prayer_catalog_template.csv", CATALOG_HEADERS, [])
    write_csv(content / "prayer_catalog_seed.csv", CATALOG_HEADERS,
              [row_for(p) for p in prayers])
    write_csv(content / "audio_manifest_template.csv", AUDIO_HEADERS, [])

    print(f"Exported {len(prayers)} prayers to Content/prayer_catalog_seed.csv")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
