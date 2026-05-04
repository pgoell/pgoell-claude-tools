# agents-md-management plugin: design spec

**Date:** 2026-05-04
**Status:** Approved, ready for implementation plan
**Plugin:** `agents-md-management` (new)
**Skills:** `agents-md-improver`, `agents-md-session-capture`

## 1. Purpose

A two-skill plugin for maintaining `AGENTS.md` and `CLAUDE.md` files (and their variants) so that host agents in any runtime have current, well-organized project context. Ports Anthropic's upstream `claude-md-management` plugin (skill + slash command) into a runtime-agnostic form that works equally in Claude Code and Codex CLI.

Two distinct workflows live side by side in the plugin:

* **`agents-md-improver`** is the periodic *cold audit*. Sweeps every agent-instruction file in scope, scores quality, recommends targeted edits.
* **`agents-md-session-capture`** is the end-of-session *warm capture*. Reflects on what context was missing during the current session and proposes additions, routing each to the file at the correct scope (project, local, user-global).

The skills are independent. They share the discovery glob and the reference docs but otherwise stay focused on their own job.

## 2. Scope

### In scope

| File | Notes |
|---|---|
| `AGENTS.md`, `AGENTS.local.md` | Codex / agents.md spec; `AGENTS.local.md` is an emerging local-override convention |
| `CLAUDE.md`, `CLAUDE.local.md` | Documented Claude Code variants |
| `.claude.md`, `.claude.local.md` | Legacy lowercase variants kept by upstream's plugin |
| `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` | User-global memory files; included in the default sweep so generalizable rules can be moved across the project/global boundary |

Files at any depth in the repo are in scope (monorepos: `packages/*/AGENTS.md` etc.).

`node_modules/` and `.git/` are excluded.

Symlinked pairs (the common case in this repo: `CLAUDE.md` → `AGENTS.md`) are deduped via `realpath` so they are audited as one logical file. Edits target the canonical realpath.

### Out of scope

* `GEMINI.md` and other non-Claude/non-Codex runtime variants. Easy to add later if a need shows up.
* Editing skill content or restructuring directories. The plugin is purely a reader/writer of memory files.
* Networking, authentication, secrets. Pure local-filesystem operation.
* Translation between AGENTS.md and CLAUDE.md when they have diverged. That is `runtime-bridge`'s job. This plugin operates on whatever files exist as-is.

## 3. Architecture

```
plugins/agents-md-management/
├── .claude-plugin/
│   └── plugin.json                          # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json                          # Codex manifest, "skills": "./skills/"
├── README.md                                # Includes upstream credit
├── LICENSE                                  # MIT
└── skills/
    ├── agents-md-improver/
    │   ├── SKILL.md                         # ported from upstream + Platform Adaptation
    │   └── references/
    │       ├── quality-criteria.md          # verbatim from upstream
    │       ├── templates.md                 # verbatim from upstream
    │       └── update-guidelines.md         # verbatim from upstream
    └── agents-md-session-capture/
        └── SKILL.md                         # converted from upstream's /revise-claude-md
```

## 4. Discovery

Both skills use the same discovery routine. Output is a deduped list of canonical (realpath-resolved) file paths.

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

For each unique file, the host agent classifies the scope before processing:

* **Project-shared:** `AGENTS.md`, `CLAUDE.md`, `.claude.md` (in repo, in git)
* **Project-local:** `AGENTS.local.md`, `CLAUDE.local.md`, `.claude.local.md` (in repo, gitignored)
* **User-global:** `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`

The audit/capture lens shifts per scope. For project files: "is this codebase well-documented?". For the global file: "are these rules organized, non-contradictory, at the right abstraction level, and not duplicated across projects?".

## 5. Skill: `agents-md-improver`

Faithful port of the upstream `claude-md-improver` skill. Workflow phases unchanged from upstream:

1. **Discovery** — run the glob from §4.
2. **Quality assessment** — score each unique file against the rubric in `references/quality-criteria.md`. Six criteria (commands/workflows, architecture clarity, non-obvious patterns, conciseness, currency, actionability), letter grades A–F.
3. **Quality report** — output the report *before* any edits, with file-by-file scores, issues, and recommended additions.
4. **Targeted updates** — show diffs for each proposed addition, grouped by target file, each with a `Why:` line. Confirmation required before writing.
5. **Apply** — edit each approved file via the host agent's edit tool (see Platform Adaptation, §7).

Reference docs (`quality-criteria.md`, `templates.md`, `update-guidelines.md`) are imported verbatim from upstream — they describe content quality, which is runtime-agnostic.

The skill body adapts the discovery section (§4), the file-types table (adds `AGENTS.md`, `AGENTS.local.md`, scope classification, dedupe-by-realpath note), and replaces "Claude auto-discovers" prose with "the host agent auto-discovers". No other content changes.

## 6. Skill: `agents-md-session-capture`

Replaces upstream's `/revise-claude-md` slash command. Codex has no slash commands, so a skill is the only artifact that works in both runtimes.

Workflow:

1. **Reflect** — what context was missing during the current session that would have helped the host agent? Bash commands used, code-style patterns followed, testing approaches that worked, environment quirks, gotchas hit.
2. **Discover** — run the glob from §4.
3. **Classify each learning by scope:**
   * Project-specific (build commands, this codebase's quirks) → project-shared file
   * Personal / not-for-team (your local override) → project-local file
   * Generalizable / cross-project (writing style, tool preferences, system-wide rules) → user-global file
4. **Draft additions** — concise, one line per concept. Format: `<command or pattern>` — `<brief description>`. Avoid verbose explanations and obvious info.
5. **Show proposed diffs** — grouped by target file, each with a `Why:` line.
6. **Apply on user approval** — file by file.

Trigger phrases include "capture session learnings", "update CLAUDE.md / AGENTS.md with what we learned", "/revise-agents-md", "/revise-claude-md" (the legacy form, since users will still type it from muscle memory).

## 7. Platform Adaptation

Both skills include the same table near the top of `SKILL.md`:

| Capability | Claude Code | Codex |
|---|---|---|
| Find files | `Glob` / `Grep` | `shell` (`find`, `grep`) |
| Read a file | `Read` | `shell` (`cat`) |
| Edit a file | `Edit` | `apply_patch` / `shell` heredoc |
| User confirmation | `AskUserQuestion` | `ask_user` / built-in approval prompt |
| Shell commands | `Bash` | `shell` |

The skill bodies refer to actions abstractly ("read the file", "apply the diff") and the host agent maps via the table.

## 8. Marketplace registration

**`.claude-plugin/marketplace.json`** (append to `plugins`):

```json
{
  "name": "agents-md-management",
  "source": "./plugins/agents-md-management",
  "description": "Audit and maintain AGENTS.md / CLAUDE.md files across project and user-global scopes; capture session learnings into the right file by scope",
  "version": "0.1.0"
}
```

**`.agents/plugins/marketplace.json`** (append to `plugins`):

```json
{
  "name": "agents-md-management",
  "source": { "source": "local", "path": "./plugins/agents-md-management" },
  "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
  "category": "Productivity",
  "interface": {
    "displayName": "Agents.md Management",
    "shortDescription": "Audit AGENTS.md/CLAUDE.md and capture session learnings"
  }
}
```

`plugins/agents-md-management/.codex-plugin/plugin.json` includes the longer interface block (`displayName`, `shortDescription`, `longDescription`, `developerName`, `category`, `capabilities: ["Interactive", "Write"]`, `defaultPrompt`, `screenshots`) per repo convention.

## 9. Versioning, attribution, license

* **Plugin version:** `0.1.0`. Matches `runtime-bridge`'s pattern. This is a port, not a v1 product.
* **Author on manifests:** Pascal Kraus.
* **Upstream credit:** README includes a credit section pointing to Anthropic's `claude-md-management` plugin and Isabella He, with a note that the reference docs (`quality-criteria.md`, `templates.md`, `update-guidelines.md`) are imported verbatim.
* **License:** MIT, matching the rest of the repo.

## 10. Tests

### Skill-triggering (`tests/skill-triggering/prompts/`)

* `agents-md-audit.txt` — "audit my CLAUDE.md files"
* `agents-md-audit-agents.txt` — "check if AGENTS.md is up to date"
* `agents-md-session-capture.txt` — "update AGENTS.md with what we learned this session"
* `agents-md-session-capture-cmd.txt` — "/revise-agents-md"
* `agents-md-global-audit.txt` — "audit my global ~/.claude/CLAUDE.md"

### Unit (`tests/unit/test-agents-md-skills.sh`)

Asserts:

* Both skills load and are recognized by name
* Descriptions mention audit/improve and session learnings respectively
* Skill bodies mention both `AGENTS.md` and `CLAUDE.md`
* Both skill bodies mention `realpath` (the dedup hint, embedded in the shared discovery snippet from §4)
* Skill bodies have the Platform Adaptation table (check for the row labels)
* Reference docs `quality-criteria.md`, `templates.md`, `update-guidelines.md` exist under `agents-md-improver/references/` and are referenced from `SKILL.md`

### No integration tests

Per project decision. The audit logic is inherited from upstream unchanged; integration tests would mostly re-validate that.

## 11. Out-of-scope follow-ups

Captured here so they don't get lost:

* `GEMINI.md` and other runtime variants in the default sweep.
* Auto-creating a missing `AGENTS.md` ↔ `CLAUDE.md` symlink when one file is present and the other isn't. That is `runtime-bridge`'s job; this plugin doesn't move into that territory.
* A "compare global vs project rules and recommend hoisting" mode for the audit skill. Currently the skill flags scope-mismatch in prose, not as a structured action.
