# 2026-10-19: Fix

presentations 0.7.3, workbench 1.4.3. Issue #222, found in the review of PR #221: removing a `<deck-stage>` element and adding it again no longer doubles its shadow DOM; a new `plugins/presentations/tests/run.sh` checks this in headless Chrome. Issue #210: the Runtime Mapping in `subagent-driven-development` names Cursor's `Task` tool to start an agent and says how to resume that agent by the ID `Task` returned, and keeps the fresh-agent fallback for when no resume works. `docs/reference/plugins/presentations.md` gains a Tests line for the new script.
