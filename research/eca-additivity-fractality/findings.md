# Findings — additivity vs. fractal dimension in elementary CAs

**TL;DR.** Additivity does **not** predict fractality in either direction. The 8
additive rules spread across four different dimensions, and eight *non-additive*
rules hit the Sierpinski dimension log₂3. Most of those are explained away (they
collapse onto rule 90 on the single-seed orbit) — but **rule 22 is a genuine
outlier**: non-additive, not orbit-equivalent to rule 90, yet with live-cell
count exactly 3ᵏ and dimension log₂3.

## Method

Mass dimension from a single seed: count live cells in the first `s = 2^k` rows
and take the slope of `log₂(mass)` vs `log₂(s)`. Validated against closed forms —
rule 90 → **1.5849625007211554** vs log₂3 = **1.5849625007211563** (agree to ~14
digits); identity rule 204 → 1.0; null rule 0 → 0.0. Full script: `experiment.wl`
(reproduces every number below from a fresh kernel).

## Results

**Additive rules** `{0, 60, 90, 102, 150, 170, 204, 240}` (the GF(2)-linear local
functions) have **four** distinct dimensions — so additivity alone fixes nothing:

| dimension | additive rules |
|---|---|
| 0 (dies out) | 0 |
| 1 (a line: shift/identity) | 170, 204, 240 |
| log₂3 ≈ 1.585 (Sierpinski) | 60, 90, 102 |
| ≈ 1.696 | 150 |

**Non-additive rules at the Sierpinski dimension.** Eight rules *outside* the
additive set measure dim = log₂3 to machine precision:
`{18, 22, 26, 82, 146, 154, 210, 218}`. So **additive ⇎ fractal** — the converse
of the hypothesis fails eight times over.

## Refutation (why those eight?) — *this is the interesting part*

Following the "find the trivial explanation" rule:

1. **The dimension is exact, not approximate.** The live-cell count is *exactly*
   `3^k` (e.g. rule 18: `{3,9,27,81,243,729,2187,6561}`), and the estimate is
   stable across resolution `K = 6…10`. Not a fitting artifact.
2. **Seven of the eight collapse onto rule 90.** From a single seed the patterns
   of `{18, 26, 82, 146, 154, 210, 218}` are **bit-identical** to rule 90's:
   their nonlinearity is never excited on this orbit, so they *are* rule 90 here.
   That's the trivial explanation — and it disqualifies them as independent
   examples.
3. **Rule 22 survives.** Its pattern is **not** identical to rule 90's, yet it
   still has exact mass `3^k` and dimension log₂3.

## Epistemic status

- **Verified:** the mass-dimension method (≈14-digit agreement on rule 90); the
  additive-rule dimension table; that 7 of the 8 non-additive Sierpinski rules
  are orbit-identical to rule 90 (exact pattern equality to 64 rows).
- **Conjecture (tested to 2¹⁰ rows):** rule 22 has dimension *exactly* log₂3 with
  live-cell count *exactly* 3ᵏ, despite not reducing to rule 90. Empirically
  exact in this range; **not proven**.
- **Speculation:** rule 22's 3ᵏ count has an algebraic explanation (a
  rule-90 sublattice/substitution-system embedding) distinct from the orbit
  collapse. Worth a follow-up.

## Limitations

Single-seed initial condition only; mass dimension (not box-counting); search
bound 2¹⁰ rows. "Fractal" is operationalized as dimension in (1,2); this conflates
self-similar with chaotic space-filling for some rules (e.g. rule 30 ≈ 1.91),
which were not the focus here.

## Open questions / next runs

- Prove rule 22's `3^k` count (substitution system / sublattice argument).
- Repeat with random and periodic initial conditions — does the additive vs.
  non-additive distinction reappear once nonlinearity is excited?
- Sweep dimension vs. Wolfram class for all 256 rules; is dimension a class proxy?
