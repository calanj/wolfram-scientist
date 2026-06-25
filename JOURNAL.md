# Methods Journal

Append a dated entry after every research run: what worked, what dead-ended,
what to try next, and any new `lib/` asset. Read the most recent entries before
starting a new run so you don't repeat dead ends. Newest first.

---

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
