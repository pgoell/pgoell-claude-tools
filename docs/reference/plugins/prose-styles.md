---
type: Reference
title: The prose-styles plugin
description: The four Claude Code output styles that govern how the agent writes prose, and what each one does.
tags: [plugin, prose-styles, output-styles, writing]
status: stable
---

# prose-styles

Four Claude Code output styles that govern how the agent writes prose. A style goes into the system prompt for the whole session, so it shapes every reply, commit message, PR body and doc until you switch it. You do not invoke it per task. All four set `keep-coding-instructions: true`, so Claude Code keeps its coding instructions and changes only how it writes.

**Runtimes:** Claude Code

Not in Codex or Cursor: neither has an output-style mechanism. See [Runtimes](/reference/runtimes.md).

**Source:** vendored in `plugins/prose-styles/`; see the [plugin README](../../../plugins/prose-styles/README.md) for details and credits.

**Setup:** [Pick an output style](/how-to/pick-an-output-style.md)

## Styles

| Style                  | What it does                                                                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prose-styles:orwell`  | Orwell's six rules from "Politics and the English Language" (1946): short word over long, no stock phrase, active voice, cut every word that can go.                |
| `prose-styles:concise` | Maximum density: fragments allowed, articles droppable, no preamble, no closing summary. Grammar yields to brevity, facts never do.                                 |
| `prose-styles:ste`     | Simplified Technical English, condensed from ASD-STE100: one meaning per word, one instruction per step, condition before instruction. For procedures and runbooks. |
| `prose-styles:house`   | All three combined: concision sets the shape, Orwell governs word choice, STE adds only its precision rules. Where STE and concision conflict, concision wins.      |

Every style governs prose only. Code, identifiers, API names, CLI flags, config keys and quoted output are exempt in all four.
