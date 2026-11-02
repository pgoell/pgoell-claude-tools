# 2026-11-02: Fix

guards 0.1.4. `pkill-self-match` removes heredoc bodies before it reads a command and treats `#` as an ordinary character, so an apostrophe or a `#` in a body no longer hides a `pkill -f` from it. No page under `docs/` changed.
