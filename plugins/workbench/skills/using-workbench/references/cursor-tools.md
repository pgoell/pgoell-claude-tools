# Cursor Tool Mapping

Skills use Claude Code tool names. When you meet these in a skill on Cursor, use the Cursor equivalent. Codex users: see `codex-tools.md`.

| Skill references                  | Cursor equivalent                                                               |
| --------------------------------- | ------------------------------------------------------------------------------- |
| `Agent` tool (dispatch subagent)  | `Task` tool with a focused prompt                                               |
| Multiple `Agent` calls (parallel) | Several `Task` calls in one message                                             |
| `SendMessage` (continue an agent) | Call `Task` again with the agent ID the first call returned, feedback in prompt |
| Model override                    | Name a model only if the `Task` schema has a model field                        |
| `Explore` agent type, haiku model | `Task` with the built-in Explore subagent, which uses a faster model by default |

Read the `Task` tool's own schema before the first call for the names of the agent ID, subagent type and model fields.

## Named agent dispatch

Claude Code skills name agent types such as `general-purpose` or `superpowers:code-reviewer`. Cursor's docs name two built-in subagents (Explore, Browser) plus the custom ones a project defines, and no `general-purpose` type.

When a skill says to dispatch a named agent type:

1. Find the agent's prompt file (for example the skill's `code-quality-reviewer-prompt.md`).
2. Fill its placeholders.
3. Pass the filled text as the `Task` prompt to a default subagent.

| Skill instruction                              | Cursor equivalent                              |
| ---------------------------------------------- | ---------------------------------------------- |
| `Agent` (`superpowers:code-reviewer`)          | `Task` with the filled `code-reviewer.md` text |
| `Agent` (`general-purpose`) with inline prompt | `Task` with the same prompt                    |

No way to continue an agent (no ID came back, or the resume fails): start a fresh `Task` with the original brief, the agent's last report and the feedback.
