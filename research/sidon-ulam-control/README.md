# Sidon-set control for the Ulam hidden-α phenomenon

**Status:** complete. Branch `research/sidon-ulam-control`, PR open.

## Finding

The Ulam sequence's deep Fourier dip (~−0.797 at N=30,000) is **not reproduced** by Sidon-set (B₂) constructions.  Two explicit Sidon families — Bose-Chowla (prime powers q=10007 and q=30011) and random subsets thereof — produce shallow dips (−0.013 to −0.029) that are statistically indistinguishable from random density-matched controls (−0.015 to −0.026 ± 0.002).  This closes the single "NOT TESTED" gap from the prior `ulam-hidden-periodicity` study.

## Result table (verified, reproducible)

| sequence | N | own refined depth | |Z| vs. controls |
|---|---|---|---|
| Ulam(1,2) | 10,000 | **−0.79682** | ~406 |
| Bose Sidon (q=10007) | 10,000 | −0.02601 | < 1 |
| Random Bose subset | 10,000 | −0.02944 | < 2 |
| Random control (mean ± σ) | 10,000 | −0.02565 ± 0.0019 | — |
| Ulam(1,2) | 30,000 | **−0.79702** | ~651 |
| Bose Sidon (q=30011) | 30,000 | −0.01331 | < 1 |
| Random Bose subset | 30,000 | −0.01662 | < 1 |
| Random control (mean ± σ) | 30,000 | −0.01520 ± 0.0012 | — |

## Refuter verdicts

All four core claims independently **VERIFIED** (independent code, fresh seeds).

## Key insight

The **exactly-one-representation** rule of the Ulam recursion is not reducible to the weaker **pairwise-sum-uniqueness** of Sidon sets.  The hidden-α signal survives its sharpest adversarial test.

## Files

- `research/sidon-ulam-control/plan.md` — proposal with rubric scores
- `research/sidon-ulam-control/context.md` — Sidon construction definitions
- `research/sidon-ulam-control/experiment.wl` — reproducible script (runs top-to-bottom in fresh kernel)
- `research/sidon-ulam-control/findings.md` — full report with epistemic labels
- `research/sidon-ulam-control/notebook.nb` — narrative notebook with embedded results
- `research/sidon-ulam-control/run-meta.json` — model roster placeholder
