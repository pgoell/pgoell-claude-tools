# Workbench Pilot Required Skills

The universal table of skills the pilot skill invokes at each step. Profiles can extend or replace rows through a `## Required skills` section in `.workbench/pilot.md`, but cannot remove rows.

## Universal table (defaults)

| Step   | Skill                                                 | Notes                                                                                                                              |
| ------ | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 0      | `deprecated:using-workbench`                          | session-start meta, workbench-native fork                                                                                          |
| 2      | `deprecated:brainstorming`                            | medium and large lanes                                                                                                             |
| 3      | `deprecated:writing-spec`                             | large lane                                                                                                                         |
| 4      | `deprecated:writing-plans`                            | medium and large lanes                                                                                                             |
| 5      | `deprecated:test-driven-development`                  | governs every implementation chunk                                                                                                 |
| 5      | `deprecated:subagent-driven-development`              | governs plan execution with subagents, including parallel dispatch (medium and large lanes; the quick lane has no plan to execute) |
| 5      | `ponytail:ponytail`                                   | optional, separate plugin: keeps the implementation minimal. See "Optional rows" below                                             |
| 6      | `agent-system-management:capturing-session-learnings` | runs on `always`, or on `on_learnings` when the run surfaced non-obvious learnings                                                 |
| 6      | `agent-system-management:improving-instructions`      | runs on `always` or explicit user request only                                                                                     |
| pre-PR | `deprecated:verification-before-completion`           | verify before push and PR readiness claims                                                                                         |

These are the rows shipped with Workbench. As more skills are ported into workbench, this table flips them to `workbench:*`.

## Optional rows

Every row above is mandatory except `ponytail:ponytail`, which is marked optional because it lives in a separate plugin rather than in workbench. Optional means three things:

- Its absence is expected and is never reported as a skipped requirement in the end-of-turn summary. Every other missing skill is.
- It usually needs no explicit invocation. Ponytail ships `SessionStart`, `SubagentStart`, and `UserPromptSubmit` hooks that inject its ruleset automatically, so by step 5 it is normally already in context. Invoke it only if it is not.
- It never overrides a mandatory row. Against `deprecated:test-driven-development`, TDD wins: ponytail governs how much code gets written, never whether the test comes first. Against `deprecated:verification-before-completion`, verification wins: a smaller diff is not evidence of a working one.

The reflex ladder ponytail encodes also runs at triage as step 0 of `deprecated:using-workbench`, independent of whether the plugin is installed. That step decides whether the task gets a lane at all; this row shapes the diff once it does.

`fewer-permission-prompts` is intentionally not in the universal table. It is Claude-Code-specific (touches `.claude/settings.json`) and an optimization rather than a discipline gate. Projects that want it can add it via `additional` (see below).

## Replace and additional semantics

Profiles override the table through a `## Required skills` heading shaped like this:

```md
## Required skills

| Step | Skill      | Action                       |
| ---- | ---------- | ---------------------------- |
| <n>  | <skill-id> | replaces <existing-skill-id> |
| <n>  | <skill-id> | additional                   |
```

### Replace

A row whose `Action` column says `replaces <skill-id>` swaps which skill fulfills an existing step; the replacement is used instead of the universal row for that step.

Example:

```md
| 4 | my-project:writing-plans | replaces deprecated:writing-plans |
```

This says "for step 4, use `my-project:writing-plans` instead of `deprecated:writing-plans`." Every other universal row is unchanged.

### Additional

A row whose `Action` column is `additional` adds a new mandatory skill at a step, in addition to the universal row(s) for that step.

Example:

```md
| 6 | my-project:custom-changelog | additional |
```

This says "at step 6, in addition to `capturing-session-learnings` and `improving-instructions`, also invoke `my-project:custom-changelog`."

### Removal not supported

Profiles cannot remove a row from the universal table. The discipline floor is fixed across projects.

The optional row is not an exception to this. `ponytail:ponytail` is optional because the plugin may not be installed, not because a profile may switch it off. A profile still cannot remove it.
