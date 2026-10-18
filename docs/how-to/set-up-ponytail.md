---
type: How-to Guide
title: Set up ponytail
description: Install the external ponytail plugin, know what its hooks do, and set or turn off its mode.
tags: [ponytail, external, hooks, setup]
status: stable
---

# Set up ponytail

`ponytail` is an external plugin: this marketplace points at [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT) and follows its `main` branch. Once installed it is always on. Its hooks run on `SessionStart`, `SubagentStart` and `UserPromptSubmit`, write the mode to `.ponytail-active` in the Claude config directory, and add its rules to every session and subagent.

1. Make sure `node` is on `PATH`; the hooks run with it.
2. Install the plugin.

   Claude Code:

   ```
   /plugin install ponytail@pgoell-claude-tools
   ```

   Codex: install `ponytail` from the `/plugins` picker, then open `/hooks`, trust its hooks, and start a new thread.
3. Set the mode, or turn it off:

   ```
   /ponytail lite
   /ponytail full
   /ponytail ultra
   /ponytail off
   ```

   `/ponytail` with no argument turns it on at the default level, or reports the current one.

## Check it worked

Start a new session; the hook's "Loading ponytail mode..." message shows at start, and `/ponytail` reports the level.

Upstream sets the versions and the release pace. See [the ponytail reference page](/reference/plugins/ponytail.md).
