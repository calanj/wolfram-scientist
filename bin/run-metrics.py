#!/usr/bin/env python3
"""run-metrics.py — measure a research run's LLM usage from harness telemetry.

The model that served a turn does NOT report these numbers (a model can't
introspect its own usage; that would be "claim, don't compute"). Claude Code —
the harness wrapping every agent, whatever model serves the turn — does. This
reads the run's persisted session transcript and reduces it to a metrics block
merged into research/<id>/run-meta.json, plus a human-readable run-meta.md.

Model-agnostic: it reads the literal model id recorded per turn, so router runs
on Kimi / GLM / GPT / etc. are measured the same as 1P Claude. Dollar cost is
ESTIMATED from bin/model-prices.json (the harness only knows Claude pricing).

Subagents (experimenter/refuter/writer) do NOT get their own transcript; their
usage is reported back inline in the orchestrator's Agent/Task tool_result
(`subagent_tokens`, `tool_uses`, `duration_ms`). We parse those and attribute
them per subagent, using the run's roster to know which model each ran on. The
orchestrator transcript is located by the pinned --session-id (unique), so no
guessing across files.

Usage:
  run-metrics.py --session-id <uuid> [--project-dir DIR] [--research-dir DIR]
                 [--started-at ISO8601] [--prices bin/model-prices.json]
"""

import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime


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
                             "cacheCreation": 0.0, "estimate": True},
                "_heuristics": [], "models": {}}


def price_for(model, prices):
    """Resolve a price entry: exact id, then substring heuristic, then default."""
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


def subagent_cost(tokens, price):
    """Subagent usage is a single total (no in/out split), so estimate with the
    model's blended (mean of input & output) rate."""
    blended = (price.get("input", 0) + price.get("output", 0)) / 2.0
    return tokens * blended / 1_000_000.0


def subagent_model(stype, models):
    if stype in ("experimenter", "refuter"):
        return models.get("experimenter_refuter")
    if stype == "writer":
        return models.get("writer_fast")
    return models.get("orchestrator")


_USAGE_RE = re.compile(r"(subagent_tokens|tool_uses|duration_ms):\s*(\d+)")


def parse_run(path):
    """Parse the orchestrator transcript: assistant turns (model/usage), tool
    calls, time span, and subagent usage embedded in Agent/Task tool_results."""
    turns, tools = [], {}
    tmin = tmax = None
    spawn_type = {}     # tool_use_id -> subagent_type
    subagents = []      # {type, tokens, toolUses, durationMs}
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
        msg = e.get("message", {}) or {}
        content = msg.get("content")
        if e.get("type") == "assistant":
            turns.append({"model": msg.get("model"),
                          "usage": msg.get("usage", {}) or {}})
            for b in (content or []):
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    name = b.get("name", "?")
                    tools[name] = tools.get(name, 0) + 1
                    if name in ("Task", "Agent"):
                        spawn_type[b.get("id")] = \
                            (b.get("input", {}) or {}).get("subagent_type", "?")
        # tool_results (subagent returns) usually arrive in user-role messages
        if isinstance(content, list):
            for b in content:
                if not (isinstance(b, dict) and b.get("type") == "tool_result"):
                    continue
                txt = b.get("content")
                if isinstance(txt, list):
                    txt = " ".join(x.get("text", "") for x in txt
                                   if isinstance(x, dict))
                txt = str(txt)
                found = dict(_USAGE_RE.findall(txt))
                if "subagent_tokens" in found:
                    subagents.append({
                        "type": spawn_type.get(b.get("tool_use_id"), "?"),
                        "tokens": int(found["subagent_tokens"]),
                        "toolUses": int(found.get("tool_uses", 0)),
                        "durationMs": int(found.get("duration_ms", 0))})
    return {"turns": turns, "tools": tools, "tmin": tmin, "tmax": tmax,
            "subagents": subagents}


def find_research_dir(project_dir, started_at):
    # Prefer an existing run-meta.json matching startedAt (non-explore seeds one).
    metas = glob.glob(os.path.join(project_dir, "research", "*", "run-meta.json"))
    if metas and started_at:
        for c in metas:
            try:
                if json.load(open(c)).get("startedAt") == started_at:
                    return os.path.dirname(c)
            except (OSError, ValueError):
                pass
    # Explore mode: the agent-chosen slug has no run-meta.json yet, so locate the
    # run by its plan.md (newest one written during/after the run window).
    plans = [p for p in glob.glob(os.path.join(project_dir, "research", "*", "plan.md"))
             if not os.path.basename(os.path.dirname(p)).startswith("_")]
    if plans:
        start_epoch = (parse_iso(started_at).timestamp() if parse_iso(started_at) else 0)
        recent = [p for p in plans if os.path.getmtime(p) >= start_epoch - 5]
        pool = recent or plans
        return os.path.dirname(max(pool, key=os.path.getmtime))
    if metas:
        return os.path.dirname(max(metas, key=os.path.getmtime))
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--session-id", required=True)
    ap.add_argument("--project-dir", default=os.getcwd())
    ap.add_argument("--research-dir")
    ap.add_argument("--started-at")
    ap.add_argument("--roster-file",
                    help="JSON sidecar with the deterministic roster (models/mode/"
                         "gateway/startedAt) when run-meta.json isn't pre-seeded "
                         "(explore mode). Avoids the agent needing an env var.")
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
    prices = load_prices(args.prices)

    # Resolve research dir + roster first (the roster tells us each subagent's model).
    research_dir = args.research_dir or find_research_dir(args.project_dir, args.started_at)
    meta = {}
    if research_dir:
        mp = os.path.join(research_dir, "run-meta.json")
        if os.path.exists(mp):
            try:
                meta = json.load(open(mp))
            except ValueError:
                meta = {}
    # Seed roster/mode/gateway/id from the runner's sidecar when run-meta.json
    # wasn't pre-seeded (explore mode) — so the agent never has to write it.
    roster_meta = {}
    if args.roster_file and os.path.exists(args.roster_file):
        try:
            roster_meta = json.load(open(args.roster_file))
        except (OSError, ValueError):
            roster_meta = {}
    for k in ("models", "mode", "gateway", "startedAt", "id"):
        if not meta.get(k) and roster_meta.get(k):
            meta[k] = roster_meta[k]
    roster = meta.get("models", {})

    run = parse_run(orch_path)
    turns = run["turns"]

    # Orchestrator: detailed per-turn tokens + cost.
    orch_tokens = {"input": 0, "output": 0, "cacheRead": 0, "cacheCreation": 0}
    by_model = {}
    orch_cost = 0.0
    any_estimate = False
    for t in turns:
        price, is_def = price_for(t["model"], prices)
        if is_def or price.get("estimate"):
            any_estimate = True
        c = turn_cost(t["usage"], price)
        orch_cost += c
        u = t["usage"]
        for k, uk in (("input", "input_tokens"), ("output", "output_tokens"),
                      ("cacheRead", "cache_read_input_tokens"),
                      ("cacheCreation", "cache_creation_input_tokens")):
            orch_tokens[k] += u.get(uk, 0)
        m = by_model.setdefault(t["model"], {"turns": 0, "estCostUSD": 0.0,
                                "tokens": dict.fromkeys(orch_tokens, 0)})
        m["turns"] += 1
        m["estCostUSD"] += c
        for k, uk in (("input", "input_tokens"), ("output", "output_tokens"),
                      ("cacheRead", "cache_read_input_tokens"),
                      ("cacheCreation", "cache_creation_input_tokens")):
            m["tokens"][k] += u.get(uk, 0)
    for m in by_model.values():
        m["estCostUSD"] = round(m["estCostUSD"], 4)

    # Subagents: total tokens (blended-rate cost) + tools + duration, by roster model.
    per_subagent = []
    subagent_cost_total = 0.0
    subagent_tokens_total = 0
    for s in run["subagents"]:
        model = subagent_model(s["type"], roster)
        price, is_def = price_for(model, prices)
        if is_def or price.get("estimate"):
            any_estimate = True
        c = subagent_cost(s["tokens"], price)
        subagent_cost_total += c
        subagent_tokens_total += s["tokens"]
        per_subagent.append({"type": s["type"], "model": model,
                             "tokens": s["tokens"], "toolUses": s["toolUses"],
                             "durationMs": s["durationMs"],
                             "estCostUSD": round(c, 4)})

    wall = (run["tmax"] - run["tmin"]).total_seconds() if run["tmin"] and run["tmax"] else None
    total_cost = orch_cost + subagent_cost_total

    metrics = {
        "measuredBy": "bin/run-metrics.py (from Claude Code transcript)",
        "sessionId": args.session_id,
        "wallClockSeconds": round(wall, 1) if wall is not None else None,
        "orchestratorTurns": len(turns),
        "orchestratorTokens": orch_tokens,
        "subagentTokensTotal": subagent_tokens_total,
        "toolCalls": {"total": sum(run["tools"].values()), "byName": run["tools"]},
        "estimatedCostUSD": round(total_cost, 4),
        "estimatedCostBreakdownUSD": {"orchestrator": round(orch_cost, 4),
                                      "subagents": round(subagent_cost_total, 4)},
        "costIsEstimate": True,
        "costNote": ("Estimated from bin/model-prices.json; subagent cost uses a "
                     "blended (mean in/out) rate since the harness reports only a "
                     "subagent token total."
                     + (" Some models used default/estimate pricing." if any_estimate else "")),
        "byModel": by_model,
        "perSubagent": per_subagent,
    }

    if not research_dir or not os.path.isdir(research_dir):
        print("run-metrics: could not locate research dir; metrics not written.",
              file=sys.stderr)
        print(json.dumps(metrics, indent=2))
        return 0

    if meta.get("id") in (None, "explore"):
        meta["id"] = os.path.basename(research_dir)
    meta["metrics"] = metrics
    meta.pop("metricsNote", None)
    meta_path = os.path.join(research_dir, "run-meta.json")
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
        f.write("\n")
    write_markdown(os.path.join(research_dir, "run-meta.md"), meta)
    print(f"run-metrics: wrote {meta_path} and run-meta.md "
          f"({len(turns)} orch turns, {len(per_subagent)} subagent(s), "
          f"~${total_cost:.2f} est).")
    print(f"RESEARCH_DIR={research_dir}")
    return 0


def write_markdown(path, meta):
    m = meta.get("metrics", {})
    models = meta.get("models", {})
    L = [f"# Run metadata — {meta.get('id', '?')}", "",
         f"- **Started:** {meta.get('startedAt', '?')}",
         f"- **Mode:** {meta.get('mode', '?')}"
         + (f" (gateway {meta['gateway']})" if meta.get("gateway") else ""), ""]
    L += ["## Model roster", "", "| Role | Model |", "|---|---|",
          f"| orchestrator | {models.get('orchestrator', '?')} |",
          f"| experimenter / refuter | {models.get('experimenter_refuter', '?')} |",
          f"| writer / fast | {models.get('writer_fast', '?')} |", ""]
    wall = m.get("wallClockSeconds")
    wall_s = f"{int(wall // 60)}m {int(wall % 60)}s" if isinstance(wall, (int, float)) else "?"
    tk = m.get("orchestratorTokens", {})
    br = m.get("estimatedCostBreakdownUSD", {})
    L += ["## Global", "",
          f"- **Wall clock:** {wall_s}",
          f"- **Orchestrator turns:** {m.get('orchestratorTurns', '?')}",
          f"- **Orchestrator tokens:** in {tk.get('input', 0):,} / out "
          f"{tk.get('output', 0):,} / cache-read {tk.get('cacheRead', 0):,} / "
          f"cache-create {tk.get('cacheCreation', 0):,}",
          f"- **Subagent tokens (total):** {m.get('subagentTokensTotal', 0):,}",
          f"- **Tool calls (orchestrator):** {m.get('toolCalls', {}).get('total', '?')}",
          f"- **Estimated cost:** ~${m.get('estimatedCostUSD', 0):.2f} "
          f"(orchestrator ${br.get('orchestrator', 0):.2f} + subagents "
          f"${br.get('subagents', 0):.2f})", ""]
    by = m.get("byModel", {})
    if by:
        L += ["## Orchestrator by model", "",
              "| Model | Turns | In | Out | Cache-read | Est $ |",
              "|---|---:|---:|---:|---:|---:|"]
        for name, d in sorted(by.items(), key=lambda kv: -kv[1]["estCostUSD"]):
            t = d["tokens"]
            L.append(f"| {name} | {d['turns']} | {t['input']:,} | {t['output']:,} | "
                     f"{t['cacheRead']:,} | ${d['estCostUSD']:.2f} |")
        L.append("")
    ps = m.get("perSubagent", [])
    if ps:
        L += ["## Subagents", "",
              "| Subagent | Model | Tokens | Tools | Time | Est $ |",
              "|---|---|---:|---:|---:|---:|"]
        for s in ps:
            secs = s.get("durationMs", 0) / 1000.0
            L.append(f"| {s['type']} | {s.get('model', '?')} | {s['tokens']:,} | "
                     f"{s['toolUses']} | {int(secs // 60)}m{int(secs % 60)}s | "
                     f"${s['estCostUSD']:.2f} |")
        L.append("")
    L += ["---", "",
          f"*{m.get('measuredBy', 'measured from telemetry')}. {m.get('costNote', '')}*", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))


if __name__ == "__main__":
    sys.exit(main())
