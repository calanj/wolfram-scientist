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
  returns the underlying features. *(research 2)*

Load everything with:

```wl
Get /@ FileNames["*.wl", "lib"]
```
