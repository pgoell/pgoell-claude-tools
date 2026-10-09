---
name: apply
description: "Use when the user has reviewed a day's session-insights note in their kasten vault and wants the kept fixes carried out, for example \"apply the insights\", \"I kept 1 and 3, go\", or \"/insights:apply --date 2026-10-08\". Acts only on a note whose \"## Proposed\" was renamed \"## Keep\". Opens a pull request per kept fix where a repository exists (never merges), adds todos to the daily note, adds newspaper feedback lines, records deleted lines as rejections and \"no:\" lines as feedback. Not for finding problems (use insights:digest)."
---

# Apply

Carry out the fixes the user kept in one day's review note. The note is the
only signal: a line kept is a yes, a line deleted is a no, a line starting
`no:` is a no with a reason. An unreviewed note means nothing was decided.

May run headless inside `insights:digest`. Never stop to ask; when a kept fix
cannot be carried out, say why in `## Done` and move on.

## Arguments

`/insights:apply [--vault PATH] [--date YYYY-MM-DD] [--periodic FOLDER]`

Vault and periodic folder resolve as in `../digest/SKILL.md`. The date is the
day the note covers, default yesterday in Europe/Berlin. Below, `ARGS` and
`IN` mean what they mean there.

## Protocol

1. **Read the decision.** `uv run "${CLAUDE_SKILL_DIR}/../digest/scripts/review.py" ARGS` prints `state`,
   `kept`, `no`, `dropped` and `other`. If `state` is `proposed`, stop: the
   note was not reviewed. If it is `done`, stop: it was applied already.
2. **Carry out each kept line**, by its problem's `action`. An `edited` line
   means the user changed the fix: follow their words over the page's.
   - **Opens a PR.** In `target.repo`, read its `AGENTS.md` or `CLAUDE.md`
     first and follow its conventions (branch names, commit format, version
     bumps, formatting, checks). Then:
     ```sh
     git -C "<repo>" fetch origin
     git -C "<repo>" worktree add "/tmp/insights-<id>" -b "fix/insights-<id>" "origin/<default branch>"
     ```
     Make the change from the problem's `fix` in that worktree, run the
     repo's own checks, commit (Conventional Commits, lowercase subject, no
     AI attribution of any kind), `git push -u origin fix/insights-<id>`, and
     `gh pr create` with a body that cites the problem: title, hits, evidence,
     and the page `<periodic>/06 Insights/<date>.html`. No attribution line in
     the body either. Never merge. Remove the worktree afterwards
     (`git -C "<repo>" worktree remove "/tmp/insights-<id>"`). Never touch the
     repo's own working tree.
   - **Adds a todo.** Append `- [ ] <the fix in a few words> #insights ➕ <today>`
     under `## TODOs` in today's daily note (`<periodic>/00 Daily/<today>.md`),
     creating that section at the end when missing. Today means the Berlin
     date of this run.
   - **Adds a feedback line.** Append `- <the fix in plain words> (insights #<id>)`
     under `## Open` in `<periodic>/05 Newspaper/feedback.md`; the next edition
     applies it.
   - **Watch only.** Nothing to do; record it as `watch`.
3. **Record.** Write one JSON list to `/tmp/insights-verdicts-<date>.json`:
   `applied` (with `ref`, the PR URL or "todo" or "feedback") for each kept
   line carried out, `watch` for kept Watch-only lines, `rejected` for every
   `dropped` problem and every `no` line that names an id (with its reason).
   Then `uv run "${CLAUDE_SKILL_DIR}/../digest/scripts/remember.py" ARGS --verdicts /tmp/insights-verdicts-<date>.json`.
4. **Pass on the reasons.** Each `no` line and each `other` line goes under
   `## Open` in `IN/feedback.md` as `- <date> #<id>: <the words>`; the next
   digest turns them into rules.
5. **Close the note.** Append to `IN/<date>.md`:
   ```markdown
   ## Done

   - #<id> -> <PR URL | todo added | feedback line added | watching | not done: why>
   ```
   One line per kept line. This is what stops a second run.
6. **Report**: PRs opened with URLs, todos and feedback lines added,
   rejections recorded, anything not done and why.

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
  `gh pr list --head fix/insights-<id>`; link it instead of opening a second.
- **The fix no longer applies** (the file moved, the rule is there now):
  record `applied` with `ref` "already in place" and say so.

## Rules

- Never merge a pull request, push to a default branch, or change a repo's
  working tree.
- Never write to `~/.claude/projects/*/memory/`.
- Never add AI attribution to commits, PR titles or bodies.
