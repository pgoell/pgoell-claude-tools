# Workbench Config Schema

Defines `.workbench/config.md` for projects that want to override per-artifact format defaults and output paths in the workbench skills `writing-spec`, `writing-plans`, `brainstorming`, and `systematic-debugging`.

`research:running-research` does not consult this file. It uses its approved brief, else its own hard-coded default (HTML, `reports/<topic-slug>-<YYYY-MM-DD>/report.html`).

## Discovery (v1)

The four workbench skills look for `.workbench/config.md` in the repo root. Missing file means defaults apply. Empty file is valid.

## Markdown-first stance (no parser)

Headings are conventions, not contracts. Both Claude Code and Codex consume the file as prompt context; there is no parser. Skills extract values section by section. YAML support is deferred until a concrete parser-consuming use case exists, paralleling the pilot profile schema's stance.

## Schema

```md
# Workbench Config

## Output formats

Specs: <md | html>
Plans: <md | html>
Brainstorm summaries: <md | html>
Debug reports: <md | html>

## Output paths

Specs: <directory path>
Plans: <directory path>
Brainstorm summaries: <directory path>
Debug reports: <directory path>

## Design system

Name: <design-system-name>
```

All sections optional. All fields within a section optional.

## Defaults when a section or field is absent

| Field                | Default format | Default folder             | File name                             |
| -------------------- | -------------- | -------------------------- | ------------------------------------- |
| Specs                | md             | `.workbench/specs`         | `YYYY-MM-DD-<topic>-design.<ext>`     |
| Plans                | md             | `.workbench/plans`         | `YYYY-MM-DD-<topic>.<ext>`            |
| Brainstorm summaries | html           | `.workbench/brainstorms`   | `YYYY-MM-DD-<topic>-brainstorm.<ext>` |
| Debug reports        | html           | `.workbench/debug-reports` | `YYYY-MM-DD-<topic>-debug.<ext>`      |

The file name is the same whichever folder wins; `<ext>` is `md` or `html` per the resolved format.

## Design system resolution

`Name:` resolves the active design system applied to HTML artifacts. The host agent locates the named directory in this order:

1. Project: `.workbench/design-systems/<name>/`
2. User: `~/.claude/workbench/design-systems/<name>/`

Per-prompt overrides take precedence over this file. Absence of the section means: use the template defaults (no overrides inlined). When the named directory is not found at either scope, the host agent reports the missing path and falls through to "no overrides".

The full design-system contract (directory structure, per-template variable surface, component contract, image inlining recipe) is documented in `deprecated:crafting-design-systems`. Producers apply the design system by following `../../crafting-design-systems/references/applying-a-design-system.md`.

## Resolution order

For each artifact, format and path resolve independently.

**Format resolution** (highest precedence first):

1. Per-invocation override in the user's prompt. Phrases like `"an HTML <artifact>"`, `"in markdown"`, `"as a markdown <artifact>"`, `"give me HTML"`, and equivalents are recognized.
2. `.workbench/config.md` `## Output formats` entry for the artifact.
3. Per-skill hard-coded default (table above).

**Path resolution** gives a folder. The skill appends the artifact's file name from the table above to it.

For specs and plans, highest precedence first (the first rung that gives a folder wins, in and outside pilot):

1. `.workbench/pilot.md` `## Documentation paths` `Specs:` or `Plans:`.
2. `.workbench/config.md` `## Output paths` `Specs:` or `Plans:`.
3. A spec or plan folder named by the project's `CLAUDE.md` or `AGENTS.md`.
4. `docs/superpowers/specs/` or `docs/superpowers/plans/`, if that folder exists.
5. `.workbench/specs/` or `.workbench/plans/` (default).

Explicit workbench config beats a prose convention, so both workbench files come before `CLAUDE.md` and `AGENTS.md`.

For brainstorm summaries and debug reports: the `.workbench/config.md` `## Output paths` entry, else the default folder in the table above.

If the resolved folder is `don't commit` (a `pilot.md` value only), write the same file name under `/tmp/<project-name>-pilot/` and do not commit it. `<project-name>` is `pilot.md` `## Project name`, else the repo folder name.

Format and path resolve separately, and meet in one place: the file name's extension comes from the resolved format. With `Specs: html` in `config.md` and `Specs: docs/architecture/` in `pilot.md`, the spec goes to `docs/architecture/YYYY-MM-DD-<topic>-design.html`.

## Relationship to `.workbench/pilot.md`

`.workbench/pilot.md` is pilot-specific (PR behavior, gates, hooks, required-skills overrides, plus existing path convention). `.workbench/config.md` is shared workbench config that applies whenever a workbench skill runs, including outside pilot. The two files coexist; neither replaces the other.
