---
name: writing-plans
description: "Use when a design spec or approved requirements need to become a concrete, step-by-step implementation plan before code changes."
---

# Writing Plans

Write implementation plans that a fresh agent can execute slice by slice without guessing.

## Overview

Use this after `workbench:writing-spec` (large lane) or after the user provides approved requirements. For the medium lane, this skill also carries the design work itself instead of a separate spec; see `## Design preamble (medium lane)` below. The output is a concrete plan with exact file paths, slice-ordered checkbox steps, test commands, and acceptance criteria.

Assume the implementer is a capable engineer with little project context. Give them enough detail to work correctly, but keep the plan focused on the requested change. Plans work at program-design altitude: exact signatures, call-stack sketches, and acceptance criteria, not full test or implementation code (the `tricky-kernel` flag is the one exception; see `## Slice Structure`). DRY, YAGNI, TDD, and frequent commits are the default.

## Path Resolution

Resolve the output format first (see `## Output Format`). Then resolve the plan folder `<paths.plans>` by the one order in `../pilot/references/config-schema.md` `## Resolution order`, and write `<paths.plans>/YYYY-MM-DD-<topic>.<ext>`, where `<ext>` is `md` or `html` per the format. If `<paths.plans>` is `don't commit`, write that file name under `/tmp/<project-name>-pilot/` and skip committing it, as that section says.

For html, write the skeleton of `references/plan-template.html` into the `.html` file and replace all its sample content; for md, write markdown. In html, each part of the plan has a slot in the template:

- `## Plan Document Header`: the title in `<title>` and in the `<h1>` of `header.page-head`, the "For agentic workers" line as a `<p>` right after that `<h1>` (write the checkbox markup escaped, `&lt;span class="checkbox"&gt;`), and Goal, Architecture and Tech Stack in `#summary`. In `header .meta`, Date is the plan's date, Owner the user (delete that span when unknown), and the pill is `status-draft` "Draft".
- The `## File Structure` file map goes in `#file-structure`.
- Medium lane: the `## Design` preamble goes in `<section id="design">`, right after `#summary`, as its `<dl>` entries Problem, Chosen approach, Key decisions and Out of scope. Remove the "Source spec" link from `header .meta`; there is no spec.
- Large lane: delete `<section id="design">`. The `Spec: <path>` line becomes the "Source spec" link in `header .meta`, its `href` the spec's path relative to the plan's folder: `../specs/<file>` for sibling folders, `./<file>` when both sit in one folder (as under `don't commit`).
- Slices: each slice is one `<article class="task">` in `#tasks`, its `.num` label "Slice 01" (two digits). A task that is not itself a slice keeps its place in that numbering and adds `p.order-note`. Its parts go in this order:
  - Files: one row per path in `.files`, labeled Create, Modify or Test.
  - Types and signatures: a `<pre>` in `.signatures`.
  - Call-stack sketch: `.diff-block` lines in `.call-stack`. Omit it or the signatures as `## Slice Structure` says.
  - Steps: each step is one `<li>` in `<ol class="steps">`, starting with `<span class="checkbox" aria-hidden="true"></span>` and then the step text (such as the failing test's name and its assertion) in `<p>`s in `<div class="step-body">`, without a "Step N:" label (the template's CSS numbers the steps). This is the html form of `- [ ]`.
  - Run and Expected: `code.test-cmd` and `.expected` inside the step. The commit step has one `code.test-cmd` per command: `git add ...`, then `git commit -m ...`.
  - Acceptance criteria: `.acceptance`, after the steps.
  - The `tricky-kernel` flag: `<span class="tricky-kernel">tricky-kernel</span>` in the step, then the one-line reason, then the complete code in a `<pre>` in that `.step-body`.
  - The ordering note of a task that is not itself a slice: `<p class="order-note">`, after the header.
- `#testing` and `#commit-points` have no md counterpart. Fill them from the slices' test commands and commit messages; delete one only when nothing would go in it.
- Delete the template's HTML comments, and start every checkbox without `done`.

## Scope Check

Before writing tasks, check whether the spec covers multiple independent subsystems. If it does, stop and split it into separate plans, one per independently testable change.

Each plan should produce working, testable software on its own.

## File Structure

Before defining slices, map which files will be created or modified and what each file is responsible for.

- Use exact paths.
- Follow existing project patterns.
- Keep files focused on one responsibility.
- Keep related changes together.
- Include a split only when it is directly needed for this work.

This file map governs the slice decomposition.

## Bite-Sized Step Granularity

Each checkbox step within a slice is one small action:

- Write the failing test: name it and its exact assertion in prose. Do not write the test body.
- Run the test and confirm the expected failure.
- Implement the smallest passing change against the slice's signatures. Embed code only under a `tricky-kernel` flag (see `## Slice Structure`).
- Run the test and confirm it passes.
- Commit the logical chunk.

Avoid broad steps that require the implementer to invent missing details. Precision comes from exact commands, exact signatures, and exact acceptance criteria, not from pre-written code.

## Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `workbench:test-driven-development` for implementation chunks. Use `workbench:subagent-driven-development` for delegated plan execution, including safe parallel fan-out across independent slices, or execute sequentially in the main session when subagents are unavailable. Steps use checkbox (`- [ ]` in md, `<span class="checkbox">` in html) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about the approach]

**Tech Stack:** [Key technologies, libraries, and commands]

---
```

## Design preamble (medium lane)

When invoked for the medium lane, open the plan with a `## Design` section immediately after the header, before the first slice (in html, `<section id="design">`; see `## Path Resolution`). It replaces the separate spec: pilot's `design` gate applies to this combined document (or, when invoked outside pilot, present the combined document for the user's direct approval); there is no separate approval round.

Cover:

- **Problem:** what is broken or missing, one paragraph.
- **Chosen approach:** the approach taken and the one or two alternatives ruled out, one line each on why.
- **Key decisions:** the load-bearing choices a reviewer needs before reading the slices (data shape, module boundaries, a third-party dependency, a migration strategy).
- **Out of scope:** exclusions, each with the one-line reason that forces it out, matching `workbench:writing-spec`'s convention.

Keep it to the length the decisions warrant. This is not the exhaustive spec: it carries only what a slice-by-slice reader needs before the file map and signatures start doing the rest of the explaining.

In the large lane, skip this section. The plan instead opens with a one-line link to the approved spec: `Spec: <path>` (in html, the "Source spec" link in `header .meta`).

## Slice Structure

Order slices as vertical, end-to-end increments. The first slice is the tracer bullet: the thinnest path through the system that is demoable end to end. Each later slice adds one coherent capability and leaves the software demoable again. If a task is not itself a slice (a pure refactor precursor, a shared scaffold), state in one line why it is ordered where it is and which slice it unblocks.

Use this shape for each slice:

````markdown
### Slice N: [end-to-end behavior]

**Files:**

- Create: `exact/path/to/new-file.ext`
- Modify: `exact/path/to/existing-file.ext`
- Test: `tests/exact/path/to/test-file.ext`

**Types and signatures:**

```language
functionName(param: Type, other: Type2): ReturnType
ClassName.method(arg: Type): ReturnType
```

**Call-stack sketch** (include only when control flow changes):

```diff
 caller()
-  oldCallee()
+  newCallee()
+    newHelper()
```

- [ ] **Step 1: Write the failing test** for `<behavior>`. Name the exact assertion in prose.
- [ ] **Step 2: Run the test to verify it fails**

Run: `exact test command`
Expected: FAIL with the missing behavior or assertion named explicitly.

- [ ] **Step 3: Implement** `<functionName>` per the signatures above.
- [ ] **Step 4: Run the test to verify it passes**

Run: `exact test command`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add exact/path/to/test-file.ext exact/path/to/existing-file.ext
git commit -m "type(scope): describe the change"
```

**Acceptance criteria:** [the observable behavior the outer-loop test must prove for this slice to count as done]
````

Omit "Types and signatures" or "Call-stack sketch" when a slice introduces no new functions or no control-flow change. Never omit Files, test commands, or acceptance criteria.

The `tricky-kernel` flag is the only place a slice may embed complete code: mark the step `**tricky-kernel:** <one-line reason>` and reserve it for algorithms where the code shape itself is the design decision (a recursive-descent parser, a bit-packing routine, a concurrency primitive). Everywhere else, the signature and the acceptance criteria are the spec; the implementer writes the body during TDD's GREEN phase.

## No Placeholders

Never write plan steps that leave work to interpretation:

- `TBD`, `TODO`, `implement later`, or `fill in details`.
- Generic instructions such as "add appropriate error handling" or "handle edge cases".
- "Write tests for the above" without a concrete assertion and an exact test command.
- "Similar to Slice N". Repeat the relevant details because slices may be read independently.
- Steps that omit the command, expected output, or file path.
- References to types, functions, files, or methods not introduced by the plan or already present in the codebase.

Signatures without bodies are the expected altitude, not a placeholder: a step that gives an exact function signature, its file path, and its acceptance criteria is complete at this altitude even though it contains no implementation code. A placeholder is missing information; a signature is a design decision already made.

## Plan Review

After writing the plan, dispatch a fresh-eyes reviewer subagent before presenting it. The reviewer should not receive the conversation history. Give it only the plan path, the source spec or requirements path when available, and the prompt template in `plan-reviewer-prompt.md`.

Claude Code: `Agent` tool, `general-purpose` subagent_type, no model override.
Codex: equivalent general-purpose subagent.
Cursor: `Task` tool.

The reviewer checks:

1. Spec-or-preamble coverage: each requirement in the source spec, or each decision in the plan's own `## Design` preamble, maps to at least one slice.
2. Placeholder scan: the plan contains none of the forbidden placeholder patterns.
3. Name consistency: later slices use the same file names, function names, types, and command names introduced earlier.
4. Testability: every slice has an exact test command and acceptance criteria naming the behavior the outer-loop test must prove.
5. Slice ordering: the first slice is a tracer bullet, and each slice leaves the software demoable.
6. Altitude: no full test or implementation code outside a `tricky-kernel` flag.

Apply the reviewer's blocking findings inline. No re-review is required. Advisory recommendations do not block handoff unless they expose a real implementation risk.

## Execution Handoff

After saving the plan, report the path and offer the execution route that fits the runtime:

```text
Plan complete and saved to `<path>`.

Recommended execution: use `workbench:test-driven-development` for each implementation chunk. If subagents are available, use `workbench:subagent-driven-development` slice by slice, including its parallel-dispatch guidance for independent slices with disjoint write scopes; otherwise execute the checkbox steps sequentially in this session.
```

Do not start implementation until the plan is saved, the reviewer pass is complete, and the required implementation discipline is clear.

## Output Format

Default for this artifact: **md**.

Override resolution order, highest precedence first:

1. Per-invocation override in the user prompt. Recognize phrases like `"an HTML plan"`, `"in markdown"`, `"as a markdown plan"`, `"give me HTML"`, and equivalents.
2. `.workbench/config.md` `## Output formats` entry for `Plans:`. Schema documented in `plugins/workbench/skills/pilot/references/config-schema.md`.
3. Per-skill hard-coded default (md).

The plan path resolves as `## Path Resolution` says; only the file name's extension comes from the format.

When emitting HTML, follow the structural skeleton in `references/plan-template.html` in this skill's directory. Read the template lazily, only when actually producing the artifact. Do not introduce U+2014 or U+2013 codepoints in body copy; HTML entity forms (`&mdash;`, `&#8212;`, `&ndash;`, `&#8211;`) are permitted.

For other HTML artifact types not covered by a workbench or research skill, see `workbench:crafting-html`.

### Applying a design system

Before emitting HTML, check whether a design system is set: a per-prompt override (e.g., "render with the `brand-2026` design system"), else `.workbench/config.md` `## Design system` `Name:`. If one is set, read `../crafting-design-systems/references/applying-a-design-system.md` and follow it. If none is set, emit with the template's defaults.

To create or edit a design system, see `workbench:crafting-design-systems`.
