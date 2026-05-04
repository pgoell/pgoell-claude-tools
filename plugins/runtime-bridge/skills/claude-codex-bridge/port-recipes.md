# Port recipes

Translation rules per artifact, both directions. Apply uses these to produce target files. Reviewer uses these to derive expected output independently.

## Tree walk exclusions

Skip when walking the project for hierarchical memory files:

- `.git/`, `.jj/`, `.svn/`
- `.worktrees/`
- `node_modules/`, `.venv/`, `venv/`, `target/`, `dist/`, `build/`, `__pycache__/`, `.next/`, `.cache/`, `.pytest_cache/`, `.ruff_cache/`
- Any directory pattern in `.gitignore` (best-effort match)

`.claude/`, `.codex/`, `.agents/` are NOT excluded. Memory files inside them get mirrored normally.

## 1. Memory files (CLAUDE.md ↔ AGENTS.md)

For every directory under repo root (after exclusions):

| State | Op |
|---|---|
| Only `CLAUDE.md` | `symlink` from `<dir>/AGENTS.md` to `<dir>/CLAUDE.md` |
| Only `AGENTS.md` | `symlink` from `<dir>/CLAUDE.md` to `<dir>/AGENTS.md` |
| Both, byte-identical | `already-aligned` |
| One is a symlink to the other | `already-aligned` |
| Both, content differs | `drift`; `newer` = path with newer mtime |
| Neither | no op |

Symlinks are relative (e.g. `AGENTS.md -> CLAUDE.md` not `AGENTS.md -> /abs/path/CLAUDE.md`).

## 2. Subagents

### `.claude/agents/<name>.md` → `.codex/agents/<name>.toml`

Source format (Claude): YAML frontmatter + markdown body.

```markdown
---
name: foo
description: ...
model: opus-4
tools: [Read, Bash]
color: blue
---

System prompt body in markdown.
```

Target format (Codex): TOML.

```toml
name = "foo"
description = "..."
model = "opus-4"
# model_reasoning_effort derived from model name (see lookup below)
developer_instructions = """
System prompt body in markdown.
"""
```

Field map:

| Claude | Codex | Notes |
|---|---|---|
| frontmatter `name` | `name` | direct |
| frontmatter `description` | `description` | direct |
| markdown body | `developer_instructions` (multi-line `"""..."""`) | preserve content verbatim including leading/trailing newlines stripped |
| frontmatter `model` | `model` | direct |
| frontmatter `model` | `model_reasoning_effort` | lookup: opus-* → "high", sonnet-* → "medium", haiku-* → "low"; if unknown, omit |
| frontmatter `tools` (MCP-style entry like `mcp__server__tool`) | `mcp_servers` array entry `"server"` | dedup |
| frontmatter `tools` (non-MCP names like `Read`, `Bash`) | TOML comment `# claude tools (no codex equivalent): Read, Bash` | preserve in comment |
| frontmatter `color` | dropped | Claude-only UI hint |

### `.codex/agents/<name>.toml` → `.claude/agents/<name>.md`

Reverse direction. `developer_instructions` becomes the markdown body. Codex-only fields (`sandbox_mode`, `nickname_candidates`, `model_reasoning_effort` separately from `model`) are emitted as a comment block at the top of the markdown body:

```markdown
---
name: foo
description: ...
model: opus-4
---

<!-- codex-only fields preserved for round-trip:
sandbox_mode = "workspace-write"
model_reasoning_effort = "high"
-->

System prompt body in markdown.
```

## 3. Hooks

`.claude/settings.json#hooks` (or files in `.claude/hooks/`) ↔ `.codex/hooks.json`.

Both formats use the same outer shape:

```jsonc
{
  "PreToolUse": [
    { "matcher": "Bash", "hooks": [{ "type": "command", "command": "...", "timeout": 30 }] }
  ]
}
```

Event name mapping:

| Event | Claude | Codex | Action when porting |
|---|---|---|---|
| `PreToolUse` | yes | yes | copy |
| `PostToolUse` | yes | yes | copy |
| `SessionStart` | yes | yes | copy |
| `UserPromptSubmit` | yes | yes | copy |
| `Stop` | yes | yes | copy |
| `SubagentStop` | yes | no | drop on Codex side; record in apply-log notes |
| `PreCompact` | yes | no | drop with note |
| `Notification` | yes | no | drop with note |
| `PermissionRequest` | no | yes | drop on Claude side; record in apply-log notes |

Inner hook entries (`{type: "command", command, timeout}`) match shape on both sides; copy verbatim.

## 4. Settings (lossy)

`.claude/settings.json` ↔ `.codex/config.toml`.

| Claude key | Codex location | Action |
|---|---|---|
| `model` | top-level `model = "..."` | translate |
| `env` | `[shell_environment_policy] set = {...}` | translate; preserve key order |
| `mcpServers.<name>` | `[mcp_servers.<name>]` table per server | translate per-server |
| `hooks` | (see section 3) | translate via hooks recipe |
| `permissions.allow` / `permissions.deny` | NOT TRANSLATED | emit `skip` entry: `path = ".claude/settings.json#permissions"`, reason = "no defensible auto-translation; translate manually if needed", suggested_followup = "Map to approval_policy and sandbox_mode in .codex/config.toml manually." |
| `permissions.*` (other) | NOT TRANSLATED | same as above |
| anything else | NOT TRANSLATED | emit `skip` entry preserving original key path and value verbatim |

Reverse direction: top-level Codex keys without Claude analogue (`[features]`, `project_doc_max_bytes`, `[agents]`, `[plugins."name@..."]`) emit `skip` entries.

## 5. Local overrides

`.claude/settings.local.json` ↔ `.codex/config.toml` `[profiles.local]` table.

When porting Claude → Codex: settings.local.json content goes into a `[profiles.local]` section in the destination `.codex/config.toml`. After write, verify destination `.gitignore` lists `.codex/config.toml` (apply emits a `note` if the user must add it manually).

When porting Codex → Claude: contents of `[profiles.local]` go into a fresh `.claude/settings.local.json`. Verify `.claude/settings.local.json` is in `.gitignore`.

## 6. Plugin / skill source-sniff

For each Claude plugin found under `~/.claude/plugins/cache/<owner>/<name>/<version>/`:

- Look at the same directory for `.codex-plugin/plugin.json` or `.agents/plugins/marketplace.json`.
- If found: emit `plugin_report` entry with `claude: true, codex: true`.
- If not: `claude: true, codex: false`.

For each Codex plugin under `~/.codex/plugins/<...>` and `~/.agents/plugins/<...>`:

- Same sibling check, in reverse.

`source` field is the absolute path on disk.

## 7. Flag-only (non-portable)

Always emit as `skip` entries:

| Path | Reason | Suggested followup |
|---|---|---|
| `.claude/commands/*.md` | Codex has no user-defined slash commands | Convert to a skill at `.agents/skills/<name>/SKILL.md` invoked as `$<name>` |
| `.claude/rules/*` | Cursor-style guidance, no Codex equivalent | Fold relevant content into AGENTS.md |
| `.codex/rules/*.rules` | Starlark execpolicy, no Claude analogue | Leave in place; only Codex enforces it |
| Codex `[profiles.<not local>]` | No Claude analogue | Leave in place |
