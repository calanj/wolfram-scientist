# Plan — additivity vs. fractal dimension in elementary CAs

**Seed (ad-hoc test run):** Among the 256 elementary cellular automata, which
produce nested/fractal patterns from a single black cell, and does additivity
(GF(2)-linearity of the local rule) predict fractality?

**Hypothesis:** Additive rules are exactly the fractal ones (a common informal
claim).

**What I'll vary / measure:**
- Enumerate additive (and affine) rules analytically.
- Measure the **mass dimension** of every rule's single-seed pattern (live cells
  in the first `s = 2^k` rows; slope of `log2 mass` vs `log2 s`).
- Cross the two: do additive ⇔ fractal?

**Interesting criteria:** a clean predictor, or a counterexample to the
additive⇔fractal claim, with dimensions verified against closed forms.

**Compute budget:** patterns to 2^10 rows; full 256-rule scan; a few minutes of
kernel time.

**Interpretation note:** "fractal" operationalized as mass dimension strictly
between 1 and 2; "Sierpinski band" = within 0.03 of log2(3).
