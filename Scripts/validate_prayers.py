#!/usr/bin/env python3
"""Validate Anjali's seed content (resources/prayers.json).

Checks that every prayer:
  * has all required fields,
  * uses only known enum raw values (moments, intentions, timeContexts,
    deity, availableModes, rotationPolicy), matching the Swift enums,
  * has a positive duration (availableModes may be empty — Silent is always
    available via Prayer.playableModes),
  * has a unique id,
  * is honestly sourced (non-empty sourceTitle).

Run:  python3 Scripts/validate_prayers.py
Exits non-zero if any problem is found, so it can gate CI.
"""

import json
import sys
from pathlib import Path

# Keep these in lock-step with Anjali/Anjali/Models/Enums.swift.
MOMENTS = {
    "dawn", "leavingHome", "beforeWork", "meeting", "study", "travel",
    "anxiety", "gratitude", "protection", "sunset", "sleep",
}
INTENTIONS = {
    "clarity", "gratitude", "protection", "peace", "focus", "courage",
    "prosperity", "wisdom", "devotion",
}
TIME_CONTEXTS = {"dawn", "morning", "midday", "sunset", "night"}
DEITIES = {
    "ganesha", "shiva", "vishnu", "krishna", "hanuman", "devi",
    "lakshmi", "saraswati", "surya",
}
MODES = {"listen", "chant", "silent"}
ROTATION_POLICIES = {"dailyAnchor", "rotateOften", "occasional", "festivalSpecific"}

REQUIRED_FIELDS = {
    "id", "title", "deity", "moments", "intentions", "timeContexts",
    "durationSeconds", "availableModes", "primaryText", "transliteration",
    "meaning", "sourceTitle", "audioAssetName", "isReviewed", "needsReview",
    "isFeatured", "sortOrder", "rotationPolicy",
}


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    data = json.loads(path.read_text())
    if not isinstance(data, list):
        return ["Top-level JSON must be an array of prayers."]

    seen_ids: set[str] = set()
    for index, prayer in enumerate(data):
        pid = prayer.get("id", f"<index {index}>")

        missing = REQUIRED_FIELDS - prayer.keys()
        if missing:
            errors.append(f"{pid}: missing fields {sorted(missing)}")

        if pid in seen_ids:
            errors.append(f"{pid}: duplicate id")
        seen_ids.add(pid)

        for moment in prayer.get("moments", []):
            if moment not in MOMENTS:
                errors.append(f"{pid}: unknown moment '{moment}'")
        for intention in prayer.get("intentions", []):
            if intention not in INTENTIONS:
                errors.append(f"{pid}: unknown intention '{intention}'")
        for tc in prayer.get("timeContexts", []):
            if tc not in TIME_CONTEXTS:
                errors.append(f"{pid}: unknown timeContext '{tc}'")
        for mode in prayer.get("availableModes", []):
            if mode not in MODES:
                errors.append(f"{pid}: unknown mode '{mode}'")

        deity = prayer.get("deity")
        if deity is not None and deity not in DEITIES:
            errors.append(f"{pid}: unknown deity '{deity}'")

        policy = prayer.get("rotationPolicy")
        if policy not in ROTATION_POLICIES:
            errors.append(f"{pid}: invalid rotationPolicy '{policy}'")

        if prayer.get("durationSeconds", 0) <= 0:
            errors.append(f"{pid}: durationSeconds must be > 0")
        # availableModes may be empty (Silent is always available via
        # Prayer.playableModes) — only the listed values are validated, above.
        if not (prayer.get("sourceTitle") or "").strip():
            errors.append(f"{pid}: sourceTitle must not be empty")
        if not (prayer.get("primaryText", {}).get("devanagari") or "").strip():
            errors.append(f"{pid}: primaryText.devanagari must not be empty")

    return errors


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    path = root / "Anjali" / "Anjali" / "Resources" / "prayers.json"
    if not path.exists():
        print(f"ERROR: {path} not found", file=sys.stderr)
        return 2

    errors = validate(path)
    if errors:
        print(f"FAILED: {len(errors)} problem(s) in {path.name}:")
        for err in errors:
            print(f"  - {err}")
        return 1

    data = json.loads(path.read_text())
    count = len(data)
    no_modes = [p.get("id", "?") for p in data if not p.get("availableModes")]
    print(f"OK: {count} prayers valid in {path.name}")
    if no_modes:
        print(f"  note: {len(no_modes)} with no explicit modes "
              f"(Silent fallback): {', '.join(no_modes)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
