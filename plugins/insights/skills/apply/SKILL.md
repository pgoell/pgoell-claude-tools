---
name: apply
description: "Use when the user has reviewed a day's session-insights note in their kasten vault and wants the kept fixes carried out, for example \"apply the insights\", \"I kept 1 and 3, go\", or \"/insights:apply --date 2026-10-08\". Acts on a note whose \"## Proposed\" was renamed \"## Keep\", or on any reviewed note when the user runs it by hand, and picks up a partly applied note where it stopped. Opens a pull request per kept fix where a repository exists (never merges), adds todos to the daily note, adds newspaper feedback lines, and records each line's verdict (applied, pending PR, already done, deferred, rejected, watch). Not for finding problems (use insights:digest)."
---

# Apply

Carry out the fixes the user kept in one day's review note. The note is the
only signal: a line kept is a yes, a line deleted is a no, a line starting
`no:` is a no with a reason. A bullet indented under a line is the user's
note on that fix: an instruction ("done", "use the port instead"), a doubt
("works as intended, no?") or a question. Follow it for that item, answer the
question in `## Done`, and treat an indented `no:` as a no for its parent.

**Who approved it.** On the cron path (`insights:digest` step 2) only a note
renamed `## Keep` counts as reviewed; a note still under `## Proposed`
decided nothing. When the user runs `/insights:apply` by hand, the run is the
approval: act on the note whether `## Proposed` was renamed or not, and say
so in `## Done`.

May run headless inside `insights:digest`. Never stop to ask; when a kept fix
cannot be carried out, say why in `## Done` and move on.

## Arguments

`/insights:apply [--vault PATH] [--date YYYY-MM-DD] [--periodic FOLDER]`

Vault and periodic folder resolve as in `../digest/SKILL.md`. The date is the
day the note covers, default yesterday in Europe/Berlin. Below, `ARGS` and
`IN` mean what they mean there.

## Verdicts

Every line ends in exactly one verdict, which `remember.py` stores per
problem and the next digest judges by:

| Verdict        | When                                                                    | `ref` / `reason` / `until`                   |
| -------------- | ----------------------------------------------------------------------- | -------------------------------------------- |
| `applied`      | a todo or feedback line was added                                       | `ref`: "todo" or "feedback"                  |
| `pending`      | a PR was opened or found open; it counts as applied only once it merges | `ref`: the PR URL                            |
| `already-done` | the fix is in place already, nothing to change                          | `reason`: what you checked                   |
| `deferred`     | the user says not now (other work first, waiting on something)          | `reason`, and `until`: what ends the wait    |
| `rejected`     | the line was deleted, or a `no:` line                                   | `reason`: the user's words, empty if deleted |
| `watch`        | a kept Watch-only line                                                  |                                              |

A deferral is not a rejection: do not write `rejected` for "later" or "not
until X". A line you could not carry out (push refused, `gh` logged out) gets
no verdict, so the next run tries it again.

## Protocol

1. **Read the decision.** `uv run "${CLAUDE_SKILL_DIR}/../digest/scripts/review.py" ARGS`
   prints `state`, `handled`, `kept`, `no`, `dropped`, `unsure`, `unmatched`
   and `other`. Stop when `state` is `done`: every line has a verdict. Stop
   when it is `proposed` and this run came from the digest; go on when the
   user ran apply. `handled` lists problems an earlier run already settled;
   leave them alone, so a partly applied note picks up where it stopped.
   `unmatched` lines carry an id that is not on the page and `unsure`
   problems may be what they meant: record nothing for either and list them
   in the report and in `## Done` as `not matched: <line>`.
2. **Carry out each kept line**, by its problem's `action`, reading its
   `notes` first. An `edited` line means the user changed the fix: follow
   their words over the page's. When a note says the fix is done already or
   not needed, check it (`command -v`, a grep of the destination) and record
   `already-done`, or `rejected` with the note as the reason.
   - **Opens a PR.** In `target.repo`, read its `AGENTS.md` or `CLAUDE.md`
     first and follow its conventions (branch names, commit format, version
     bumps, formatting, checks). Check `gh pr list --head fix/insights-<id>`
     first; an open PR for this id is linked, not opened twice. Then:
     ```sh
     git -C "<repo>" fetch origin
     git -C "<repo>" worktree add "<repo>/.worktrees/fix/insights-<id>" -b "fix/insights-<id>" "origin/<default branch>"
     ```
     When the repo does not ignore `.worktrees/`, add it to
     `<repo>/.git/info/exclude`. Make the change from the problem's `fix` in
     that worktree. Run the repo's own format, lint and test commands: the
     `mise run` tasks where a `mise.toml` exists (`mise tasks` lists them),
     else what its instructions name. Commit (Conventional Commits, lowercase
     subject, no AI attribution of any kind), `git push -u origin fix/insights-<id>`,
     and `gh pr create` with a body that cites the problem: title, hits,
     evidence, and the page `<periodic>/06 Insights/<date>.html`. No
     attribution line in the body either. Never merge. Remove the worktree
     afterwards (`git -C "<repo>" worktree remove "<repo>/.worktrees/fix/insights-<id>"`).
     Never touch the repo's own working tree. Record `pending` with the PR
     URL; the digest turns it into `applied` when the PR merges.
   - **Adds a todo.** Append `- [ ] <the fix in a few words> #insights ➕ <today>`
     under `## TODOs` in today's daily note (`<periodic>/00 Daily/<today>.md`),
     creating that section at the end when missing. Today means the Berlin
     date of this run.
   - **Adds a feedback line.** Append `- <the fix in plain words> (insights #<id>)`
     under `## Open` in `<periodic>/05 Newspaper/feedback.md`; the next edition
     applies it.
   - **Watch only.** Nothing to do; record it as `watch`.
3. **Record.** Write one JSON list to `/tmp/insights-verdicts-<date>.json`,
   one `{"fingerprint", "id", "verdict", "ref", "reason", "until"}` per line
   settled this run (see Verdicts), including `rejected` for every `dropped`
   problem and every `no` line that names an id. Then
   `uv run "${CLAUDE_SKILL_DIR}/../digest/scripts/remember.py" ARGS --verdicts /tmp/insights-verdicts-<date>.json`.
   It skips a verdict the problem already holds, so the first date stays.
4. **Pass on the reasons.** Each `no` reason, each deferral and each `other`
   line goes under `## Open` in `IN/feedback.md` as
   `- <date> #<id>: <the words> (recorded: <verdict>)`; the next digest
   turns them into rules and, seeing `recorded:`, does not record the
   verdict again. Write a `no` line with no reason there only if it says
   something a rule could use.
5. **Close the note.** Append to `IN/<date>.md`, under the existing `## Done`
   when there is one, else under a new one:
   ```markdown
   ## Done

   - #<id> -> <PR URL (pending) | todo added | feedback line added | already in place: why | deferred: why, until | rejected: why | watching | not done: why | not matched: the line>
   ```
   One line per line settled or tried this run, plus the answer to any
   question the user asked under it. Memory, not this section, decides what
   a later run skips.
6. **Report**: PRs opened with URLs, todos and feedback lines added,
   verdicts recorded by kind, lines not matched, anything not done and why.

## Platform mapping

| Step    | Claude Code                                        | Codex                                             |
| ------- | -------------------------------------------------- | ------------------------------------------------- |
| Scripts | `uv run "${CLAUDE_SKILL_DIR}/../digest/scripts/…"` | `uv run <the digest skill's directory>/scripts/…` |
| PRs     | `git` and `gh` through Bash                        | `git` and `gh` in the shell                       |

## Self-Healing

- **`gh` not logged in or push refused**: leave the worktree, write
  `not done: <the error>` in `## Done`, record no verdict for that line, and
  go on with the rest.
- **The branch exists already**: a PR for this id is open or was. Check with
  `gh pr list --head fix/insights-<id> --state all`; link it as `pending` if
  open, `applied` if merged, instead of opening a second.
- **The fix no longer applies** (the file moved, the rule is there now):
  record `already-done` with what you checked as the reason.

## Rules

- Never merge a pull request, push to a default branch, or change a repo's
  working tree.
- Never record `rejected` for a line `review.py` could not match.
- Never write to `~/.claude/projects/*/memory/`.
- Never add AI attribution to commits, PR titles or bodies.
