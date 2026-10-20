# Pilot pull request: body and PR-behavior modes

Two parts of pilot's PR work that `SKILL.md` links to: the PR body pilot writes in step 7, and the step 9 procedures for the two `Mode` values that do more than stop (`automerge` and `request_review`). `SKILL.md` keeps the push, `gh pr create`, the CI loop, the `stop_at_green` default, and the "don't merge" override.

## PR body (step 7)

- PR body structure: `## Summary` (1-3 bullets), then scope or non-goals if relevant, `## Reading guide`, `## Test plan` checklist, links to spec (or design preamble) + plan + ADR if present.
- `## Reading guide` is always present, in every lane: one line per slice or bounded task, in review order, naming what to look at and what verification already proved. In the quick lane (no slices), it degenerates to one line covering the whole change.

## `automerge` (step 9)

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

## `request_review` (step 9)

- `gh pr ready <pr>`.
- Post a one-line reviewer note as a PR comment.
- Stop. Report the PR URL.
