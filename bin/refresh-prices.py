#!/usr/bin/env python3
"""refresh-prices.py — regenerate bin/model-prices.json from the router.

run-metrics.py estimates dollar cost from a per-model price table. Rather than
hand-maintain it, pull the live model list and pricing from your LiteLLM-style
gateway, which exposes per-token costs at /model/info.

Env (no hostnames are baked into the repo):
  LITELLM_BASE  the gateway base URL (e.g. https://<your-gateway>)
  LITELLM_KEY   the bearer token

Usage:
  LITELLM_BASE=... LITELLM_KEY=... bin/refresh-prices.py

Keeps the existing _note / _heuristics / _default in model-prices.json and
replaces the "models" map with whatever the gateway reports (costs converted
from $/token to $/million-tokens). Run with /usr/bin/python3 if your default
python has broken TLS.
"""

import json
import os
import sys
import urllib.request

HERE = os.path.dirname(__file__)
TABLE = os.path.join(HERE, "model-prices.json")
PER_M = 1_000_000.0


def fetch(base, key):
    req = urllib.request.Request(
        base.rstrip("/") + "/model/info",
        headers={"Authorization": f"Bearer {key}"} if key else {})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def to_m(x):
    try:
        return round(float(x) * PER_M, 6)
    except (TypeError, ValueError):
        return None


def main():
    base = os.environ.get("LITELLM_BASE")
    key = os.environ.get("LITELLM_KEY")
    if not base:
        print("LITELLM_BASE not set — point it at your gateway base URL.", file=sys.stderr)
        return 2

    payload = fetch(base, key)
    rows = payload.get("data", payload if isinstance(payload, list) else [])

    models = {}
    skipped = 0
    for row in rows:
        name = row.get("model_name") or row.get("model")
        info = row.get("model_info", {}) or {}
        inp = to_m(info.get("input_cost_per_token"))
        out = to_m(info.get("output_cost_per_token"))
        if not name or inp is None or out is None:
            skipped += 1
            continue
        entry = {"input": inp, "output": out}
        cr = to_m(info.get("cache_read_input_token_cost"))
        cc = to_m(info.get("cache_creation_input_token_cost"))
        entry["cacheRead"] = cr if cr is not None else 0.0
        entry["cacheCreation"] = cc if cc is not None else 0.0
        models[name] = entry

    if not models:
        print(f"No priced models returned (skipped {skipped}); leaving table unchanged.",
              file=sys.stderr)
        return 1

    # Preserve the human-maintained scaffolding; replace only the models map.
    try:
        table = json.load(open(TABLE))
    except (OSError, ValueError):
        table = {}
    table.setdefault("_note", "Per-model price table for run-metrics.py cost "
                     "estimates. USD per million tokens.")
    table.setdefault("_default", {"input": 1.0, "output": 5.0, "cacheRead": 0.1,
                                  "cacheCreation": 1.25, "estimate": True})
    table.setdefault("_heuristics", [
        {"contains": "opus", "use": "claude-opus"},
        {"contains": "sonnet", "use": "claude-sonnet"},
        {"contains": "haiku", "use": "claude-haiku"}])
    table["_refreshedFrom"] = "router /model/info"
    table["models"] = dict(sorted(models.items()))

    with open(TABLE, "w") as f:
        json.dump(table, f, indent=2)
        f.write("\n")
    print(f"Wrote {len(models)} models to {TABLE} (skipped {skipped} without pricing).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
