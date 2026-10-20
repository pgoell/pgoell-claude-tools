---
type: Explanation
title: One skill directory, three runtimes
description: Why Claude Code, Codex and Cursor read the same skill files through separate manifests, and why some plugins ship to Claude Code alone.
tags: [runtimes, manifests, codex, cursor]
status: stable
---

# One skill directory, three runtimes

Each skill lives once, at `plugins/<plugin>/skills/<skill>/SKILL.md`. Claude Code, Codex and Cursor all read that same file. Nobody keeps a second copy for another runtime, so a fix lands in all three at once and the copies cannot drift apart.

## Separate manifests

What differs between runtimes is the metadata that tells each one a plugin exists:

| Runtime     | Marketplace file                   | Per-plugin manifest                         |
| ----------- | ---------------------------------- | ------------------------------------------- |
| Claude Code | `.claude-plugin/marketplace.json`  | `plugins/<name>/.claude-plugin/plugin.json` |
| Codex       | `.agents/plugins/marketplace.json` | `plugins/<name>/.codex-plugin/plugin.json`  |
| Cursor      | `.cursor-plugin/marketplace.json`  | `plugins/<name>/.cursor-plugin/plugin.json` |

The Codex manifest points at the shared folder with `"skills": "./skills/"`. Where a skill uses a tool that differs between runtimes, such as the subagent tool, the skill body carries a short mapping table instead of forking into two files.

Nobody writes the Cursor files by hand. `mise run sync-cursor-manifests` builds them from the Claude Code and Codex manifests: name, description, version and the rest from the Claude Code side, the display name and skills path from the Codex side. CI runs the same task with `--check` and fails when the Cursor files drift from their sources.

## Why some plugins are Claude Code only

A plugin stays out of a runtime's marketplace when it would not work there. Four local plugins ship to Claude Code alone, for three reasons:

- **It drives Claude Code itself.** `issue-loop` has one session type `/clear` into another Claude Code session, start sessions with `--permission-mode bypassPermissions` (or `auto` when `loop.env` sets `PERMISSION_MODE=auto`), and answer Claude Code's own dialogs. Nobody has run it under Codex or Cursor, so neither lists it.
- **It ships output styles.** `prose-styles` has no skills, only Claude Code output styles. Codex and Cursor have no output-style mechanism.
- **It ships Claude Code hooks.** `guards` and `session-title` use Claude Code's hook format. Neither has a port to another runtime's hooks.

Two more gaps have other causes. Cursor leaves out `deprecated`, a frozen archive. The upstream plugins (`ponytail`, `emil`, `taste-skill`, `vercel`) have no local folder to hold a Cursor manifest, and only `ponytail` and `taste-skill` are registered for Codex. [Runtimes](/reference/runtimes.md) lists every plugin against every runtime.

A plugin left out of a marketplace still keeps its `.codex-plugin/plugin.json`, because the version check in CI needs one for every local plugin.

[AGENTS.md](../../AGENTS.md) states the rules in short; the sections below keep their reasons and history for contributors.

## Codex compatibility is metadata plus platform mapping

Codex manifests sit beside the Claude Code manifests and point at the same `skills` folder. A tool that differs between runtimes goes into the shared skill body as a mapping, never into a second skill file. A copy for one runtime would drift from the other on the first fix.

## A plugin with skills may be registered for Claude Code only when its skills drive Claude Code itself

`issue-loop` (2026-10) was the first local plugin that ships skills and still stays out of `.agents/plugins/marketplace.json`. Its skills tell an orchestrator session to send `/clear` to another Claude Code session, to start sessions with `claude --permission-mode bypassPermissions` (the `loop.env` default; `PERMISSION_MODE=auto` there makes them ask), and to answer Claude Code's own dialogs. Nobody ran the loop under Codex, so offering it in the Codex picker would promise what nobody tried.

Its `.codex-plugin/plugin.json` still exists and still sets `"skills": "./skills/"`, because the version check needs the manifest and the manifest rule needs the path; only the marketplace entry is left out, and [Runtimes](/reference/runtimes.md) says why. This shape is not for a skill that merely names Claude Code tools: there a platform mapping in the skill body is the rule. It is only for skills whose subject is Claude Code. The plugin's skills name the example project (Blattomat) for numbers and faults only; names of people, hosts, accounts and data paths from that run stay out of every file.

## Cursor manifests are generated, not written

Cursor reads `.cursor-plugin/marketplace.json` at the repo root and `plugins/<name>/.cursor-plugin/plugin.json` per plugin (format: https://cursor.com/docs/reference/plugins). `mise-tasks/sync-cursor-manifests` builds both from the Claude Code and Codex manifests: `name`, `description`, `author`, `license`, `keywords`, and `version` from `.claude-plugin/plugin.json` (the Codex version when Claude Code's omits it), `displayName` from the Codex `interface`, `skills` when the Codex manifest sets it, plus `homepage` and `repository`.

Cursor's `plugin.schema.json` rejects unknown fields, so the generator gains a field only when that schema lists it. Cursor-only fields per plugin live in the task's `extra_for` function. No plugin uses it now; its one use, a Cursor-format hooks file for `workbench`, left with that plugin in 2026-10.

The task's `EXCLUDE` list keeps five plugins out of Cursor: `deprecated` (a frozen archive), `prose-styles` (output styles have no Cursor equivalent), `guards` (its Claude Code `PreToolUse` hook needs a `beforeShellExecution` port), `session-title` (sets a Claude Code session title), and `issue-loop` (drives Claude Code sessions). Upstream-URL entries are skipped because they have no local folder.

After any manifest change, run `mise run sync-cursor-manifests`. `validate-plugin-schema` runs it with `--check` and fails on drift, and the `validate-cursor-plugins` CI job runs Cursor's own validator from `.github/cursor-validate/`.

An installed Cursor marketplace plugin was seen (2026-10) as a copy of the whole plugin folder at one commit, so files beside a skill (presets, themes, scripts, references) should ship with it and `../../presets/` style paths in skill text should keep working. Nobody has yet checked this for a plugin from this repo, and Cursor documents no way to leave out a folder such as `evals/`. Listing in the public Cursor Marketplace is a manual submission at https://cursor.com/marketplace/publish, and Cursor reviews every update before users get it.
