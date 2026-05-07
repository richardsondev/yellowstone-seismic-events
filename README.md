# yellowstone-seismic-events

History of Yellowstone and Utah area seismographic data collected by University of Utah seismograph stations using the Git scraping technique ([Simon Willison's git scraping](https://simonwillison.net/2021/Mar/5/git-scraping/)).

See more information here: https://quake.utah.edu/earthquake-center/quake-map

## Files

Every commit in this repository contains:

- **`data.json`** — canonical, normalized schema (see below). Use this for time-series queries.
- **`eventmap.json`** — raw response from the upstream `eventmap` API (preserved for consumers that need the original format).

The "fetched at" timestamp lives in the git commit metadata (`commit.author_date`), not in `data.json`. Read it with `git log --format=%aI` or via the GitHub API.

### `data.json` schema

```json
{
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

This repository's full history was rewritten on 2026-05-07 to unify three previous incompatible data layouts into the single `data.json` schema above, and to remove redundant commits where the data didn't change between scrapes.

**Before the rewrite**, the repo went through several eras:

| Era | Date Range | Source files |
|-----|------------|--------------|
| 1 | 2021-03 → 2025-07 | `stations.json`, `events-uu.json`, `events-nonuu.json` |
| 2 | 2025-07 → 2026-04 | (broken: zero-byte files) |
| 3 | 2026-04 → 2026-05 | `eventmap.json` + zero-byte stubs |
| 4 | 2026-05 → 2026-05-07 | `eventmap.json` only |

After the rewrite, every commit contains the same canonical `data.json`. Commits where the resulting `data.json` was identical to the parent (no new information) were dropped, keeping only commits with genuinely new content. All commit timestamps, authors, and messages on retained commits are preserved.

### Recovering pre-rewrite SHAs

The pre-rewrite history is preserved at the tag **`backup/pre-rewrite-2026-05-07`** which points to the original `b69895e09` commit. To browse the old format:

```bash
git fetch origin refs/tags/backup/pre-rewrite-2026-05-07
git checkout backup/pre-rewrite-2026-05-07
ls *.json   # stations.json, events-uu.json, events-nonuu.json, eventmap.json
```

The backup tag will be retained indefinitely.


## License & Attribution

This repository uses a dual-licensing structure to properly handle both the software and the dataset:

* **Code:** The scraping scripts and GitHub Actions workflows are licensed under the [MIT License](LICENSE.md).
* **Data:** The seismic datasets (`data.json` and `eventmap.json`) are licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](LICENSE.md).

### Data Source
The seismic data hosted here is generated and maintained by the University of Utah Seismograph Stations (UUSS). If you fork, redistribute, or build upon this dataset, you must include the following attribution:

> *"Data sourced from the University of Utah Seismograph Stations (UUSS). Available at: https://quake.utah.edu/"*
