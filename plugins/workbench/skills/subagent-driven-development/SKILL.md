---
name: subagent-driven-development
description: Use when executing an implementation plan with fresh subagents, task ownership, and review gates in the current session.
---

# Subagent-Driven Development

Execute an implementation plan by giving each slice a focused implementation agent, then running two review gates before moving on.

Core rule: the main session coordinates. Agents implement or review bounded work. The main session integrates, verifies, and decides when to proceed.

## When To Use

Use this skill when:

- An implementation plan already exists.
- The plan has slices (`workbench:writing-plans` emits `### Slice N` sections) or similarly bounded tasks.
- Slices can be assigned with clear ownership.
- The current runtime has subagent support, or the main session can follow the same task discipline sequentially.

If there is no plan yet, use `workbench:writing-plans` first. If implementation is starting, use `workbench:test-driven-development` before writing production code.

## Task Loop

For each plan slice (or bounded task, when the plan is not slice-shaped):

1. Paste the slice text into the agent prompt: its heading, files map, signatures, test commands, acceptance criteria, and checkbox steps. One agent per slice; the checkbox steps are the slice's internal TDD rhythm and are never split across agents.
2. Define ownership: files, directories, or behavior the agent may change.
3. Include acceptance criteria and verification commands.
4. Tell the agent it is not alone in the codebase and must not revert edits made by others.
5. Wait for the implementation agent to return.
6. Record any deviations the agent returned in a running list for the whole plan execution.
7. The main session runs the verification commands itself (see Handling Agent Status) before spec review.
8. Run the spec compliance reviewer.
9. Fix any spec gaps and re-review.
10. Run the code quality reviewer.
11. Fix any quality issues and re-review.
12. Mark the slice complete only after both review gates pass.

## Two review gates

Spec compliance reviewer:

- Confirms the implementation matches the plan and spec.
- Flags missing requested behavior.
- Flags extra behavior that was not requested.

Code quality reviewer:

- Checks maintainability, local patterns, tests, error handling, and integration risk.
- Focuses on bugs and regressions, not style preferences.
- Approves only when important issues are resolved.

Do not start the code quality reviewer until spec compliance passes.

## Implementation agent prompt

```md
Implement this plan slice:

[paste one slice: heading, files map, signatures, test commands, acceptance criteria, checkbox steps]

Ownership:

- You may edit: [files or directories]
- Do not edit: [files or directories]

Context:

- Relevant spec or plan excerpt.
- Relevant prior commits or decisions.

Rules:

- Use workbench:test-driven-development.
- You are not alone in the codebase. Do not revert edits made by others.
- Keep the change minimal.

Return:

- Status: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.
- Files changed.
- Verification commands and results.
- Concerns, if any.
- Deviations: each decision point the slice did not specify and how you resolved it, or none.
```

## Handling Agent Status

`DONE`: the agent's own "passed" counts for nothing. Before spec review, the main session runs the verification commands itself: every command the brief names, run as shell commands in the main session.

- No verification command in the brief: do not accept `DONE` with nothing run. Take the slice's test commands or acceptance criteria; failing those, the project's full relevant test set; failing that, ask the user for a command and wait for the answer; this slice does not go to spec review until then. Add the gap to the deviation list of Task Loop step 6, then run the command.
- A command fails: treat the task as `DONE_WITH_CONCERNS`. Send the failing command, its exit code and its output back to the same agent (see Runtime Mapping); fix it in the main session only when the fix is a few lines. Run every command again; start spec review only when all pass. Still failing after that one fix round (one agent return or one main-session fix): handle as `BLOCKED`.

`DONE_WITH_CONCERNS`: read the concerns. Fix in-scope correctness, lint, test, or scope concerns, then run every verification command as for `DONE` before review.

`NEEDS_CONTEXT`: provide the missing context and continue with the same task, in the same agent (see Runtime Mapping).

`BLOCKED`: change something before retrying. Provide missing context, split the task, use a more capable model, or stop if the plan is wrong.

## Parallel dispatch

Default to one implementation slice at a time. This keeps review gates simple and avoids shared-state conflicts.

Dispatch tasks in parallel only when all of these hold:

- Two or more independent domains: tasks, investigations, or edits.
- Each task can be understood with its own focused context.
- Each task has a disjoint write scope, or is read-only.
- The result of one task is not needed before another can start.

Do not dispatch in parallel when:

- Failures are likely symptoms of one shared root cause.
- Tasks edit the same files, generated artifacts, shared schemas, or lockfiles.
- One task depends on another task's result.
- You need a single coherent system diagnosis before splitting work.

When in doubt, do one short local pass to classify the work before dispatching agents.

Read-only review agents may run in parallel when they review different artifacts.

### Per-agent prompt shape

Each parallel agent prompt should include:

- The exact domain or task.
- Files or directories the agent owns.
- Files or directories it must not edit.
- Relevant failure output or acceptance criteria.
- Expected report format.

### Integration checklist

- Read every returned summary before committing.
- Inspect `git status` and `git diff`.
- For each returned `DONE` or `DONE_WITH_CONCERNS`, the main session runs the verification commands itself for that agent's brief before integration, not only the final full set.
- Resolve conflicts in the main session.
- Run the full relevant test set after all agent work lands.
- If one agent's result changes another agent's assumptions, re-verify the affected task.

## Runtime Mapping

Claude Code: use `Agent` with a focused prompt for implementation and review agents. To send work back to the same agent, use `SendMessage` with the agent's ID or name; it is a deferred tool, so load it first with `ToolSearch` query `select:SendMessage`.

Codex: use `spawn_agent` for independent sidecar tasks when useful. For urgent blocking work, implement locally and preserve the same task loop. For delegated code edits, assign a disjoint write set and tell the worker not to revert others' changes. To send work back to the same agent, use `send_input` with the id `spawn_agent` returned (`followup_task` under multi-agent v2), then `wait`.

No tool to continue an agent (Cursor, Codex without multi-agent): start a fresh agent with the original brief, the agent's last report and the feedback (for a failed command: the command, its exit code and its output). Tell it its earlier work is already in the tree. Its return counts as the same agent's return, also for the one fix round.

## Completion

After all slices pass both review gates:

- Run the full relevant verification set.
- Inspect `git status` and `git diff`.
- Report the collected deviations from all slices to the user, or state that there were none.
- Use `workbench:verification-before-completion` before claiming the branch is complete or ready.
