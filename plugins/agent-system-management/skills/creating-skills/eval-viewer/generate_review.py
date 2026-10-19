#!/usr/bin/env python3
"""Generate and serve a review page for eval results.

Reads the workspace directory, discovers runs (directories with outputs/),
embeds all output data into a self-contained HTML page, and serves it via
a tiny HTTP server. Feedback auto-saves to feedback.json in the workspace.

Usage:
    python generate_review.py <workspace-path> [--port PORT] [--skill-name NAME]
    python generate_review.py <workspace-path> --previous-workspace /path/to/old/iteration

No dependencies beyond the Python stdlib are required.
"""

import argparse
import base64
import json
import math
import mimetypes
import os
import re
import signal
import subprocess
import sys
import time
import webbrowser
from functools import partial
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

# A repeat run folder: run-<n>. Same constant in scripts/aggregate_benchmark.py.
RUN_DIR_RE = re.compile(r"^run-(\d+)$")

# An eval folder: eval-<n>-<name>. Same constant in scripts/aggregate_benchmark.py.
EVAL_DIR_RE = re.compile(r"^eval-(\d+)(-|$)")

# Files to exclude from output listings
METADATA_FILES = {"transcript.md", "user_notes.md", "metrics.json"}

# Extensions we render as inline text
TEXT_EXTENSIONS = {
    ".txt", ".md", ".json", ".csv", ".py", ".js", ".ts", ".tsx", ".jsx",
    ".yaml", ".yml", ".xml", ".html", ".css", ".sh", ".rb", ".go", ".rs",
    ".java", ".c", ".cpp", ".h", ".hpp", ".sql", ".r", ".toml",
}

# Extensions we render as inline images
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}

# MIME type overrides for common types
MIME_OVERRIDES = {
    ".svg": "image/svg+xml",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


# JSON readers. A missing value takes its default quietly; a wrong-typed one
# (bool is never a number) takes it with one warning. Same helpers in
# scripts/aggregate_benchmark.py.
NUM = (int, float)
KIND_NAMES = {dict: "an object", list: "a list", str: "a string", int: "an int", NUM: "a number"}


def _read_obj(path: Path) -> dict | None:
    """A JSON file's object; None, with a warning, for bad JSON, an
    unreadable file or a value that is not an object."""
    try:
        data = json.loads(path.read_text())
    except (ValueError, OSError) as e:
        print(f"Warning: {path}: cannot read: {e}")
        return None
    if not isinstance(data, dict):
        print(f"Warning: {path}: not a JSON object, ignored")
        return None
    return data


def _finite(value) -> bool:
    """Whether a number is finite as a float (not NaN, Infinity or too big)."""
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _ok(value, kind, path, field: str) -> bool:
    """Whether value has the kind (a number also finite); warns when not."""
    if isinstance(value, kind) and not isinstance(value, bool) and (kind is not NUM or _finite(value)):
        return True
    print(f"Warning: {path}: {field} is not {KIND_NAMES[kind]}, ignored")
    return False


def _field(obj: dict, key: str, kind, default, path, field: str = ""):
    """obj[key] if it has the kind, else default."""
    if key not in obj:
        return default
    return obj[key] if _ok(obj[key], kind, path, field or key) else default


def _items(values: list, kind, path, field: str) -> list:
    """The items of values that have the kind."""
    return [v for v in values if _ok(v, kind, path, field + " item")]


def assign_eval_ids(evals: list[tuple]) -> list[int]:
    """Unique ids for evals given as (folder, metadata id, folder id) in
    folder order: the int metadata id (the first eval keeps a duplicate),
    else the folder id if no eval holds it, else one past the largest id in
    use. Same function in scripts/aggregate_benchmark.py."""
    ids = [None] * len(evals)
    used = set()
    for i, (folder, meta_id, _) in enumerate(evals):
        if meta_id is None:
            continue
        if meta_id in used:
            print(f"Warning: {folder}: eval_id {meta_id} is taken by another eval")
        else:
            ids[i] = meta_id
            used.add(meta_id)
    for i, (_, _, folder_id) in enumerate(evals):
        if ids[i] is None and folder_id is not None and folder_id not in used:
            ids[i] = folder_id
            used.add(folder_id)
    for i, (folder, _, _) in enumerate(evals):
        if ids[i] is None:
            ids[i] = max(used, default=0) + 1
            used.add(ids[i])
            print(f"Warning: {folder}: no free eval id, using {ids[i]}")
    return ids


def clean_grading(path: Path) -> dict | None:
    """grading.json with the fields the page reads made safe; None when it
    is not an object."""
    grading = _read_obj(path)
    if grading is None:
        return None
    grading = dict(grading)
    if "summary" in grading:
        summary = dict(_field(grading, "summary", dict, {}, path))
        for key in ("pass_rate", "passed", "failed", "total"):
            if key in summary:
                summary[key] = _field(summary, key, NUM, 0, path, "summary." + key)
        grading["summary"] = summary
    if "expectations" in grading:
        grading["expectations"] = _items(
            _field(grading, "expectations", list, [], path), dict, path, "expectations")
    return grading


# Numbers in a benchmark run's result
RESULT_NUMBERS = ("pass_rate", "passed", "failed", "total", "time_seconds", "tokens", "tool_calls", "errors")


def clean_benchmark(path: Path) -> dict | None:
    """benchmark.json with the fields the Benchmark tab reads made safe:
    a wrong-typed field is dropped or takes its default. None when it is
    not an object (no Benchmark tab)."""
    data = _read_obj(path)
    if data is None:
        return None
    data = dict(data)
    if "metadata" in data:
        metadata = dict(_field(data, "metadata", dict, {}, path))
        if "evals_run" in metadata and not _ok(metadata["evals_run"], list, path, "metadata.evals_run"):
            del metadata["evals_run"]
        data["metadata"] = metadata
    if "run_summary" in data:
        run_summary = {}
        for config, stats in _field(data, "run_summary", dict, {}, path).items():
            field = "run_summary." + config
            if config == "delta":
                run_summary[config] = stats if _ok(stats, dict, path, field) else {}
            elif _ok(stats, dict, path, field):
                run_summary[config] = {
                    k: v for k, v in stats.items()
                    if k not in ("pass_rate", "time_seconds", "tokens")
                    or (_ok(v, dict, path, f"{field}.{k}")
                        and _ok(v.get("mean"), NUM, path, f"{field}.{k}.mean")
                        and _ok(v.get("stddev"), NUM, path, f"{field}.{k}.stddev"))
                }
        data["run_summary"] = run_summary
    if "runs" in data:
        runs = []
        for run in _items(_field(data, "runs", list, [], path), dict, path, "runs"):
            if "configuration" not in run or not _ok(run["configuration"], str, path, "runs item configuration"):
                continue
            run = dict(run)
            if "result" in run:
                run["result"] = {
                    k: v for k, v in _field(run, "result", dict, {}, path, "runs item result").items()
                    if k not in RESULT_NUMBERS or _ok(v, NUM, path, "runs item result." + k)
                }
            if "expectations" in run:
                run["expectations"] = _items(
                    _field(run, "expectations", list, [], path, "runs item expectations"),
                    dict, path, "runs item expectations")
            runs.append(run)
        data["runs"] = runs
    if "notes" in data:
        data["notes"] = _items(_field(data, "notes", list, [], path), str, path, "notes")
    return data


def get_mime_type(path: Path) -> str:
    ext = path.suffix.lower()
    if ext in MIME_OVERRIDES:
        return MIME_OVERRIDES[ext]
    mime, _ = mimetypes.guess_type(str(path))
    return mime or "application/octet-stream"


def find_runs(workspace: Path) -> list[dict]:
    """Recursively find directories that contain an outputs/ subdirectory."""
    runs: list[dict] = []
    metas: dict[Path, tuple] = {}
    _find_runs_recursive(workspace, workspace, runs, metas)
    # Eval ids by the same rule as scripts/aggregate_benchmark.py, per folder
    # of evals (the benchmark reads one iteration folder), in folder order;
    # every eval-* folder beside a run's eval counts, runs or not
    evals = {run["_eval"] for run in runs if run["_eval"] is not None}
    ids: dict[Path, int] = {}
    for parent in sorted({d.parent for d in evals}):
        group = sorted(d for d in parent.glob("eval-*") if d.is_dir())
        entries = []
        for d in group:
            meta = _folder_meta(d, metas)
            m = EVAL_DIR_RE.match(d.name)
            entries.append((d, meta[0] if meta else None, int(m.group(1)) if m else None))
        ids.update(zip(group, assign_eval_ids(entries)))
    for run in runs:
        eval_dir = run.pop("_eval")
        if eval_dir is not None:
            run["eval_id"] = ids[eval_dir]
    # Runs without an eval_id sort last
    runs.sort(key=lambda r: (r["eval_id"] is None, r["eval_id"] or 0, r["id"]))
    return runs


def _find_runs_recursive(root: Path, current: Path, runs: list[dict], metas: dict) -> None:
    if not current.is_dir():
        return

    # A config dir with run-<n>/ folders: those are the runs, not current
    run_dirs = sorted(
        (d for d in current.iterdir() if d.is_dir() and RUN_DIR_RE.match(d.name)),
        key=lambda d: int(RUN_DIR_RE.match(d.name).group(1)),
    )
    if run_dirs:
        for d in run_dirs:
            _find_runs_recursive(root, d, runs, metas)
        return

    outputs_dir = current / "outputs"
    if outputs_dir.is_dir():
        run = build_run(root, current, metas)
        if run:
            runs.append(run)
        return

    skip = {"node_modules", ".git", "__pycache__", "skill", "inputs"}
    for child in sorted(current.iterdir()):
        # A run-* folder that is not run-<n> (run-notes/) is never a run
        stray_run = child.name.startswith("run-") and not RUN_DIR_RE.match(child.name)
        if child.is_dir() and child.name not in skip and not stray_run:
            _find_runs_recursive(root, child, runs, metas)


def _folder_meta(d: Path, metas: dict) -> tuple | None:
    """d's eval_metadata.json as (int eval_id or None, prompt), read once per
    folder; None when d has none."""
    if d not in metas:
        path = d / "eval_metadata.json"
        meta = None
        if path.exists():
            meta_id, prompt = None, ""
            metadata = _read_obj(path)
            if metadata is not None:
                meta_id = _field(metadata, "eval_id", int, None, path)
                prompt = _field(metadata, "prompt", str, "", path)
            meta = (meta_id, prompt)
        metas[d] = meta
    return metas[d]


def build_run(root: Path, run_dir: Path, metas: dict) -> dict | None:
    """Build a run dict with prompt, outputs, and grading data. _eval names
    its eval: the nearest eval-* folder below root, whose id find_runs sets.
    With none, eval_id is the first eval_metadata.json's int eval_id."""
    # Climb from run_dir up to root: the first eval_metadata.json gives the
    # prompt, the nearest eval-* folder is the eval
    eval_dir = first = None
    for d in [run_dir, *run_dir.parents]:
        if eval_dir is None and d != root and d.name.startswith("eval-"):
            eval_dir = d
        if first is None:
            first = _folder_meta(d, metas)
        if d == root:
            break
    eval_id, prompt = first or (None, "")
    if eval_dir is not None:
        eval_id = None

    # Fall back to transcript.md
    if not prompt:
        for candidate in [run_dir / "transcript.md", run_dir / "outputs" / "transcript.md"]:
            if candidate.exists():
                try:
                    text = candidate.read_text()
                    match = re.search(r"## Eval Prompt\n\n([\s\S]*?)(?=\n##|$)", text)
                    if match:
                        prompt = match.group(1).strip()
                except OSError:
                    pass
                if prompt:
                    break

    if not prompt:
        prompt = "(No prompt found)"

    run_id = str(run_dir.relative_to(root)).replace("/", "-").replace("\\", "-")

    # Collect output files
    outputs_dir = run_dir / "outputs"
    output_files: list[dict] = []
    if outputs_dir.is_dir():
        for f in sorted(outputs_dir.iterdir()):
            if f.is_file() and f.name not in METADATA_FILES:
                output_files.append(embed_file(f))

    # Load grading if present: only the run dir's own grading.json
    grading = None
    grading_path = run_dir / "grading.json"
    if grading_path.exists():
        grading = clean_grading(grading_path)

    return {
        "id": run_id,
        "prompt": prompt,
        "eval_id": eval_id,
        "outputs": output_files,
        "grading": grading,
        "_eval": eval_dir,
    }


def embed_file(path: Path) -> dict:
    """Read a file and return an embedded representation."""
    ext = path.suffix.lower()
    mime = get_mime_type(path)

    if ext in TEXT_EXTENSIONS:
        try:
            content = path.read_text(errors="replace")
        except OSError:
            content = "(Error reading file)"
        return {
            "name": path.name,
            "type": "text",
            "content": content,
        }
    elif ext in IMAGE_EXTENSIONS:
        try:
            raw = path.read_bytes()
            b64 = base64.b64encode(raw).decode("ascii")
        except OSError:
            return {"name": path.name, "type": "error", "content": "(Error reading file)"}
        return {
            "name": path.name,
            "type": "image",
            "mime": mime,
            "data_uri": f"data:{mime};base64,{b64}",
        }
    elif ext == ".pdf":
        try:
            raw = path.read_bytes()
            b64 = base64.b64encode(raw).decode("ascii")
        except OSError:
            return {"name": path.name, "type": "error", "content": "(Error reading file)"}
        return {
            "name": path.name,
            "type": "pdf",
            "data_uri": f"data:{mime};base64,{b64}",
        }
    elif ext == ".xlsx":
        try:
            raw = path.read_bytes()
            b64 = base64.b64encode(raw).decode("ascii")
        except OSError:
            return {"name": path.name, "type": "error", "content": "(Error reading file)"}
        return {
            "name": path.name,
            "type": "xlsx",
            "data_b64": b64,
        }
    else:
        # Binary / unknown: base64 download link
        try:
            raw = path.read_bytes()
            b64 = base64.b64encode(raw).decode("ascii")
        except OSError:
            return {"name": path.name, "type": "error", "content": "(Error reading file)"}
        return {
            "name": path.name,
            "type": "binary",
            "mime": mime,
            "data_uri": f"data:{mime};base64,{b64}",
        }


def load_previous_iteration(workspace: Path) -> dict[str, dict]:
    """Load previous iteration's feedback and outputs.

    Returns a map of run_id -> {"feedback": str, "outputs": list[dict]}.
    """
    result: dict[str, dict] = {}

    # Load feedback
    feedback_map: dict[str, str] = {}
    feedback_path = workspace / "feedback.json"
    if feedback_path.exists():
        try:
            data = json.loads(feedback_path.read_text())
            feedback_map = {
                r["run_id"]: r["feedback"]
                for r in data.get("reviews", [])
                if r.get("feedback", "").strip()
            }
        except (json.JSONDecodeError, OSError, KeyError):
            pass

    # Load runs (to get outputs)
    prev_runs = find_runs(workspace)
    for run in prev_runs:
        result[run["id"]] = {
            "feedback": feedback_map.get(run["id"], ""),
            "outputs": run.get("outputs", []),
        }

    # Also add feedback for run_ids that had feedback but no matching run
    for run_id, fb in feedback_map.items():
        if run_id not in result:
            result[run_id] = {"feedback": fb, "outputs": []}

    return result


def generate_html(
    runs: list[dict],
    skill_name: str,
    previous: dict[str, dict] | None = None,
    benchmark: dict | None = None,
) -> str:
    """Generate the complete standalone HTML page with embedded data."""
    template_path = Path(__file__).parent / "viewer.html"
    template = template_path.read_text()

    # Build previous_feedback and previous_outputs maps for the template
    previous_feedback: dict[str, str] = {}
    previous_outputs: dict[str, list[dict]] = {}
    if previous:
        for run_id, data in previous.items():
            if data.get("feedback"):
                previous_feedback[run_id] = data["feedback"]
            if data.get("outputs"):
                previous_outputs[run_id] = data["outputs"]

    embedded = {
        "skill_name": skill_name,
        "runs": runs,
        "previous_feedback": previous_feedback,
        "previous_outputs": previous_outputs,
    }
    if benchmark:
        embedded["benchmark"] = benchmark

    # Every "<" as <, so no string ("</script>", "<!--") can end or
    # change the script block
    data_json = json.dumps(embedded).replace("<", "\\u003c")

    return template.replace("/*__EMBEDDED_DATA__*/", f"const EMBEDDED_DATA = {data_json};")


# ---------------------------------------------------------------------------
# HTTP server (stdlib only, zero dependencies)
# ---------------------------------------------------------------------------

def _kill_port(port: int) -> None:
    """Kill any process listening on the given port."""
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True, text=True, timeout=5,
        )
        for pid_str in result.stdout.strip().split("\n"):
            if pid_str.strip():
                try:
                    os.kill(int(pid_str.strip()), signal.SIGTERM)
                except (ProcessLookupError, ValueError):
                    pass
        if result.stdout.strip():
            time.sleep(0.5)
    except subprocess.TimeoutExpired:
        pass
    except FileNotFoundError:
        print("Note: lsof not found, cannot check if port is in use", file=sys.stderr)

class ReviewHandler(BaseHTTPRequestHandler):
    """Serves the review HTML and handles feedback saves.

    Regenerates the HTML on each page load so that refreshing the browser
    picks up new eval outputs without restarting the server.
    """

    def __init__(
        self,
        workspace: Path,
        skill_name: str,
        feedback_path: Path,
        previous: dict[str, dict],
        benchmark_path: Path | None,
        *args,
        **kwargs,
    ):
        self.workspace = workspace
        self.skill_name = skill_name
        self.feedback_path = feedback_path
        self.previous = previous
        self.benchmark_path = benchmark_path
        super().__init__(*args, **kwargs)

    def do_GET(self) -> None:
        if self.path == "/" or self.path == "/index.html":
            # Regenerate HTML on each request (re-scans workspace for new outputs)
            runs = find_runs(self.workspace)
            benchmark = None
            if self.benchmark_path and self.benchmark_path.exists():
                benchmark = clean_benchmark(self.benchmark_path)
            html = generate_html(runs, self.skill_name, self.previous, benchmark)
            content = html.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == "/api/feedback":
            data = b"{}"
            if self.feedback_path.exists():
                data = self.feedback_path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_error(404)

    def do_POST(self) -> None:
        if self.path == "/api/feedback":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                if not isinstance(data, dict) or "reviews" not in data:
                    raise ValueError("Expected JSON object with 'reviews' key")
                self.feedback_path.write_text(json.dumps(data, indent=2) + "\n")
                resp = b'{"ok":true}'
                self.send_response(200)
            except (json.JSONDecodeError, OSError, ValueError) as e:
                resp = json.dumps({"error": str(e)}).encode()
                self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        else:
            self.send_error(404)

    def log_message(self, format: str, *args: object) -> None:
        # Suppress request logging to keep terminal clean
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and serve eval review")
    parser.add_argument("workspace", type=Path, help="Path to workspace directory")
    parser.add_argument("--port", "-p", type=int, default=3117, help="Server port (default: 3117)")
    parser.add_argument("--skill-name", "-n", type=str, default=None, help="Skill name for header")
    parser.add_argument(
        "--previous-workspace", type=Path, default=None,
        help="Path to previous iteration's workspace (shows old outputs and feedback as context)",
    )
    parser.add_argument(
        "--benchmark", type=Path, default=None,
        help="Path to benchmark.json to show in the Benchmark tab",
    )
    parser.add_argument(
        "--static", "-s", type=Path, default=None,
        help="Write standalone HTML to this path instead of starting a server",
    )
    args = parser.parse_args()

    workspace = args.workspace.resolve()
    if not workspace.is_dir():
        print(f"Error: {workspace} is not a directory", file=sys.stderr)
        sys.exit(1)

    runs = find_runs(workspace)
    if not runs:
        print(f"No runs found in {workspace}", file=sys.stderr)
        sys.exit(1)

    skill_name = args.skill_name or workspace.name.replace("-workspace", "")
    feedback_path = workspace / "feedback.json"

    previous: dict[str, dict] = {}
    if args.previous_workspace:
        previous = load_previous_iteration(args.previous_workspace.resolve())

    benchmark_path = args.benchmark.resolve() if args.benchmark else None
    benchmark = None
    if benchmark_path and benchmark_path.exists():
        benchmark = clean_benchmark(benchmark_path)

    if args.static:
        html = generate_html(runs, skill_name, previous, benchmark)
        args.static.parent.mkdir(parents=True, exist_ok=True)
        args.static.write_text(html)
        print(f"\n  Static viewer written to: {args.static}\n")
        sys.exit(0)

    # Kill any existing process on the target port
    port = args.port
    _kill_port(port)
    handler = partial(ReviewHandler, workspace, skill_name, feedback_path, previous, benchmark_path)
    try:
        server = HTTPServer(("127.0.0.1", port), handler)
    except OSError:
        # Port still in use after kill attempt: find a free one
        server = HTTPServer(("127.0.0.1", 0), handler)
        port = server.server_address[1]

    url = f"http://localhost:{port}"
    print(f"\n  Eval Viewer")
    print(f"  ─────────────────────────────────")
    print(f"  URL:       {url}")
    print(f"  Workspace: {workspace}")
    print(f"  Feedback:  {feedback_path}")
    if previous:
        print(f"  Previous:  {args.previous_workspace} ({len(previous)} runs)")
    if benchmark_path:
        print(f"  Benchmark: {benchmark_path}")
    print(f"\n  Press Ctrl+C to stop.\n")

    webbrowser.open(url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
