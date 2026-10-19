# 2026-10-19: Fix

workbench 1.4.11, issue #251. `subagent-driven-development` finds slices in both plan formats: `### Slice N` sections in md, `<article class="task">` elements in `#tasks` labeled "Slice 01" in html. A task with an ordering note or `p.order-note` is a bounded task, not a slice. Task Loop step 1, the implementation prompt and the pilot Claude Code adapter say to paste the whole slice in either form. The plan reviewer checks design coverage against `## Design` in md and `#design` in html. No other page under `docs/` changed.
