---
type: Reference
title: The critique plugin
description: The skill that critiques an idea or plan through independent thinking frames and ends in one decision.
tags: [plugin, critique, decision]
status: stable
---

# critique

One skill that critiques an idea, plan, decision, claim or situation from several independent angles, to counter the agreeable answer a single session tends to give. It is not for code review or for feedback on a prose draft.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/critique/`; see the [plugin README](../../../plugins/critique/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation                   | What it does                                                                                                                                                                                                                                         |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/critique:critiquing-ideas` | Rewrite the input as a neutral brief, send it to one fresh subagent per thinking frame, show every frame's verdict word for word, and end with one decision, kill conditions and the cheapest next test. A fresh subagent writes that synthesis too. |

## Modes

| Mode           | Frames                                                                                                                                                                                                                                                   | Subagents |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| Full (default) | Eight core frames (pre-mortem, steelman opponent, outside view, steelman proponent, second-order effects, incentives, alternatives, assumption audit), plus conditional frames such as Chesterton's fence and a Fermi estimate when their trigger holds. | 9 or more |
| Quick          | Pre-mortem, steelman opponent, outside view. Say "quick", "fast" or "short".                                                                                                                                                                             | 4         |

The frame texts, triggers, brief template and synthesis prompt live in `plugins/critique/skills/critiquing-ideas/references/frames.md`.
