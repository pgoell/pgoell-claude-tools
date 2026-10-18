---
type: Explanation
title: Versions and the lockstep sites
description: Why every plugin change bumps the version at several sites at once, and why a new plugin or skill touches a fixed set of docs pages.
tags: [versions, lockstep, ci, docs, contributors]
status: stable
---

# Versions and the lockstep sites

A plugin's version sits in several files, and its docs sit on several pages. Each copy drifts when one is edited and the others are not. The lockstep rules name every copy, so a change moves them all in one pull request. [AGENTS.md](../../AGENTS.md) states the rules; this page keeps the reasons and the history.

## Every plugin change bumps version

Any change to a plugin's skills, metadata, docs, hooks, agents, or tests bumps that plugin's version in lockstep across every site that records it. New skills are minor bumps; fixes, docs, tests, and description changes are patch bumps unless they change behavior materially.

The full set of sites:

1. `.claude-plugin/plugin.json`, only when this file already declares a `version` field. The `atlassian` and `google-workspace` plugins leave it out on purpose, because Claude Code reads their version from `.claude-plugin/marketplace.json`.
2. `.codex-plugin/plugin.json`, always. Every Codex manifest in this repo declares `version`.
3. The `version` field of the plugin's entry in `.claude-plugin/marketplace.json`.
4. The plugin's line in the AGENTS.md "Current Plugins" list. CLAUDE.md is a symlink to AGENTS.md, so it updates with it.

A plugin offered in Cursor also carries the version in `.cursor-plugin/plugin.json`, but `mise run sync-cursor-manifests` copies it from sites 1 to 3, so run that task after a bump and never edit the Cursor file. The Codex marketplace entry (`.agents/plugins/marketplace.json`) records no version.

The bump is per pull request (per ship unit), not per commit. With `Squash: yes` in `.workbench/pilot.md`, several commits on one feature branch merge as one commit at one version, so a follow-up commit on a branch that already bumped does not bump again. Before bumping, run `git diff <base>..HEAD -- plugins/<plugin>/.claude-plugin/plugin.json plugins/<plugin>/.codex-plugin/plugin.json .claude-plugin/marketplace.json AGENTS.md` to see whether the branch already moved the version.

A parallel branch can claim the same next number. Check open pull requests and local worktrees (`git worktree list`, then each worktree's uncommitted diff) for another branch that bumps the same plugin. In 2026-06 `feat/perfecting-presentations-skill` and `feat/deck-to-pptx-skill` both aimed at workbench 0.18.0. Whichever ships second bumps again before merge.

CI checks sites 1 to 3 and the generated Cursor manifest through the version-bump task. Site 4 is on you: a stale line there shows consumers a wrong version, and nothing catches it.

## The docs lockstep for a new plugin or skill

The README is a front page and the docs live in `docs/`, so a new plugin touches a fixed set of sites: the README plugin line and plugin count, the plugin's reference page plus its entries in the plugin index, `skills.md` and `runtimes.md`, a setup how-to only when the plugin needs setup (a missing page says there is no setup), the README install notes only when the install command differs, a dated `docs/log.md` entry, and the plugin's line in AGENTS.md "Current Plugins". Cursor needs `mise run sync-cursor-manifests` or an entry in that task's `EXCLUDE` list. This set comes on top of the version sites above, in the same commit.

A new skill in an existing plugin usually needs only the plugin's reference page and `docs/reference/skills.md`, plus the log entry. Two more sites drift without a sound: the plugin's own `README.md` `## Skills` list, and, for workbench, the skill list inside the "One skill per service, one plugin per product family" rule in AGENTS.md. The copilot and exporting-decks-to-pptx additions both had to update that list. The workbench README had fallen eight skills behind before the 2026-06 exporting-decks-to-pptx pull request brought it current. Nothing tests either site.

## Why checks run by hand

The shell test suite (`tests/` with unit, integration, and skill-triggering tests) went away in 2026-07 in favor of eval-based skill testing through `agent-system-management:creating-skills`. Until evals cover a skill, nobody checks its behavior but you, and the manual greps (dash lint, frontmatter YAML, invocation syntax) are the only structural gates left.
