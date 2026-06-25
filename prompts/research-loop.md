# Research loop

Execute one research request end to end. Follow the rigor rules and output
contract in `CLAUDE.md`. Work autonomously; do not ask for confirmation.

## Steps

1. **Orient.** Read `CLAUDE.md` and the last few entries of `JOURNAL.md`. Skim
   `lib/` for assets you can reuse. Determine `<id>` (issue number, or a short
   slug for ad-hoc runs) and create `research/<id>/`.

2. **Plan** → write `research/<id>/plan.md`: restate the question, your
   hypothesis, exactly what you will vary and measure, what would count as
   "interesting", and your compute budget (time/size limits). If the request is
   ambiguous, state your interpretation here.

3. **Create a branch:** `research/<id>`.

4. **Experiment.** Build `research/<id>/experiment.wl` incrementally, running
   each block through `WolframLanguageEvaluator` as you write it. Look up
   functions with `WolframLanguageContext`/`SymbolDefinition` rather than
   guessing. Keep everything `TimeConstrained`/`MemoryConstrained`. Capture the
   actual outputs.

5. **Refute.** Actively try to break the result: counterexamples, edge cases,
   larger search bounds, trivial explanations, unit/off-by-one errors. Record
   what you tried and what survived.

6. **Write up** → `research/<id>/findings.md` with epistemic labels (Verified /
   Conjecture (tested on N) / Speculation), the refutation attempts, and
   limitations. Then build `research/<id>/notebook.nb` by constructing the
   notebook expression and `Export`-ing it (never a WriteNotebook tool).

7. **Self-improve.** Factor any reusable computation into `lib/`; append a dated
   entry to `JOURNAL.md` (what worked, dead ends, next ideas, new assets).

8. **Verify reproducibility.** Run `experiment.wl` once in a fresh evaluation
   and confirm it regenerates the headline results. Fix it if it doesn't.

9. **Deliver.** Commit on the `research/<id>` branch, open a PR summarizing the
   finding and its epistemic status, and post a concise summary as a comment on
   the originating issue (if there is one). Do not merge.

Remember: a verified null/negative result is a legitimate, publishable outcome.
Do not manufacture significance.
