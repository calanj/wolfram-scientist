# Data sources — curated whitelist for empirical studies

The Scientist's empirical studies pull data from **outside** Wolfram's curated
knowledge base. This file is the **whitelist**: a short list of clean, stable,
programmatically-accessible sources with known schemas. Acquisition is **hybrid**:

- **Whitelist** — when a request names one of the sources below, use the
  documented base endpoint and query shape. High hit-rate, known schema.
- **Discovery** — the Scientist may use a source *not* on this list (an issue
  links a dataset, or an open-ended study needs one). That's allowed; tag its
  provenance `"discovery"`.

**Every** external pull — whitelist or discovery — goes through
`lib/dataProvenance.wl` (`dataFetch` / `dataLoad`), so it is cached, SHA-256
fingerprinted, and recorded in `research/<id>/inputs/manifest.json`. Never
`Import` a remote URL directly in an experiment; you lose reproducibility.

When a discovery source proves clean and reusable, **promote it**: add an entry
here in the same run that used it (that's the "vetted once, then added" half of
the hybrid policy). The whitelist grows the way `lib/` does.

## Why these are gridable

Each source below is keyless or trivially keyed, returns CSV/JSON/GeoJSON that
`Import` handles, is large enough for a statistical claim, and exposes a
textbook empirical regularity with built-in **refutation axes** (re-test on a
different region / window / catalog). That last property is what makes the
rigor loop have teeth — see `CLAUDE.md`.

## Whitelist

### USGS Earthquake Catalog — seismology *(no key)*
- **Good for:** Gutenberg–Richter b-value, Omori aftershock decay, Bååth's law,
  magnitude/depth distributions.
- **Base:** `https://earthquake.usgs.gov/fdsnws/event/1/query`
- **Example:** `...query?format=csv&starttime=2024-01-01&endtime=2024-02-01&minmagnitude=2.5`
- **Format:** CSV (also GeoJSON). **Refutation axes:** region (`minlatitude`…),
  time window, magnitude cutoff, independent catalog.
- **Gotchas:** result count is capped (~20k rows); narrow the window or bbox for
  complete catalogs rather than truncating.

### FRED — macroeconomics & finance *(free API key)*
- **Good for:** cross-series scaling, lead/lag, regime breaks, volatility.
- **Base:** `https://api.stlouisfed.org/fred/series/observations`
- **Example:** `...observations?series_id=GDPC1&file_type=json&api_key=KEY`
- **Format:** JSON. **Refutation axes:** different series, sub-periods, frequency.
- **Gotchas:** needs a free `api_key`; pass it via an env var, never hard-code it.

### World Bank Open Data — country panel *(no key)*
- **Good for:** urban scaling, convergence, Kuznets-type relations, allometry.
- **Base:** `https://api.worldbank.org/v2/country/all/indicator/<CODE>`
- **Example:** `.../SP.POP.TOTL?format=json&per_page=20000`
- **Format:** JSON (paginated). **Refutation axes:** indicator, year, region subset.
- **Gotchas:** page 1 of the JSON is metadata; data is in page 2 of the envelope.

### GBIF — biodiversity occurrences *(no key for search/count)*
- **Good for:** species–area relations, range-size distributions, Taylor's law.
- **Base:** `https://api.gbif.org/v1/occurrence/search`
- **Example:** `.../search?taxonKey=212&country=US&limit=300`
- **Format:** JSON. **Refutation axes:** taxon, country, time slice.
- **Gotchas:** `limit`+`offset` paging caps at 100k via search; bulk needs the
  download API (async, keyed). For occurrence *counts* use `/occurrence/count`.

### Open-Meteo — weather & climate *(no key)*
- **Good for:** extreme-value distributions, trend detection, spatial correlation.
- **Base (archive):** `https://archive-api.open-meteo.com/v1/archive`
- **Example:** `...archive?latitude=40.1&longitude=-88.2&start_date=2000-01-01&end_date=2020-12-31&daily=temperature_2m_max`
- **Format:** JSON. **Refutation axes:** location, variable, period.
- **Gotchas:** request only the variables you need; payloads grow fast (→ likely
  hash-large).

### OpenAlex — scholarly metadata *(no key; polite pool via mailto)*
- **Good for:** citation distributions, collaboration-network scaling, Lotka's law.
- **Base:** `https://api.openalex.org/works`
- **Example:** `.../works?filter=publication_year:2020&per-page=200&mailto=you@example.com`
- **Format:** JSON (cursor-paginated). **Refutation axes:** field, year, venue.
- **Gotchas:** add `mailto=` for the faster polite pool; use `cursor=*` paging.

### openFDA — drug/device/food safety *(no key; higher limits with one)*
- **Good for:** adverse-event distributions, Benford tests on report counts.
- **Base:** `https://api.fda.gov/`  (see the `openfda-database` skill)
- **Format:** JSON. **Refutation axes:** endpoint, date range, product class.
- **Gotchas:** 1000-record page cap; `count=` aggregations avoid bulk paging.

## Discovery sources

Allowed for issue-linked datasets, GitHub issue attachments
(`https://github.com/user-attachments/...`), and open-ended studies. Tag them
`"Source" -> "discovery"`. Same provenance discipline applies. If one earns its
keep, add it to the whitelist above in the same PR.
