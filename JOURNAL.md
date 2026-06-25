# Methods Journal

Append a dated entry after every research run: what worked, what dead-ended,
what to try next, and any new `lib/` asset. Read the most recent entries before
starting a new run so you don't repeat dead ends. Newest first.

---

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
