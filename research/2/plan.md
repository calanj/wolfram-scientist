# Plan — Is single-seed mass dimension a proxy for Wolfram class? (id 2)

## Question
Across all 256 elementary cellular automata (ECAs), measure the **single-seed
mass dimension** D (live cells in the first 2^k rows, slope of log2 mass vs
log2 size; `lib/massDimension.wl`). Assign each rule a **Wolfram class** (1–4).
Test how well D separates the classes: cleanest separators, overlap regions,
outliers. Conclude whether D *alone* is a usable classifier.

## Interpretation / key tension (stated up front)
- **Mass dimension is a single-seed quantity.** Wolfram class is canonically the
  *typical* behavior from **random** initial conditions. These need not agree:
  a rule that is chaotic on random ICs can die or go periodic from one seed
  (and vice-versa). The mismatch is itself part of the expected story.
- There is no undisputed built-in per-rule "Wolfram class" table. I will assign
  classes with a **reproducible, in-kernel behavioral classifier** computed from
  random ICs, **validated against ~15 consensus anchor rules** from the
  literature, and treat the canonical class-4 set {110,124,137,193} as a known
  override. Class labels are therefore an explicit **proxy (Conjecture-level)**,
  not ground truth — epistemics labelled throughout.

## What I will vary / measure
- **D** = `massDimension[rule, 10]` for all 256 rules (single seed, 2^10 rows).
- **Behavioral class** per rule from random ICs (W=400 lattice, T steps):
  - *death/uniformity* → Class 1
  - *spreading velocity v* (damage-cone half-width growth slope under a 1-cell
    perturbation) ≈ 0 + non-uniform → Class 2
  - v > 0 + high spatial disorder → Class 3
  - class-4 override set {110,124,137,193}
- Cross-tabulate D vs class. Report per-class D distributions, threshold/band
  separators, overlaps, and named outliers (class-3 rules with low D, class-1/2
  rules with high D).

## What would count as interesting
- A clean D threshold or small set of bands separating classes, **or**
- A clean negative result: D cannot distinguish class 3 from class 4 (or, more
  strongly, single-seed D is blind to class for the many rules that don't
  excite from one seed).
- Named outlier rules that defy the trend.

## Refutation plan
- Anchor-validate the classifier; report disagreements honestly.
- Check D stability vs K (2^9 vs 2^10 rows) for borderline rules.
- Re-derive D from the orbit's own seed (single black cell) and confirm trivial
  cases (D∈{0,1}) really are dynamically trivial, not artifacts.
- Look for the trivial explanation: how much of any D–class correlation is just
  "single seed dies → D≈0/1" rather than D measuring chaos.

## Compute budget
Patterns to 2^10 rows; full 256-rule sweep; random-IC classifier W=400.
Target a few minutes of kernel time; wrap heavy steps in TimeConstrained.
