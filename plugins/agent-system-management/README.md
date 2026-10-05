# agent-system-management

Manage the host agent's instruction layer and skill layer in any runtime: audit and update `AGENTS.md` / `CLAUDE.md` files (and their variants), capture session learnings, and scaffold or iterate on Claude Code / Codex skills.

Three skills:

|                               | Purpose                                                                                                                          | Triggered by                                                                                                                                              |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `improving-instructions`      | Periodic cold audit of agent-instruction files                                                                                   | "audit my CLAUDE.md", "check if AGENTS.md is up to date"                                                                                                  |
| `capturing-session-learnings` | End-of-session warm capture of learnings                                                                                         | "/revise-agents-md", "update AGENTS.md with what we learned this session"                                                                                 |
| `creating-skills`             | Full skill lifecycle (create, eval-driven iteration, benchmarking, bulletproofing, description optimization, cutting, packaging) | "create a skill", "improve this skill", "run evals on my skill", "optimize the description", "turn this conversation into a skill", "cut this skill down" |

Works in Claude Code and Codex CLI. Files are deduped via `realpath`, so `CLAUDE.md` symlinked to `AGENTS.md` counts as one logical file.

## Files in scope (instruction skills)

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
create a new skill for formatting my release notes
improve this skill based on the eval results
benchmark this skill against a no-skill baseline
optimize this skill's description for triggering
turn this conversation into a reusable skill
cut this skill to its core
```

## Credits

The `improving-instructions` and `capturing-session-learnings` skills are derived from Anthropic's [`claude-md-management`](https://github.com/anthropics/claude-plugins/tree/main/plugins/claude-md-management) plugin by Isabella He, licensed under Apache 2.0. The reference docs under `skills/improving-instructions/references/` are imported verbatim. See `NOTICE` for full attribution.

The `creating-skills` skill is derived from Anthropic's [`skill-creator`](https://github.com/anthropics/skills) skill (Apache 2.0), with writing guidance adapted from Matt Pocock's [`writing-great-skills`](https://github.com/mattpocock/skills) and Jesse Vincent's [`writing-skills`](https://github.com/obra/superpowers) and swyx's [`skill-cutter`](https://github.com/swyxio/skills/tree/main/skill-cutter) (all MIT). It was ported via the AIDE-claude-plugins marketplace. See `NOTICE` for full attribution and the port-time em-dash substitution rules.

This plugin is licensed MIT (`LICENSE`).
