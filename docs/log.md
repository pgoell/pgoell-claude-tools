# Directory Update Log

## 2026-10-18

- **Update**: `reference/plugins/deprecated.md` and `explanation/ports-and-licenses.md`: the archived `frontend-design` port now links `anthropics/skills` at a pinned commit instead of the dead `anthropics/claude-plugins` repo (deprecated 0.4.2).
- **Update**: `explanation/ports-and-licenses.md`: the archived `frontend-design` port's `NOTICE` predates the SHA rule and pins no commit, and its dash claim now rests on the archived file, not on an unpinned upstream.
- **Update**: `explanation/the-deprecated-archive.md`: only the `frontend-design` `LICENSE` moved into `deprecated`; its `NOTICE` there is a new file that carries over the skill's attribution block.
- **Update**: `explanation/ports-and-licenses.md`: the port attribution paragraph names `playground` as its live example, not the retired `frontend-design`, which lives on only in `deprecated`.
- **Update**: `explanation/repo-conventions.md`: the em-dash debt count is fourteen files, as the grep finds, and the invocation audit grep lists every plugin with skills instead of the retired `frontend-design`.
- **Update**: insights 0.4.2. `insights:apply` makes its worktree under `~/Code/.worktrees/<repo>/`, and `activity` and `digest` fold sessions from worktrees there into their repo.
- **Creation**: Started this bundle. Structure follows Diátaxis, file format follows OKF v0.2. The content moved out of `README.md`, which is now a short front page, and each fact was checked against the code on the way.
- **Update**: The cron wrappers of news and insights now all read the periodic folder from `KASTEN_PERIODIC_PATH`; the schedule how-tos say so. `explanation/shared-skills.md` names `bypassPermissions` as the issue-loop default. The Atlassian setup and reference pages were checked against the corrected `acli jira auth` commands in the skills.
- **Update**: The history and reasons behind each design decision moved out of `AGENTS.md`, which now holds only the rules, into `explanation/`. New pages: `versions-and-lockstep.md`, `repo-conventions.md`, `ports-and-licenses.md`, `html-producers-presets-and-themes.md`, `skill-design-patterns.md`, `workbench-routing.md`. `shared-skills.md`, `external-and-vendored-plugins.md`, `the-deprecated-archive.md` and `plugins-without-skills.md` gained sections for the decisions they already covered.
- **Update**: `set-up-atlassian.md` and `reference/plugins/atlassian.md`: the Confluence skill uses curl only; acli serves the Jira skill.
