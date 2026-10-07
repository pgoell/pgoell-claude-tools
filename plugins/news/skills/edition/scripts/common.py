"""Paths and small helpers every news script shares.

Python puts a script's own directory first on sys.path, so `import common`
works under `uv run` without packaging. Stdlib only, so it adds nothing to the
inline dependency blocks of the scripts that import it.
"""

import argparse
import re
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

SKILL_DIR = Path(__file__).resolve().parent.parent
DEFAULTS = SKILL_DIR / "references" / "defaults"
DESIGNS = SKILL_DIR / "designs"

PERIODIC = "01 Periodic"
"""kasten's KASTEN_PERIODIC_PATH default."""

NEWSPAPER = "05 Newspaper"
EDITION_NAME = re.compile(r"^(\d{4}-\d{2}-\d{2})\.html$")
"""An edition's file name. Comparison renders (`2026-10-07.magazine.html`) do not match."""


def today() -> date:
    # The paper is a Gelnhausen morning paper: its day is the Berlin day, not the host's.
    return datetime.now(ZoneInfo("Europe/Berlin")).date()


def base_parser(description: str) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--vault", required=True, type=Path, help="kasten vault root")
    parser.add_argument("--periodic", default=PERIODIC, help=f"periodic folder in the vault (default {PERIODIC!r})")
    parser.add_argument("--date", type=date.fromisoformat, default=None, help="edition date, default today in Berlin")
    return parser


def newspaper_dir(vault: Path, periodic: str) -> Path:
    return vault / periodic / NEWSPAPER


def edition_dates(folder: Path) -> list[date]:
    """Dates of the editions on disk, oldest first."""
    found = (EDITION_NAME.match(p.name) for p in folder.glob("*.html"))
    return sorted(date.fromisoformat(m.group(1)) for m in found if m)
