---
type: Explanation
title: Repository conventions
description: The reasons behind the dash lint, the frontmatter rule, the skill invocation syntax, lazy auth, self-contained skills, and the rule on shipped code.
tags: [conventions, lint, frontmatter, auth, shipped-code, contributors]
status: stable
---

# Repository conventions

These rules cover every skill and doc in the repository. [AGENTS.md](../../AGENTS.md) states each one in a few lines ("Skills may ship code" sits in [Developing a skill](/reference/conventions/developing-a-skill.md)); this page keeps the reasons and the history.

## Skills may ship code; wrappers around an existing CLI stay banned

Through 2026-09 this rule banned all shipped code; it now bans only the wrapper. A skill that drives a service still calls its CLI directly (`gws` for Google Workspace) or raw `curl` with env-var auth (for Atlassian), because a bash layer that renames existing commands drifts out of date and adds nothing.

A skill may ship code when the code does work the agent cannot do reliably from prose: layout, geometry validation, rendering, deterministic checks. The `diagrams` plugin was the first: `skills/creating-diagrams/engine/` vendors the archify Node engine, which lays out, validates, and renders diagrams. `presentations:editing-presentations` is another: `assets/server.py` (Python standard library) serves a deck with source offsets on every slide element and patches the file at those offsets through `assets/deck_source.py`, and `assets/overlay.js` is the editor it injects into the served page, with `assets/overlay-edit.js` (the edit tools) and `assets/overlay-gates.js` (the hard-gate check).

Shipped code must:

1. run on a runtime the host already has (Node 18+, Python through `uv`) with no install step, so dependencies are either absent or committed;
2. make no network requests at runtime except for an action the user asks for, so ports drop update notifiers and telemetry;
3. be driven from `SKILL.md` with exact commands and a stated fallback for a host without the runtime;
4. follow every repo convention that applies to text: the dash lint (inside string literals, write a backslash-u escape of U+2014 or U+2013 instead of the character, so runtime output stays the same), port attribution in `NOTICE`, and the version-bump lockstep.

There is no automated test suite, so a port runs the upstream's own tests against the changed copy at port time and records the result in `NOTICE`.

Runtime codegen stays valid beside shipped code. `presentations:exporting-presentations-to-pptx` has the agent write a fresh python-pptx generator per deck (and forbids templating slide content off an earlier conversion), and ships only a recipe file (`references/python-pptx-recipes.md`). Prefer that shape when the code must differ per run.

A third shape is the script template. `issue-loop:running-the-loop` ships `assets/*.sh` that `scripts/init.sh` copies into a loop folder in the user's own space, where the user edits them. Its `driver-herdr.sh` is not a banned wrapper: the five `drv_*` functions are the seam through which another terminal manager is swapped in, and `next.sh`, `wait.sh` and `gate.sh` do work prose cannot do reliably (a wait with a clock, a match on an exact token, a pass or fail over several `gh` calls). Shipped scripts that can run without a live service get a test beside them (`plugins/issue-loop/tests/run.sh`, stub driver, no network), and the plugin README records the last result.

## Skills are self-contained

Each SKILL.md holds everything the host agent needs to use the service without reading other files, except reference docs it links to. An agent that loads a skill should be able to act on one read.

## Skill invocation syntax in docs is `/<plugin>:<skill>`, not `/<marketplace>:<skill>`

Claude Code resolves skill calls by `plugin:skill` (for example `/atlassian:jira`, `/workbench:pilot`), not by marketplace name. The marketplace name `pgoell-claude-tools` appears only as the `@pgoell-claude-tools` suffix in `/plugin install <plugin>@<marketplace>` lines and in `codex plugin marketplace add pgoell/pgoell-claude-tools`; it cannot prefix a skill call.

The fully qualified form always works, whatever other marketplaces the user has installed. The short form `/<skill>` (such as `/jira`) works only when no other installed skill shares the name, which a doc cannot know, so docs never teach it. The 2026-05 README rewrite fixed 33 wrong `/pgoell-claude-tools:<skill>` examples that had piled up through copy and paste.

The audit greps: `grep -rnE '/pgoell-claude-tools:[a-z]' README.md docs/` must print nothing, and `grep -rnE '/(atlassian|google-workspace|research|writing|runtime-bridge|agent-system-management|workbench|terminal|playground|databricks|learning|critique|presentations|diagrams|news|insights|file-size|issue-loop|ponytail|emil|vercel|taste-skill|deprecated):' docs/` should match at least once per plugin whose skills the doc names.

## Em-dash lint and instruction text

The ban on U+2014 and U+2013 covers every file in the repo: skill bodies, bundled `references/*.html` templates, vendored `references/**/*.css` and `references/**/*.js` (such as code comments in a ported runtime), and root-level docs. The check has been a manual grep since the shell test suite went away in 2026-07: `grep -rnP '[\x{2014}\x{2013}]' plugins/ README.md AGENTS.md`.

That repo-wide grep does not come back empty. Nine tracked files that predate the rule (in google-workspace's recipes, research, runtime-bridge, and workbench's visualizing-options, the frozen using-superpowers snapshot, and session-start hook) carry the characters as accepted debt, and the gitignored notes under `plugins/databricks/references/research/` add more hits in clones that keep them. So a change is gated on the files it touches: `git diff <base>..HEAD --name-only | xargs grep -nP '[\x{2014}\x{2013}]'` must print nothing, and `README.md` and `AGENTS.md` stay clean.

A markdown file that needs to talk about the characters names them by codepoint (`U+2014`, `U+2013`), so the grep does not match the description. In HTML body copy the entities `&mdash;`, `&#8212;`, `&ndash;`, `&#8211;` are allowed, because the grep matches raw codepoints only. CSS and JS comments have no entity escape, so a port substitutes the character.

## SKILL.md frontmatter `description:` must not contain a colon-space unless the whole value is quoted

Skill frontmatter must parse as strict YAML. An unquoted scalar holding a colon followed by a space (for example `description: Use when X. Examples: "..."`) reads as a nested mapping and fails with `mapping values are not allowed here`. Rephrase (`Examples:` becomes `For example`) or quote the whole value. Double quotes inside an unquoted value are fine as long as the value does not start with one.

No automated check exists since 2026-07, so validate by hand: feed the frontmatter block to `python3 -c 'import yaml,sys; yaml.safe_load(sys.stdin)'`. The `learning:quizzing-a-topic` description hit this at its 0.1.0 add and was fixed by replacing `Examples:` with `For example`.

## Lazy auth, never print secrets

Skills do not check authentication up front. They try the operation and diagnose auth only when a command fails, in Self-Healing. That saves a round trip on every call that works, and the failure message says more than a pre-check would. Credentials, tokens, and API keys are never printed or echoed; a skill only checks whether one is set (`test -n`).
