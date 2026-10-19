---
type: llm
---

The user asks how to make Claude Code run Prettier on a file after every edit or write, and guesses that it is a hook in settings.json. This is a request for a hooks config, not for a skill or an instruction-file rule.

PASS if the response shows a hooks config for settings.json inline (a PostToolUse hook, any matcher that covers Edit and Write, such as `Edit|MultiEdit|Write`, and a command that runs the formatter), or asks one short clarifying question (a proposed config passes, since the available tools cannot write files). FAIL if the response proposes a skill or a CLAUDE.md or AGENTS.md line instead of a hook, or gives neither a config nor one short clarifying question.
