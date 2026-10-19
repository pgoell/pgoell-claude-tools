# Skill Writing Guide

Read this when you set a frontmatter field beyond name and description, lay out a new skill's folder and files, decide what goes in SKILL.md and what goes behind a pointer, or write and review the body.

## Optional frontmatter fields

These sit beside **name** and **description** in "Write the SKILL.md" in SKILL.md:

- **disable-model-invocation** (optional): `true` lets only the user, typing its name, start the skill. The description then stops loading into the agent's context on every turn and becomes a human-facing one-line summary. It also blocks invocation through the Skill tool, subagent preloading, and scheduled-task use, so no other skill and no successor session can load it. Leave it unset unless the user asks for it; in pgoell-claude-tools no skill sets it.
- **user-invocable** (optional): Set to `false` to hide a skill from the `/` menu while leaving Claude able to load it. For background knowledge that is not actionable as a command (mechanics in `references/platform-mechanics.md`).
- **compatibility** / **dependencies**: Environment requirements (optional, rarely needed). The agentskills.io spec field is `compatibility` (advisory); claude.ai documents `dependencies` (e.g. `python>=3.8`).
- Claude Code supports further fields: `allowed-tools` (an agentskills.io spec field, experimental, support varies by platform) plus its own extensions `disallowed-tools`, `context: fork` with `agent`, `model`, `effort`, `hooks`, `paths`, and argument declarations. See `references/platform-mechanics.md` for the full reference; the extensions are not portable to other Agent Skills platforms.

## Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name + description; required for claude.ai upload, optional in Claude Code)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

## Progressive Disclosure

Skills use a three-level loading system:

1. **Metadata** (name + description) - In context every turn for model-invoked skills (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)

These word counts are approximate and you can feel free to go longer if needed.

**Key patterns:**

- Keep SKILL.md under 500 lines; if you're approaching this limit, split content into more sibling reference files, linked directly from SKILL.md with clear pointers about where the model using the skill should go next to follow up.
- Reference files clearly from SKILL.md with guidance on when to read them
- Keep references one level deep: link every reference file directly from SKILL.md. Agents preview nested files with partial reads (`head -100`), so material two hops away gets truncated or missed.
- For large reference files (>300 lines), include a table of contents
- To decide what goes behind a pointer, how to word the pointer, and what to keep together, read "Information hierarchy" in `references/writing-great-skills.md` (the branching test, pointer wording, co-location).

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:

```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

Claude reads only the relevant reference file.

## Principle of Lack of Surprise

This goes without saying, but skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user in their intent if described. Don't go along with requests to create misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activities. Things like a "roleplay as an XYZ" are OK though.

The same principle covers accidental hazards. Never hardcode secrets (API keys, tokens, passwords) into a skill or its scripts: a packaged skill is a shared artifact, and an embedded key travels with every copy. Route external service access through MCP connections rather than embedded credentials. And when asked to improve a skill someone else authored, read it fully before running anything in it.

## Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats** - You can do it like this:

```markdown
## Report structure

ALWAYS use this exact template:

# [Title]

## Executive summary

## Key findings

## Recommendations
```

**Examples pattern** - It's useful to include examples. You can format them like this (but if "Input" and "Output" are in the examples you might want to deviate a little):

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

**Arguments** - Skills accept arguments at invocation (`/fix-issue 123`), available in the body as `$ARGUMENTS` (or positionally as `$0`, `$1`, ...), with `argument-hint` documenting the expected shape. Use them to parameterize task skills instead of making the agent fish the parameter out of conversation. The full substitution table (named arguments, session variables) is in `references/platform-mechanics.md`.

**Dynamic context injection** (Claude Code only) - A `` !`command` `` line in the body runs at render time and is replaced by its output before Claude sees the skill, so live state (a git diff, PR data, environment info) arrives already inlined at zero agent turns. A policy setting can disable execution, so the skill should still read sensibly without the output. Mechanics and caveats in `references/platform-mechanics.md`.

**Wrapping CLIs and APIs**: for a skill that drives an external service, teach it to attempt the operation first and diagnose auth only on failure; upfront auth checks add a round trip to every run and still miss expired credentials. Never echo or log credential values, check presence with `test -n "$VAR"` only. Confirm with the user before destructive operations. And don't bundle wrapper scripts around a CLI the user already has: the agent can call the CLI directly, and a wrapper is a layer that drifts out of date. Bundled scripts earn their place for repeated multi-step work (see "Look for repeated work across test cases" in `references/improving-skills.md`), not for renaming existing commands.

**Feedback loops**: a pattern that greatly improves output quality is run validator, fix, repeat until clean. The validator can be a script or a checklist document the agent compares its output against, and failure should loop back explicitly ("if verification fails, return to step 2"). For multi-step workflows, embed a literal checklist the agent copies into its response and ticks off, so skipped steps become visible.

## Writing Style

Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs. Use theory of mind and try to make the skill general and not super-narrow to specific examples. Start by writing a draft and then look at it with fresh eyes and improve it.

Before you draft the body, and again when you review it, read `references/writing-great-skills.md` (adapted from Matt Pocock's writing-great-skills). Its sections "Leading words", "Completion criteria and legwork", "Pruning" (the no-op test) and "Failure modes" (negation, so prompt the positive) set how each sentence should steer.

Calibrate specificity to fragility: prose heuristics where many approaches work, a parameterized template where one pattern is preferred, an exact do-not-modify command where the operation breaks under variation. Pick one term per concept and use it throughout; mixing synonyms (URL, route, path) makes instructions harder to follow.

Match the form of a fix to the failure you observed (adapted from Jesse Vincent's writing-skills): classify the baseline failure before writing, because the form that bulletproofs one failure type backfires on another. An agent that knows a rule but skips it under pressure needs prohibition, a rationalization table, and red flags; an agent whose output has the wrong shape needs a positive recipe stating what the output is. `references/bulletproofing.md` has the full form-to-failure matrix, the head-to-head evidence, and the rules that hold for any form.
