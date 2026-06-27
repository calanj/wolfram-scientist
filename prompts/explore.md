# Open-ended start (orchestrator)

No issue and no seed were given. This is a **"just start doing research"** run:
you survey the Scientist's own past work, decide on the single most worthwhile
new line of inquiry, propose it, and — if it clears the bar — pursue it through
the normal research loop. You are the **orchestrator**; follow the rigor rules
and output contract in `CLAUDE.md`. Work autonomously; do not ask for
confirmation.

The danger of an open-ended run is **research for its own sake** — busywork,
trivial sweeps, restating what's known. Your defense is the scored proposal
below: a candidate must justify itself before any expensive experiment runs, and
**declining is a valid outcome**.

## Phase 1 — Survey the portfolio

Read, don't skim:
- `CLAUDE.md` (identity + rigor) and the last several `JOURNAL.md` entries
  (especially the "what to try next" notes — this is a standing backlog).
- Every `research/*/findings.md`, focusing on **verified results** and their
  **open-questions** sections.
- `lib/` (including `lib/data-sources.md`) — assets that make some follow-ups
  cheap, and the external data sources available for empirical studies.

Note which **domains are already well-represented** (e.g. several
cellular-automata studies) — you will deliberately weight *away* from over-mined
domains for diversity.

## Phase 2 — Generate a candidate slate (≥ 3)

Draw candidates from:
- **Logged loose threads** — the "next ideas" / open questions already recorded.
- **Extensions of a *verified* finding** — push N higher, a sibling system, a
  different region/window of data, a stronger test.
- **Cross-pollination** — a method from one study applied to a new phenomenon.
- **A fresh empirical study** — an under-explored domain from `data-sources.md`
  (data from *outside* Wolfram's curated knowledge base), if it improves
  diversity.

## Phase 3 — Score each candidate

Rate every candidate against this rubric (be explicit and brief per criterion):
1. **Sharpness** — can it be stated as a falsifiable, in-kernel-checkable claim?
2. **Stake** — what would a result actually change or settle? ("nothing" ⇒ drop it)
3. **Leverage** — does it extend a *verified* finding or reuse `lib/`?
4. **Non-duplication** — not a near-restatement of an existing study.
5. **Cost vs. insight** — within a sane compute budget.
6. **Stop condition** — what counts as "done" so it can't sprawl.
Plus a **diversity adjustment**: penalize candidates in already-well-represented
domains.

## Phase 4 — Decide

**If no candidate clears the bar** (low stake, not sharp, duplicative): **decline.**
- Create branch `explore/declined-<UTCstamp>` and write
  `research/_explore/declined-<UTCstamp>.md`: the slate, the scores, and why none
  was worth pursuing.
- Commit, open a PR titled `[explore] declined: no question cleared the bar
  (<date>)`, and STOP. Do not manufacture a study. A clean "nothing worth doing
  this cycle" is a legitimate, honest result — the question-level analogue of a
  null finding.

**Otherwise**, pick the single best candidate and:
1. Derive a short kebab-case **slug** for it; this is the run `<id>`.
2. Create `research/<slug>/` and write `research/<slug>/plan.md` as the
   **proposal**: the chosen question + hypothesis, the rubric scores, the
   **rejected alternatives** (one line each, why not), and **why this / why
   now**. Then the usual plan fields (what you'll vary/measure, interesting
   criteria, compute budget).
3. Write the model roster: the env var `WS_ROSTER_JSON` holds this run's
   deterministic model roster — write its exact contents to
   `research/<slug>/run-meta.json` (do not edit or invent the numbers; metrics
   are filled in post-run from telemetry, not by you).
4. Create branch `research/<slug>`, commit the proposal, and **open a DRAFT PR**
   with the proposal as the body. This is the human's early visibility + veto
   point (they can close the PR or stop the run if the premise is wrong).

## Phase 5 — Pursue it (normal loop)

Now read `prompts/research-loop.md` and carry out its procedure **from step 4
(Gather context) onward** for the chosen `<slug>` — experiment → refute → write
up → self-improve → verify reproducibility. Push commits onto the same
`research/<slug>` branch (and PR). When the findings are settled, **flip the PR
from draft to ready** and post the usual concise summary.

Remember: the proposal and the draft PR are what keep an autonomous run honest.
Do not skip the scoring, and do not let a weak question through just to have
something to run.
