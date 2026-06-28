# lib/ — accreted Wolfram Language assets

Reusable functions the Scientist factors out of its experiments. Each `.wl` file
should define one focused, documented function with a runnable usage example, so
future runs (and humans) can reuse it instead of re-deriving it. This directory
growing — and being *used* by later runs — is the concrete, measurable form of
the Scientist's "self-improvement".

## Assets

- **`massDimension.wl`** — `massDimension[rule, K]`: single-seed mass (cluster)
  dimension of a 1-D CA pattern (slope of log₂ live-cells vs log₂ rows over 2^K
  rows). log₂3 to ~14 digits on rule 90. *(research 1)*
- **`wolframClass.wl`** — `wolframClass[rule] -> 1|2|3|4`: a reproducible,
  in-kernel *operational* classifier for the Wolfram class of an ECA, from
  damage-spreading under a 1-cell perturbation of a random IC. Validated 27/27 on
  literature-consensus anchors. Class 3 vs 4 is not auto-separable; the canonical
  class-4 set {110,124,137,193} is an explicit override. `wolframClassData[rule]`
  returns the underlying features. *(mass-dimension-wolfram-class)*
- **`ulam.wl`** — `ulamSequence[n]` / `ulamSequence[{a,b}, n]`: counter-based
  (Gibbs-style) sieve for the Ulam sequence A002858 (default `(a,b)=(1,2)`) and
  its (a,b)-variants. ~7 s for 100,000 terms of A002858 on a single core;
  cost roughly linear in the largest term reached. *(research
  ulam-hidden-periodicity)*
- **`dataProvenance.wl`** — `dataFetch[url, dir]` / `dataLoad[dir, key]` /
  `dataInputsDir[id]`: provenance-tracked acquisition of **external** data (data
  from outside Wolfram's curated knowledge base). Caches each pull under
  `research/<id>/inputs/`, SHA-256 fingerprints it, records URL + shape + fetch
  time in `manifest.json`, and enforces "commit small, hash large" by
  regenerating the inputs `.gitignore`. `dataFetch` is idempotent (re-runs skip
  the download when the cache matches), so `experiment.wl` stays reproducible
  offline. Shared by issue-fed data sources and open-ended empirical studies;
  see `data-sources.md` for the source whitelist. *(infra)*

This directory also holds **`data-sources.md`** — the curated whitelist of clean
external data sources (USGS, FRED, World Bank, GBIF, Open-Meteo, OpenAlex,
openFDA, …) with base endpoints, example queries, and refutation axes.

Load everything with:

```wl
Get /@ FileNames["*.wl", "lib"]
```
