# Directory Update Log

## 2026-10-18

- **Update**: insights 0.4.2. `insights:apply` makes its worktree under `~/Code/.worktrees/<repo>/`, and `activity` and `digest` fold sessions from worktrees there into their repo.
- **Creation**: Started this bundle. Structure follows Diátaxis, file format follows OKF v0.2. The content moved out of `README.md`, which is now a short front page, and each fact was checked against the code on the way.
- **Update**: The cron wrappers of news and insights now all read the periodic folder from `KASTEN_PERIODIC_PATH`; the schedule how-tos say so. `explanation/shared-skills.md` names `bypassPermissions` as the issue-loop default. The Atlassian setup and reference pages were checked against the corrected `acli jira auth` commands in the skills.
