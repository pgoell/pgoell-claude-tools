# Pilot Step 6: Finalize docs and improvement pass

How pilot runs step 6. `SKILL.md` keeps the step heading; this file holds the branches on `Improvement pass:`, the two inline prompts, and the docs the orchestrator updates itself.

Branch on `Improvement pass:` from the profile (`always`, `on_learnings` default, or `off`).

## Capturing session learnings

Runs on `always`, or `on_learnings` when the run surfaced non-obvious learnings:

1. Under `on_learnings`, judge whether the run surfaced a non-obvious learning worth capturing (a gotcha, a corrected assumption, a repo convention discovered mid-run). Log the judgment, run or skip and why, in the deviation log.
2. If running: invoke `agent-system-management:capturing-session-learnings` via the `Skill` tool in the main session. This skill reads the conversation transcript, so it must run inline in the orchestrator. Pass **inline-prompt A** below. Wait for it to return and verify its commits exist on the feature branch via `git log` before proceeding.

Under `off`, skip capturing-session-learnings entirely and log the skip.

## Improving instructions

Runs on `always`, or explicit user request this run; never on plain `on_learnings`; an explicit user request this run also overrides `off`, since user instructions outrank the profile.

Dispatch `agent-system-management:improving-instructions` to a general-purpose subagent (Claude Code: `Agent` tool, `general-purpose` subagent_type, no model override. Codex: equivalent general-purpose subagent.) Pass **inline-prompt B** below. The improver does a cold read and does not need session context; running it in a subagent keeps the orchestrator's context lean.

Either skill can be replaced via the profile.

## Inline prompts

**Inline-prompt A (orchestrator pastes into the session-capture Skill invocation):**

> "You are running inside workbench pilot in the main orchestrator session, on the feature branch in the current working directory. Skip the approval prompt at the end of your skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message. Report back: every file you edited and a one-line summary per file."

**Inline-prompt B (orchestrator pastes into the improver subagent dispatch):**

> "You are running inside workbench pilot as a subagent, on the feature branch in the current working directory. Invoke `agent-system-management:improving-instructions` via the `Skill` tool. Skip the approval prompt at the end of the skill. After deciding what to change, apply the edits directly. Commit each logical change on the feature branch with a Conventional Commits message (`docs(agents-md): ...`). Report back: every file you edited, a one-line summary per file, and the commit hashes you created."

## Where the edits land

**All edits land on the feature branch in this run.** AGENTS.md, CLAUDE.md, `*.local.md`, user-global agent-instruction files, ADRs, OPEN_THINGS updates: each one a commit on the current branch with a matching Conventional Commits type. No follow-up chore PRs.

After each dispatched skill returns, the orchestrator:

1. Reads its summary.
2. Verifies the commits exist via `git log <feature-branch> --oneline`.
3. Includes the summary in the end-of-turn report.

## Docs the orchestrator updates

Then, **the orchestrator** updates the following inline (it does not delegate to a subagent), committing each as a separate Conventional Commits entry on the feature branch:

- Update `<paths.adr>/NNNN-<short-title>.md` for load-bearing decisions if the path exists in the project. Index in `<paths.adr>/README.md`.
- Update `<paths.open_things>` if it exists: remove resolved items, add follow-ups ordered by importance.
