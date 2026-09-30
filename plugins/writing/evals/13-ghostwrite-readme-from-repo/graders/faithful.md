---
type: llm
focus: {source: file, path: README.md}
---

The repository holds one script, wc_top.py, a word-frequency CLI run as `python3 wc_top.py FILE`, with options `--top N` (default 10), `--min-length N` (default 3), `--ignore-case`, and `--version` (prints "wc_top 0.4.1"), plus a tests/ directory run with pytest. There is no package, no pip install, no config file, and no other feature.
PASS if all of these hold, otherwise FAIL:

1. Every command, flag, default, and output shown in the README matches the description above.
2. The README does not invent features, install steps (such as `pip install wc-top`), a license, contributors, badges, or a project history.
3. Any rationale or claim not derivable from the code is absent or clearly marked for the owner.
