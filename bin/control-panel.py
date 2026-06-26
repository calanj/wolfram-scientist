#!/usr/bin/env python3
"""Local control panel for the Wolfram Scientist.

A single-file, dependency-free web UI to tweak the runner's knobs and kick off
runs, streaming the live log back to the browser. It just shells out to
bin/run-research.sh — every guarantee (the Sonnet cap, auth, the agents) lives
there, not here.

    /usr/bin/python3 bin/control-panel.py          # then open http://127.0.0.1:8765
    /usr/bin/python3 bin/control-panel.py --port 9000

Launch it from a shell that has your run env (e.g. LITELLM_KEY for
router mode and your Claude auth) — the subprocess inherits this server's
environment. Binds to 127.0.0.1 only.
"""
import argparse
import json
import os
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUNNER = os.path.join(ROOT, "bin", "run-research.sh")
VERSION = "6"  # bump on UI changes; shown in the header so a stale page is obvious

_lock = threading.Lock()
_current = {"proc": None}


def _short(s, n=160):
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[:n] + "…"


def _tool_summary(name, inp):
    inp = inp or {}
    if name == "Task":
        return f"→ delegate to {inp.get('subagent_type','?')}: {_short(inp.get('description',''), 80)}"
    if name == "Bash":
        return f"$ {_short(inp.get('command',''), 120)}"
    if name in ("Read", "Write", "Edit"):
        return f"{name} {inp.get('file_path','')}"
    if name.startswith("mcp__Wolfram__"):
        short = name.replace("mcp__Wolfram__", "Wolfram/")
        arg = inp.get("input") or inp.get("code") or inp.get("symbol") or inp.get("query") or ""
        return f"{short}: {_short(arg, 120)}"
    if name in ("WebSearch", "WebFetch"):
        return f"{name}: {_short(inp.get('query') or inp.get('url',''), 100)}"
    return f"{name} {_short(json.dumps(inp), 100)}"


def _fmt_event(line):
    """Translate one stream-json line into a readable progress line, or None to
    skip. Non-JSON lines (the runner's plain echoes) pass through verbatim."""
    line = line.rstrip("\n")
    if not line.strip():
        return None
    try:
        ev = json.loads(line)
    except json.JSONDecodeError:
        return line  # runner echoes ("Routing ALL agents through …")
    t = ev.get("type")
    sub = "    " if ev.get("parent_tool_use_id") else ""  # indent subagent activity
    if t == "system" and ev.get("subtype") == "init":
        return f"● session init — model={ev.get('model','?')}"
    if t == "assistant":
        out = []
        for b in ev.get("message", {}).get("content", []):
            if b.get("type") == "text" and b.get("text", "").strip():
                out.append(sub + _short(b["text"], 400))
            elif b.get("type") == "tool_use":
                out.append(sub + "  " + _tool_summary(b.get("name", "?"), b.get("input")))
        return "\n".join(out) if out else None
    if t == "user":
        out = []
        for b in ev.get("message", {}).get("content", []):
            if isinstance(b, dict) and b.get("type") == "tool_result":
                c = b.get("content")
                if isinstance(c, list):
                    c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
                mark = "✗" if b.get("is_error") else "✓"
                out.append(sub + f"  {mark} {_short(c, 200)}")
        return "\n".join(out) if out else None
    if t == "result":
        ms = ev.get("duration_ms", 0)
        cost = ev.get("total_cost_usd")
        tail = f", ${cost:.4f}" if isinstance(cost, (int, float)) else ""
        status = "✓ done" if not ev.get("is_error") else "✗ error"
        head = f"━━ {status} in {ms/1000:.1f}s{tail}"
        res = ev.get("result")
        return f"{head}\n{_short(res, 600)}" if res else head
    return None  # hooks, rate-limit, misc


def _corporate_ca():
    """Locate a CA bundle for a corporate TLS-intercepting proxy, so curl can
    verify the LLM gateway over HTTPS (claude/Node use NODE_EXTRA_CA_CERTS for
    the same reason). Returns a path or None."""
    candidates = [
        os.environ.get("CURL_CA_BUNDLE"),
        os.environ.get("SSL_CERT_FILE"),
        os.environ.get("NODE_EXTRA_CA_CERTS"),
        os.path.expanduser("~/.cline/certs/wolfram-ca.pem"),
    ]
    return next((c for c in candidates if c and os.path.isfile(c)), None)

PAGE = r"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>🔬 Wolfram Scientist — Control Panel</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin:0; font:14px/1.5 ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;
         background:#0e1117; color:#e6edf3;
         height:100vh; overflow:hidden; display:flex; flex-direction:column; }
  header { flex:0 0 auto; padding:16px 24px; border-bottom:1px solid #21262d; }
  header h1 { margin:0; font-size:18px; }
  header p { margin:4px 0 0; color:#8b949e; font-size:12px; }
  main { flex:1 1 auto; min-height:0; display:grid; grid-template-columns:380px 1fr; gap:0; }
  form { padding:20px 24px; overflow-y:auto; border-right:1px solid #21262d; }
  label { display:block; margin:14px 0 4px; font-weight:600; font-size:12px; color:#c9d1d9; }
  .hint { font-weight:400; color:#8b949e; }
  input[type=text], textarea, select {
    width:100%; padding:8px 10px; background:#0d1117; color:#e6edf3;
    border:1px solid #30363d; border-radius:6px; font:inherit; }
  textarea { resize:vertical; min-height:80px; }
  .seg { display:flex; gap:8px; margin-top:4px; }
  .seg label { display:flex; align-items:center; gap:6px; margin:0; padding:8px 12px;
    border:1px solid #30363d; border-radius:6px; cursor:pointer; flex:1; font-weight:500; }
  .seg input { accent-color:#2ea043; }
  .row { display:flex; gap:8px; align-items:flex-end; }
  .row > div { flex:1; }
  button { margin-top:18px; width:100%; padding:10px; border:0; border-radius:6px;
    background:#238636; color:#fff; font-weight:600; font-size:14px; cursor:pointer; }
  button:hover { background:#2ea043; }
  button.stop { background:#da3633; margin-top:8px; }
  button.stop:hover { background:#f85149; }
  button:disabled { opacity:.5; cursor:not-allowed; }
  .refresh { background:#21262d; color:#c9d1d9; padding:8px; font-size:12px; flex:0 0 auto; width:auto; margin:0; }
  #cmd { margin-top:16px; padding:8px 10px; background:#0d1117; border:1px dashed #30363d;
    border-radius:6px; font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:12px;
    color:#7ee787; word-break:break-all; }
  section.log { display:flex; flex-direction:column; min-height:0; }
  .logbar { padding:10px 24px; border-bottom:1px solid #21262d; display:flex; justify-content:space-between;
    align-items:center; }
  .logbar .status { font-size:12px; color:#8b949e; }
  pre#log { flex:1; min-height:0; margin:0; padding:16px 24px; overflow:auto; white-space:pre-wrap;
    font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:12.5px; }
  .dot { display:inline-block; width:8px; height:8px; border-radius:50%; background:#484f58; margin-right:6px; }
  .dot.run { background:#d29922; animation:pulse 1s infinite; }
  .dot.ok { background:#2ea043; } .dot.err { background:#f85149; }
  @keyframes pulse { 50% { opacity:.3; } }
</style></head>
<body>
<header>
  <h1>🔬 Wolfram Scientist — Control Panel</h1>
  <p>Tweak the knobs, kick off a run. Everything streams below. Guarantees (Sonnet cap, auth) are enforced by <code>bin/run-research.sh</code>. <span style="color:#484f58">build __VERSION__</span></p>
</header>
<main>
  <form id="f" onsubmit="return false">
    <label>Mode</label>
    <div class="seg">
      <label><input type="radio" name="mode" value="1p" checked onchange="modeChanged()"> 1P Claude</label>
      <label><input type="radio" name="mode" value="router" onchange="modeChanged()"> LiteLLM router</label>
    </div>

    <label>Research target <span class="hint">— issue number, or a slug for ad-hoc</span></label>
    <input type="text" id="target" placeholder="12   or   ca-rule90">

    <label>Inline seed <span class="hint">— required for a slug; optional for an issue #</span></label>
    <textarea id="seed" placeholder="Explore whether ..."></textarea>

    <label>Orchestrator model <span class="hint">— may be Opus</span></label>
    <select id="orchestrator"></select>

    <div class="row">
      <div>
        <label>Experimenter model <span class="hint">— Sonnet-capped (Claude)</span></label>
        <select id="experimenter"></select>
      </div>
      <button type="button" class="refresh" id="refresh" onclick="loadModels(true)" title="Refresh router model list">↻</button>
    </div>

    <div id="cmd">—</div>
    <button type="button" id="run" onclick="startRun()">▶ Start run</button>
    <button type="button" class="stop" id="stop" onclick="stopRun()" disabled>■ Stop</button>
  </form>

  <section class="log">
    <div class="logbar">
      <span><span class="dot" id="dot"></span><span id="status" class="status">idle</span></span>
      <button class="refresh" onclick="document.getElementById('log').textContent=''">clear log</button>
    </div>
    <pre id="log"></pre>
  </section>
</main>

<script>
let MODELS = [];
const $ = id => document.getElementById(id);
window.addEventListener('error', e => {
  try { $('log').textContent += '\n[js error] '+e.message+' @ '+(e.filename||'')+':'+e.lineno+'\n'; } catch(_){}
});
const mode = () => document.querySelector('input[name=mode]:checked').value;

function opt(v, label){ const o=document.createElement('option'); o.value=v; o.textContent=label??v; return o; }

function fillSelects(){
  const orch = $('orchestrator'), exp = $('experimenter');
  orch.innerHTML=''; exp.innerHTML='';
  if (mode()==='1p'){
    orch.append(opt('', 'default (session model)'), opt('opus'), opt('sonnet'), opt('haiku'));
    exp.append(opt('', 'default (sonnet)'), opt('sonnet'), opt('haiku'));
  } else {
    orch.append(opt('claude-opus-4-7', 'claude-opus-4-7 (default)'));
    exp.append(opt('claude-sonnet-4-6', 'claude-sonnet-4-6 (default)'));
    for (const m of MODELS){
      orch.append(opt(m));
      if (!/opus/i.test(m)) exp.append(opt(m));   // mirror the Sonnet cap
    }
  }
  updateCmd();
}

async function loadModels(force){
  if (mode()!=='router') { fillSelects(); return; }
  if (MODELS.length && !force){ fillSelects(); return; }
  $('status').textContent='loading models…';
  try {
    const r = await fetch('/api/models'); const j = await r.json();
    if (j.error){ $('log').textContent += '\n[model list error] '+j.error+'\n'; MODELS=[]; }
    else MODELS = j.models;
  } catch(e){ $('log').textContent += '\n[model list error] '+e+'\n'; }
  $('status').textContent='idle';
  fillSelects();
}

function modeChanged(){ loadModels(false); }

function buildArgs(){
  const a=[];
  if (mode()==='router') a.push('--router');
  if ($('orchestrator').value) a.push('--model', $('orchestrator').value);
  if ($('experimenter').value) a.push('--experimenter-model', $('experimenter').value);
  if ($('target').value.trim()) a.push($('target').value.trim());
  if ($('seed').value.trim()) a.push($('seed').value.trim());
  return a;
}
function updateCmd(){
  const a = buildArgs().map(x => /\s/.test(x) ? JSON.stringify(x) : x);
  $('cmd').textContent = 'bin/run-research.sh ' + (a.join(' ') || '…');
}
['target','seed','orchestrator','experimenter'].forEach(id =>
  document.addEventListener('input', e => { if (e.target.id===id) updateCmd(); }));

async function startRun(){
  if (!$('target').value.trim()){ alert('Enter a research target (issue # or slug).'); return; }
  $('run').disabled=true; $('stop').disabled=false;
  $('dot').className='dot run'; $('status').textContent='starting…';
  $('log').textContent += '$ '+$('cmd').textContent+'\n(launching — first output can take ~10s)\n\n';
  $('log').scrollTop=$('log').scrollHeight;
  try {
    const res = await fetch('/api/run', {method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({mode:mode(), orchestrator:$('orchestrator').value,
        experimenter:$('experimenter').value, target:$('target').value.trim(), seed:$('seed').value.trim()})});
    if (!res.ok){ throw new Error('server returned HTTP '+res.status); }
    $('status').textContent='running';
    const reader = res.body.getReader(); const dec=new TextDecoder();
    for(;;){ const {value,done}=await reader.read(); if(done)break;
      const log=$('log'); log.textContent+=dec.decode(value,{stream:true}); log.scrollTop=log.scrollHeight; }
    const t=$('log').textContent; const ok=/\[exit 0\]\s*$/.test(t);
    $('dot').className='dot '+(ok?'ok':'err'); $('status').textContent=ok?'done':'finished (non-zero / stopped)';
  } catch(e){
    $('log').textContent += '\n[panel error] '+e+'\n';
    $('dot').className='dot err'; $('status').textContent='error';
  } finally {
    $('run').disabled=false; $('stop').disabled=true;
  }
}
async function stopRun(){ await fetch('/api/stop',{method:'POST'}); }

loadModels(false);
</script>
</body></html>
"""


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"  # connection-close framing → simple streaming

    def log_message(self, *a):  # quiet
        pass

    def _send(self, code, body, ctype="text/html; charset=utf-8"):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/" or self.path.startswith("/index"):
            self._send(200, PAGE.replace("__VERSION__", VERSION))
        elif self.path == "/api/models":
            self._send(200, json.dumps(self._models()), "application/json")
        else:
            self._send(404, "not found", "text/plain")

    def do_POST(self):
        if self.path == "/api/stop":
            with _lock:
                p = _current["proc"]
            if p and p.poll() is None:
                p.terminate()
            self._send(200, json.dumps({"ok": True}), "application/json")
        elif self.path == "/api/run":
            self._run()
        else:
            self._send(404, "not found", "text/plain")

    # --- helpers -------------------------------------------------------------
    def _models(self):
        """Fetch the router model list directly (curl does the HTTPS; we parse
        the JSON here). Avoids the runner's pyenv `curl | python3 -c` pipeline
        and surfaces a real error rather than a traceback."""
        key = os.environ.get("LITELLM_KEY")
        base = os.environ.get("LITELLM_BASE")
        if not key or not base:
            return {"error": "LITELLM_KEY and LITELLM_BASE must be set in this "
                    "server's environment. Relaunch the panel from a shell that "
                    "has them (set them in your shell rc, e.g. ~/.zshrc)."}
        cmd = ["curl", "-sS", "-w", "\n%{http_code}",
               f"{base}/v1/models",
               "-H", f"Authorization: Bearer {key}"]
        ca = _corporate_ca()  # behind a TLS-intercepting proxy, curl needs the CA
        if ca:
            cmd += ["--cacert", ca]
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        except Exception as e:  # noqa: BLE001
            return {"error": f"could not run curl: {e}"}
        if out.returncode != 0:
            return {"error": (out.stderr or "curl failed").strip()[:400]}
        body, _, code = out.stdout.rpartition("\n")
        if code.strip() != "200":
            return {"error": f"router returned HTTP {code.strip()}: {body.strip()[:300]}"}
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            return {"error": f"router returned non-JSON: {body.strip()[:200]}"}
        models = sorted(m["id"] for m in data.get("data", [])
                        if m.get("id") and "embedding" not in m["id"])
        return {"models": models}

    def _run(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length) or "{}")
        argv = [RUNNER]
        if body.get("mode") == "router":
            argv.append("--router")
        if body.get("orchestrator"):
            argv += ["--model", body["orchestrator"]]
        if body.get("experimenter"):
            argv += ["--experimenter-model", body["experimenter"]]
        if body.get("target"):
            argv.append(body["target"])
        if body.get("seed"):
            argv.append(body["seed"])

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

        env = {**os.environ, "WS_STREAM": "1"}  # ask the runner for the event stream
        with _lock:
            if _current["proc"] and _current["proc"].poll() is None:
                self.wfile.write(b"A run is already in progress. Stop it first.\n[exit 1]\n")
                return
            proc = subprocess.Popen(argv, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, bufsize=1)
            _current["proc"] = proc
        try:
            for line in proc.stdout:
                try:
                    out = _fmt_event(line)
                except Exception:  # noqa: BLE001 — never let formatting kill the stream
                    out = line.rstrip("\n")
                if out:
                    self.wfile.write((out + "\n").encode())
                    self.wfile.flush()
            proc.wait()
            self.wfile.write(f"\n[exit {proc.returncode}]\n".encode())
        except (BrokenPipeError, ConnectionResetError):
            proc.terminate()  # client navigated away
        finally:
            with _lock:
                _current["proc"] = None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--host", default="127.0.0.1")
    args = ap.parse_args()
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Wolfram Scientist control panel → http://{args.host}:{args.port}")
    print("(launch from a shell that has LITELLM_KEY + your Claude auth)")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    main()
