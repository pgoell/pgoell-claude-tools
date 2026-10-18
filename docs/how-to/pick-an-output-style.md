---
type: How-to Guide
title: Pick an output style
description: Turn on one of the four prose-styles output styles in Claude Code, and turn it off again.
tags: [prose-styles, output-style, claude-code, setup]
status: stable
---

# Pick an output style

The `prose-styles` plugin ships four Claude Code output styles: `orwell`, `concise`, `ste` and `house`. A style goes into the system prompt and shapes every reply, commit message and PR body until you switch it. All four keep Claude Code's coding instructions. Claude Code only: Codex and Cursor have no output styles.

1. Install the plugin, if you have not:

   ```
   /plugin install prose-styles@pgoell-claude-tools
   ```

2. Select a style, by name:

   ```
   /output-style prose-styles:house
   ```

   Or open `/config` and pick it from the **Output style** list.

Claude Code saves the choice for this project in `.claude/settings.local.json` (key `outputStyle`). To use a style in every project, set the same key in `~/.claude/settings.json`.

## Check it worked

`/config` shows the style under **Output style**. The next reply follows it; on an older Claude Code, run `/clear` or start a new session first.

## Turn it off

```
/output-style default
```

What each style does, and which to pick: [the prose-styles reference page](/reference/plugins/prose-styles.md).
