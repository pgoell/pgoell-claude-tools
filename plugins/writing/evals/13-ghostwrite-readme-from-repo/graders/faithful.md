---
type: llm
focus: {source: file, path: README.md}
---

Facts about the repository, from its code:

- One script, `wc_top.py`, standard library only, argparse program name `wc_top`, description "Print the most frequent words in a text file."
- Run as `python3 wc_top.py FILE`; FILE may be `-` to read stdin.
- Options: `--top N` (default 10), `--min-length N` (ignore words shorter than N, default 3), `--ignore-case`, `--version` (prints "wc_top 0.4.1"), `-h`/`--help`.
- Output: one line per word, the count, a tab, then the word, most frequent first (ties keep first-seen order).
- Words are runs of letters and apostrophes. Counting is case-sensitive unless `--ignore-case` is given.
- A `sample.txt` file and a `tests/` directory (pytest tests) ship with it.
- There is no package, no pip install, no config file, no license file, and no other feature.

Output shown in the README may come from running the script, so a correct run on sample.txt is not an invention. The list above is not exhaustive: other details read from the code (for example exit codes from argparse, the file encoding, or the `top_words` function signature) are allowed when they are consistent with it. Flag only content that contradicts the code or could not have come from the repository.

PASS if all of these hold, otherwise FAIL:

1. Every command, flag, default, and behavior shown in the README is consistent with the facts above.
2. The README does not invent features, a package install (such as `pip install wc-top`), a license, contributors, badges, or a project history.
3. Any rationale or claim not derivable from the code is absent or clearly marked for the owner.
