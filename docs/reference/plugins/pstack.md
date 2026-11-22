---
type: Reference
title: The pstack plugin
description: Lauren Tan's agent workflow skills from Cursor's plugin repo, with the no-comments pass and 24 principle skills, mirrored from upstream and synced weekly.
tags: [plugin, pstack, upstream, mirror, workflow, review]
status: stable
---

# pstack

Lauren Tan's ("poteto") agent workflow skills: `/pstack:poteto-mode` picks a playbook for a task (bug fix, feature, refactor, perf, shipping), and the other skills cover review, planning, explanation and verification. It also ships 24 short principle skills and two subagents, `poteto-agent` and `comment-sicko`. See the [pstack README](https://github.com/cursor/plugins/tree/main/pstack).

**Runtimes:** Claude Code, Codex, Cursor, and the skills CLI

Codex and the skills CLI copy skills only, so there the skills that start a subagent (`/pstack:no-comments`, `/pstack:poteto-mode`) find no `comment-sicko` or `poteto-agent`. The skills CLI also leaves out the plugin's `docs/` folder, which about 20 skills link to. See [Runtimes](/reference/runtimes.md).

**Source:** a mirror, not a port: `plugins/pstack/` is a verbatim copy of [cursor/plugins](https://github.com/cursor/plugins) `harness/pstack/claude-code`, the Claude Code tree upstream generates from `pstack/` (MIT, copyright 2026 Lauren Tan). `mise run sync-pstack` writes it and adds the Codex manifest upstream lacks; `NOTICE` names the commit. The `Sync pstack mirror` workflow runs the task every Monday and opens a pull request when upstream changed. Never edit the mirrored files. Why a mirror: [External and vendored plugins](/explanation/external-and-vendored-plugins.md).

**Setup:** None beyond install. `/pstack:setup-pstack` picks the model and reasoning budget for each role. In Claude Code the plugin adds about 4,700 tokens to every session.

## Skills

All but `setup-pstack` and `automate-me` set `disable-model-invocation: true`, so in Claude Code and Cursor they run only when you type the slash command. [Upstream skills at a glance](/reference/upstream-skills.md) lists every skill with one line each.

`/pstack:no-comments` sends the `comment-sicko` subagent over the current diff, deletes comments that restate code, keeps license headers, public API docs and constraints the code cannot express, and offers a lint, type or test in place of each "do not change" comment. The [project template](https://github.com/pgoell/project-template) runs the same rule as a pre-commit and CI check.

`pstack` has its own `unslop` (writing) and `tdd` skills; they are not the [unslop](/reference/plugins/unslop.md) plugin, which works on screens.
