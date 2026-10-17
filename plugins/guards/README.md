# guards

Claude Code hooks that block shell commands known to fail. Each hook denies the call and tells the agent what to run instead, so the agent fixes the command on the next try rather than losing its shell.

Claude Code only. The hooks use Claude Code's hook format, so the plugin is not in the Codex marketplace.

## Hooks

### `pkill-self-match` (PreToolUse, Bash)

Blocks `pkill -f <pattern>` (also `--full` and combined flags such as `-9f` or `-fx`) when the pattern is plain text.

Claude Code runs each Bash call through a `bash -c` whose command line holds the whole command, pattern included. `pkill -f` matches full command lines, so it matches that shell and kills it. The call ends in "Exit code 144", even with `; true` after it. Over 14 days on one host, 83 Bash calls ended in exit 144, and 44 of them started with `pkill -f`.

The deny message offers two fixes:

- Stop the process by port: `fuser -k 8765/tcp`.
- Bracket the first letter of the pattern: `pkill -f '[u]vicorn app:app'`. The class still matches the process, but the text `[u]vicorn` does not match itself.

The hook also blocks `pgrep -f <pattern>` with a plain pattern when it sits in an `until` or `while` condition, such as `until ! pgrep -f 'capture.sh'; do sleep 5; done`. The `bash -c` running the loop holds the pattern too, so `pgrep` always finds it and the loop never ends. One such loop ran on through a 3-hour capture. The fix is the same bracket: `until ! pgrep -f '[c]apture.sh'`.

`pkill` or `pgrep` without `-f`, bracketed patterns, a one-shot `pgrep -f` outside a loop condition, and every other command pass through untouched. A command the hook cannot parse also passes.
