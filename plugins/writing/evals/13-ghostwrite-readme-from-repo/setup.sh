#!/bin/bash
# Builds a tiny word-frequency CLI in the empty eval workspace. The README the
# agent writes must match this code, which it can only learn by reading it or
# running it.
set -euo pipefail

cat > wc_top.py <<'PY'
#!/usr/bin/env python3
"""Print the most frequent words in a text file."""
import argparse
import collections
import re
import sys

VERSION = "0.4.1"


def top_words(text, top=10, min_length=3, ignore_case=False):
    if ignore_case:
        text = text.lower()
    words = [w for w in re.findall(r"[A-Za-z']+", text) if len(w) >= min_length]
    return collections.Counter(words).most_common(top)


def main(argv=None):
    parser = argparse.ArgumentParser(prog="wc_top", description=__doc__)
    parser.add_argument("file", help="text file to read, or - for stdin")
    parser.add_argument("--top", type=int, default=10, help="how many words to print (default: 10)")
    parser.add_argument("--min-length", type=int, default=3, help="ignore words shorter than this (default: 3)")
    parser.add_argument("--ignore-case", action="store_true", help="count Word and word as the same word")
    parser.add_argument("--version", action="version", version=f"wc_top {VERSION}")
    args = parser.parse_args(argv)
    handle = sys.stdin if args.file == "-" else open(args.file, encoding="utf-8")
    with handle:
        text = handle.read()
    for word, count in top_words(text, args.top, args.min_length, args.ignore_case):
        print(f"{count}\t{word}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
PY

mkdir -p tests
cat > tests/test_wc_top.py <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from wc_top import top_words


def test_min_length_filters_short_words():
    assert top_words("a an the cat cat", min_length=3) == [("cat", 2), ("the", 1)]


def test_ignore_case_merges_words():
    assert top_words("Dog dog DOG", ignore_case=True) == [("dog", 3)]
PY

cat > sample.txt <<'TXT'
The quick brown fox jumps over the lazy dog. The dog sleeps. The fox runs.
TXT

git init -q
git add .
git -c user.email=eval@example.com -c user.name=eval commit -q -m "Add wc_top"
