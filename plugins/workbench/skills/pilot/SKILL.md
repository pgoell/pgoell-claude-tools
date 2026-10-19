---
name: pilot
description: Ship a feature end to end, from design through PR, with the human gates that the .workbench/pilot.md profile sets. Started by /workbench:pilot.
disable-model-invocation: true
---

# Pilot: feature flow with composable human gates

You are running the workbench pilot workflow. Pilot replaces autopilot and copilot with one orchestrator whose human gates come from the project profile's `Gates:` row: `none` runs the whole flow autonomously (the old autopilot behavior), `design` pauses for a human-driven brainstorm and spec (or combined-doc) approval while everything else stays automated (the old copilot behavior), and `slices` adds a pause after each implemented slice to review its diff before the next one starts. The default, when the row is absent, is `design, slices`. A per-invocation phrase overrides the profile for this run only: "auto mode" or "no gates" resolves to `none`; "co mode" resolves to `design`.

## Bootstrap

**First action:** find `.workbench/pilot.md` in the current repo root.

If the file is missing: stop. Tell the user that pilot requires a project profile at `.workbench/pilot.md`, and surface the example file at `references/example-project-profile.md` as a starting point. The full profile format is documented in `references/profile-schema.md`. Do not attempt to detect a missing profile.

If the file exists:

1. Read `## PR behavior` and apply: `Mode` (default `stop_at_green`), `Base branch` (default = repo default branch), `Squash` (default `yes`), `Hooks` (each optional).
2. Read `## Gates` and apply the active gate set: `design`, `slices`, both, or the literal `none`. Absent row means `design, slices`. A per-invocation phrase overrides for this run only: "auto mode" or "no gates" resolves to `none`; "co mode" resolves to `design`.
3. Read `## Improvement pass` and apply: `always`, `on_learnings` (default), or `off`.
4. Read `## Required skills` if present; merge `replaces` and `additional` rows into the universal table from `references/required-skills.md`.
5. For other project information (default branch, task runner, doc paths, project rules), resolve in this order, per field:
   - Profile heading.
   - Session context (`CLAUDE.md`, `AGENTS.md`, both already loaded into the agent).
   - Git or filesystem detection (`git symbolic-ref refs/remotes/origin/HEAD`, presence of `mise.toml` / `Makefile` / `package.json`, existence of `docs/superpowers/specs` etc.).
   - Ask the user. Never guess.

A field that no source provides and the active step needs stops the workflow with a question.

## Lanes

Lane comes from the `workbench:using-workbench` triage (step 0). Pilot proposes the lane with one line of reasoning. With any human gate active (`design` or `slices`), the user confirms the lane before step 1 begins. In a gateless run (`Gates: none`), pilot decides and records the chosen lane in the deviation log.

| Lane   | Steps run                 | Notes                                                                                                                                                                                   |
| ------ | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Quick  | 0, 1, 5, 6, 7, 8, 9       | Steps 2 to 4 are skipped. Step 5 runs as one TDD-governed chunk without a plan document. The slice gate does not fire (there are no slices). The reading guide degenerates to one line. |
| Medium | 0, 1, 2, 4, 5, 6, 7, 8, 9 | Step 3 is skipped. Step 4 writes the combined design and plan doc with a `## Design` preamble; the `design` gate applies to that doc.                                                   |
| Large  | 0 through 9               | All steps run. Step 3 writes the separate spec with its own approval gate.                                                                                                              |

Before proposing a lane, pilot runs the reflex ladder from `workbench:using-workbench` step 0. If a rung holds, the task does not get a lane: report which rung held and what to do instead, and stop rather than shipping a PR for work that should not exist. In a gateless run, log that call in the deviation log.

When unsure which lane applies, `workbench:using-workbench` picks the lighter one; pilot follows that call. Pilot escalates past it only for a named user request (spec, plan, or brainstorm) or for destructive and hard-to-reverse work, the two exceptions that skill lists. An escalation on any other grounds is a deviation and gets logged with the concrete reason the lighter lane failed.

## Task List Discipline

Pilot maintains a visible task list for the whole run and keeps it current. This is part of the workflow contract, not optional reporting.

- Create the task list immediately after bootstrap and before step 0. Use one top-level item per pilot step.
- Use the runtime's task-list primitive. Claude Code: `TodoWrite`. Codex: `update_plan`.
- Keep exactly one item `in_progress` while work is active. Mark an item `completed` as soon as its step finishes.
- Expand the task list dynamically when new work becomes known. After step 4 writes the implementation plan, add each slice as a task-list item nested by naming convention, for example `Step 5: Slice 2: <slice title>`.
- Add discovered follow-up tasks when hooks, review gates, CI failures, or docs updates create real work. Do not add speculative items.
- Before dispatching a subagent, mark the owned task in progress or add a concrete task-list item for that agent's assignment. When the subagent returns, update that item based on its result.
- Keep the task list aligned with the committed or scratch plan. If the plan changes, update the task list in the same turn before executing the changed work.
- In the end-of-turn summary, mention any task-list item that remains incomplete and why.

## Deviation Log

Keep a per-run deviation log so the user can see afterward where the run departed from the spec, plan, or profile, or where pilot decided something the profile did not specify.

- Start the log fresh at the beginning of every run: `mkdir -p /tmp/<project-name>-pilot && rm -f /tmp/<project-name>-pilot/deviations.md`.
- When you hit a decision point the plan, spec, or profile did not specify, or where reality contradicts them (an API that does not behave as the spec assumed, a missing file, a wrong test command), decide per the fork rule in Tone and reporting, then append one entry before continuing: the step you were in, what was unspecified or wrong, what you decided, and one line of reasoning.
- Log every departure from the committed plan: a task executed differently than written, a task skipped, or a task added. Also log any deviation a subagent reports in its return (a `DONE_WITH_CONCERNS` status or a deviations block).
- In a gateless run (`Gates: none`), log the lane pilot chose (see Lanes) as a deviation-log entry, not a silent decision.
- Log an `Improvement pass: on_learnings` skip decision: if step 6 judges the run surfaced no non-obvious learnings and skips `capturing-session-learnings`, log that judgment and the one-line reasoning.
- Decisions the user made at an active gate are user decisions, not deviations; do not log them. If a deviation would invalidate a decision the user made at a gate, stop and ask before proceeding; do not log-and-continue past a human decision.
- Do not log routine choices the plan anticipated (variable names, commit wording). The log records forks, not noise.
- The log lives in scratch and is never committed.

## Non-negotiables

See `references/invariants.md` for the full list. Summary:

1. PR behavior respects `Mode`. Default never auto-merges.
2. Never skip hooks (`--no-verify`, `--no-gpg-sign`, `LEFTHOOK=0`).
3. No AI attribution in commits, PRs, or code.
4. Conventional Commits compliance.
5. No em-dashes or en-dashes in prose.
6. Never synthesize a skill's output freehand.

## Required skill invocations

Read `references/required-skills.md` for the full table and `replaces` / `additional` semantics.

| Step   | Universal skill                                                                                            | Lane                    |
| ------ | ---------------------------------------------------------------------------------------------------------- | ----------------------- |
| 0      | `workbench:using-workbench`                                                                                | all                     |
| 2      | `workbench:brainstorming`                                                                                  | medium, large           |
| 3      | `workbench:writing-spec`                                                                                   | large                   |
| 4      | `workbench:writing-plans`                                                                                  | medium, large           |
| 5      | `workbench:test-driven-development`                                                                        | all                     |
| 5      | `workbench:subagent-driven-development`                                                                    | medium, large           |
| 5      | `ponytail:ponytail` (optional, see below)                                                                  | all                     |
| 6      | `agent-system-management:capturing-session-learnings` and `agent-system-management:improving-instructions` | per `Improvement pass:` |
| pre-PR | `workbench:verification-before-completion`                                                                 | all                     |

If a listed skill is unavailable in the current runtime, say so explicitly in the end-of-turn summary and skip only that entry. Never silently drop a row.

`ponytail:ponytail` is the one optional row: it lives in a separate plugin that a project may not have installed, so its absence is expected and is not reported as a skipped requirement. It also ships hooks that inject its ruleset at session start, so when the plugin is installed the ruleset is usually already active and no explicit invocation is needed. Invoke it only if step 5 begins without it in context. Where it conflicts with `workbench:test-driven-development`, TDD wins: ponytail governs how much code gets written, never whether the test comes first.

## Runtime adapters

This skill uses Claude Code tool names by default. If running on Codex, see `references/codex-adapter.md` for the tool-name mapping and the sequential fallback note for subagent-driven-development. For Claude Code specifics (subagent dispatch patterns, CI polling shape, error recovery), see `references/claude-code-adapter.md`.

---

## Steps

### Step 0: Establish skill discipline

**First action:** invoke `workbench:using-workbench` via the `Skill` tool. Nothing else happens until the skill returns.

If the profile's `## Required skills` table replaces this row with a different skill, invoke that one instead.

### Step 1: Prepare the workspace

- `git checkout <default branch> && git pull origin <default branch>` to get the latest.
- If the local branch diverges from origin (for example after a squash merge), `git reset --hard origin/<default branch>`. Check with the user first if there are unpushed local commits.
- Create a new branch: `git checkout -b <type>/<short-topic-slug>`. Use a Conventional-Commits type prefix (`feat/...`, `fix/...`, `docs/...`, etc.).

`<default branch>` resolves through the bootstrap precedence chain.

### Step 2: Brainstorm (medium and large lanes only)

Skip this step in the quick lane.

**With the `design` gate active:** **first action:** invoke `workbench:brainstorming` via the `Skill` tool. This is a REAL interactive grilling, not an autonomous one. Drive the skill's "one question at a time" rhythm with the user: ask each question, wait for the user's answer, and let it shape the next question. Do not answer on the user's behalf; the user owns these decisions. In the medium lane, ask a few targeted questions feeding the combined doc's `## Design` preamble (see Step 4); in the large lane, walk the design tree depth-first and grill exhaustively toward a separate spec (see Step 3). Continue until the design concept converges and the user approves it. If the topic is too big for one spec, stop and help the user decompose it, then let the user pick which sub-topic to tackle first.

The brainstorming skill writes its own summary artifact (HTML by default, or per `.workbench/config.md`). Pilot does not commit that record; it is a record, not a deliverable.

**Without the `design` gate:** do not invoke `workbench:brainstorming`. (This branch also applies under `Gates: slices`; only the design gate is absent there, and the slice gate still fires in step 5.) Instead write a short decision doc directly to `/tmp/<project-name>-pilot/decision.md`: topic, options considered, decisions, risks. No simulated Q&A, no format-verify grep. If the topic is too big for one spec, decompose it, record the chosen sub-topic and the reasoning in the deviation log, and continue with that sub-topic.

`<project-name>` resolves through the bootstrap precedence chain (profile `## Project name` heading; otherwise repo dir basename).

### Step 3: Write the spec (large lane only)

Skip this step in the quick and medium lanes; the medium lane's combined doc replaces the separate spec (see Step 4).

**First action:** invoke `workbench:writing-spec` via the `Skill` tool. (If the profile replaces this row, invoke the replacement.)

Then, following that skill's guidance:

- Use the design converged on in step 2 (the human-driven brainstorm, or, without the `design` gate, the decision doc).
- Path: `<paths.specs>/YYYY-MM-DD-<topic>-design.md`. `<paths.specs>` resolves through the bootstrap precedence chain.
- If `<paths.specs>` is `don't commit`, write the spec under `/tmp/<project-name>-pilot/` instead and do not commit it.
- The skill runs its self-review subagent and its user approval gate. **With the `design` gate active,** this is a real human gate: present the spec and WAIT for the user's approval; do not answer it yourself. If the user requests changes, apply them and re-run the self-review before proceeding. **Without the `design` gate,** self-answer the approval gate using the decision doc as the basis.
- Commit: `docs: add <topic> design spec`, unless `<paths.specs>` is `don't commit`.

If `Hooks.post_spec` is defined in the profile, run it now with `{{spec_path}}` substituted to the spec path.

With the `design` gate active, once the user approves the spec, proceed autonomously through the remaining steps.

### Step 4: Write the implementation plan

**First action:** invoke `workbench:writing-plans` via the `Skill` tool, passing the lane. (If the profile replaces this row, invoke the replacement.)

- **Large lane:** the plan links the approved spec from step 3.
- **Medium lane:** invoke writing-plans' `## Design` preamble mode; the plan opens with problem, chosen approach, key decisions, and out of scope, replacing the separate spec. **With the `design` gate active,** present the combined doc and WAIT for the user's approval before proceeding, the same real human gate as step 3's spec approval. **Without the `design` gate,** self-answer the approval using the decision doc from step 2 as the basis.

Then:

- Path: `<paths.plans>/YYYY-MM-DD-<topic>.md`.
- If `<paths.plans>` is `don't commit`, write the plan under `/tmp/<project-name>-pilot/` instead and do not commit it.
- Use slice-ordered tasks (checkbox syntax `- [ ]` per step within each slice) so progress is trackable.
- Commit: `docs: add <topic> implementation plan`, unless `<paths.plans>` is `don't commit`.

If `Hooks.post_plan` is defined, run it now with `{{plan_path}}` substituted.

### Step 5: Execute the plan

**First actions:** invoke `workbench:test-driven-development` via the `Skill` tool; in the medium and large lanes also invoke `workbench:subagent-driven-development` (in that order, both replaceable via the profile). TDD governs every implementation chunk; subagent-driven-development governs how slices run and covers safe parallel fanout (its `## Parallel dispatch` section). It is not invoked in the quick lane: it requires a plan, and the quick lane has none.

**Quick lane:** execute as one TDD-governed chunk in the main session, no plan document, no subagent task loop, no slice gate.

**Medium and large lanes:** execute slice by slice, in plan order. Each slice is its own unit of work: implement it, run its verification (the test commands and acceptance criteria the plan states for that slice), and commit it before moving to the next slice.

**With the `slices` gate active:** after a slice's own review gates pass (per `workbench:subagent-driven-development`), present the slice's diff summary to the user: files touched, key hunks, verification results. Wait for the user to approve or resteer before starting the next slice. **Without the `slices` gate,** move straight to the next slice.

**Subagent dispatch (Claude Code):** see `references/claude-code-adapter.md` for the full pattern. Summary:

- Independent tasks (no shared files, no ordering dependency): multiple `Agent` calls in one message.
- Shared-state tasks: one agent at a time, sequential.
- Trivial polish (rename one symbol, one-line lint fix): main session if files are already loaded; otherwise a subagent.

**Subagent dispatch (Codex):** see `references/codex-adapter.md`. Use Codex's task or subagent equivalent if installed; else execute tasks sequentially in the main session with explicit context-reset discipline.

Each subagent prompt must include: the slice text it owns, which files to touch, the relevant commits that preceded it, the acceptance criteria.

**Project-specific rebuild discipline.** When the profile's `## Project-specific rules` requires a rebuild or regen step before tests (for example "rebuild PyO3 binding before pytest"), include that step in the subagent's prompt as an explicit acceptance criterion. Otherwise the subagent observes phantom errors from stale artifacts.

Then:

- Commit in logical chunks with Conventional Commits scopes matching the module, one commit per slice where practical.
- Run `<task runner> <lint command>` and the relevant `<task runner> <test command>` before each commit.

If `Hooks.post_implementation` is defined, run it now after the last implementation commit.

### Step 6: Finalize docs and improvement pass

Branch on `Improvement pass:` from the profile (`always`, `on_learnings` default, or `off`).

**Capturing session learnings (`always`, or `on_learnings` when the run surfaced non-obvious learnings):**

1. Under `on_learnings`, judge whether the run surfaced a non-obvious learning worth capturing (a gotcha, a corrected assumption, a repo convention discovered mid-run). Log the judgment, run or skip and why, in the deviation log.
2. If running: invoke `agent-system-management:capturing-session-learnings` via the `Skill` tool in the main session. This skill reads the conversation transcript, so it must run inline in the orchestrator. Pass **inline-prompt A** below. Wait for it to return and verify its commits exist on the feature branch via `git log` before proceeding.

Under `off`, skip capturing-session-learnings entirely and log the skip.

**Improving instructions (`always`, or explicit user request this run; never on plain `on_learnings`; an explicit user request this run also overrides `off`, since user instructions outrank the profile):**

Dispatch `agent-system-management:improving-instructions` to a general-purpose subagent (Claude Code: `Agent` tool, `general-purpose` subagent_type, no model override. Codex: equivalent general-purpose subagent.) Pass **inline-prompt B** below. The improver does a cold read and does not need session context; running it in a subagent keeps the orchestrator's context lean.

Either skill can be replaced via the profile.

**Inline-prompt A (orchestrator pastes into the session-capture Skill invocation):**

> "You are running inside workbench pilot in the main orchestrator session, on the feature branch in the current working directory. Skip the approval prompt at the end of your skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message. Report back: every file you edited and a one-line summary per file."

**Inline-prompt B (orchestrator pastes into the improver subagent dispatch):**

> "You are running inside workbench pilot as a subagent, on the feature branch in the current working directory. Invoke `agent-system-management:improving-instructions` via the `Skill` tool. Skip the approval prompt at the end of the skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message (`docs(agents-md): ...`). Report back: every file you edited, a one-line summary per file, and the commit hashes you created."

**All edits land on the feature branch in this run.** AGENTS.md, CLAUDE.md, `*.local.md`, user-global agent-instruction files, ADRs, OPEN_THINGS updates: each one a commit on the current branch with a matching Conventional Commits type. No follow-up chore PRs.

After each dispatched skill returns, the orchestrator:

1. Reads its summary.
2. Verifies the commits exist via `git log <feature-branch> --oneline`.
3. Includes the summary in the end-of-turn report.

Then, **the orchestrator** updates the following inline (it does not delegate to a subagent), committing each as a separate Conventional Commits entry on the feature branch:

- Update `<paths.adr>/NNNN-<short-title>.md` for load-bearing decisions if the path exists in the project. Index in `<paths.adr>/README.md`.
- Update `<paths.open_things>` if it exists: remove resolved items, add follow-ups ordered by importance.

### Pre-PR verification (between step 6 and step 7)

**First action:** invoke `workbench:verification-before-completion` via the `Skill` tool. This governs the push and the PR-readiness claim.

It gates on outcomes, not process: fresh lint and test evidence (rerun now, not recalled from earlier in the session), a read of the actual diff (not a summary of intent), and confirmation that the docs lockstep from step 6 is done.

If verification surfaces a gap, fix it, commit the correction, and only then proceed to step 7.

### Step 7: Open the PR

After pre-PR verification passes:

- Push: `git push -u <git remote, default origin> <branch>`. If the project documents a wrapper (for example `mise exec --` for pinned hooks), use it.
- Create the PR: `gh pr create --base <base branch> --title "<Conventional-Commits title>" --body "<body>"`.
- PR body structure: `## Summary` (1-3 bullets), then scope or non-goals if relevant, `## Reading guide`, `## Test plan` checklist, links to spec (or design preamble) + plan + ADR if present.
- `## Reading guide` is always present, in every lane: one line per slice, in review order, naming what to look at and what verification already proved. In the quick lane (no slices), it degenerates to one line covering the whole change.

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
- Pilot pauses for the user at every active gate: the `design` gate's brainstorm and spec (or combined-doc) approval, and the `slices` gate's per-slice diff review. At those gates, slow down and let the user drive. Everywhere else, keep moving.
- End-of-turn summary: PR URL, one sentence on what changed, next step (usually "review when ready" or, for automerge, "merged at <commit>"). Also list any required skill that was unavailable in the runtime and therefore skipped. Also list every deviation-log entry, one line each, or state that there were no deviations; a deviation that changed user-visible behavior also belongs in the PR body's `## Summary`.
- Pilot pauses only at active gates and at a true fork it cannot resolve; everywhere else it decides for itself, that is the point of composable gates.
