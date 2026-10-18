---
type: Reference
title: The playground plugin
description: The skill that builds single-file HTML playgrounds with controls, a live preview and a prompt to copy back.
tags: [plugin, playground, html]
status: stable
---

# playground

One skill that builds an interactive HTML playground: a self-contained file with controls on one side, a live preview on the other, and a generated prompt you copy back into the chat. It helps when the input is large, visual or structural and hard to put in words.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/playground/`; see the [plugin README](../../../plugins/playground/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation               | What it does                                                                                                                                                                                             |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/playground:playground` | Build a playground for design choices, data and queries, concept maps, document critique, diff review or code architecture, open it in your browser, and let you iterate until you copy the prompt back. |

## Templates

The skill picks the closest of six templates under `plugins/playground/skills/playground/templates/` and adapts it: `design-playground`, `data-explorer`, `concept-map`, `document-critique`, `diff-review`, `code-map`.

## Licence

A port of Anthropic's `playground` plugin, Apache 2.0. The skill body and templates are vendored verbatim apart from dash substitutions; the plugin's own additions are MIT. The plugin's `NOTICE` records the upstream commit and the rules applied.
