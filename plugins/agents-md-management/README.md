# agents-md-management

Audit and maintain `AGENTS.md` / `CLAUDE.md` files (and their variants) so the host agent in any runtime has current, well-organized project context.

Two skills:

| | Purpose | Triggered by |
|---|---|---|
| `agents-md-improver` | Periodic cold audit against the codebase | "audit my CLAUDE.md", "check if AGENTS.md is up to date" |
| `agents-md-session-capture` | End-of-session warm capture of learnings | "/revise-agents-md", "update AGENTS.md with what we learned this session" |

Works in Claude Code and Codex CLI. Files are deduped via `realpath`, so `CLAUDE.md` symlinked to `AGENTS.md` counts as one logical file.

## Files in scope

- `AGENTS.md`, `AGENTS.local.md`
- `CLAUDE.md`, `CLAUDE.local.md`
- `.claude.md`, `.claude.local.md` (legacy lowercase from upstream)
- `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` (user-global, included so generalizable rules can be hoisted)

`GEMINI.md` and other runtime variants are out of scope.

## Usage

```text
audit my CLAUDE.md files
check if AGENTS.md is up to date
update AGENTS.md with what we learned this session
/revise-agents-md
/revise-claude-md
```

## Credits

Derived from Anthropic's [`claude-md-management`](https://github.com/anthropics/claude-plugins/tree/main/plugins/claude-md-management) plugin by Isabella He, licensed under Apache 2.0. The reference docs under `skills/agents-md-improver/references/` are imported verbatim. See `NOTICE` for full attribution.

This plugin is licensed MIT (`LICENSE`).
