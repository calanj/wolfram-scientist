#!/usr/bin/env python3
"""run-metrics.py — measure a research run's LLM usage from harness telemetry.

The model that served a turn does NOT report these numbers (a model can't
introspect its own usage; that would be "claim, don't compute"). Claude Code —
the harness wrapping every agent, whatever model serves the turn — does. This
reads the persisted session transcript(s) and reduces them to a metrics block
merged into research/<id>/run-meta.json, plus a human-readable run-meta.md.

Model-agnostic by design: it reads the literal model id recorded per turn, so
router runs on Kimi / GLM / etc. are measured the same as 1P Claude. Dollar cost
is ESTIMATED from bin/model-prices.json (the harness only knows Claude pricing),
clearly labelled as an estimate.

Usage:
  run-metrics.py --session-id <uuid> [--project-dir DIR] [--research-dir DIR]
                 [--started-at ISO8601] [--prices bin/model-prices.json]

Locating transcripts: the orchestrator transcript is found by globbing
~/.claude/projects/*/<session-id>.jsonl (session id is unique, so the project
slug doesn't matter). Subagents run as their own sessions; we best-effort
include other transcripts in the same directory modified within the run window.
Per-subagent attribution is therefore approximate until validated on a live run;
whole-run totals and per-model/per-transcript breakdowns are exact.
"""

import argparse
import glob
import json
import os
import sys
from datetime import datetime, timezone


def parse_iso(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_prices(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"_default": {"input": 1.0, "output": 5.0, "cacheRead": 0.1,
                             "cacheCreation": 1.25, "estimate": True},
                "_heuristics": [], "models": {}}


def price_for(model, prices):
    """Resolve a price entry for a model id: exact, then heuristic, then default."""
    models = prices.get("models", {})
    if model in models:
        return models[model], False
    low = (model or "").lower()
    for h in prices.get("_heuristics", []):
        if h.get("contains", "") in low and h.get("use") in models:
            return models[h["use"]], False
    return prices.get("_default", {"input": 0, "output": 0,
                                   "cacheRead": 0, "cacheCreation": 0}), True


def turn_cost(usage, price):
    return (
        usage.get("input_tokens", 0) * price.get("input", 0)
        + usage.get("output_tokens", 0) * price.get("output", 0)
        + usage.get("cache_read_input_tokens", 0) * price.get("cacheRead", 0)
        + usage.get("cache_creation_input_tokens", 0) * price.get("cacheCreation", 0)
    ) / 1_000_000.0


def parse_transcript(path):
    """Return a per-transcript summary: turns, models, token totals, tool calls,
    Task spawns, time span, and the raw assistant turns (for costing)."""
    turns = []
    spawns = []
    tools = {}
    tmin = tmax = None
    for line in open(path, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except ValueError:
            continue
        ts = parse_iso(e.get("timestamp"))
        if ts:
            tmin = ts if tmin is None or ts < tmin else tmin
            tmax = ts if tmax is None or ts > tmax else tmax
        if e.get("type") != "assistant":
            continue
        msg = e.get("message", {}) or {}
        turns.append({"model": msg.get("model"),
                      "usage": msg.get("usage", {}) or {},
                      "sidechain": bool(e.get("isSidechain"))})
        for b in (msg.get("content") or []):
            if isinstance(b, dict) and b.get("type") == "tool_use":
                name = b.get("name", "?")
                tools[name] = tools.get(name, 0) + 1
                if name in ("Task", "Agent"):
                    spawns.append((b.get("input", {}) or {}).get("subagent_type", "?"))
    return {"path": path, "turns": turns, "spawns": spawns, "tools": tools,
            "tmin": tmin, "tmax": tmax}


def tok_sum(turns):
    t = {"input": 0, "output": 0, "cacheRead": 0, "cacheCreation": 0}
    for x in turns:
        u = x["usage"]
        t["input"] += u.get("input_tokens", 0)
        t["output"] += u.get("output_tokens", 0)
        t["cacheRead"] += u.get("cache_read_input_tokens", 0)
        t["cacheCreation"] += u.get("cache_creation_input_tokens", 0)
    return t


def find_research_dir(project_dir, started_at):
    """Explore mode: the slug is agent-chosen. Match by the roster's startedAt,
    else fall back to the most recently modified run-meta.json."""
    candidates = glob.glob(os.path.join(project_dir, "research", "*", "run-meta.json"))
    if not candidates:
        return None
    if started_at:
        for c in candidates:
            try:
                if json.load(open(c)).get("startedAt") == started_at:
                    return os.path.dirname(c)
            except (OSError, ValueError):
                pass
    return os.path.dirname(max(candidates, key=os.path.getmtime))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--session-id", required=True)
    ap.add_argument("--project-dir", default=os.getcwd())
    ap.add_argument("--research-dir")
    ap.add_argument("--started-at")
    ap.add_argument("--prices",
                    default=os.path.join(os.path.dirname(__file__), "model-prices.json"))
    args = ap.parse_args()

    home = os.path.expanduser("~")
    hits = glob.glob(os.path.join(home, ".claude", "projects", "*",
                                  args.session_id + ".jsonl"))
    if not hits:
        print(f"run-metrics: no transcript for session {args.session_id}; "
              "leaving run-meta.json metrics unset.", file=sys.stderr)
        return 0
    orch_path = hits[0]
    tdir = os.path.dirname(orch_path)

    started = parse_iso(args.started_at)
    start_epoch = started.timestamp() if started else 0

    # Orchestrator transcript + best-effort subagent transcripts (same dir,
    # modified within the run window).
    paths = [orch_path]
    for p in glob.glob(os.path.join(tdir, "*.jsonl")):
        if p == orch_path:
            continue
        if os.path.getmtime(p) >= start_epoch - 5:
            paths.append(p)

    summaries = [parse_transcript(p) for p in paths]
    prices = load_prices(args.prices)

    # Global + per-model aggregation.
    all_turns = [t for s in summaries for t in s["turns"]]
    global_tokens = tok_sum(all_turns)
    by_model = {}
    est_cost = 0.0
    any_estimate = False
    for t in all_turns:
        price, is_def = price_for(t["model"], prices)
        if is_def or price.get("estimate"):
            any_estimate = True
        c = turn_cost(t["usage"], price)
        est_cost += c
        m = by_model.setdefault(t["model"], {"turns": 0, "estCostUSD": 0.0,
                                             "tokens": {"input": 0, "output": 0,
                                                        "cacheRead": 0, "cacheCreation": 0}})
        m["turns"] += 1
        m["estCostUSD"] += c
        u = t["usage"]
        m["tokens"]["input"] += u.get("input_tokens", 0)
        m["tokens"]["output"] += u.get("output_tokens", 0)
        m["tokens"]["cacheRead"] += u.get("cache_read_input_tokens", 0)
        m["tokens"]["cacheCreation"] += u.get("cache_creation_input_tokens", 0)
    for m in by_model.values():
        m["estCostUSD"] = round(m["estCostUSD"], 4)

    tools = {}
    spawns = {}
    for s in summaries:
        for k, v in s["tools"].items():
            tools[k] = tools.get(k, 0) + v
        for st in s["spawns"]:
            spawns[st] = spawns.get(st, 0) + 1
    tmins = [s["tmin"] for s in summaries if s["tmin"]]
    tmaxs = [s["tmax"] for s in summaries if s["tmax"]]
    wall = (max(tmaxs) - min(tmins)).total_seconds() if tmins and tmaxs else None

    # Per-transcript breakdown (the best-effort per-operation view).
    per_transcript = []
    for s in summaries:
        tk = tok_sum(s["turns"])
        c = sum(turn_cost(t["usage"], price_for(t["model"], prices)[0]) for t in s["turns"])
        models = sorted({t["model"] for t in s["turns"] if t["model"]})
        per_transcript.append({
            "file": os.path.basename(s["path"]),
            "isOrchestrator": s["path"] == orch_path,
            "turns": len(s["turns"]),
            "models": models,
            "tokens": tk,
            "estCostUSD": round(c, 4),
            "spawns": s["spawns"],
        })

    metrics = {
        "measuredBy": "bin/run-metrics.py (from Claude Code transcripts)",
        "sessionId": args.session_id,
        "transcriptCount": len(summaries),
        "wallClockSeconds": round(wall, 1) if wall is not None else None,
        "assistantTurns": len(all_turns),
        "tokens": global_tokens,
        "totalTokens": sum(global_tokens.values()),
        "toolCalls": {"total": sum(tools.values()), "byName": tools},
        "subagentSpawns": spawns,
        "estimatedCostUSD": round(est_cost, 4),
        "costIsEstimate": True,
        "costNote": ("Estimated from bin/model-prices.json"
                     + (" (includes non-list/default-priced models)" if any_estimate else "")),
        "byModel": by_model,
        "perTranscript": per_transcript,
        "perOperationNote": ("Per-transcript view. Subagents run as separate "
                             "sessions; subagent transcripts are matched by "
                             "directory + run window (best-effort) until linkage "
                             "is validated on a live run."),
    }

    research_dir = args.research_dir or find_research_dir(args.project_dir, args.started_at)
    if not research_dir or not os.path.isdir(research_dir):
        print("run-metrics: could not locate research dir; metrics not written.",
              file=sys.stderr)
        print(json.dumps(metrics, indent=2))
        return 0

    meta_path = os.path.join(research_dir, "run-meta.json")
    meta = {}
    if os.path.exists(meta_path):
        try:
            meta = json.load(open(meta_path))
        except ValueError:
            meta = {}
    # In explore mode the launch label was "explore"; adopt the chosen slug.
    if meta.get("id") in (None, "explore"):
        meta["id"] = os.path.basename(research_dir)
    meta["metrics"] = metrics
    meta.pop("metricsNote", None)
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
        f.write("\n")

    write_markdown(os.path.join(research_dir, "run-meta.md"), meta)
    print(f"run-metrics: wrote {meta_path} and run-meta.md "
          f"({len(summaries)} transcript(s), {len(all_turns)} turns, "
          f"~${est_cost:.2f} est).")
    print(f"RESEARCH_DIR={research_dir}")
    return 0


def write_markdown(path, meta):
    m = meta.get("metrics", {})
    models = meta.get("models", {})
    lines = [f"# Run metadata — {meta.get('id', '?')}", ""]
    lines += [f"- **Started:** {meta.get('startedAt', '?')}",
              f"- **Mode:** {meta.get('mode', '?')}"
              + (f" (gateway {meta['gateway']})" if meta.get("gateway") else ""),
              ""]
    lines += ["## Model roster", "",
              "| Role | Model |", "|---|---|",
              f"| orchestrator | {models.get('orchestrator', '?')} |",
              f"| experimenter / refuter | {models.get('experimenter_refuter', '?')} |",
              f"| writer / fast | {models.get('writer_fast', '?')} |", ""]
    wall = m.get("wallClockSeconds")
    wall_s = f"{int(wall // 60)}m {int(wall % 60)}s" if isinstance(wall, (int, float)) else "?"
    tk = m.get("tokens", {})
    lines += ["## Global", "",
              f"- **Wall clock:** {wall_s}",
              f"- **Assistant turns:** {m.get('assistantTurns', '?')}",
              f"- **Tokens:** {m.get('totalTokens', '?'):,} total "
              f"(in {tk.get('input', 0):,} / out {tk.get('output', 0):,} / "
              f"cache-read {tk.get('cacheRead', 0):,} / "
              f"cache-create {tk.get('cacheCreation', 0):,})",
              f"- **Tool calls:** {m.get('toolCalls', {}).get('total', '?')}",
              f"- **Estimated cost:** ~${m.get('estimatedCostUSD', 0):.2f} "
              f"({m.get('costNote', 'estimate')})", ""]
    by = m.get("byModel", {})
    if by:
        lines += ["## By model", "",
                  "| Model | Turns | In | Out | Est $ |", "|---|---:|---:|---:|---:|"]
        for name, d in sorted(by.items(), key=lambda kv: -kv[1]["estCostUSD"]):
            t = d["tokens"]
            lines.append(f"| {name} | {d['turns']} | {t['input']:,} | "
                         f"{t['output']:,} | ${d['estCostUSD']:.2f} |")
        lines.append("")
    sp = m.get("subagentSpawns", {})
    if sp:
        lines += ["## Subagent spawns", "",
                  ", ".join(f"{k}×{v}" for k, v in sorted(sp.items())), ""]
    lines += ["---", "",
              f"*{m.get('measuredBy', 'measured from telemetry')}. "
              f"{m.get('perOperationNote', '')}*", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    sys.exit(main())
