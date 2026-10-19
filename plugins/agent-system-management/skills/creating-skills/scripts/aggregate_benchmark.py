#!/usr/bin/env python3
"""
Aggregate individual run results into benchmark summary statistics.

Reads grading.json files from run directories and produces:
- run_summary with mean, stddev, min, max for each metric
- delta between with_skill and without_skill configurations

Usage:
    python aggregate_benchmark.py <benchmark_dir>

Example:
    python aggregate_benchmark.py <workspace>/iteration-<N>/

The script supports these directory layouts. A run directory holds
outputs/, timing.json and grading.json. Each eval dir holds
eval_metadata.json (eval_id, eval_name). Configs are with_skill,
without_skill, old_skill (or new_skill); the delta is with_skill (or
new_skill) minus the baseline.

    Workspace layout (one run per config, as SKILL.md sets it up; the
    config dir is the run directory):
    <benchmark_dir>/
    └── eval-<id>-<name>/
        ├── eval_metadata.json
        ├── with_skill/
        │   ├── outputs/
        │   ├── grading.json
        │   └── timing.json
        └── without_skill/
            ├── outputs/
            ├── grading.json
            └── timing.json

    Repeat runs (one run-<n>/ run directory per repeat; when run-<n>
    folders exist, a grading.json in the config dir itself is ignored, and
    any other run-* entry is skipped with a warning):
    <benchmark_dir>/
    └── eval-<id>-<name>/
        ├── with_skill/
        │   ├── run-1/grading.json
        │   └── run-2/grading.json
        └── without_skill/
            ├── run-1/grading.json
            └── run-2/grading.json
"""

import argparse
import json
import math
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

# A repeat run folder: run-<n>. Same constant in eval-viewer/generate_review.py.
RUN_DIR_RE = re.compile(r"^run-(\d+)$")

# An eval folder: eval-<n>-<name>. Same constant in eval-viewer/generate_review.py.
EVAL_DIR_RE = re.compile(r"^eval-(\d+)(-|$)")

# Shown for a missing delta. A name, since Python before 3.12 rejects a
# backslash inside an f-string expression.
DASH = "\N{EM DASH}"

# Configs that hold the skill under test; they come first so the delta is
# skill minus baseline.
PRIMARY_CONFIGS = ("with_skill", "new_skill")

# JSON readers. A missing value takes its default quietly; a wrong-typed one
# (bool is never a number) takes it with one warning. Same helpers in
# eval-viewer/generate_review.py.
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
    use. Same function in eval-viewer/generate_review.py."""
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


def calculate_stats(values: list[float]) -> dict:
    """Calculate mean, stddev, min, max for a list of values."""
    if not values:
        return {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0}

    n = len(values)
    mean = sum(values) / n

    if n > 1:
        variance = sum((x - mean) ** 2 for x in values) / (n - 1)
        stddev = math.sqrt(variance)
    else:
        stddev = 0.0

    return {
        "mean": round(mean, 4),
        "stddev": round(stddev, 4),
        "min": round(min(values), 4),
        "max": round(max(values), 4)
    }


def load_run_results(benchmark_dir: Path) -> dict:
    """
    Load all run results from a benchmark directory.

    Returns dict keyed by config name (e.g. "with_skill"/"without_skill",
    or "with_skill"/"old_skill"), each containing a list of run results.
    with_skill and new_skill come first, then the other configs sorted.
    """
    eval_dirs = sorted(d for d in benchmark_dir.glob("eval-*") if d.is_dir())
    if not eval_dirs:
        print(f"No eval directories found in {benchmark_dir}")
        return {}

    results: dict[str, list] = {}

    # Read every eval's metadata first: an eval's id depends on the others
    evals = []
    for eval_dir in eval_dirs:
        meta_id = eval_name = None
        metadata_path = eval_dir / "eval_metadata.json"
        if metadata_path.exists():
            metadata = _read_obj(metadata_path)
            if metadata is not None:
                meta_id = _field(metadata, "eval_id", int, None, metadata_path)
                eval_name = _field(metadata, "eval_name", str, None, metadata_path)
        m = EVAL_DIR_RE.match(eval_dir.name)
        evals.append((eval_dir, meta_id, int(m.group(1)) if m else None, eval_name))
    eval_ids = assign_eval_ids([e[:3] for e in evals])

    for (eval_dir, _, _, eval_name), eval_id in zip(evals, eval_ids):
        # Discover config directories dynamically rather than hardcoding names
        for config_dir in sorted(eval_dir.iterdir()):
            if not config_dir.is_dir():
                continue
            # A config dir holds run-<n>/ folders, or is itself the one run
            runs = []
            for d in sorted(config_dir.glob("run-*")):
                m = RUN_DIR_RE.match(d.name)
                if m and d.is_dir():
                    runs.append((d, int(m.group(1))))
                else:
                    print(f"Warning: skipping {d}: not a run-<n> folder")
            runs.sort(key=lambda r: r[1])
            if not runs:
                if (config_dir / "grading.json").exists():
                    runs = [(config_dir, 1)]
                elif (config_dir / "outputs").is_dir():
                    print(f"Warning: grading.json not found in {config_dir}")
                    continue
                else:
                    # Skip non-config directories (inputs, etc.)
                    continue
            config = config_dir.name
            if config not in results:
                results[config] = []

            for run_dir, run_number in runs:
                result = load_run(run_dir, eval_id, eval_name, run_number)
                if result is not None:
                    results[config].append(result)

    order = [c for c in PRIMARY_CONFIGS if c in results]
    order += sorted(c for c in results if c not in PRIMARY_CONFIGS)
    return {c: results[c] for c in order}


def load_run(run_dir: Path, eval_id, eval_name, run_number: int) -> dict | None:
    """Read one run directory's grading.json (and timing.json) into a result."""
    grading_file = run_dir / "grading.json"

    if not grading_file.exists():
        print(f"Warning: grading.json not found in {run_dir}")
        return None

    # Not an object: warned, the run is skipped
    grading = _read_obj(grading_file)
    if grading is None:
        return None

    # Extract metrics
    summary = _field(grading, "summary", dict, {}, grading_file)

    def stat(key, default):
        return _field(summary, key, NUM, default, grading_file, "summary." + key)

    result = {
        "eval_id": eval_id,
        "eval_name": eval_name,
        "run_number": run_number,
        "pass_rate": stat("pass_rate", 0.0),
        "passed": stat("passed", 0),
        "failed": stat("failed", 0),
        "total": stat("total", 0),
    }

    # Time: grading.json timing, else timing.json (seconds, else duration_ms).
    # Tokens: timing.json total_tokens only.
    timing_data = {}
    timing_file = run_dir / "timing.json"
    if timing_file.exists():
        timing_data = _read_obj(timing_file) or {}
    timing = _field(grading, "timing", dict, {}, grading_file)
    graded_seconds = _field(timing, "total_duration_seconds", NUM, None, grading_file,
                            "timing.total_duration_seconds")
    seconds = _field(timing_data, "total_duration_seconds", NUM, None, timing_file)
    ms = _field(timing_data, "duration_ms", NUM, 0, timing_file)
    # A 0 counts as missing at each step.
    result["time_seconds"] = graded_seconds or seconds or ms / 1000 or 0.0
    result["tokens"] = _field(timing_data, "total_tokens", NUM, 0, timing_file)

    # Extract metrics if available
    metrics = _field(grading, "execution_metrics", dict, {}, grading_file)
    result["tool_calls"] = _field(metrics, "total_tool_calls", NUM, 0, grading_file,
                                  "execution_metrics.total_tool_calls")
    result["errors"] = _field(metrics, "errors_encountered", NUM, 0, grading_file,
                              "execution_metrics.errors_encountered")

    # Extract expectations: viewer requires fields: text, passed, evidence
    raw_expectations = _items(_field(grading, "expectations", list, [], grading_file),
                              dict, grading_file, "expectations")
    for exp in raw_expectations:
        if "text" not in exp or "passed" not in exp:
            print(f"Warning: expectation in {grading_file} missing required fields (text, passed, evidence): {exp}")
    result["expectations"] = raw_expectations

    # Extract notes from user_notes_summary
    notes_summary = _field(grading, "user_notes_summary", dict, {}, grading_file)
    notes = []
    for key in ("uncertainties", "needs_review", "workarounds"):
        notes.extend(_field(notes_summary, key, list, [], grading_file, "user_notes_summary." + key))
    result["notes"] = notes

    return result


def aggregate_results(results: dict) -> dict:
    """
    Aggregate run results into summary statistics.

    Returns run_summary with stats for each configuration and delta.
    """
    run_summary = {}
    configs = list(results.keys())

    for config in configs:
        runs = results.get(config, [])

        if not runs:
            run_summary[config] = {
                "pass_rate": {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0},
                "time_seconds": {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0},
                "tokens": {"mean": 0, "stddev": 0, "min": 0, "max": 0}
            }
            continue

        pass_rates = [r["pass_rate"] for r in runs]
        times = [r["time_seconds"] for r in runs]
        tokens = [r.get("tokens", 0) for r in runs]

        run_summary[config] = {
            "pass_rate": calculate_stats(pass_rates),
            "time_seconds": calculate_stats(times),
            "tokens": calculate_stats(tokens)
        }

    # Calculate delta between the first two configs (if two exist)
    if len(configs) >= 2:
        primary = run_summary.get(configs[0], {})
        baseline = run_summary.get(configs[1], {})
    else:
        primary = run_summary.get(configs[0], {}) if configs else {}
        baseline = {}

    delta_pass_rate = primary.get("pass_rate", {}).get("mean", 0) - baseline.get("pass_rate", {}).get("mean", 0)
    delta_time = primary.get("time_seconds", {}).get("mean", 0) - baseline.get("time_seconds", {}).get("mean", 0)
    delta_tokens = primary.get("tokens", {}).get("mean", 0) - baseline.get("tokens", {}).get("mean", 0)

    run_summary["delta"] = {
        "pass_rate": f"{delta_pass_rate:+.2f}",
        "time_seconds": f"{delta_time:+.1f}",
        "tokens": f"{delta_tokens:+.0f}"
    }

    return run_summary


def generate_benchmark(benchmark_dir: Path, skill_name: str = "", skill_path: str = "") -> dict:
    """
    Generate complete benchmark.json from run results.
    """
    results = load_run_results(benchmark_dir)
    run_summary = aggregate_results(results)

    # Build runs array for benchmark.json
    runs = []
    for config in results:
        for result in results[config]:
            runs.append({
                "eval_id": result["eval_id"],
                "eval_name": result["eval_name"],
                "configuration": config,
                "run_number": result["run_number"],
                "result": {
                    "pass_rate": result["pass_rate"],
                    "passed": result["passed"],
                    "failed": result["failed"],
                    "total": result["total"],
                    "time_seconds": result["time_seconds"],
                    "tokens": result.get("tokens", 0),
                    "tool_calls": result.get("tool_calls", 0),
                    "errors": result.get("errors", 0)
                },
                "expectations": result["expectations"],
                "notes": result["notes"]
            })

    # Determine eval IDs from results
    eval_ids = sorted(set(
        r["eval_id"]
        for config in results.values()
        for r in config
    ))

    # Most runs found for any (eval, config) pair
    run_counts = Counter((r["eval_id"], r["configuration"]) for r in runs)
    runs_per_configuration = max(run_counts.values(), default=0)

    benchmark = {
        "metadata": {
            "skill_name": skill_name or "<skill-name>",
            "skill_path": skill_path or "<path/to/skill>",
            "executor_model": "<model-name>",
            "analyzer_model": "<model-name>",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "evals_run": eval_ids,
            "runs_per_configuration": runs_per_configuration
        },
        "runs": runs,
        "run_summary": run_summary,
        "notes": []  # To be filled by analyzer
    }

    return benchmark


def generate_markdown(benchmark: dict) -> str:
    """Generate human-readable benchmark.md from benchmark data."""
    metadata = benchmark["metadata"]
    run_summary = benchmark["run_summary"]

    # Determine config names (excluding "delta")
    configs = [k for k in run_summary if k != "delta"]
    config_a = configs[0] if len(configs) >= 1 else "config_a"
    config_b = configs[1] if len(configs) >= 2 else "config_b"
    label_a = config_a.replace("_", " ").title()
    label_b = config_b.replace("_", " ").title()

    lines = [
        f"# Skill Benchmark: {metadata['skill_name']}",
        "",
        f"**Model**: {metadata['executor_model']}",
        f"**Date**: {metadata['timestamp']}",
        f"**Evals**: {', '.join(map(str, metadata['evals_run']))} ({metadata['runs_per_configuration']} runs each per configuration)",
        "",
        "## Summary",
        "",
        f"| Metric | {label_a} | {label_b} | Delta |",
        "|--------|------------|---------------|-------|",
    ]

    a_summary = run_summary.get(config_a, {})
    b_summary = run_summary.get(config_b, {})
    delta = run_summary.get("delta", {})

    # Format pass rate
    a_pr = a_summary.get("pass_rate", {})
    b_pr = b_summary.get("pass_rate", {})
    lines.append(f"| Pass Rate | {a_pr.get('mean', 0)*100:.0f}% ± {a_pr.get('stddev', 0)*100:.0f}% | {b_pr.get('mean', 0)*100:.0f}% ± {b_pr.get('stddev', 0)*100:.0f}% | {delta.get('pass_rate', DASH)} |")

    # Format time
    a_time = a_summary.get("time_seconds", {})
    b_time = b_summary.get("time_seconds", {})
    lines.append(f"| Time | {a_time.get('mean', 0):.1f}s ± {a_time.get('stddev', 0):.1f}s | {b_time.get('mean', 0):.1f}s ± {b_time.get('stddev', 0):.1f}s | {delta.get('time_seconds', DASH)}s |")

    # Format tokens
    a_tokens = a_summary.get("tokens", {})
    b_tokens = b_summary.get("tokens", {})
    lines.append(f"| Tokens | {a_tokens.get('mean', 0):.0f} ± {a_tokens.get('stddev', 0):.0f} | {b_tokens.get('mean', 0):.0f} ± {b_tokens.get('stddev', 0):.0f} | {delta.get('tokens', DASH)} |")

    # Notes section
    if benchmark.get("notes"):
        lines.extend([
            "",
            "## Notes",
            ""
        ])
        for note in benchmark["notes"]:
            lines.append(f"- {note}")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Aggregate benchmark run results into summary statistics"
    )
    parser.add_argument(
        "benchmark_dir",
        type=Path,
        help="Path to the benchmark directory"
    )
    parser.add_argument(
        "--skill-name",
        default="",
        help="Name of the skill being benchmarked"
    )
    parser.add_argument(
        "--skill-path",
        default="",
        help="Path to the skill being benchmarked"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        help="Output path for benchmark.json (default: <benchmark_dir>/benchmark.json)"
    )

    args = parser.parse_args()

    if not args.benchmark_dir.exists():
        print(f"Directory not found: {args.benchmark_dir}")
        sys.exit(1)

    # Generate benchmark
    benchmark = generate_benchmark(args.benchmark_dir, args.skill_name, args.skill_path)

    # Determine output paths
    output_json = args.output or (args.benchmark_dir / "benchmark.json")
    output_md = output_json.with_suffix(".md")

    # Write benchmark.json
    with open(output_json, "w") as f:
        json.dump(benchmark, f, indent=2)
    print(f"Generated: {output_json}")

    # Write benchmark.md
    markdown = generate_markdown(benchmark)
    with open(output_md, "w") as f:
        f.write(markdown)
    print(f"Generated: {output_md}")

    # Print summary
    run_summary = benchmark["run_summary"]
    configs = [k for k in run_summary if k != "delta"]
    delta = run_summary.get("delta", {})

    print(f"\nSummary:")
    for config in configs:
        pr = run_summary[config]["pass_rate"]["mean"]
        label = config.replace("_", " ").title()
        print(f"  {label}: {pr*100:.1f}% pass rate")
    print(f"  Delta:         {delta.get('pass_rate', DASH)}")


if __name__ == "__main__":
    main()
