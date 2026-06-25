# 🔬 Wolfram Scientist

An autonomous computational scientist: an LLM agent (Claude Code as the harness)
whose laboratory is a **Wolfram Language kernel**. People file GitHub issues with
research seeds; the Scientist runs real experiments in the kernel, tries to
refute its own results, writes them up reproducibly, and opens a PR with the
findings. It accretes a library of reusable methods over time.

It plays off the "AI solves science" framing honestly: Wolfram is the exact
experimental substrate (no hallucinated numbers), the LLM is the
hypothesis-generator / pattern-spotter / writer, and the loop is closed by
**in-kernel verification**. It surfaces *candidates*, with explicit epistemic
labels — it does not announce breakthroughs.

## Why Claude Code (not a Python agent framework)

This is a long-running, file-writing, git-committing, tool-using agent loop —
exactly what Claude Code already is. It gives us, for free: the Wolfram kernel
over MCP, skills as domain instruments, subagents for the critic loop, headless
mode for unattended runs, and the GitHub Action for the issue-driven trigger.

## How it works

```
GitHub issue (research seed)
        │   @claude  ──or──  bin/run-research.sh <id>
        ▼
prompts/research-loop.md  +  CLAUDE.md   (the procedure + the rigor rules)
        ▼
   plan → experiment in Wolfram → refute → write up → notebook
        ▼
   self-improve (lib/ + JOURNAL.md)  →  branch + PR  (human reviews, then merges)
```

### Rigor (enforced by `CLAUDE.md`)
- Every number is computed in Wolfram and shown — never asserted.
- `experiment.wl` must re-run from scratch and regenerate all results.
- Every claim is labelled **Verified** / **Conjecture (tested on N)** /
  **Speculation**. The agent actively tries to break its own result.
- A verified null result is a valid finding. No hype.

### Self-improvement (concrete, version-controlled)
- `lib/` — reusable WL functions it factors out (and later runs reuse).
- `JOURNAL.md` — dated lessons, read before each run.
- A critic/refutation pass before anything counts as a finding.

## Running it

**Locally (recommended for real experiments — uses your local kernel):**

```bash
bin/run-research.sh 12                          # research issue #12
bin/run-research.sh ca-elementary "Among ..."   # ad-hoc seed, no issue needed
```

The local kernel is configured in `.mcp.json`. Paths there are machine-specific
(currently Wolfram 15.0 on this Mac) — edit for your install. Output lands on a
`research/<id>` branch as a PR.

**Via GitHub (issue-driven):** enable `.github/workflows/scientist.yml`, add an
`ANTHROPIC_API_KEY` repo secret, file a Research Request issue, and comment
`@claude`. Note: GitHub-hosted runners have **no local Wolfram kernel**, so the
workflow uses the **free remote Wolfram MCP service** (stateless, light
experiments). For heavy/stateful work, use a **self-hosted runner** with Wolfram
Engine and switch the workflow to the local stdio server.

## Layout

| Path | Purpose |
|---|---|
| `CLAUDE.md` | The Scientist's identity + non-negotiable rigor rules (always loaded) |
| `prompts/research-loop.md` | The step-by-step procedure for one request |
| `bin/run-research.sh` | Local headless runner |
| `.mcp.json` | Local Wolfram kernel (MCP, stdio) |
| `.claude/settings.json` | Tool allowlist for unattended runs |
| `.github/ISSUE_TEMPLATE/` | Research Request form |
| `.github/workflows/scientist.yml` | `@claude` issue trigger (remote MCP) |
| `lib/` | Accreted reusable WL functions (self-improvement) |
| `JOURNAL.md` | Methods log (self-improvement) |
| `research/<id>/` | Per-request outputs: `plan.md`, `experiment.wl`, `findings.md`, `notebook.nb` |

## Status

Harness live; the loop has produced its first finding.

- **[`research/eca-additivity-fractality`](research/eca-additivity-fractality/)** —
  in the 256 elementary CAs, additivity (GF(2)-linearity) does *not* predict
  fractal dimension in either direction. The mass-dimension method was validated
  to ~14 digits (rule 90 = log₂3), and the refutation pass isolated **rule 22**
  as a genuine outlier: non-additive, not orbit-equivalent to rule 90, yet with
  exact live-cell count 3ᵏ and dimension log₂3. (merged)

Next seeds: prove rule 22's 3ᵏ count; sweep dimension vs. Wolfram class across
all 256 rules; rerun under random/periodic initial conditions.
