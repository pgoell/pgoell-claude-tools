---
type: Reference
title: The pstack plugin
description: Lauren Tan's agent workflow skills from Cursor's plugin repo, with the no-comments pass and 24 principle skills, tracked from upstream.
tags: [plugin, pstack, upstream, workflow, review]
status: stable
---

# pstack

Lauren Tan's ("poteto") agent workflow skills: `/pstack:poteto-mode` picks a playbook for a task (bug fix, feature, refactor, perf, shipping), and the other skills cover review, planning, explanation and verification. It also ships 24 short principle skills and two subagents, `poteto-agent` and `comment-sicko`. See the [pstack README](https://github.com/cursor/plugins/tree/main/pstack).

**Runtimes:** Claude Code

Not in Codex: the upstream ships no Codex manifest. Not in this repo's Cursor marketplace either, because Cursor's own marketplace offers `pstack` directly. See [Runtimes](/reference/runtimes.md).

For Codex or another agent, `npx skills add cursor/plugins` (or `bunx`) installs the skills straight from upstream; it finds all 58, plus the two of Cursor's `origin-apps`. It copies skills only, so `/pstack:no-comments` and the other skills that start a subagent lose `comment-sicko` and `poteto-agent`. `npx skills add pgoell/pgoell-claude-tools` skips upstream entries and does not offer pstack.

**Source:** upstream, not vendored: a `git-subdir` entry that tracks [cursor/plugins](https://github.com/cursor/plugins) `main` unpinned, folder `harness/pstack/claude-code`, which upstream generates for Claude Code from `pstack/` (MIT, copyright 2026 Lauren Tan).

**Setup:** None beyond install. `/pstack:setup-pstack` picks the model and reasoning budget for each role. The plugin adds about 4,700 tokens to every session.

## Skills

All but `setup-pstack` and `automate-me` set `disable-model-invocation: true`, so they run only when you type the slash command. [Upstream skills at a glance](/reference/upstream-skills.md) lists every skill with one line each.

`/pstack:no-comments` sends the `comment-sicko` subagent over the current diff, deletes comments that restate code, keeps license headers, public API docs and constraints the code cannot express, and offers a lint, type or test in place of each "do not change" comment. The [project template](https://github.com/pgoell/project-template) runs the same rule as a pre-commit and CI check.

`pstack` has its own `unslop` (writing) and `tdd` skills; they are not the [unslop](/reference/plugins/unslop.md) plugin, which works on screens.
