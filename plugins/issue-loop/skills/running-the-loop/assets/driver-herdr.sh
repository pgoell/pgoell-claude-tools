#!/bin/bash
# The herdr driver. This is the only file that knows herdr. To use another
# terminal manager, write these five functions for it and point DRIVER in
# loop.env at your file. Needs: herdr, jq, timeout.

# Type TEXT into session NAME and submit it.
drv_send() { herdr agent prompt "$1" "$2" >/dev/null; }

# Print the state of session NAME: working, idle, done, blocked or unknown.
# Print "gone" when no session has that name.
drv_status() {
  herdr agent list | jq -r --arg n "$1" '[.result.agents[] | select(.name == $n) | .agent_status][0] // "gone"'
}

# Return when session NAME stops working, or after SECONDS, whichever is first.
drv_wait() {
  timeout "$2" herdr agent wait "$1" --until idle --until done --until blocked >/dev/null 2>&1
  true
}

# Print the last LINES lines of a session's screen, one report line per line.
# NAME is a session name, or the handle drv_start printed (a pane id): a
# session that sits on a start dialog has no name yet.
drv_read() {
  herdr agent read "$1" --source recent-unwrapped --lines "$2" 2>/dev/null ||
    herdr pane read "$1" --source recent-unwrapped --lines "$2"
}

# Start a Claude Code session NAME in a new tab with working folder CWD and tab
# label LABEL, in the permission mode from loop.env. Print a handle that
# drv_read accepts (here: the pane id).
drv_start() {
  local pane
  pane=$(herdr tab create ${HERDR_WORKSPACE:+--workspace "$HERDR_WORKSPACE"} --cwd "$2" --label "$3" --no-focus |
    jq -r '[.. | .pane_id? | strings][0] // empty')
  [ -n "$pane" ] || { echo "no pane id from herdr tab create" >&2; return 1; }
  nap 5
  herdr agent start "$1" --kind claude --pane "$pane" -- --permission-mode "${PERMISSION_MODE:-auto}" >/dev/null || return 1
  echo "$pane"
}
