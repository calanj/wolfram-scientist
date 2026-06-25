# Plan — Ulam hidden periodicity

## Question

Steinerberger (arXiv:1507.00267, 2015) reported a striking empirical rigidity in
the Ulam sequence A002858 (a_1=1, a_2=2; each term the smallest integer > prev
expressible as a sum of two distinct earlier terms in *exactly one* way):

> There exists α ≈ 2.5714474995… such that {α·a_n mod 2π} is supported on a
> non-uniform absolutely-continuous measure, with the explicit consequence
> cos(α·a_n) < 0 for all a_n in the first 10^7 except {2, 3, 47, 69}.

Three sub-questions:

1. **Replicate.** Within our compute budget, does the Fourier sum
   f_N(x) = Σ cos(x·a_n) really have a single non-trivial minimum near
   x ≈ 2.5714 with value ≈ -0.8 N, growing linearly in N? Does the exceptional
   set {2, 3, 47, 69} match exactly?
2. **Precision/stability.** How well can we pin α from a moderate N (~10^5)?
   How does α(N) drift with N? Compare to McCranie's reported bounds
   2.57144749846 < α < 2.57144749850.
3. **Specificity.** Is this an artifact of *any* sparse increasing sequence, or
   genuinely a feature of the Ulam construction?
   - Other "erratic" Ulam-type (a,b) sequences (the paper reports
     α_(1,3)≈2.83349751, α_(1,4)≈0.506013502, α_(2,3)≈1.16501287) — do we
     reproduce a clear α and a similar non-uniform distribution?
   - Density-matched **random sparse increasing sequences** — these should
     give |f_N|/N → 0 like 1/√N, NOT a linear signal. This is the key
     specificity test.
   - A "periodic-differences" Ulam variant (e.g. (a,b)=(2,5)) where the
     sequence is eventually arithmetic — that *should* trivially have peaks
     at rational multiples of 2π; presence of such a peak there shouldn't
     count as the same phenomenon.

## What we vary / measure

- N ∈ {10^3, 3·10^3, 10^4, 3·10^4, 10^5}: convergence of α(N) and of
  min_x f_N(x)/N.
- Sequences: A002858; Ulam(1,3), Ulam(1,4), Ulam(2,3); 100 random sparse
  increasing sequences matched to the empirical density 0.0739 of A002858 at
  the chosen N; Ulam(2,5) as a positive control for trivial periodicity.
- For each sequence: f_N on a fine grid; refine the minimum by golden-section
  / FindMinimum to ~10 digits; tabulate the exceptional set
  {a_n : cos(α·a_n) ≥ 0}.

## What counts as "interesting"

Pre-registered criteria, all must hold for the headline to stand:

- (R1) Headline α value computed in-kernel agrees with McCranie's interval
  2.57144749846 < α < 2.57144749850 to within our N-limited uncertainty.
- (R2) min_x f_N(x)/N stabilises to a value clearly below -0.5 as N grows —
  i.e. NOT shrinking like 1/√N (which would refute the linear-in-N claim).
- (R3) Exceptional set for our largest N is consistent with (subset of)
  {2, 3, 47, 69}; if we find additional exceptions, report them by name.
- (R4) For the 100 density-matched random sparse sequences, the analogous
  min_x f_N(x)/N is consistent with the random-sums baseline of order
  N^{-1/2} (a Z-score). Specifically: the Ulam value should be many sigma
  beyond the random-sequence distribution.
- (R5) At least one *other* erratic Ulam-type (a,b) shows a comparable
  signal at the paper's reported frequency.

If all five hold, the finding is **verified** within our compute window. If any
fail, label and report which.

## Compute budget

- Ulam generation: aim for N = 10^5 terms of A002858 (last term ≈ 1.35·10^6).
  Use a counter-based sieve so generation is roughly linear in the max element.
  Target: ≤ ~60s.
- Fourier grid scan: coarse grid 10^4 points on [0, π], refine top dip with
  FindMinimum. Cost ~ N · 10^4 ≈ 10^9 ops; doable with Compile/vector ops in
  ~ tens of seconds. Restrict to [2, π] for the headline scan once we know
  where the dip is.
- Total wall clock target: under ~20 min including refutation.

## Interpretation when ambiguous

We will treat "the hidden signal exists" as a *quantitative* claim
(min_x f_N(x)/N is bounded below 0 uniformly in N, located near 2.5714…) rather
than as the qualitative existence of any non-uniform behaviour. Spurious
peaks from arithmetic-progression-like structure mod small integers (the c_ℓ
table in the paper) are a known artifact of the same α and should NOT count
as independent signals.
