# 2026-10-28: Fix

guards 0.1.3. `pkill-self-match` now tests each `pkill -f` or looping `pgrep -f` pattern against the command's own text instead of passing any pattern with a bracketed first letter. `pkill -f '[p]ytest x' ; pytest x` killed the agent's shell, because the later plain `pytest x` in the `bash -c` matched the pattern. The deny message now says to run the bracketed `pkill` in a Bash call of its own. Changed `reference/plugins/guards.md` and `explanation/plugins-without-skills.md`.
