## Session — 2026-06-24

### Completed
- Scaffolded the **Wolfram Scientist** harness (Claude Code-native): `CLAUDE.md` (rigor rules), `prompts/research-loop.md`, `bin/run-research.sh` (headless runner), `.mcp.json` (local kernel), `.claude/settings.json` (tool allowlist), issue template, GH Action workflow, `lib/`, `JOURNAL.md`, `README.md`.
- Ran the **first experiment** (Claude acting as the Scientist via the local Wolfram MCP): `research/eca-additivity-fractality`. Finding — in the 256 elementary CAs, **additivity ⇎ fractality** both ways; **rule 22** is a genuine outlier (non-additive, not orbit-equivalent to rule 90, yet exact mass 3ᵏ and dim log₂3). `massDimension` validated to ~14 digits.
- Produced full artifacts: `plan.md`, reproducible `experiment.wl`, `findings.md`, `notebook.nb` (via `Export`), `JOURNAL.md` entry, new `lib/massDimension.wl`.
- Created private repo **github.com/calanj/wolfram-scientist**; scaffold on `main`, finding on `research/eca-additivity-fractality` → **PR #1 (merged by user)**. README Status updated post-merge and pushed.

### Decisions
- **Claude Code, not ADK**, as the harness — this is an autonomous file/git/tool loop, which Claude Code already is.
- Repo under **`calanj`**; commits use **`alanj@wolfram.com`** (set per-repo).
- "Self-improvement" defined concretely = growing `lib/` + `JOURNAL.md` + the critic/refutation pass (not mystical self-modification).
- Findings land via **branch + PR**, never direct push to `main`.

### Current state
- Repo live; PR #1 merged; `main` contains the finding + updated README.
- The Action workflow `.github/workflows/scientist.yml` is **on disk but untracked/unpushed** (token lacks `workflow` scope).

### Needs scrutiny
- **gh multi-account trap:** SSH authenticates as `calanjoyce`, but the repo is under `calanj`. Fix used: `gh auth setup-git` + HTTPS remote so the active-account token pushes. Don't revert to SSH for this repo.
- **`workflow` scope missing** on the `calanj` token → can't commit the Action file. Needs `gh auth refresh -h github.com -s workflow` (interactive — user must run), then `git add .github/workflows && commit`.
- The "test" was **Claude impersonating the agent**, not an actual `bin/run-research.sh` headless run — the headless path itself has **not** been executed end-to-end yet.
- The **rule-22 result is a conjecture** (empirically exact to 2¹⁰ rows), not proven.
- If pursuing **Cowork** for autonomy: scheduled tasks are desktop-bound (Mac awake + Claude Desktop open) and default to plan-then-approve — verify unattended runs actually proceed hands-off.

### Next steps
- Add a **poll mode** to `bin/run-research.sh`: list open `research-request` issues lacking a `research/<id>/` dir or open PR, and dispatch each — the single entry point for any scheduler.
- Stand up scheduling: **local cron/launchd + headless `claude -p`** (subscription auth, runs without the Desktop app, keeps the local kernel) and/or a **Cowork scheduled task + Skill**.
- Refresh token scope and push the Action workflow.
- Next research seeds: prove rule 22's 3ᵏ count (substitution/sublattice); dimension-vs-Wolfram-class sweep over all 256; rerun under random/periodic initial conditions.
