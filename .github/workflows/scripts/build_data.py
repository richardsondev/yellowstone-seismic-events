#!/usr/bin/env python3
"""
Build canonical data.json from a freshly-fetched eventmap.json.

Used by the scrape-events.yml workflow to produce the unified schema.

Usage:
    build_data.py <eventmap.json> <data.json>

Schema (data.json):
{
  "events": [...],
  "stations": []   // empty: stations endpoint discontinued by upstream API
}

Note: timestamp is preserved in the git commit metadata; consumers can
read it via `git log` or the GitHub API. No fetchedAt field needed.
"""
import json
import sys


def safe_float(v):
    if v is None:
        return None
    try:
        return float(v)
    except (ValueError, TypeError):
        return None


def safe_str(v):
    if v is None:
        return None
    s = str(v).strip()
    return s if s else None


def normalize_event(e):
    return {
        "identifier": safe_str(e.get("identifier")),
        "authority": (safe_str(e.get("authority")) or "").upper() or None,
        "eventType": safe_str(e.get("eventType")),
        "originTimeUtc": safe_float(e.get("originTimeUTC")),
        "latitudeDeg": safe_float(e.get("latitudeDeg")),
        "longitudeDeg": safe_float(e.get("longitudeDeg")),
        "depthKm": safe_float(e.get("depthKM")),
        "magnitude": safe_float(e.get("magnitude")),
        "isLocal": e.get("isLocal") if isinstance(e.get("isLocal"), bool) else None,
        "nearestTown": safe_str(e.get("nearestTown")),
        "version": None,
    }


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <eventmap.json> <data.json>", file=sys.stderr)
        sys.exit(2)

    src_path, dst_path = sys.argv[1], sys.argv[2]

    with open(src_path) as f:
        src = json.load(f)

    if not isinstance(src, dict) or src.get("status") != 200:
        print(f"eventmap.json status != 200: {src.get('status')}", file=sys.stderr)
        sys.exit(1)

    raw_events = (src.get("data") or {}).get("events") or []
    seen = set()
    events = []
    for e in raw_events:
        if not isinstance(e, dict):
            continue
        ev = normalize_event(e)
        if ev["identifier"] and ev["identifier"] not in seen:
            seen.add(ev["identifier"])
            events.append(ev)

    out = {
        "events": events,
        "stations": [],
    }

    with open(dst_path, "w") as f:
        json.dump(out, f, indent=2, sort_keys=False)
        f.write("\n")

    print(f"Wrote {dst_path}: {len(events)} events", file=sys.stderr)


if __name__ == "__main__":
    main()
