---
type: Tutorial
title: Getting started
description: Add the marketplace, install the critique plugin, and run its skill once in Claude Code and once in Codex.
tags: [install, claude-code, codex, critique]
status: stable
---

# Getting started

In this lesson you add the marketplace to Claude Code, install one plugin, and run its skill on an idea of your own. Then you do the same in Codex. You need Claude Code or Codex installed, and nothing else: the plugin we use, `critique`, needs no setup.

## Add the marketplace in Claude Code

Start Claude Code in any folder and type:

```
/plugin marketplace add pgoell/pgoell-claude-tools
```

Claude Code now knows the 25 plugins in this repository, but none is installed yet.

## Install one plugin

```
/plugin install critique@pgoell-claude-tools
```

The part after `@` names the marketplace. If the skill does not show up yet, run `/reload-plugins` or start a new session.

## Run the skill

Skills run as `/<plugin>:<skill>`. The `critique` plugin has one skill, `critiquing-ideas`. Give it a plan you are weighing, and ask for the quick mode:

```
/critique:critiquing-ideas quick critique: move our team's weekly status meeting to a written update in Slack every Friday
```

Watch what happens:

1. The skill writes a short neutral brief of your idea, with every stake it could not find marked "not stated". If your idea is too thin, it asks you one question first.
2. It sends the brief to three fresh subagents, one per thinking frame: a pre-mortem, a steelman of the opposing view, and an outside view. None of them sees your conversation.
3. One more fresh subagent reads their replies and writes the decision.
4. You get the brief as sent, a table with each frame's verdict word for word, and the decision with its kill conditions and a next test.

Without "quick", the skill runs its eight core frames plus any that fit your idea. That takes longer and costs more tokens.

## Do the same in Codex

Codex adds the marketplace from your shell, then installs from inside a session:

```sh
codex plugin marketplace add pgoell/pgoell-claude-tools
codex
```

In the session, type `/plugins`, pick `critique` from the list, and install it. Then run the same line as before:

```
/critique:critiquing-ideas quick critique: move our team's weekly status meeting to a written update in Slack every Friday
```

Codex reads the same skill file as Claude Code. Where Codex has no subagent tool, the skill runs each frame in turn in one context and says so in its report, because the frames then lose their independence.

The Codex list is shorter than the Claude Code one. [Runtimes](/reference/runtimes.md) says which plugins are missing and why.

## Cursor

Cursor installs plugins from its own marketplace screens, not from a chat command. Follow [Install in Cursor](/how-to/install-in-cursor.md).

## Where to go next

- [Skills at a glance](/reference/skills.md) lists every skill of this repo's plugins, and [Upstream skills at a glance](/reference/upstream-skills.md) those of the upstream plugins, each with the plugin that ships it.
- [Plugins](/reference/plugins/index.md) has one page per plugin, with what it needs.
- Some plugins need a CLI or an account first. Their setup guides are in [How-to guides](/how-to/index.md), for example [Set up the atlassian plugin](/how-to/set-up-atlassian.md).
- [Update plugins](/how-to/update-plugins.md) shows how to pick up new versions.
