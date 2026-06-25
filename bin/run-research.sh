#!/usr/bin/env bash
# Run one research request locally, using the local Wolfram kernel (via .mcp.json)
# and Claude Code in headless mode.
#
#   bin/run-research.sh 12                       # research GitHub issue #12
#   bin/run-research.sh ca-rule90 "Explore ..."  # ad-hoc run with an inline seed
#
# Findings land on a `research/<id>` branch as a PR; nothing is merged.
set -euo pipefail
cd "$(dirname "$0")/.."

# This machine exports GITHUB_TOKEN (a PAT) in ~/.zshrc, which overrides gh's
# keyring credentials and may lack push rights to this repo (=> 403 on push).
# Drop it for this process so git/gh use the active gh account via the gh
# credential helper (run `gh auth setup-git` once). Comment out if your
# GITHUB_TOKEN is the credential you actually want headless runs to push with.
unset GITHUB_TOKEN

ID="${1:?usage: run-research.sh <issue-number | slug> [inline seed text]}"
SEED="${2:-}"

if [[ -z "$SEED" && "$ID" =~ ^[0-9]+$ ]]; then
  echo "Fetching issue #$ID ..."
  SEED="$(gh issue view "$ID" --json title,body \
          --template '{{.title}}{{"\n\n"}}{{.body}}')"
fi
[[ -n "$SEED" ]] || { echo "No issue body found and no inline seed given." >&2; exit 1; }

PROMPT="$(cat prompts/research-loop.md)

## This research request (id: $ID)

$SEED
"

# acceptEdits + the allowlist in .claude/settings.json keep this unattended.
# For a fully hands-off run on a trusted machine, add --dangerously-skip-permissions.
exec claude -p "$PROMPT" \
  --permission-mode acceptEdits \
  --append-system-prompt "You are operating as the autonomous Wolfram Scientist. Research id: $ID."
