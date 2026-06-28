# Methods Journal

Append a dated entry after every research run: what worked, what dead-ended,
what to try next, and any new `lib/` asset. Read the most recent entries before
starting a new run so you don't repeat dead ends. Newest first.

---

## 2026-06-27 — sidon-ulam-control: the gap is closed, specificity survives

**Result:** clean **negative** — Sidon (B₂) set constructions do **not** reproduce the Ulam hidden-α Fourier dip.  Bose-Chowla (q=10007, 30011) and random Bose subsets yield depths −0.026 and −0.013 respectively, statistically indistinguishable from random density-matched controls (−0.026±0.002, −0.015±0.001).  Ulam depth at same N: **−0.797** — ~30–60× deeper, |Z| ≈ 400–650 vs. controls.  The specificity claim from the prior study survives its sharpest adversarial test.

**What worked:** the corrected Bose formula `2·i·q + Mod[i², q]` (verified Sidon for q=13: all 91 pairwise sums distinct).  The 8000-point coarse scan + `FindMinimum` (WP 25) protocol replicated from the Ulam study found Bose dips reliably, and the Ulam dip reproduced at −0.7970 (N=30k) confirming the method is sound.  Independent refuter with fresh seeds reproduced all control statistics within noise.

**Dead ends / gotchas:** 
- **Formula confusion:** the first experimenter used `i*q + Mod[i^2,q]`, which is NOT a Sidon set (4 duplicate sums for q=13).  We caught this only because the refuter independently checked Sidon correctness.  **Always verify construction properties independently, not by trusting the formula.**
- **Coarse-grid-only "polishing" is fatal for Ulam:** the prior (stopped) experimenter tried a 1000-point local grid instead of `FindMinimum` — the dip width is ~6.5×10⁻⁷, so the grid spacing (~2×10⁻⁵) misses it by ~30×.  This gave Ulam 30k depth −0.624 instead of −0.797.  **Always use `FindMinimum` with `WorkingPrecision` for sharp landscapes.**
- **The first experimenter evaluated every sequence at the FIXED Ulam α instead of finding each sequence's own argmin.**  This answered a different (and less informative) question.  We caught and corrected this mid-run.
- The writer subagent did NOT actually write `findings.md` to disk — it returned the text in chat.  I (orchestrator) had to write it manually.  **Don't trust the writer to persist files; verify `FileExistsQ`.**

**No new `lib/` asset** — the Bose generator is small enough to live in `experiment.wl`.

**Next (from this run's open questions):**
- greedy Sidon (Mian-Chowla, OEIS A005282) at N=10k–30k — the most important remaining gap;
- push Ulam to N=10⁶ to verify exceptional-set stability and close in on McCranie's α interval;
- LLL/CF probe for α closed form (speculative but cheap);
- rule 22's exact 3ᵏ count in the ECA fractality study.

---

## 2026-06-25 — ulam-hidden-periodicity: Steinerberger's α replicates cleanly

**Result:** clean **positive replication** of Steinerberger 2015 within N=10^5.
α̂(10^5) = **2.571447610061** (two independent refinements agree to 2×10^-11);
depth f(α̂)/N = **−0.79751**, already ≈99.7% of the paper's asymptotic −0.8 at
N=10^7. Exceptional set {a_n : cos(α̂·a_n) ≥ 0} = **{2, 3, 47, 69}** exactly,
stable at every prefix from N=10^3 to N=10^5 (high-precision modular check at
WP 30; no borderline near-zeros).

**Specificity is the sharpest finding.** Over 100 random density-matched
strictly-increasing integer sequences (N=30,000, support {1..a_30000}),
f(α_Ulam)/N has mean −7×10^-5, std 0.0041 — Ulam's −0.795 is a **Z ≈ −194**
outlier (refuter reproduced Z = −194.0 with a fresh RNG). No random sample
came within a factor of 70. Rational frequencies 2π·p/q for q ≤ 20 also fail
to produce comparable dips (best −0.005). The phenomenon recurs across the
erratic Ulam-type starts (1,3), (1,4), (2,3) at their reported paper-α to
~10^-7, with depths −0.80, −0.86, −0.83 respectively.

**What worked:** the Gibbs counter-based sieve (compiled, C target) — 7 s for
N=10^5, costs roughly linear in max element. Seeding `FindMinimum` at the
paper's α was essential: a 4000-point uniform grid over [0.05, π] *misses* the
dip entirely (it lands on a shallow −0.013 local minimum at x≈2.01). The dip's
0.1-rise half-width is ≈6.5×10^-7 — genuinely sub-grid at typical
exploratory resolutions. Same hidden-at-grid character for Ulam(1,3) and
(2,3) (paper α is correct but invisible to the coarse scan); (1,4) is wide
enough that the coarse minimum happens to land on it. This made the "hidden"
in the paper title operational rather than rhetorical.

**Dead ends / gotchas:** initial writer agent silently failed to save
`findings.md` to disk (printed it in chat instead), AND swapped the
"coarse-grid minimum" and "refined-at-paper-α" columns for (1,4)/(2,3),
which would have flipped the conclusion from "replicates" to "refutes" for
two of three (a,b) variants. **Always verify the writer's table cells
against the experimenter's raw numbers — don't ship the writer output blind.**
Sidon-set control (a stronger "hand-tuned sparse sequence" check) timed out
in budget — left as a documented gap.

**New asset:** `lib/ulam.wl` — `ulamSequence[n]` and `ulamSequence[{a,b}, n]`,
counter-based sieve, ~7 s for 100k terms of A002858; cross-validated against
OEIS b-file (a_10000 = 132788) and a naive O(n²) reference.

**Next:**
- close the Sidon-set gap (an engineered sparse non-Ulam control that *could*
  exhibit a similar dip would qualitatively change the conclusion);
- push to N ≈ 10^6 or 10^7 to verify whether the exceptional set ever grows
  beyond {2,3,47,69} and to land α inside McCranie's interval;
- a cheap small-scale sweep over more erratic (a,b) pairs to widen the
  "every erratic Ulam-type has a deep α" conjecture (currently tested on 4
  cases);
- the dip's f''/N ≈ 5×10^11 and width ~7×10^-7 suggest an internal length
  scale that begs for an analytic explanation; worth examining whether α has
  a closed form via continued-fraction probes or LLL.

## 2026-06-24 — research 2: mass dimension vs Wolfram class (all 256 ECAs)

**Result:** clean **negative**. Single-seed mass dimension `D` does **not** proxy
Wolfram class. Best single `D`-threshold separating class 2 vs 3 = **0.776 =
majority baseline** (zero gain); naive `D≥1.5` = 0.732 (*worse* than guessing).
76% of class-2 and 69% of class-3 rules pile up at `D≈1`. Named outliers: **rule
254** (class 1, solid triangle, `D=2.0` — trivial dynamics, maximal dimension);
class-2 rules 50/178/94 (`D≈1.97`, ordered yet space-filling); **35/51 class-3
rules collapse to `D<1.05`** from a single seed.

**Best part — the mechanism:** the chaotic-yet-`D≈1` collapse is largely a
**rule-parity artifact**. Odd rules have f(0,0,0)=1 → seed evolves on a *blinking*
background → `massDimension` (cells differing from background) sees only a
linearly-growing deviation → `D≈1`. 32/35 collapsers are odd; all 16 high-`D`
chaotic rules are even; class-3 mean `D` 1.66 (even) vs 1.01 (odd). Genuine
even-background chaotic-yet-`D≈1` outliers: **106, 120, 184**.

**What worked:** damage-spreading (Hamming fraction of a 1-cell-perturbation
difference, **max over 3 seeds**) as the order/chaos discriminator — 27/27 on
anchors; the multi-seed max was essential to catch rule 18 (its single-seed defect
is seed-sensitive and annihilated for some ICs). The "trivial explanation" rule
again earned its keep (single seed doesn't excite the chaos) and the refutation
pass turned it into the parity-confound mechanism. Classifier robust: only 18/256
rules flip class under a disjoint seed set, all at the 2↔3 margin; conclusion
unchanged.

**Dead ends / gotchas:** cone-*width* spreading velocity over-called chaos
(155/256) — class-2 rules with a single *propagating* defect inflate it; switched
to saturated Hamming *fraction* (does the damage fill its cone) → sane counts
(24/177/51/4). Per-row entropy alone conflates temporal blinkers (rule 1) with
spatial disorder; needed a temporal-period test too. **Notebook export bug:**
`BoxData@ToBoxes@Defer@@{code}` mis-parses by precedence into
`BoxData[ToBoxes[Defer]][Null]` → `Export[...nb]` returns `$Failed` silently. Use
`SetAttributes[icell,HoldFirst]; Cell[BoxData@MakeBoxes[code,StandardForm],"Input"]`.
Also: `Export` to `.nb` returns `$Failed` (not a message) on bad boxes — always
check the return value / `FileExistsQ`, don't trust a following `Print`.

**New asset:** `lib/wolframClass.wl` (`wolframClass`, `wolframClassData`).

**Next:** random-IC spatial/correlation dimension (should track class far better —
sees the chaos the single seed hides); a real class-4 detector (localized
propagating structures); chase the genuine outliers 106/120/184.

## 2026-06-24 — eca-additivity-fractality (first run)

**Result:** additivity does not predict fractality either way. Additive rules
span dims {0, 1, log₂3, 1.696}; eight non-additive rules hit log₂3 — but 7 of
them are just rule 90 on the single-seed orbit. **Rule 22** is the real outlier
(non-additive, distinct pattern, exact mass 3ᵏ, dim log₂3).

**What worked:** *mass dimension* (live cells in first 2^k rows, slope of
log₂mass vs log₂s) — exact to ~14 digits on rule 90. Box-counting was biased
(read 1.44–1.50 for rule 90 depending on the scale band) — avoid it for lattice
fractals. The "check for the trivial explanation" rule earned its keep: it caught
the 7 orbit-collapse rules and isolated rule 22.

**New asset:** `lib/massDimension.wl`.

**Next:** prove rule 22's 3ᵏ count (substitution/sublattice); rerun with random
& periodic ICs; dimension-vs-Wolfram-class sweep over all 256.

## 2026-06-24 — bootstrap

Repo scaffolded. No experiments run yet. First seed will be a systematic
elementary-cellular-automaton exploration (see the issue template example).
