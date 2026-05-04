# agents-md-management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Anthropic's `claude-md-management` plugin (one skill + one slash command) into a runtime-agnostic, two-skill plugin in this marketplace, working in both Claude Code and Codex CLI.

**Architecture:** New plugin `plugins/agents-md-management/` with two skills: `agents-md-improver` (cold audit) and `agents-md-session-capture` (warm end-of-session capture). Reference docs ported verbatim from upstream. Shared discovery glob covers `AGENTS.md`/`CLAUDE.md` plus their variants and user-global memory files; symlinked pairs are deduped via `realpath`. Both skills include a Platform Adaptation table mapping Claude Code tool names to Codex equivalents.

**Tech Stack:** Markdown skill files, JSON plugin manifests, Bash unit tests via the repo's existing `tests/test-helpers.sh`.

**Spec:** `docs/superpowers/specs/2026-05-04-agents-md-management-design.md`

**Upstream source path (read-only):**
`/home/pascal/.claude/plugins/marketplaces/claude-plugins-official/plugins/claude-md-management/`

**Licensing note:** Upstream is Apache 2.0. This plugin's LICENSE is MIT for our additions. A NOTICE file at the plugin root attributes the ported portions (reference docs and skill workflows derived from upstream) to Anthropic / Isabella He under Apache 2.0. Apache 2.0 and MIT are compatible; the NOTICE preserves Apache's attribution requirement.

---

## File Structure

```
plugins/agents-md-management/
├── .claude-plugin/
│   └── plugin.json                          # NEW — Claude Code manifest
├── .codex-plugin/
│   └── plugin.json                          # NEW — Codex manifest, "skills": "./skills/"
├── LICENSE                                  # NEW — MIT
├── NOTICE                                   # NEW — Apache 2.0 attribution for ported content
├── README.md                                # NEW — usage + upstream credit
└── skills/
    ├── agents-md-improver/
    │   ├── SKILL.md                         # NEW — adapted port
    │   └── references/
    │       ├── quality-criteria.md          # NEW — verbatim copy from upstream
    │       ├── templates.md                 # NEW — verbatim copy from upstream
    │       └── update-guidelines.md         # NEW — verbatim copy from upstream
    └── agents-md-session-capture/
        └── SKILL.md                         # NEW — adapted from upstream's /revise-claude-md command

.claude-plugin/marketplace.json              # MODIFY — append plugin entry
.agents/plugins/marketplace.json             # MODIFY — append plugin entry
README.md                                    # MODIFY — add to Plugins table

tests/skill-triggering/prompts/
├── agents-md-audit.txt                      # NEW
├── agents-md-audit-agents.txt               # NEW
├── agents-md-session-capture.txt            # NEW
├── agents-md-session-capture-cmd.txt        # NEW
└── agents-md-global-audit.txt               # NEW

tests/unit/
└── test-agents-md-skills.sh                 # NEW
```

---

## Task 1: Scaffold plugin directory + manifests + LICENSE/NOTICE/README

**Files:**
- Create: `plugins/agents-md-management/.claude-plugin/plugin.json`
- Create: `plugins/agents-md-management/.codex-plugin/plugin.json`
- Create: `plugins/agents-md-management/LICENSE`
- Create: `plugins/agents-md-management/NOTICE`
- Create: `plugins/agents-md-management/README.md`

- [ ] **Step 1: Create the directory tree**

```bash
mkdir -p plugins/agents-md-management/.claude-plugin
mkdir -p plugins/agents-md-management/.codex-plugin
mkdir -p plugins/agents-md-management/skills/agents-md-improver/references
mkdir -p plugins/agents-md-management/skills/agents-md-session-capture
```

- [ ] **Step 2: Write `plugins/agents-md-management/.claude-plugin/plugin.json`**

```json
{
  "name": "agents-md-management",
  "version": "0.1.0",
  "description": "Audit and maintain AGENTS.md / CLAUDE.md files across project and user-global scopes; capture session learnings into the right file by scope.",
  "author": { "name": "Pascal Kraus" },
  "license": "MIT",
  "keywords": ["agents-md", "claude-md", "memory", "audit", "session-capture", "claude-code", "codex"]
}
```

- [ ] **Step 3: Write `plugins/agents-md-management/.codex-plugin/plugin.json`**

```json
{
  "name": "agents-md-management",
  "version": "0.1.0",
  "description": "Audit and maintain AGENTS.md / CLAUDE.md files; capture session learnings",
  "author": { "name": "Pascal Kraus" },
  "license": "MIT",
  "keywords": ["agents-md", "claude-md", "memory", "audit", "session-capture", "claude-code", "codex"],
  "skills": "./skills/",
  "interface": {
    "displayName": "Agents.md Management",
    "shortDescription": "Audit AGENTS.md/CLAUDE.md and capture session learnings",
    "longDescription": "Two skills for keeping agent-instruction files current. agents-md-improver runs a periodic cold audit, scoring each file against a six-criterion rubric and proposing targeted edits. agents-md-session-capture runs an end-of-session warm capture, classifying each learning by scope (project-shared, project-local, user-global) and routing edits to the right file. Discovery is symlink-aware via realpath, so paired CLAUDE.md/AGENTS.md count as one logical file. User-global memory files (~/.claude/CLAUDE.md, ~/.codex/AGENTS.md) are included in the default sweep.",
    "developerName": "Pascal Kraus",
    "category": "Productivity",
    "capabilities": ["Interactive", "Read", "Write"],
    "defaultPrompt": [
      "Audit my CLAUDE.md and AGENTS.md files",
      "Update AGENTS.md with what we learned this session",
      "Check if my agent instructions are up to date"
    ],
    "screenshots": []
  }
}
```

- [ ] **Step 4: Write `plugins/agents-md-management/LICENSE` (MIT)**

```text
MIT License

Copyright (c) 2026 Pascal Kraus

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 5: Write `plugins/agents-md-management/NOTICE`**

```text
agents-md-management
Copyright 2026 Pascal Kraus

This plugin contains content derived from Anthropic's claude-md-management
plugin (https://github.com/anthropics/claude-plugins), authored by Isabella He,
licensed under the Apache License, Version 2.0:

  - skills/agents-md-improver/SKILL.md
      (workflow phases, quality rubric structure, report format)
  - skills/agents-md-improver/references/quality-criteria.md (verbatim)
  - skills/agents-md-improver/references/templates.md         (verbatim)
  - skills/agents-md-improver/references/update-guidelines.md (verbatim)
  - skills/agents-md-session-capture/SKILL.md
      (adapted from upstream's /revise-claude-md slash command)

Apache License 2.0: http://www.apache.org/licenses/LICENSE-2.0

Adaptations are licensed under MIT (see LICENSE) where they qualify as
original work; preserved upstream content remains under Apache 2.0.
```

- [ ] **Step 6: Write `plugins/agents-md-management/README.md`**

````markdown
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
````

- [ ] **Step 7: Verify the manifests parse**

```bash
jq empty plugins/agents-md-management/.claude-plugin/plugin.json
jq empty plugins/agents-md-management/.codex-plugin/plugin.json
```

Expected: no output, exit 0 for both.

- [ ] **Step 8: Commit**

```bash
git add plugins/agents-md-management/.claude-plugin/plugin.json \
        plugins/agents-md-management/.codex-plugin/plugin.json \
        plugins/agents-md-management/LICENSE \
        plugins/agents-md-management/NOTICE \
        plugins/agents-md-management/README.md
git commit -m "feat(agents-md-management): scaffold plugin manifests, license, readme"
```

---

## Task 2: Port reference docs verbatim from upstream

**Files:**
- Create: `plugins/agents-md-management/skills/agents-md-improver/references/quality-criteria.md`
- Create: `plugins/agents-md-management/skills/agents-md-improver/references/templates.md`
- Create: `plugins/agents-md-management/skills/agents-md-improver/references/update-guidelines.md`

These are imported verbatim from upstream because they describe content quality (rubric scoring, CLAUDE.md templates, update do's-and-don'ts), which is runtime-agnostic. Do not edit them.

- [ ] **Step 1: Copy the three reference files verbatim**

```bash
UPSTREAM=/home/pascal/.claude/plugins/marketplaces/claude-plugins-official/plugins/claude-md-management/skills/claude-md-improver/references
DEST=plugins/agents-md-management/skills/agents-md-improver/references

cp "$UPSTREAM/quality-criteria.md"   "$DEST/quality-criteria.md"
cp "$UPSTREAM/templates.md"          "$DEST/templates.md"
cp "$UPSTREAM/update-guidelines.md"  "$DEST/update-guidelines.md"
```

- [ ] **Step 2: Verify the copies are byte-identical**

```bash
diff -r "$UPSTREAM" "$DEST"
```

Expected: no output, exit 0. Diff should report no differences.

- [ ] **Step 3: Commit**

```bash
git add plugins/agents-md-management/skills/agents-md-improver/references/
git commit -m "feat(agents-md-management): port reference docs verbatim from upstream"
```

---

## Task 3: Write `agents-md-improver/SKILL.md` (adapted port)

**Files:**
- Create: `plugins/agents-md-management/skills/agents-md-improver/SKILL.md`

The skill is a faithful port of upstream's `claude-md-improver/SKILL.md`. Three changes from upstream:

1. Frontmatter `name` is `agents-md-improver` (not `claude-md-improver`); description lists synonyms (CLAUDE.md, AGENTS.md, "agent instructions", "memory file") so it triggers regardless of which name the user uses.
2. Discovery section uses the new glob (six file variants + user-global) and dedupes via `realpath`.
3. Replace "Claude auto-discovers" prose with "the host agent auto-discovers"; add the Platform Adaptation table.

Reference doc links unchanged (still `references/quality-criteria.md` etc.).

- [ ] **Step 1: Write the file**

````markdown
---
name: agents-md-improver
description: Audit and improve AGENTS.md / CLAUDE.md files (and variants like AGENTS.local.md, CLAUDE.local.md, .claude.md, .claude.local.md, plus user-global ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md) in repositories. Use when user asks to check, audit, update, improve, or fix agent-instruction files. Scans for all variants, dedupes symlinked pairs via realpath, evaluates quality against a six-criterion rubric, outputs a quality report, then makes targeted updates. Also triggers on "CLAUDE.md maintenance", "AGENTS.md audit", "project memory optimization", or "agent instructions audit".
tools: Read, Glob, Grep, Bash, Edit
---

# Agents.md Improver

Audit, evaluate, and improve agent-instruction files (AGENTS.md, CLAUDE.md, and variants) across a codebase to ensure the host agent has optimal project context.

**This skill can write to agent-instruction files.** After presenting a quality report and getting user approval, it updates files with targeted improvements.

## Platform Adaptation

| Capability | Claude Code | Codex |
|---|---|---|
| Find files | `Glob` / `Grep` | `shell` (`find`, `grep`) |
| Read a file | `Read` | `shell` (`cat`) |
| Edit a file | `Edit` | `apply_patch` / `shell` heredoc |
| User confirmation | `AskUserQuestion` | `ask_user` / built-in approval prompt |
| Shell commands | `Bash` | `shell` |

The skill body refers to actions abstractly ("read the file", "apply the diff"). The host agent maps to its own tool inventory.

## Workflow

### Phase 1: Discovery

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

**File Types & Locations:**

| Type | Location | Purpose |
|------|----------|---------|
| Project-shared | `./AGENTS.md`, `./CLAUDE.md`, `./.claude.md` | Primary project context, in git, shared with team |
| Project-local | `./AGENTS.local.md`, `./CLAUDE.local.md`, `./.claude.local.md` | Personal overrides, gitignored |
| User-global | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` | User-wide defaults across all projects |
| Package-specific | `./packages/*/AGENTS.md`, `./packages/*/CLAUDE.md` | Module-level context in monorepos |
| Subdirectory | Any nested location | Feature/domain-specific context |

**Note:** The host agent auto-discovers agent-instruction files in parent directories, making monorepo setups work automatically. When two paths share the same `realpath` (typical when CLAUDE.md is a symlink to AGENTS.md), audit them as one logical file and edit the canonical realpath target.

### Phase 2: Quality Assessment

For each unique file, evaluate against quality criteria. See [references/quality-criteria.md](references/quality-criteria.md) for detailed rubrics.

**Scope-aware lens:** the assessment lens shifts per scope. For project files: "is this codebase well-documented for an agent?". For user-global files: "are these rules organized, non-contradictory, at the right abstraction level, and not duplicated across projects?".

**Quick Assessment Checklist:**

| Criterion | Weight | Check |
|-----------|--------|-------|
| Commands/workflows documented | High | Are build/test/deploy commands present? |
| Architecture clarity | High | Can the host agent understand the codebase structure? |
| Non-obvious patterns | Medium | Are gotchas and quirks documented? |
| Conciseness | Medium | No verbose explanations or obvious info? |
| Currency | High | Does it reflect current codebase state? |
| Actionability | High | Are instructions executable, not vague? |

**Quality Scores:**
- **A (90-100)**: Comprehensive, current, actionable
- **B (70-89)**: Good coverage, minor gaps
- **C (50-69)**: Basic info, missing key sections
- **D (30-49)**: Sparse or outdated
- **F (0-29)**: Missing or severely outdated

### Phase 3: Quality Report Output

**ALWAYS output the quality report BEFORE making any updates.**

Format:

```
## Agents.md Quality Report

### Summary
- Files found: X (Y unique after realpath dedup)
- Average score: X/100
- Files needing update: X

### File-by-File Assessment

#### 1. ./AGENTS.md (Project-shared) — also reachable as ./CLAUDE.md (symlink)
**Score: XX/100 (Grade: X)**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Commands/workflows | X/20 | ... |
| Architecture clarity | X/20 | ... |
| Non-obvious patterns | X/15 | ... |
| Conciseness | X/15 | ... |
| Currency | X/15 | ... |
| Actionability | X/15 | ... |

**Issues:**
- [List specific problems]

**Recommended additions:**
- [List what should be added]

#### 2. ./packages/api/AGENTS.md (Package-specific)
...
```

### Phase 4: Targeted Updates

After outputting the quality report, ask user for confirmation before updating.

**Update Guidelines (Critical):**

1. **Propose targeted additions only** — focus on genuinely useful info:
   - Commands or workflows discovered during analysis
   - Gotchas or non-obvious patterns found in code
   - Package relationships that weren't clear
   - Testing approaches that work
   - Configuration quirks

2. **Keep it minimal** — avoid:
   - Restating what's obvious from the code
   - Generic best practices already covered
   - One-off fixes unlikely to recur
   - Verbose explanations when a one-liner suffices

3. **Show diffs** — for each change, show:
   - Which file to update (use the canonical realpath)
   - The specific addition (as a diff or quoted block)
   - Brief explanation of why this helps future sessions

**Diff Format:**

````markdown
### Update: ./AGENTS.md

**Why:** Build command was missing, causing confusion about how to run the project.

```diff
+ ## Quick Start
+
+ ```bash
+ npm install
+ npm run dev  # Start development server on port 3000
+ ```
```
````

### Phase 5: Apply Updates

After user approval, apply changes (see Platform Adaptation for the right edit tool). Preserve existing content structure. Edit the canonical realpath target only — symlinks update automatically.

## Templates

See [references/templates.md](references/templates.md) for templates by project type.

## Update Guidelines Reference

See [references/update-guidelines.md](references/update-guidelines.md) for full do's and don'ts.

## Common Issues to Flag

1. **Stale commands**: build commands that no longer work
2. **Missing dependencies**: required tools not mentioned
3. **Outdated architecture**: file structure that's changed
4. **Missing environment setup**: required env vars or config
5. **Broken test commands**: test scripts that have changed
6. **Undocumented gotchas**: non-obvious patterns not captured
7. **Scope mismatch**: project-specific rules in the user-global file (or vice versa)
8. **Duplicate rules**: same rule stated in both project and user-global file

## User Tips to Share

When presenting recommendations, remind users:

- **`#` key shortcut (Claude Code)**: during a Claude Code session, press `#` to have Claude auto-incorporate learnings into the project memory file
- **Keep it concise**: agent-instruction files should be human-readable; dense is better than verbose
- **Actionable commands**: all documented commands should be copy-paste ready
- **Use `*.local.md`**: for personal preferences not shared with team (add to `.gitignore`)
- **Global defaults**: put user-wide preferences in `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md`
- **Symlink for cross-runtime parity**: if you use both Claude Code and Codex, symlink `CLAUDE.md` → `AGENTS.md` so a single file serves both

## What Makes a Great Agent-Instruction File

**Key principles:**
- Concise and human-readable
- Actionable commands that can be copy-pasted
- Project-specific patterns, not generic advice
- Non-obvious gotchas and warnings

**Recommended sections** (use only what's relevant):
- Commands (build, test, dev, lint)
- Architecture (directory structure)
- Key Files (entry points, config)
- Code Style (project conventions)
- Environment (required vars, setup)
- Testing (commands, patterns)
- Gotchas (quirks, common mistakes)
- Workflow (when to do what)
````

- [ ] **Step 2: Verify file size and references**

```bash
wc -l plugins/agents-md-management/skills/agents-md-improver/SKILL.md
ls plugins/agents-md-management/skills/agents-md-improver/references/
```

Expected: SKILL.md should be ~180–220 lines. References dir should contain `quality-criteria.md`, `templates.md`, `update-guidelines.md`.

- [ ] **Step 3: Verify discovery snippet is well-formed**

```bash
grep -A 12 'find \\.' plugins/agents-md-management/skills/agents-md-improver/SKILL.md | head -15
```

Expected: prints the discovery glob block.

- [ ] **Step 4: Commit**

```bash
git add plugins/agents-md-management/skills/agents-md-improver/SKILL.md
git commit -m "feat(agents-md-management): add agents-md-improver skill"
```

---

## Task 4: Write `agents-md-session-capture/SKILL.md`

**Files:**
- Create: `plugins/agents-md-management/skills/agents-md-session-capture/SKILL.md`

This skill replaces upstream's `/revise-claude-md` slash command. Codex has no slash commands, so it must be a skill. Description triggers on `/revise-claude-md` and `/revise-agents-md` so users typing the legacy form still get routed correctly.

- [ ] **Step 1: Write the file**

````markdown
---
name: agents-md-session-capture
description: Capture learnings from the current session and update AGENTS.md / CLAUDE.md (and variants, including user-global ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md) with context that would help future sessions. Use when the user wants to "update CLAUDE.md with what we learned", "capture session learnings", "revise AGENTS.md", or types "/revise-agents-md" or "/revise-claude-md". Routes each learning to the right file by scope: project-specific learnings to AGENTS.md/CLAUDE.md, personal overrides to *.local.md, generalizable rules to the user-global file.
tools: Read, Glob, Grep, Bash, Edit
---

# Agents.md Session Capture

Review the current session for context that was missing and would have helped the host agent. Propose targeted additions to the right agent-instruction file by scope.

## Platform Adaptation

| Capability | Claude Code | Codex |
|---|---|---|
| Find files | `Glob` / `Grep` | `shell` (`find`, `grep`) |
| Read a file | `Read` | `shell` (`cat`) |
| Edit a file | `Edit` | `apply_patch` / `shell` heredoc |
| User confirmation | `AskUserQuestion` | `ask_user` / built-in approval prompt |
| Shell commands | `Bash` | `shell` |

The skill body refers to actions abstractly. The host agent maps to its own tool inventory.

## Step 1: Reflect

What context was missing during this session that would have helped the host agent?

- Bash commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment / configuration quirks
- Warnings or gotchas encountered
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

| Scope | Target file | Examples |
|---|---|---|
| Project-shared | `AGENTS.md` / `CLAUDE.md` (canonical) | Build commands, this codebase's quirks, team-wide conventions |
| Project-local | `AGENTS.local.md` / `CLAUDE.local.md` | Your personal overrides for this project, not for the team |
| User-global | `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md` | Cross-project rules: writing style, tool preferences, system-wide preferences |

If a learning is generic enough to apply to other projects, route it to the user-global file rather than this project's AGENTS.md. Avoid duplication: if a rule already exists in the user-global file, don't restate it project-locally.

## Step 4: Draft additions

**Keep it concise** — one line per concept. Agent-instruction files are part of the prompt, so brevity matters.

Format: `<command or pattern>` — `<brief description>`

Avoid:
- Verbose explanations
- Obvious information
- One-off fixes unlikely to recur

## Step 5: Show proposed changes

For each addition:

````markdown
### Update: ./AGENTS.md

**Why:** [one-line reason]

```diff
+ [the addition — keep it brief]
```
````

Group by target file. Show all proposed edits to one file together.

## Step 6: Apply with approval

Ask if the user wants to apply the changes. Only edit files they approve. Use the right edit tool per Platform Adaptation. Edit the canonical realpath target only — symlinks update automatically.
````

- [ ] **Step 2: Verify the file**

```bash
wc -l plugins/agents-md-management/skills/agents-md-session-capture/SKILL.md
grep -c 'realpath' plugins/agents-md-management/skills/agents-md-session-capture/SKILL.md
```

Expected: ~80–110 lines. `realpath` should appear at least 2 times (in the discovery snippet and the dedup note).

- [ ] **Step 3: Commit**

```bash
git add plugins/agents-md-management/skills/agents-md-session-capture/SKILL.md
git commit -m "feat(agents-md-management): add agents-md-session-capture skill"
```

---

## Task 5: Register in Claude Code marketplace

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Inspect current state**

```bash
jq '.plugins | length' .claude-plugin/marketplace.json
jq '.plugins[].name' .claude-plugin/marketplace.json
```

Expected: 5 plugins, names include `atlassian`, `google-workspace`, `research`, `writing`, `runtime-bridge`.

- [ ] **Step 2: Append the new plugin entry using `jq`**

```bash
jq '.plugins += [{
  "name": "agents-md-management",
  "source": "./plugins/agents-md-management",
  "description": "Audit and maintain AGENTS.md / CLAUDE.md files across project and user-global scopes; capture session learnings into the right file by scope",
  "version": "0.1.0"
}]' .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.tmp \
&& mv .claude-plugin/marketplace.json.tmp .claude-plugin/marketplace.json
```

- [ ] **Step 3: Verify**

```bash
jq '.plugins | length' .claude-plugin/marketplace.json
jq '.plugins[-1]' .claude-plugin/marketplace.json
```

Expected: 6 plugins; last entry matches the new plugin block.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat(agents-md-management): register in Claude Code marketplace"
```

---

## Task 6: Register in Codex marketplace

**Files:**
- Modify: `.agents/plugins/marketplace.json`

- [ ] **Step 1: Inspect current state**

```bash
jq '.plugins | length' .agents/plugins/marketplace.json
jq '.plugins[].name' .agents/plugins/marketplace.json
```

Expected: 5 plugins.

- [ ] **Step 2: Append the new entry**

```bash
jq '.plugins += [{
  "name": "agents-md-management",
  "source": { "source": "local", "path": "./plugins/agents-md-management" },
  "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
  "category": "Productivity",
  "interface": {
    "displayName": "Agents.md Management",
    "shortDescription": "Audit AGENTS.md/CLAUDE.md and capture session learnings"
  }
}]' .agents/plugins/marketplace.json > .agents/plugins/marketplace.json.tmp \
&& mv .agents/plugins/marketplace.json.tmp .agents/plugins/marketplace.json
```

- [ ] **Step 3: Verify**

```bash
jq '.plugins | length' .agents/plugins/marketplace.json
jq '.plugins[-1]' .agents/plugins/marketplace.json
```

Expected: 6 plugins; last entry matches the new block above.

- [ ] **Step 4: Commit**

```bash
git add .agents/plugins/marketplace.json
git commit -m "feat(agents-md-management): register in Codex marketplace"
```

---

## Task 7: Skill-triggering test prompts

**Files:**
- Create: `tests/skill-triggering/prompts/agents-md-audit.txt`
- Create: `tests/skill-triggering/prompts/agents-md-audit-agents.txt`
- Create: `tests/skill-triggering/prompts/agents-md-session-capture.txt`
- Create: `tests/skill-triggering/prompts/agents-md-session-capture-cmd.txt`
- Create: `tests/skill-triggering/prompts/agents-md-global-audit.txt`

Each file is a single natural-language prompt; the test runner asserts that the named skill triggers.

- [ ] **Step 1: Write `agents-md-audit.txt`**

```text
Audit my CLAUDE.md files and tell me where the gaps are.
```

- [ ] **Step 2: Write `agents-md-audit-agents.txt`**

```text
Check if my AGENTS.md is up to date with the current codebase.
```

- [ ] **Step 3: Write `agents-md-session-capture.txt`**

```text
Update AGENTS.md with what we learned during this session.
```

- [ ] **Step 4: Write `agents-md-session-capture-cmd.txt`**

```text
/revise-agents-md
```

- [ ] **Step 5: Write `agents-md-global-audit.txt`**

```text
Audit my global ~/.claude/CLAUDE.md and let me know if any rules belong in a project file instead.
```

- [ ] **Step 6: Sanity-check the prompt files**

```bash
ls tests/skill-triggering/prompts/agents-md-*.txt
wc -l tests/skill-triggering/prompts/agents-md-*.txt
```

Expected: 5 files listed; each 1–2 lines.

- [ ] **Step 7: Commit**

```bash
git add tests/skill-triggering/prompts/agents-md-*.txt
git commit -m "test(agents-md-management): skill-triggering prompts"
```

---

## Task 8: Unit test (TDD-style: write, fail, fix to green)

**Files:**
- Create: `tests/unit/test-agents-md-skills.sh`

Asserts skill loading, content fidelity, and structural invariants. Follows the pattern of `tests/unit/test-claude-codex-bridge-skill.sh`.

- [ ] **Step 1: Write the test script**

```bash
#!/usr/bin/env bash
# Test: agents-md-improver and agents-md-session-capture skills
# Verifies the skills load, mention both AGENTS.md and CLAUDE.md, include
# realpath dedup, the Platform Adaptation table, and reference docs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../test-helpers.sh"

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)/plugins/agents-md-management"

echo "=== Test: agents-md-management plugin structure ==="
echo ""

# Test 1: Plugin manifest files exist and parse
echo "Test 1: Plugin manifests exist and parse..."
if [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ] \
   && jq empty "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
    echo "  [PASS] .claude-plugin/plugin.json exists and parses"
else
    echo "  [FAIL] .claude-plugin/plugin.json missing or malformed"
    exit 1
fi
if [ -f "$PLUGIN_ROOT/.codex-plugin/plugin.json" ] \
   && jq empty "$PLUGIN_ROOT/.codex-plugin/plugin.json" 2>/dev/null; then
    echo "  [PASS] .codex-plugin/plugin.json exists and parses"
else
    echo "  [FAIL] .codex-plugin/plugin.json missing or malformed"
    exit 1
fi
echo ""

# Test 2: Both skills' SKILL.md files exist
echo "Test 2: Skill files exist..."
for skill in agents-md-improver agents-md-session-capture; do
    if [ -f "$PLUGIN_ROOT/skills/$skill/SKILL.md" ]; then
        echo "  [PASS] skills/$skill/SKILL.md exists"
    else
        echo "  [FAIL] skills/$skill/SKILL.md missing"
        exit 1
    fi
done
echo ""

# Test 3: Reference docs exist and are non-empty
echo "Test 3: Reference docs exist..."
for ref in quality-criteria.md templates.md update-guidelines.md; do
    f="$PLUGIN_ROOT/skills/agents-md-improver/references/$ref"
    if [ -s "$f" ]; then
        echo "  [PASS] references/$ref exists"
    else
        echo "  [FAIL] references/$ref missing or empty"
        exit 1
    fi
done
echo ""

# Test 4: Both skill bodies mention AGENTS.md and CLAUDE.md
echo "Test 4: Both skill bodies mention AGENTS.md and CLAUDE.md..."
for skill in agents-md-improver agents-md-session-capture; do
    body="$(cat "$PLUGIN_ROOT/skills/$skill/SKILL.md")"
    if echo "$body" | grep -q 'AGENTS\.md' && echo "$body" | grep -q 'CLAUDE\.md'; then
        echo "  [PASS] $skill mentions both"
    else
        echo "  [FAIL] $skill missing one of AGENTS.md / CLAUDE.md"
        exit 1
    fi
done
echo ""

# Test 5: Both skill bodies mention realpath (dedup hint, embedded in shared discovery snippet)
echo "Test 5: Both skill bodies mention realpath..."
for skill in agents-md-improver agents-md-session-capture; do
    if grep -q 'realpath' "$PLUGIN_ROOT/skills/$skill/SKILL.md"; then
        echo "  [PASS] $skill mentions realpath"
    else
        echo "  [FAIL] $skill missing realpath dedup snippet"
        exit 1
    fi
done
echo ""

# Test 6: Both skill bodies include Platform Adaptation table
echo "Test 6: Both skill bodies have Platform Adaptation table..."
for skill in agents-md-improver agents-md-session-capture; do
    body="$(cat "$PLUGIN_ROOT/skills/$skill/SKILL.md")"
    if echo "$body" | grep -q '## Platform Adaptation' \
       && echo "$body" | grep -q 'Claude Code' \
       && echo "$body" | grep -q 'Codex'; then
        echo "  [PASS] $skill has Platform Adaptation table"
    else
        echo "  [FAIL] $skill missing Platform Adaptation table"
        exit 1
    fi
done
echo ""

# Test 7: agents-md-improver SKILL.md references the three reference docs by name
echo "Test 7: agents-md-improver references all three docs..."
body="$(cat "$PLUGIN_ROOT/skills/agents-md-improver/SKILL.md")"
for ref in quality-criteria.md templates.md update-guidelines.md; do
    if echo "$body" | grep -q "references/$ref"; then
        echo "  [PASS] references $ref"
    else
        echo "  [FAIL] missing reference to $ref"
        exit 1
    fi
done
echo ""

# Test 8: User-global memory files mentioned in both skill bodies
echo "Test 8: User-global files mentioned in both skill bodies..."
for skill in agents-md-improver agents-md-session-capture; do
    body="$(cat "$PLUGIN_ROOT/skills/$skill/SKILL.md")"
    if echo "$body" | grep -q '~/.claude/CLAUDE.md' \
       && echo "$body" | grep -q '~/.codex/AGENTS.md'; then
        echo "  [PASS] $skill includes both user-global paths"
    else
        echo "  [FAIL] $skill missing one or both user-global paths"
        exit 1
    fi
done
echo ""

# Test 9: Skill descriptions trigger on the right phrases
echo "Test 9: Description fields mention key trigger phrases..."
improver_body="$(cat "$PLUGIN_ROOT/skills/agents-md-improver/SKILL.md")"
capture_body="$(cat "$PLUGIN_ROOT/skills/agents-md-session-capture/SKILL.md")"

improver_desc=$(echo "$improver_body" | awk '/^description:/{flag=1;sub(/^description:[ ]*/,"")} /^---$/{flag=0} flag')
capture_desc=$(echo "$capture_body" | awk '/^description:/{flag=1;sub(/^description:[ ]*/,"")} /^---$/{flag=0} flag')

if echo "$improver_desc" | grep -qiE 'audit|improve|fix'; then
    echo "  [PASS] improver description mentions audit/improve/fix"
else
    echo "  [FAIL] improver description missing audit/improve/fix"
    exit 1
fi

if echo "$capture_desc" | grep -qiE 'session|learned|capture|revise'; then
    echo "  [PASS] capture description mentions session/learned/capture/revise"
else
    echo "  [FAIL] capture description missing session/learned/capture/revise"
    exit 1
fi

if echo "$capture_desc" | grep -q '/revise-claude-md' \
   && echo "$capture_desc" | grep -q '/revise-agents-md'; then
    echo "  [PASS] capture description mentions both legacy and new slash forms"
else
    echo "  [FAIL] capture description missing one of the slash forms"
    exit 1
fi
echo ""

echo "=== Tests complete ==="
```

- [ ] **Step 2: Make it executable and run it (expect PASS for all 9 tests)**

```bash
chmod +x tests/unit/test-agents-md-skills.sh
bash tests/unit/test-agents-md-skills.sh
```

Expected: every assertion `[PASS]`, final line `=== Tests complete ===`.

- [ ] **Step 3: If any test FAILs, fix the corresponding skill or manifest file (do not edit the test). Re-run until all pass.**

Common failure modes:
- Test 4/8 failure on `agents-md-session-capture`: likely missing `~/.claude/CLAUDE.md` reference in the skill body — re-check Step 3 of that skill.
- Test 5 failure: `realpath` not in one of the SKILL.md files — make sure the discovery snippet is embedded in both, not just linked from one.
- Test 9 failure on `/revise-claude-md`: description missing the legacy form — add to frontmatter `description:`.

- [ ] **Step 4: Commit**

```bash
git add tests/unit/test-agents-md-skills.sh
git commit -m "test(agents-md-management): unit tests for skill structure and content"
```

---

## Task 9: Update root README.md

**Files:**
- Modify: `README.md` (project root)

The root README has a Plugins table and Installation/Setup sections. Add `agents-md-management` to each.

- [ ] **Step 1: Inspect current README plugins section**

```bash
grep -n 'Plugins' README.md | head -5
grep -n '| Plugin' README.md | head -3
```

Expected: locate the markdown table heading. Note the line numbers.

- [ ] **Step 2: Read the table block**

Use the line numbers from Step 1 to locate the existing plugin table. Read it to confirm structure (column count, separator style).

- [ ] **Step 3: Append the new row to the Plugins table**

Use the Edit tool. The exact change depends on the current table contents; the new row must follow the same format. Pattern:

```diff
 | `runtime-bridge` | 0.1.0 | `claude-codex-bridge` |
+| `agents-md-management` | 0.1.0 | `agents-md-improver`, `agents-md-session-capture` |
```

- [ ] **Step 4: Update Installation section**

Find the section that lists `/plugin install <name>@pgoell-claude-tools` lines. Add:

```text
/plugin install agents-md-management@pgoell-claude-tools
```

- [ ] **Step 5: Update Setup section**

If the Setup section has per-plugin notes, add a one-liner like:

```markdown
### agents-md-management

No setup required. Operates on local agent-instruction files only.
```

If the Setup section is structured differently, follow the existing pattern.

- [ ] **Step 6: Verify**

```bash
grep -c 'agents-md-management' README.md
```

Expected: at least 2 hits (table row + install command). 3+ if a Setup blurb was added.

- [ ] **Step 7: Commit**

```bash
git add README.md
git commit -m "docs: add agents-md-management to root README"
```

---

## Task 10: Run the codex-plugin-structure test and final verification

The repo has `tests/unit/test-codex-plugin-structure.sh` which validates that every plugin under `plugins/` has both `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` with the required Codex `interface` block. The new plugin must pass it.

- [ ] **Step 1: Run the structure test**

```bash
bash tests/unit/test-codex-plugin-structure.sh
```

Expected: passes for `agents-md-management` (alongside the other 5 plugins).

- [ ] **Step 2: If it fails, fix the relevant manifest field**

Most common cause: missing `interface.displayName` or `interface.shortDescription` in `.codex-plugin/plugin.json`. Re-check Task 1 Step 3.

- [ ] **Step 3: Run the new unit test**

```bash
bash tests/unit/test-agents-md-skills.sh
```

Expected: all PASS.

- [ ] **Step 4: Verify both marketplaces still parse and contain 6 plugins**

```bash
jq '.plugins | length' .claude-plugin/marketplace.json
jq '.plugins | length' .agents/plugins/marketplace.json
jq '.plugins[].name' .claude-plugin/marketplace.json
jq '.plugins[].name' .agents/plugins/marketplace.json
```

Expected: both report 6, both lists include `agents-md-management`.

- [ ] **Step 5: Verify directory tree matches the spec**

```bash
find plugins/agents-md-management -type f | sort
```

Expected output (no extras, no missing):

```
plugins/agents-md-management/.claude-plugin/plugin.json
plugins/agents-md-management/.codex-plugin/plugin.json
plugins/agents-md-management/LICENSE
plugins/agents-md-management/NOTICE
plugins/agents-md-management/README.md
plugins/agents-md-management/skills/agents-md-improver/SKILL.md
plugins/agents-md-management/skills/agents-md-improver/references/quality-criteria.md
plugins/agents-md-management/skills/agents-md-improver/references/templates.md
plugins/agents-md-management/skills/agents-md-improver/references/update-guidelines.md
plugins/agents-md-management/skills/agents-md-session-capture/SKILL.md
```

- [ ] **Step 6: Skill-triggering smoke test (optional, requires `claude` CLI)**

For each prompt file, verify the right skill triggers. This is slow (~60s per call) and requires Claude API access; skip if unavailable. The runner outputs PASS/FAIL.

```bash
PLUGIN_DIR=plugins/agents-md-management bash tests/skill-triggering/run-test.sh agents-md-improver tests/skill-triggering/prompts/agents-md-audit.txt
PLUGIN_DIR=plugins/agents-md-management bash tests/skill-triggering/run-test.sh agents-md-improver tests/skill-triggering/prompts/agents-md-audit-agents.txt
PLUGIN_DIR=plugins/agents-md-management bash tests/skill-triggering/run-test.sh agents-md-improver tests/skill-triggering/prompts/agents-md-global-audit.txt
PLUGIN_DIR=plugins/agents-md-management bash tests/skill-triggering/run-test.sh agents-md-session-capture tests/skill-triggering/prompts/agents-md-session-capture.txt
PLUGIN_DIR=plugins/agents-md-management bash tests/skill-triggering/run-test.sh agents-md-session-capture tests/skill-triggering/prompts/agents-md-session-capture-cmd.txt
```

Expected: each prints `[PASS] Skill 'X' was triggered`.

If any prompt does NOT trigger the expected skill, the description field needs sharpening. Edit the relevant SKILL.md frontmatter `description:` and re-run. Re-run the unit test (Task 8) to ensure it still passes.

- [ ] **Step 7: Final state check — no outstanding changes, clean working tree**

```bash
git status
git log --oneline | head -10
```

Expected: clean tree (everything committed across Tasks 1–9), recent commits show the agents-md-management feature progression.

---

## Self-Review Notes

Performed inline before saving the plan; no issues found:

- **Spec coverage:** Every section of the spec is mapped to a task. §1 (Purpose) → Tasks 3, 4 (skill content). §2 (Scope, in + out) → Tasks 3, 4 (discovery section). §3 (Architecture) → Tasks 1, 2, 3, 4 (file creation). §4 (Discovery) → embedded in Tasks 3, 4 SKILL.md. §5 (Improver workflow) → Task 3. §6 (Session-capture workflow) → Task 4. §7 (Platform Adaptation) → Tasks 3, 4 (table). §8 (Marketplace registration) → Tasks 5, 6. §9 (Versioning, attribution, license) → Task 1 (manifests, NOTICE, LICENSE, README credit). §10 (Tests) → Tasks 7, 8, 10.
- **Placeholder scan:** no TBD/TODO/"add appropriate handling"/"similar to". Every code block contains real content.
- **Type consistency:** plugin name `agents-md-management`, skill names `agents-md-improver` and `agents-md-session-capture` are used consistently. Discovery glob is byte-identical between Tasks 3 and 4 (and the spec). Test assertion targets align with the strings the SKILL.md files actually contain.
