#!/usr/bin/env bash
# Run one research request locally, using the local Wolfram kernel (via .mcp.json)
# and Claude Code in headless mode.
#
# Claude Code runs as an ORCHESTRATOR: it gathers context (web tools), plans, and
# delegates computation to subagents defined in .claude/agents/ (experimenter,
# refuter, writer). See prompts/research-loop.md.
#
#   bin/run-research.sh 12                       # research GitHub issue #12
#   bin/run-research.sh ca-rule90 "Explore ..."  # ad-hoc run with an inline seed
#
# Model selection — two modes:
#
#   (default) 1P Claude: orchestrator + subagents on your subscription/API Claude
#     against api.anthropic.com. Open-ended WebSearch works. Models are Claude
#     tiers (opus/sonnet/haiku). --model / --experimenter-model take 1P names.
#
#   --router : route ALL agents through a LiteLLM-style gateway that speaks the
#     Anthropic Messages API at /v1/messages. Set its base URL via $LITELLM_BASE
#     and its key via $LITELLM_KEY (neither is baked into the repo). Pick ANY
#     model per role — good for benchmarking non-Claude experimenters. WebSearch
#     may be unavailable on such a gateway; the orchestrator then gathers web
#     data via WebFetch / kernel URLRead instead.
#
#   bin/run-research.sh --model opus 12                       # 1P, orchestrator on Opus
#   bin/run-research.sh --router 12                           # router, Claude defaults
#   bin/run-research.sh --router --experimenter-model Kimi-K2.6 12   # bench Kimi as experimenter
#   bin/run-research.sh --list-models                         # list router model ids
#
# Roles map to model ALIASES so the .claude/agents/ files work in both modes:
#   orchestrator = the main --model     (default: opus / router: claude-opus-4-7)
#   experimenter + refuter = `sonnet`   (default: 1P sonnet / router: claude-sonnet-4-6)
#   writer + small-fast = `haiku`       (default: 1P haiku / router: claude-haiku-4-5)
# --experimenter-model overrides the `sonnet` alias (this is the benchmarking knob).
#
# CAP: Claude subagents never run above Sonnet-level — the orchestrator may be
# Opus, but subagents only ever resolve to Sonnet/Haiku. The runner rejects a
# Claude-Opus --experimenter-model. (Non-Claude models are allowed there.)
#
# NOTE (router): subagents lean heavily on MCP tool calls — use a strong
# tool-caller. Verified working (2026-06-25): claude-sonnet-4-6, claude-opus-4-7,
# Kimi-K2.6, zai-glm-5. The GPT-5.x family currently FAILS (Azure rejects an
# `output_config` param Claude Code sends — a LiteLLM translation gap). Non-tool
# models (Llama, Gemma, Qwen-local, embeddings) stall on the first tool step.
#
# Findings land on a `research/<id>` branch as a PR; nothing is merged.
set -euo pipefail
cd "$(dirname "$0")/.."

# Base URL of the Anthropic-API-compatible gateway used by --router / --list-models.
# Set this in your environment (e.g. ~/.bash_profile); no default, so no internal
# endpoint is baked into the repo.
LITELLM_BASE="${LITELLM_BASE:-}"

# --- arg parsing -------------------------------------------------------------
ROUTER="${WS_ROUTER:-0}"
MODEL="${WS_MODEL:-}"                       # orchestrator model
EXP_MODEL="${WS_EXPERIMENTER_MODEL:-}"      # experimenter/refuter model (sonnet alias)
EXPLORE="${WS_EXPLORE:-0}"                  # open-ended start: no issue/seed
LIST_MODELS=0
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --explore)                 EXPLORE=1; shift ;;
    --router)                  ROUTER=1; shift ;;
    --model)                   MODEL="${2:?--model needs a model id}"; shift 2 ;;
    --model=*)                 MODEL="${1#*=}"; shift ;;
    --experimenter-model)      EXP_MODEL="${2:?--experimenter-model needs a model id}"; shift 2 ;;
    --experimenter-model=*)    EXP_MODEL="${1#*=}"; shift ;;
    --list-models)             LIST_MODELS=1; shift ;;
    *)                         POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]:-}"

# --- subagent model cap ------------------------------------------------------
# Hard rule: Claude subagents never run above Sonnet-level, even if the
# orchestrator is Opus. The agent frontmatter only ever uses the sonnet/haiku
# aliases, so the lone way to breach this is --experimenter-model. Reject a
# Claude Opus (or higher) id there. Non-Claude models are allowed (benchmarking).
if [[ "$EXP_MODEL" =~ [Oo]pus ]]; then
  echo "Refusing --experimenter-model '$EXP_MODEL': subagents are capped at" >&2
  echo "Sonnet-level for Claude models. Use a Sonnet/Haiku tier or a non-Claude model." >&2
  exit 1
fi

# --- LiteLLM helpers ---------------------------------------------------------
if [[ "$LIST_MODELS" == 1 ]]; then
  : "${LITELLM_BASE:?LITELLM_BASE not set — point it at your Anthropic-API-compatible gateway}"
  : "${LITELLM_KEY:?LITELLM_KEY not set (set it in your shell rc, e.g. ~/.zshrc)}"
  echo "Models callable via $LITELLM_BASE :"
  curl -s "$LITELLM_BASE/v1/models" \
    -H "Authorization: Bearer $LITELLM_KEY" \
    | python3 -c "import sys,json; print('\n'.join('  '+m['id'] for m in json.load(sys.stdin)['data']))"
  exit 0
fi

# This machine exports GITHUB_TOKEN (a PAT) in ~/.zshrc, which overrides gh's
# keyring credentials and may lack push rights to this repo (=> 403 on push).
# Drop it for this process so git/gh use the active gh account via the gh
# credential helper (run `gh auth setup-git` once). Comment out if your
# GITHUB_TOKEN is the credential you actually want headless runs to push with.
unset GITHUB_TOKEN

if [[ "$EXPLORE" == 1 ]]; then
  # Open-ended start: no issue, no seed. The agent surveys prior research,
  # proposes a line of inquiry, and (if it clears the bar) pursues it — minting
  # its own slug. RESEARCH_DIR is therefore unknown until the agent picks one.
  ID="explore"
  echo "Open-ended run: surveying prior research to choose a new line of inquiry."
  PROMPT="$(cat prompts/explore.md)"
else
  ID="${1:?usage: run-research.sh [--explore] [--router] [--model <id>] [--experimenter-model <id>] <issue-number | slug> [inline seed text]}"
  SEED="${2:-}"

  if [[ -z "$SEED" && "$ID" =~ ^[0-9]+$ ]]; then
    echo "Fetching issue #$ID ..."
    SEED="$(gh issue view "$ID" --json title,body \
            --template '{{.title}}{{"\n\n"}}{{.body}}')"
  fi
  [[ -n "$SEED" ]] || { echo "No issue body found and no inline seed given." >&2; exit 1; }

  # --- pre-stage GitHub attachment files -------------------------------------
  # A user can attach a data file to the issue; GitHub leaves a link in the body.
  # For a PRIVATE repo those links need auth the kernel lacks, so download them
  # here with gh's credentials into research/<id>/inputs/. The orchestrator then
  # `dataRegister`s them (provenance) instead of re-fetching. Best-effort and
  # non-fatal: a failed pull just means the orchestrator tries dataFetch itself.
  RESEARCH_DIR="research/$ID"
  INPUTS_DIR="$RESEARCH_DIR/inputs"
  ATTACH_URLS="$(printf '%s\n' "$SEED" | grep -oE \
    'https://(github\.com/user-attachments/[^ )"]+|github\.com/[^/]+/[^/]+/assets/[^ )"]+|user-images\.githubusercontent\.com/[^ )"]+)' \
    | sort -u || true)"
  if [[ -n "$ATTACH_URLS" ]]; then
    mkdir -p "$INPUTS_DIR"
    GH_TOKEN_HDR=()
    if tok="$(gh auth token 2>/dev/null)" && [[ -n "$tok" ]]; then
      GH_TOKEN_HDR=(-H "Authorization: token $tok")
    fi
    while IFS= read -r u; do
      [[ -z "$u" ]] && continue
      fname="$(basename "${u%%\?*}")"
      echo "Staging attachment: $fname"
      curl -fsSL "${GH_TOKEN_HDR[@]}" "$u" -o "$INPUTS_DIR/$fname" \
        || echo "  (attachment download failed; orchestrator will try dataFetch)" >&2
    done <<< "$ATTACH_URLS"
  fi

  PROMPT="$(cat prompts/research-loop.md)

## This research request (id: $ID)

$SEED
"
fi

# --- model routing -----------------------------------------------------------
# Subagents pick their model via the opus/sonnet/haiku aliases in their
# frontmatter; we remap those aliases per mode with ANTHROPIC_DEFAULT_*_MODEL.
MODEL_FLAG=()
if [[ "$ROUTER" == 1 ]]; then
  : "${LITELLM_BASE:?LITELLM_BASE not set — point it at your Anthropic-API-compatible gateway}"
  : "${LITELLM_KEY:?LITELLM_KEY not set (set it in your shell rc, e.g. ~/.zshrc)}"
  : "${MODEL:=claude-opus-4-7}"
  : "${EXP_MODEL:=claude-sonnet-4-6}"
  echo "Routing ALL agents through $LITELLM_BASE"
  echo "  orchestrator: $MODEL    experimenter/refuter: $EXP_MODEL    writer/fast: claude-haiku-4-5"
  export ANTHROPIC_BASE_URL="$LITELLM_BASE"
  export ANTHROPIC_AUTH_TOKEN="$LITELLM_KEY"
  # The bearer token is the credential; a lingering ANTHROPIC_API_KEY would conflict.
  unset ANTHROPIC_API_KEY
  export ANTHROPIC_DEFAULT_SONNET_MODEL="$EXP_MODEL"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5"
  export ANTHROPIC_SMALL_FAST_MODEL="claude-haiku-4-5"
  MODEL_FLAG=(--model "$MODEL")
else
  # 1P Claude. Only override aliases the user explicitly pinned.
  [[ -n "$EXP_MODEL" ]] && export ANTHROPIC_DEFAULT_SONNET_MODEL="$EXP_MODEL"
  [[ -n "$MODEL" ]] && MODEL_FLAG=(--model "$MODEL")
fi

# WS_STREAM=1 emits the live JSON event stream (init, subagent spawns, tool
# calls, results) instead of one final blob — the control panel sets this and
# renders it as readable progress. Plain CLI runs leave it off.
STREAM_FLAGS=()
[[ "${WS_STREAM:-0}" == 1 ]] && STREAM_FLAGS=(--output-format stream-json --verbose)

# --- record the model roster (deterministic; metrics filled post-run) --------
# "Which model worked on which part" is known HERE, from the resolved flags —
# so we record it deterministically. Token/time/tool metrics are NOT guessed by
# any agent (a model can't introspect its own usage); they are measured later by
# bin/run-metrics.py from the run's telemetry. This writes the roster only.
if [[ "$ROUTER" == 1 ]]; then
  RM_MODE="router"; RM_ORCH="$MODEL"; RM_EXP="$EXP_MODEL"
  RM_WRITER="claude-haiku-4-5"; RM_GATEWAY="\"$LITELLM_BASE\""
else
  RM_MODE="1p"
  RM_ORCH="${MODEL:-(1P session default)}"
  RM_EXP="${EXP_MODEL:-sonnet (1P default)}"
  RM_WRITER="haiku (1P default)"; RM_GATEWAY="null"
fi
RUN_META_JSON="$(cat <<JSON
{
  "id": "$ID",
  "startedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mode": "$RM_MODE",
  "gateway": $RM_GATEWAY,
  "models": {
    "orchestrator": "$RM_ORCH",
    "experimenter_refuter": "$RM_EXP",
    "writer_fast": "$RM_WRITER"
  },
  "metrics": null,
  "metricsNote": "Populated post-run by bin/run-metrics.py from the run's telemetry; agents do not self-report counts."
}
JSON
)"
if [[ "$EXPLORE" == 1 ]]; then
  # In explore mode the slug (hence research dir) is chosen by the agent; hand it
  # the roster via the environment to place at research/<slug>/run-meta.json
  # (explore.md instructs this).
  export WS_ROSTER_JSON="$RUN_META_JSON"
else
  mkdir -p "$RESEARCH_DIR"
  printf '%s\n' "$RUN_META_JSON" > "$RESEARCH_DIR/run-meta.json"
fi

# acceptEdits + the allowlist in .claude/settings.json keep this unattended.
# For a fully hands-off run on a trusted machine, add --dangerously-skip-permissions.
exec claude -p "$PROMPT" \
  "${MODEL_FLAG[@]}" \
  "${STREAM_FLAGS[@]}" \
  --permission-mode acceptEdits \
  --append-system-prompt "You are operating as the autonomous Wolfram Scientist orchestrator. Research id: $ID."
