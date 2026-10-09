"""Paths and small helpers every insights script shares.

Python puts a script's own directory first on sys.path, so `import common`
works under `uv run` without packaging. Stdlib only.
"""

import argparse
import json
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

SKILL_DIR = Path(__file__).resolve().parent.parent
DEFAULTS = SKILL_DIR / "references" / "defaults"
TEMPLATE = SKILL_DIR / "references" / "page.html.j2"

BERLIN = ZoneInfo("Europe/Berlin")
PERIODIC = "01 Periodic"
"""kasten's KASTEN_PERIODIC_PATH default."""
INSIGHTS = "06 Insights"
WINDOW = 14
"""Days of history behind every count: the analysed day and the 13 before it."""


def today() -> date:
    return datetime.now(BERLIN).date()


def base_parser(description: str) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--vault", required=True, type=Path, help="kasten vault root")
    parser.add_argument("--periodic", default=PERIODIC, help=f"periodic folder in the vault (default {PERIODIC!r})")
    parser.add_argument(
        "--date", type=date.fromisoformat, default=None, help="the analysed day, default yesterday in Berlin"
    )
    return parser


def analysed_day(args: argparse.Namespace) -> date:
    return args.date or today() - timedelta(days=1)


def insights_dir(vault: Path, periodic: str) -> Path:
    return vault / periodic / INSIGHTS


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows))
