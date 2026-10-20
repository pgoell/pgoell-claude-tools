---
name: copilot
description: Deprecated and retired without replacement. Formerly used for semi-autonomous, human-in-the-loop feature shipping where the user drove the brainstorm and spec by hand and the agent automated the plan, implementation, docs, audit, and PR using .workbench/autopilot.md.
---

# Copilot: human-in-the-loop feature flow

> **Deprecated.** Retired without replacement. Its successor `deprecated:pilot` is archived too. This copy is archived and no longer maintained.

You are running the workbench copilot workflow. Copilot is the human-in-the-loop sibling of autopilot: the user pilots the design (step 2 brainstorm grilling and step 3 spec approval are real human gates that you do not answer on the user's behalf) and you, the copilot, automate the rest (steps 1 and 4 through 9). Pause for the user at the two design gates; be autonomous everywhere else, only stopping for a true fork you cannot resolve or a CI failure you cannot fix.

## Bootstrap

**First action:** find `.workbench/autopilot.md` in the current repo root.

Copilot reads the SAME `.workbench/autopilot.md` profile autopilot uses; there is no separate copilot profile. Its reference docs are shared with autopilot at `../autopilot/references/`.

If the file is missing: stop. Tell the user that copilot requires a project profile at `.workbench/autopilot.md`, and surface the example file at `../autopilot/references/example-project-profile.md` as a starting point. The full profile format is documented in `../autopilot/references/profile-schema.md`. Do not attempt to detect a missing profile.

If the file exists:

1. Read `## PR behavior` and apply: `Mode` (default `stop_at_green`), `Base branch` (default = repo default branch), `Squash` (default `yes`), `Hooks` (each optional).
2. Read `## Required skills` if present; merge `replaces` and `additional` rows into the universal table from `../autopilot/references/required-skills.md`.
3. For other project information (default branch, task runner, doc paths, project rules), resolve in this order, per field:
   - Profile heading.
   - Session context (`CLAUDE.md`, `AGENTS.md`, both already loaded into the agent).
   - Git or filesystem detection (`git symbolic-ref refs/remotes/origin/HEAD`, presence of `mise.toml` / `Makefile` / `package.json`, existence of `docs/superpowers/specs` etc.).
   - Ask the user. Never guess.

A field that no source provides and the active step needs stops the workflow with a question.

## Task List Discipline

Copilot maintains a visible task list for the whole run and keeps it current. This is part of the workflow contract, not optional reporting.

- Create the task list immediately after bootstrap and before step 0. Use one top-level item per copilot step, plus one item for the skill audit.
- Use the runtime's task-list primitive. Claude Code: `TodoWrite`. Codex: `update_plan`.
- Keep exactly one item `in_progress` while work is active. Mark an item `completed` as soon as its step finishes.
- Expand the task list dynamically when new work becomes known. After step 4 writes the implementation plan, add each implementation checkbox as a task-list item nested by naming convention, for example `Step 5: <plan task>`.
- Add discovered follow-up tasks when hooks, audits, CI failures, or docs updates create real work. Do not add speculative items.
- Before dispatching a subagent, mark the owned task in progress or add a concrete task-list item for that agent's assignment. When the subagent returns, update that item based on its result.
- Keep the task list aligned with the committed or scratch plan. If the plan changes, update the task list in the same turn before executing the changed work.
- In the end-of-turn summary, mention any task-list item that remains incomplete and why.

## Deviation Log

The user personally approved the design at the two gates; a departure from the approved spec or committed plan during the autonomous steps (1 and 4 through 9) is recorded, never silently absorbed. Keep a per-run deviation log.

- Start the log fresh at the beginning of every run: `mkdir -p /tmp/<project-name>-autopilot && rm -f /tmp/<project-name>-autopilot/deviations.md`.
- When you hit a decision point the spec or plan did not specify, or where reality contradicts them (an API that does not behave as the spec assumed, a missing file, a wrong test command), decide it, then append one entry before continuing: the step you were in, what was unspecified or wrong, what you decided, and one line of reasoning.
- Log every departure from the committed plan: a task executed differently than written, a task skipped, or a task added. Also log any deviation a subagent reports in its return (a `DONE_WITH_CONCERNS` status or a deviations block).
- Decisions the user made at the two human gates (brainstorm, spec approval) are user decisions, not deviations; do not log them. If a deviation would invalidate a decision the user made at a gate, stop and ask before proceeding; do not log-and-continue past a human decision.
- Do not log routine choices the plan anticipated (variable names, commit wording). The log records forks, not noise.
- The log lives in scratch and is never committed.

## Non-negotiables

See `../autopilot/references/invariants.md` for the full list. Summary:

1. PR behavior respects `Mode`. Default never auto-merges.
2. Never skip hooks (`--no-verify`, `--no-gpg-sign`, `LEFTHOOK=0`).
3. No AI attribution in commits, PRs, or code.
4. Conventional Commits compliance.
5. No em-dashes or en-dashes in prose.
6. Never synthesize a skill's output freehand. A present human at the two design gates does not excuse skipping a `Skill` tool call.

## Required skill invocations

Read `../autopilot/references/required-skills.md` for the full table and `replaces` / `additional` semantics. The pre-PR audit (after step 6, before step 7) walks the merged table. The required skills are identical to autopilot; copilot differs only in how steps 2 and 3 are driven (by the user, not autonomously), never in which skills run.

| Step   | Universal skill                                                                                                              |
| ------ | ---------------------------------------------------------------------------------------------------------------------------- |
| 0      | `deprecated:using-workbench`                                                                                                 |
| 2      | `deprecated:brainstorming`                                                                                                   |
| 3      | `deprecated:writing-spec`                                                                                                    |
| 4      | `deprecated:writing-plans`                                                                                                   |
| 5      | `deprecated:test-driven-development`, `deprecated:dispatching-parallel-agents`, and `deprecated:subagent-driven-development` |
| 6      | `agent-system-management:capturing-session-learnings` and `agent-system-management:improving-instructions`                   |
| pre-PR | `deprecated:verification-before-completion`                                                                                  |

If a listed skill is unavailable in the current runtime, say so explicitly in the end-of-turn summary and skip only that entry. Never silently drop a row.

## Runtime adapters

This skill uses Claude Code tool names by default. If running on Codex, see `../autopilot/references/codex-adapter.md` for the tool-name mapping and the sequential fallback note for subagent-driven-development. For Claude Code specifics (subagent dispatch patterns, CI polling shape, error recovery), see `../autopilot/references/claude-code-adapter.md`.

---

## Steps

### Step 0: Establish skill discipline

**First action:** invoke `deprecated:using-workbench` via the `Skill` tool. Nothing else happens until the skill returns.

If the profile's `## Required skills` table replaces this row with a different skill, invoke that one instead.

### Step 1: Prepare the workspace

- `git checkout <default branch> && git pull origin <default branch>` to get the latest.
- If the local branch diverges from origin (for example after a squash merge), `git reset --hard origin/<default branch>`. Check with the user first if there are unpushed local commits.
- Create a new branch: `git checkout -b <type>/<short-topic-slug>`. Use a Conventional-Commits type prefix (`feat/...`, `fix/...`, `docs/...`, etc.).

`<default branch>` resolves through the bootstrap precedence chain.

### Step 2: Brainstorm (interactive, human-driven)

**First action:** invoke `deprecated:brainstorming` via the `Skill` tool. This is a REAL interactive grilling, not an autonomous one. Drive the skill's "one question at a time" rhythm with the user: ask each question, wait for the user's answer, and let it shape the next question. Walk the design tree depth-first and grill exhaustively. Do not answer on the user's behalf; the user owns these decisions. This is the first of copilot's two human gates.

Continue until the design concept converges and the user approves the design. If the topic is too big for one spec, stop and help the user decompose it, then let the user pick which sub-topic to tackle first.

The brainstorming skill writes its own summary artifact (HTML by default, or per `.workbench/config.md`). Copilot does not commit that record; it is a record, not a deliverable. There is no `/tmp` scratch file and no format-verify gate in copilot; those exist in autopilot only to substitute for an absent human.

### Step 3: Write the spec (human-approved)

**First action:** invoke `deprecated:writing-spec` via the `Skill` tool. (If the profile replaces this row, invoke the replacement.)

Then, following that skill's guidance:

- Use the design the brainstorm converged on in step 2.
- Path: `<paths.specs>/YYYY-MM-DD-<topic>-design.md`. `<paths.specs>` resolves through the bootstrap precedence chain.
- If `<paths.specs>` is `don't commit`, write the spec under `/tmp/<project-name>-autopilot/` instead and do not commit it.
- The skill runs its self-review subagent AND its user approval gate. This is copilot's second human gate: present the spec and WAIT for the user to approve it. Do not answer the approval gate yourself. If the user requests changes, apply them and re-run the self-review before proceeding.
- Commit: `docs: add <topic> design spec`, unless `<paths.specs>` is `don't commit`.

If `Hooks.post_spec` is defined in the profile, run it now with `{{spec_path}}` substituted to the spec path.

Once the user approves the spec, proceed autonomously through the remaining steps.

### Step 4: Write the implementation plan

**First action:** invoke `deprecated:writing-plans` via the `Skill` tool. (If the profile replaces this row, invoke the replacement.)

Then:

- Path: `<paths.plans>/YYYY-MM-DD-<topic>.md`.
- If `<paths.plans>` is `don't commit`, write the plan under `/tmp/<project-name>-autopilot/` instead and do not commit it.
- Use checkbox syntax (`- [ ]`) per task step so progress is trackable.
- Commit: `docs: add <topic> implementation plan`, unless `<paths.plans>` is `don't commit`.

If `Hooks.post_plan` is defined, run it now with `{{plan_path}}` substituted.

### Step 5: Execute the plan

**First actions, in order:** invoke `deprecated:test-driven-development`, then `deprecated:dispatching-parallel-agents`, then `deprecated:subagent-driven-development`. All three via the `Skill` tool. (Replace any of them if the profile says so.) TDD governs every implementation chunk, dispatching-parallel-agents governs safe fanout, and subagent-driven-development governs how chunks run.

**Subagent dispatch (Claude Code):** see `../autopilot/references/claude-code-adapter.md` for the full pattern. Summary:

- Independent tasks (no shared files, no ordering dependency): multiple `Agent` calls in one message.
- Shared-state tasks: one agent at a time, sequential.
- Trivial polish (rename one symbol, one-line lint fix): main session if files are already loaded; otherwise a subagent.

**Subagent dispatch (Codex):** see `../autopilot/references/codex-adapter.md`. Use Codex's task or subagent equivalent if installed; else execute tasks sequentially in the main session with explicit context-reset discipline.

Each subagent prompt must include: the plan task it owns (paste the checkbox block), which files to touch, the relevant commits that preceded it, the acceptance criteria.

**Project-specific rebuild discipline.** When the profile's `## Project-specific rules` requires a rebuild or regen step before tests (for example "rebuild PyO3 binding before pytest"), include that step in the subagent's prompt as an explicit acceptance criterion. Otherwise the subagent observes phantom errors from stale artifacts.

Then:

- Commit in logical chunks with Conventional Commits scopes matching the module.
- Run `<task runner> <lint command>` and the relevant `<task runner> <test command>` before each commit.

If `Hooks.post_implementation` is defined, run it now after the last implementation commit.

### Step 6: Finalize docs and improvement pass

**First actions, in order:**

1. Invoke `agent-system-management:capturing-session-learnings` via the `Skill` tool in the main session. This skill reads the conversation transcript, so it must run inline in the orchestrator. Pass **inline-prompt A** below. Wait for it to return and verify its commits exist on the feature branch via `git log` before proceeding.
2. After session-capture has returned and its commits have landed, dispatch `agent-system-management:improving-instructions` to a general-purpose subagent (Claude Code: `Agent` tool, `general-purpose` subagent_type, no model override. Codex: equivalent general-purpose subagent.) Pass **inline-prompt B** below. The improver does a cold audit and does not need session context; running it in a subagent keeps the orchestrator's context lean.

Either skill can be replaced via the profile.

**Inline-prompt A (orchestrator pastes into the session-capture Skill invocation):**

> "You are running inside workbench copilot in the main orchestrator session, on the feature branch in the current working directory. Skip the approval prompt at the end of your skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message. Report back: every file you edited and a one-line summary per file."

**Inline-prompt B (orchestrator pastes into the improver subagent dispatch):**

> "You are running inside workbench copilot as a subagent, on the feature branch in the current working directory. Invoke `agent-system-management:improving-instructions` via the `Skill` tool. Skip the approval prompt at the end of the skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message (`docs(agents-md): ...`). Report back: every file you edited, a one-line summary per file, and the commit hashes you created."

**All edits land on the feature branch in this run.** AGENTS.md, CLAUDE.md, `*.local.md`, user-global agent-instruction files, ADRs, OPEN_THINGS updates: each one a commit on the current branch with a matching Conventional Commits type. No follow-up chore PRs.

After the subagent returns, the orchestrator:

1. Reads the subagent's summary.
2. Verifies the commits exist via `git log <feature-branch> --oneline`.
3. Includes both skills' summaries in the end-of-turn report.

Then, **the orchestrator** updates the following inline (it does not delegate to a subagent), committing each as a separate Conventional Commits entry on the feature branch:

- Update `<paths.adr>/NNNN-<short-title>.md` for load-bearing decisions if the path exists in the project. Index in `<paths.adr>/README.md`.
- Update `<paths.open_things>` if it exists: remove resolved items, add follow-ups ordered by importance.

### Skill audit (between step 6 and step 7, blocking)

**First action:** invoke `deprecated:verification-before-completion` via the `Skill` tool. This governs the audit, push, and PR readiness claim.

Re-read `../autopilot/references/required-skills.md` and the profile's `## Required skills` section. Walk every row in the merged table:

1. For each universal row, confirm the corresponding skill was invoked via the `Skill` tool this session. If the profile replaces a row, audit the replacement instead.
2. For each `additional` row from the profile, confirm that skill was also invoked.
3. Re-read the profile's `## Project-specific rules` section. If any rule names a skill or command that should have been invoked, confirm it was.
4. Re-read the project's `CLAUDE.md` and `AGENTS.md`. If either documents skill discipline naming a specific skill at a specific point, confirm that was invoked.

If any required invocation is missing: invoke the skill now, let it reshape the artifact it governs, commit the correction, and only then proceed.

The audit is blocking; do not push until it passes.

### Step 7: Open the PR

After the audit passes:

- Push: `git push -u <git remote, default origin> <branch>`. If the project documents a wrapper (for example `mise exec --` for pinned hooks), use it.
- Create the PR: `gh pr create --base <base branch> --title "<Conventional-Commits title>" --body "<body>"`.
- PR body structure: `## Summary` (1-3 bullets), then scope or non-goals if relevant, `## Test plan` checklist, links to spec + plan + ADR if present.

If `Hooks.post_pr` is defined, run it now with `{{pr}}` substituted to the PR number.

### Step 8: CI loop

Poll until every check resolves. Use the runtime adapter's polling primitive (Claude Code: `Monitor`; Codex: `run_in_background` plus sleep, or Codex's equivalent).

Programmatic poll:

```bash
gh pr view <pr> --json statusCheckRollup -q '.statusCheckRollup[] | "\(.status):\(.conclusion // "")"'
```

Loop until no row's status differs from `COMPLETED` and no `conclusion` is `FAILURE`, `CANCELLED`, or `TIMED_OUT`. (`gh pr checks <pr>` is human-readable; do not pass `--json` to it, the flag does not exist on `gh pr checks`.)

If a check fails: `gh run view <run-id> --log-failed | tail -200`, diagnose, commit the fix, push. Repeat until green.

If `Hooks.post_ci_green` is defined, run it now once everything is green.

### Step 9: Apply PR-behavior policy

Branch on `Mode` from the profile.

**`stop_at_green`** (default):

- Report the PR URL in the end-of-turn summary.
- Stop. Do not merge.

**`automerge`:**

1. Set automerge:

   ```bash
   gh pr merge <pr> --auto --squash
   ```

   Use `--squash` if `Squash: yes` (default), `--merge` if `Squash: no`.

2. Poll for merge:

   ```bash
   gh pr view <pr> --json state -q .state
   ```

   Until it returns `MERGED`. If it returns `CLOSED` without merging, branch protection blocked the merge; surface the reason to the user instead of retrying.

3. Refresh local default branch:

   ```bash
   git checkout <default branch>
   git pull origin <default branch>
   git branch -d <feature-branch>
   ```

   The lowercase `-d` refuses to delete an unmerged branch; if it fails, inspect before forcing.

4. Report the merged commit hash and PR URL in the end-of-turn summary.

**`request_review`:**

- `gh pr ready <pr>`.
- Post a one-line reviewer note as a PR comment.
- Stop. Report the PR URL.

If the user explicitly says "don't merge" before or during the run, override `automerge` to `request_review` for this run only; do not modify the profile.

---

## Tone and reporting

- Terse between tool calls. The user sees the PR diff; they don't need narration.
- Copilot pauses for the user at the two design gates (step 2 brainstorm and step 3 spec). At those gates, slow down and let the user drive. Everywhere else, keep moving.
- End-of-turn summary: PR URL, one sentence on what changed, next step (usually "review when ready" or, for automerge, "merged at <commit>"). Also list any required skill that was unavailable in the runtime and therefore skipped. Also list every deviation-log entry, one line each, or state that there were no deviations; a deviation that changed user-visible behavior also belongs in the PR body's `## Summary`.
- Copilot pauses only at the two human gates (brainstorm and spec) and at a true fork it cannot resolve; everywhere else it decides for itself, that is the point of copilot.
