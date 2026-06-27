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
bin/run-research.sh --explore                   # open-ended: survey past work,
                                                # propose & pursue a new line
```

**Open-ended start (`--explore`).** With no issue and no seed, the Scientist
surveys its own portfolio (`research/`, `JOURNAL.md`, `lib/`), scores a slate of
candidate questions against a value rubric (sharpness · stake · leverage ·
non-duplication · cost · stop-condition, with a diversity guard against
over-mined domains), and either **declines** (a clean "nothing worth doing this
cycle", reported as a PR) or picks the best one, mints a slug, opens a **draft
PR** with the proposal as the body, and pursues it through the normal loop —
flipping the PR to ready when the findings settle. The draft PR is your early
visibility + veto point: if the premise looks wrong, close it / stop the run.
See `prompts/explore.md`.

**First-time setup of the local kernel.** `.mcp.json` is git-ignored because it
holds absolute, machine-specific paths. Create your own from the template:

```bash
cp .mcp.json.example .mcp.json
```

Then edit `.mcp.json` for your install:
- `command` — the path to your `wolfram` executable (e.g.
  `/Applications/Wolfram.app/Contents/MacOS/wolfram`, or a versioned
  `Wolfram 15.0` app).
- the `WOLFRAM_USERBASE` / `WOLFRAM_LOCALBASE` env paths — point at your own home dir.

It uses the `Wolfram/AgentTools` paclet's stdio MCP server. If you don't yet have
Wolfram Engine + that paclet wired up, the **`wolfram-setup` skill** walks through
installing/activating the engine and configuring the MCP server. Output lands on
a `research/<id>` branch as a PR.

**Optional — run on a specific model via a LiteLLM-style gateway:**

```bash
bin/run-research.sh --list-models               # list callable model ids
bin/run-research.sh --model claude-opus-4-7 12   # research issue #12 on that model
```

Requires `LITELLM_BASE` (the gateway URL) and `LITELLM_KEY` in the environment.
Without `--model`/`WS_MODEL`
the runner uses your normal Claude auth. (Verified working: the Claude 4.x,
Kimi-K2.x, and GLM-5 families. The GPT-5.x family currently fails through this
path — see the note in `bin/run-research.sh`.)

**Via the control panel (a local web UI for the knobs):**

```bash
/usr/bin/python3 bin/control-panel.py        # then open http://127.0.0.1:8765
```

A dependency-free, localhost-only page to pick the mode (1P / router),
orchestrator and experimenter models (router lists are fetched live; the
experimenter dropdown mirrors the Sonnet cap), set the issue/slug and seed, and
kick off a run with the log streaming back. It just shells out to
`bin/run-research.sh`, so every guarantee lives there. Launch it from a shell
that has your run env (`LITELLM_BASE` + `LITELLM_KEY` + your Claude auth) — the run
inherits the server's environment.

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
| `prompts/research-loop.md` | The orchestrator's procedure for one request |
| `prompts/explore.md` | Open-ended start (`--explore`): survey → propose → pursue |
| `lib/data-sources.md` | Curated whitelist of external data sources (provenance via `lib/dataProvenance.wl`) |
| `.claude/agents/` | Subagents: `experimenter`, `refuter`, `writer` (own tools + model) |
| `bin/run-research.sh` | Local headless runner (`--explore` / `--router` / `--model` / `--experimenter-model`) |
| `bin/run-metrics.py` | Post-run: reduce the run's telemetry → `run-meta.json` + `run-meta.md` (model roster, tokens, time, tool calls, est. cost) |
| `bin/model-prices.json` | Editable per-model price table for cost estimates (all router models; Claude/GPT list prices, others flagged estimates) |
| `bin/refresh-prices.py` | Regenerate the price table from the router's `/model/info` (needs an admin key) |
| `bin/control-panel.py` | Local web UI (stdlib only) to set the knobs and stream runs |
| `.mcp.json.example` | Template for the local Wolfram kernel (MCP, stdio); copy to `.mcp.json` and edit paths |
| `.claude/settings.json` | Tool allowlist for unattended runs |
| `.github/ISSUE_TEMPLATE/` | Research Request form |
| `.github/workflows/scientist.yml` | `@claude` issue trigger (remote MCP) |
| `lib/` | Accreted reusable WL functions (self-improvement) |
| `JOURNAL.md` | Methods log (self-improvement) |
| `research/<id>/` | Per-request outputs: `plan.md`, `experiment.wl`, `findings.md`, `notebook.nb`, `run-meta.{json,md}`, `inputs/` (provenance-tracked data) |

## Findings

The harness is live and the loop runs end-to-end (autonomous experiment →
self-critique → PR). Rather than enumerate results here (where they go stale),
see the source of truth:

- **[`research/`](research/)** — each completed study (`plan.md`,
  `experiment.wl`, `findings.md`, `notebook.nb`).
- **[`JOURNAL.md`](JOURNAL.md)** — the running methods log: what worked, dead
  ends, new `lib/` assets, and the next seeds to try.
