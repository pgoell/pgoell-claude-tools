---
type: Explanation
title: Plugins without skills
description: What the prose-styles, guards and session-title plugins change in Claude Code without any skill, and why they work nowhere else.
tags: [output-styles, hooks, prose-styles, guards, session-title, claude-code]
status: stable
---

# Plugins without skills

Three plugins ship no skill. A skill waits until the agent or you call it. These plugins change Claude Code in other ways: through an output style you select once, or through a hook that runs on its own.

## prose-styles: output styles

`prose-styles` ships four output styles: `orwell`, `concise`, `ste` and `house`. An output style is text Claude Code adds to its system prompt, so it shapes every reply in the project until you switch it off. You select one with `/output-style prose-styles:house` or from the Output style list in `/config`; see [Pick an output style](/how-to/pick-an-output-style.md).

Each style sets `keep-coding-instructions: true`. Without it Claude Code drops its own software-engineering prompt, and a coding session turns into a writing assistant. Claude Code injects a style on its own, never beside another, so each file repeats the shared rules (such as the punctuation bans) in full.

Codex and Cursor have no output-style mechanism, so the plugin is in neither marketplace.

## guards and session-title: hooks

A hook is a script Claude Code runs at a fixed point, such as before a tool call or when a session starts. Both plugins declare theirs in `hooks/hooks.json`, in Claude Code's hook format.

- **guards** runs `pkill-self-match` before every Bash call. It denies `pkill -f` with a plain pattern, because Claude Code runs each command through a `bash -c` whose command line holds the pattern, so `pkill -f` kills the agent's own shell. It also denies `pgrep -f` with a plain pattern in an `until` or `while` condition, because such a loop never ends. The deny message tells the agent the fix: bracket the first letter (`pkill -f '[u]vicorn'`) or stop the process by port.
- **session-title** runs when a session starts and after `/clear`. It names the session after its folder, git branch and start time, such as `server-infra main 10-18 11:09`, so sessions stay apart in the Remote Control list. A resumed session keeps its title, and `/rename` still overrides it.

Codex and Cursor use other hook formats, and neither plugin has a port yet, so both are Claude Code only.

The plugins' own READMEs hold the details: [prose-styles](../../plugins/prose-styles/README.md), [guards](../../plugins/guards/README.md), [session-title](../../plugins/session-title/README.md).
