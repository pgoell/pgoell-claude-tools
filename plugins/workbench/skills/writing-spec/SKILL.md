---
name: writing-spec
description: "Use when a design discussion is ready to be written into a spec document, before any implementation planning. Synthesizes the conversation into a spec, runs a fresh-eyes self-review subagent, and gates on user approval before handing off to writing-plans."
---

# Writing a Design Spec

Take a design discussion and synthesize it into a written spec document. Run a fresh-eyes self-review, fix issues inline, gate on user approval, then recommend `workbench:writing-plans` as the next step.

## When to Invoke

After a design discussion (typically a `workbench:brainstorming` session) where the user has approved the design verbally or in scratch notes. The discussion must be far enough along that the spec is a synthesis, not another round of questions.

If the user is still asking questions or exploring approaches, return them to `workbench:brainstorming` first.

## Steps

You MUST create a task for each of these items and complete them in order:

1. **Resolve the output format and the spec path** (see `## Output Format` and `## Path Resolution`).
2. **Draft the spec document** at the resolved path. For html, write the skeleton of `references/spec-template.html` into the `.html` file and replace all its sample content; for md, write markdown.
3. **Dispatch the self-review subagent** with the prompt template in `spec-document-reviewer-prompt.md`.
4. **Apply the reviewer's findings inline.** No re-review.
5. **Present to the user for approval.**
6. **Commit the spec** if the path is committable.
7. **Recommend `workbench:writing-plans`** as the next skill.

## Path Resolution

`<paths.specs>` resolves in order:

1. `.workbench/pilot.md` `Specs:` heading.
2. Project `CLAUDE.md` or `AGENTS.md` spec-path convention.
3. `.workbench/specs/` (default).

Resolve the format first. If `<paths.specs>` is `don't commit`, write the spec to `/tmp/<project-name>-pilot/YYYY-MM-DD-<topic>-design.<ext>` and skip the commit step. Otherwise write to `<paths.specs>/YYYY-MM-DD-<topic>-design.<ext>`, where `<ext>` is `html` or `md` per the format resolved in `## Output Format`.

## Drafting

Cover, scaling each section to its complexity:

- Problem.
- Solution overview.
- User stories (numbered).
- Implementation decisions (modules, interfaces, file layout, no code snippets).
- Reference artifacts, only if the discussion anchored on any: path or URL of each (existing code, mockup, similar system), plus one line each on what to imitate and what to diverge from.
- Testing decisions.
- Out of scope. Give every exclusion a one-line reason naming what forces it out: a conflicting requirement, an external dependency, or a boundary into a separate spec. If the only reason is implementation effort, write "cut for effort" explicitly so the user can pull the item back in at the approval gate instead of assuming it was impossible.
- Risks.

Use `elements-of-style:writing-clearly-and-concisely` if available.

## Self-Review (Fresh-Eyes Subagent)

Dispatch a general-purpose subagent that has not seen the brainstorming conversation. The subagent reads the spec file and reports against four checks. You apply the findings; no re-review.

Claude Code: `Agent` tool, `general-purpose` subagent_type, no model override.
Codex: equivalent general-purpose subagent.
Cursor: `Task` tool.

The full reviewer prompt template lives in `spec-document-reviewer-prompt.md` in this skill's directory; paste it into the dispatch with `[SPEC_FILE_PATH]` replaced.

The four checks:

1. Placeholder scan: any "TBD", "TODO", incomplete sections, or vague requirements?
2. Internal consistency: do any sections contradict each other?
3. Scope check: is this focused enough for a single implementation plan?
4. Ambiguity check: could any requirement be interpreted two different ways?

After the report comes back, fix any issues inline in the spec document.

## User Approval Gate

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for the user's response. If they request changes, make them and re-run the self-review subagent. Only proceed to the next step once the user approves.

## Handoff

The terminal action of this skill is recommending `workbench:writing-plans`. Do not invoke any implementation skill yourself. The spec is the artifact; the plan comes next.

## Reference

`spec-document-reviewer-prompt.md`: full reviewer subagent prompt template.

## Output Format

Default for this artifact: **md**.

Override resolution order, highest precedence first:

1. Per-invocation override in the user prompt. Recognize phrases like `"an HTML spec"`, `"in markdown"`, `"as a markdown spec"`, `"give me HTML"`, and equivalents.
2. `.workbench/config.md` `## Output formats` entry for `Specs:`. Schema documented in `plugins/workbench/skills/pilot/references/config-schema.md`.
3. Per-skill hard-coded default (md).

Path resolution order: `.workbench/pilot.md` `## Documentation paths` `Specs:` first; then `.workbench/config.md` `## Output paths` `Specs:`; then `.workbench/specs/` default. Path and format resolve independently; the file name takes its extension from the format, as `## Path Resolution` says.

When emitting HTML, follow the structural skeleton in `references/spec-template.html` in this skill's directory. Read the template lazily, only when actually producing the artifact. Do not introduce U+2014 or U+2013 codepoints in body copy; HTML entity forms (`&mdash;`, `&#8212;`, `&ndash;`, `&#8211;`) are permitted.

For other HTML artifact types not covered by a workbench or research skill, see `workbench:crafting-html`.

### Applying a design system

Before emitting HTML, check whether a design system is set: a per-prompt override (e.g., "render with the `brand-2026` design system"), else `.workbench/config.md` `## Design system` `Name:`. If one is set, read `../crafting-design-systems/references/applying-a-design-system.md` and follow it. If none is set, emit with the template's defaults.

To create or edit a design system, see `workbench:crafting-design-systems`.
