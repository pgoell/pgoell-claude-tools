# session-title

A Claude Code hook that names each new session after its folder, git branch and start time, such as `server-infra main 10-18 11:09`. With many sessions a day, the Remote Control list on the phone otherwise shows names that are hard to tell apart.

Claude Code only. The hook uses Claude Code's hook format, so the plugin is not in the Codex marketplace.

## Hooks

### `session-title` (SessionStart, `startup|clear`)

Prints `hookSpecificOutput.sessionTitle`, which Claude Code saves as the session's custom title, the same field `/rename` writes. The title is the last part of the working directory, the current git branch, and the start time as `MM-DD HH:MM`. Without a current branch (no git repo, detached HEAD) the branch is left out: `vault 10-18 11:09`.

The hook runs on a new session and after `/clear`. A resumed session keeps its title. `/rename` still works and overrides it.

Needs `jq` and `git` on the `PATH`.
