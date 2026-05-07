# yellowstone-seismic-events

History of Yellowstone and Utah area seismographic data collected by University of Utah seismograph stations using the Git scraping technique ([Simon Willison's git scraping](https://simonwillison.net/2021/Mar/5/git-scraping/)).

See more information here: https://quake.utah.edu/earthquake-center/quake-map

## Files

Every commit in this repository contains:

- **`data.json`** — canonical, normalized schema (see below). Use this for time-series queries.
- **`eventmap.json`** — raw response from the upstream `eventmap` API (preserved for consumers that need the original format).

### `data.json` schema (`schemaVersion: 2`)

```json
{
  "schemaVersion": 2,
  "fetchedAt": "2026-05-07T09:12:45.848772Z",
  "events": [
    {
      "identifier": "mb90135653",
      "authority": "MB",
      "eventType": "eq",
      "originTimeUtc": 1777632041.25,
      "latitudeDeg": 44.7426666666667,
      "longitudeDeg": -111.128333333333,
      "depthKm": 7.15,
      "magnitude": -0.37,
      "isLocal": false,
      "nearestTown": null,
      "version": null
    }
  ],
  "stations": [
    {
      "sta": "YEE",
      "name": "East Entrance, YNP, WY, USA",
      "authority": "WY",
      "latitudeDeg": 44.49,
      "longitudeDeg": -109.90,
      "elevationM": 2270.0,
      "stationCode": "Broadband",
      "description": "instrument"
    }
  ]
}
```

`stations` is empty in commits after July 2025 because the upstream stations endpoint was discontinued. Historical station data (321-327 entries) is preserved in earlier commits.

## History rewrite (2026-05-07)

This repository's full ~32k-commit history was rewritten on 2026-05-07 to unify three previous incompatible data layouts into the single `data.json` schema above.

**Before the rewrite**, the repo went through several eras:

| Era | Date Range | Source files |
|-----|------------|--------------|
| 1 | 2021-03 → 2025-07 | `stations.json`, `events-uu.json`, `events-nonuu.json` |
| 2 | 2025-07 → 2026-04 | (broken: zero-byte files) |
| 3 | 2026-04 → 2026-05 | `eventmap.json` + zero-byte stubs |
| 4 | 2026-05 → 2026-05-07 | `eventmap.json` only |

After the rewrite, every commit contains the same canonical `data.json`. Truly empty commits (~2,350 from the broken 2025-2026 period) were dropped. All commit timestamps, authors, and messages are preserved.

### Recovering pre-rewrite SHAs

The pre-rewrite history is preserved at the tag **`backup/pre-rewrite-2026-05-07`** which points to the original `b69895e09` commit. To browse the old format:

```bash
git fetch origin refs/tags/backup/pre-rewrite-2026-05-07
git checkout backup/pre-rewrite-2026-05-07
ls *.json   # stations.json, events-uu.json, events-nonuu.json, eventmap.json
```

The backup tag will be retained indefinitely.
