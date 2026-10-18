# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Re-derive the handover point from real orchestrator transcripts.

usage: uv run tests/handover-cost.py ~/.claude/projects/<loop-folder-slug>/*.jsonl ...

Pass the transcripts of orchestrator sessions only (the folder Claude Code
keeps for the loop folder), never the implementer's. Reads; changes nothing.

Per session it prints the start context, the growth per call, the cache misses
(a write of more than half the context, the sign of a gap past the TTL) and the
cost at list prices. Then it models the average cost per call when the
orchestrator hands over at a given context, for the measured miss rate and for
none and 5%, and prints the cheapest point. gate.sh says hand over past 120k;
rerun this when the model, its prices or the start context change.
"""

import json
import statistics
import sys
from datetime import datetime

# Claude Opus 5.5 list prices, $ per token, as of 2026-10. Update with the model.
READ = 0.20e-6  # cache read
WRITE_5M = 5e-6  # cache write, 5-minute TTL (1.25x input)
WRITE_1H = 8e-6  # cache write, 1-hour TTL (2x input)
INPUT = 4e-6
OUTPUT = 20e-6
# Calls the outgoing session spends on the handover itself. Not measured.
HANDOVER_CALLS = 10
POINTS = (80_000, 100_000, 120_000, 150_000, 200_000, 300_000)


def load(path):
    seen, rows = set(), []
    for line in open(path):
        try:
            o = json.loads(line)
        except ValueError:
            continue
        m = o.get("message") or {}
        u = m.get("usage")
        if o.get("type") != "assistant" or not u or m.get("id") in seen:
            continue
        seen.add(m.get("id"))
        w = u.get("cache_creation_input_tokens", 0)
        w1 = (u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens", 0)
        rows.append(
            dict(
                t=datetime.fromisoformat(o["timestamp"].replace("Z", "+00:00")),
                inp=u.get("input_tokens", 0),
                rd=u.get("cache_read_input_tokens", 0),
                w=w,
                w1=w1,
                out=u.get("output_tokens", 0),
            )
        )
    return rows


def cost(x):
    return (
        x["inp"] * INPUT
        + x["rd"] * READ
        + (x["w"] - x["w1"]) * WRITE_5M
        + x["w1"] * WRITE_1H
        + x["out"] * OUTPUT
    )


def per_call(c, b, d, out, miss):
    """Average $ per call when a session starts at b and hands over at c."""
    step = lambda ctx: ctx * READ + d * WRITE_1H + out * OUTPUT + miss * ctx * (WRITE_1H - READ)
    n = max(1, int((c - b) / d))
    handover = b * WRITE_1H + HANDOVER_CALLS * step(c)
    return (handover + sum(step(b + i * d) for i in range(n))) / n


sessions = []
for p in sys.argv[1:]:
    r = load(p)
    if len(r) < 20:
        continue
    ctx = [x["inp"] + x["rd"] + x["w"] for x in r]
    top = max(range(len(ctx)), key=ctx.__getitem__)
    misses = [x for i, x in enumerate(r) if x["w"] > 20_000 and x["w"] > ctx[i] / 2]
    s = dict(
        name=p.rsplit("/", 1)[-1][:8],
        calls=len(r),
        ctx0=ctx[0],
        top=ctx[top],
        growth=(ctx[top] - ctx[0]) / max(1, top),
        out=sum(x["out"] for x in r) / len(r),
        misses=len(misses),
        miss_cost=sum(cost(x) for x in misses),
        cost=sum(cost(x) for x in r),
    )
    sessions.append(s)
    print(
        f"{s['name']} calls={s['calls']} start={s['ctx0'] // 1000}k top={s['top'] // 1000}k "
        f"growth/call={s['growth']:.0f} out/call={s['out']:.0f} misses={s['misses']} "
        f"miss_cost=${s['miss_cost']:.2f} cost=${s['cost']:.2f}"
    )
if not sessions:
    sys.exit("no transcript with 20 or more calls given")

b = statistics.median(s["ctx0"] for s in sessions)
d = statistics.median(s["growth"] for s in sessions)
out = statistics.mean(s["out"] for s in sessions)
calls = sum(s["calls"] for s in sessions)
miss = sum(s["misses"] for s in sessions) / calls
total = sum(s["cost"] for s in sessions)
print(
    f"\n{len(sessions)} sessions, {calls} calls, ${total:.2f}; misses ${sum(s['miss_cost'] for s in sessions):.2f}"
    f"\nstart {b / 1000:.0f}k, growth {d:.0f}/call, output {out:.0f}/call, miss rate {miss:.3f}/call"
)
print("\ncents per call when handing over at " + ", ".join(f"{c // 1000}k" for c in POINTS))
for m in (0.0, miss, 0.05):
    row = "  ".join(f"{per_call(c, b, d, out, m) * 100:5.2f}" for c in POINTS)
    best = min(range(int(b) + 10_000, 400_000, 5_000), key=lambda c: per_call(c, b, d, out, m))
    print(f"miss rate {m:.3f}: {row}   cheapest {best // 1000}k")
