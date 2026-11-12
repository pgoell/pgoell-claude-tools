---
name: capturing-session-learnings
description: Save what we learned this session into AGENTS.md or CLAUDE.md. Use when the user wants today's lessons, gotchas or commands written into an instruction file, also when worded as improving CLAUDE.md with what we learned. Triggers on /revise-agents-md and /revise-claude-md.
---

# Agents.md Session Capture

Review the current session for context that was missing and would have helped the host agent. Propose targeted changes to the right agent-instruction file by scope: new lines, and old lines narrowed or removed.

## Platform Adaptation

| Capability        | Claude Code       | Codex                                 |
| ----------------- | ----------------- | ------------------------------------- |
| Find files        | `Glob` / `Grep`   | `shell` (`find`, `grep`)              |
| Read a file       | `Read`            | `shell` (`cat`)                       |
| Edit a file       | `Edit`            | `apply_patch` / `shell` heredoc       |
| User confirmation | `AskUserQuestion` | `ask_user` / built-in approval prompt |
| Shell commands    | `Bash`            | `shell`                               |

The skill body refers to actions abstractly. The host agent maps to its own tool inventory.

## Step 1: Reflect

What context was missing during this session that would have helped the host agent?

- Bash commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment / configuration quirks
- Warnings or gotchas encountered (one failure is not a standing rule unless it repeats or the user asks for one)
- Tool preferences (e.g. "always use ripgrep over grep here")

## Step 2: Discover candidate files

Find every agent-instruction file in scope (project + user-global), dedupe symlinked pairs via `realpath`:

```bash
{
  find . \( \
      -name "AGENTS.md" \
      -o -name "AGENTS.local.md" \
      -o -name "CLAUDE.md" \
      -o -name "CLAUDE.local.md" \
      -o -name ".claude.md" \
      -o -name ".claude.local.md" \
    \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
  ls ~/.claude/CLAUDE.md ~/.codex/AGENTS.md 2>/dev/null
} | xargs -I{} realpath {} | sort -u
```

When two paths share the same `realpath`, treat them as one logical file. Edits target the canonical realpath.

## Step 3: Classify each learning by scope

Decide where each addition belongs before drafting it:

| Scope          | Target file                                  | Examples                                                                      |
| -------------- | -------------------------------------------- | ----------------------------------------------------------------------------- |
| Project-shared | `AGENTS.md` / `CLAUDE.md` (canonical)        | Build commands, this codebase's quirks, team-wide conventions                 |
| Project-local  | `AGENTS.local.md` / `CLAUDE.local.md`        | Your personal overrides for this project, not for the team                    |
| User-global    | `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md` | Cross-project rules: writing style, tool preferences, system-wide preferences |

If a learning is generic enough to apply to other projects, route it to the user-global file rather than this project's AGENTS.md. Avoid duplication: if a rule already exists in the user-global file, don't restate it project-locally.

## Step 4: Draft changes

Before drafting a line, search the target file for one on the same subject. If one exists, change it (narrow, widen or delete it) instead of adding a second line beside it.

**Keep it concise**, one line per concept. Agent-instruction files are part of the prompt, so brevity matters.

Format: `<command or pattern>`, `<brief description>`

Avoid:

- Verbose explanations
- Obvious information
- One-off fixes unlikely to recur

A caution says when it applies, what to do and why, in the same line. A bare "do not X" reads as absolute in every later session; "prefer Y over X when W, because Z" does not. Prefer "ask before X" or "do X unless Y" to "never X".

## Step 5: Show proposed changes

For each change:

````markdown
### Update: ./AGENTS.md

**Why:** [one-line reason]

```diff
- [the old line, when you change or delete one]
+ [the new line; keep it brief]
```
````

Group by target file. Show all proposed edits to one file together.

## Step 6: Apply with approval

Ask if the user wants to apply the changes. Only edit files they approve. Use the right edit tool per Platform Adaptation. Edit the canonical realpath target only; symlinks update automatically.
