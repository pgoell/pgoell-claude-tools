# The driver

The loop needs something that can type into another terminal session and read its screen. The scripts reach it through five shell functions in one file, named by `DRIVER` in `loop.env`. Everything else in the loop folder is plain `bash`, `gh`, `git`, `jq` and `curl`.

## What any driver must do

Four things, plus a state word that the wait is built on.

| Function                   | Must do                                                                                               |
| -------------------------- | ----------------------------------------------------------------------------------------------------- |
| `drv_send NAME TEXT`       | Type TEXT into session NAME and submit it. TEXT may be many lines (the whole brief)                   |
| `drv_wait NAME SECONDS`    | Return when the session stops working, or after SECONDS. Always return 0                              |
| `drv_read NAME LINES`      | Print the last LINES lines of the session's screen, unwrapped: one report line stays one line         |
| `drv_start NAME CWD LABEL` | Start a Claude Code session with that name and working folder, in the permission mode from `loop.env` |
| `drv_status NAME`          | Print `working`, `idle`, `done`, `blocked` or `unknown`; print `gone` when no session has the name    |

`wait.sh` builds "wait for the DONE token" from `drv_wait`, `drv_read` and `drv_status`: it waits, reads the last 40 lines, looks for `DONE <token>` or `BLOCKED <token>` at the start of a line, and settles only when the state is no longer `working`. So a driver does not need to know about tokens.

Two demands are easy to miss:

- **Unwrapped lines.** `wait.sh` and the go-ahead check match at the start of a line. A driver that returns the screen as wrapped rows breaks the match when the DONE line is long.
- **A state that can say "blocked".** That is how `wait.sh` sees a permission question. A driver without it can print `unknown`; then a waiting session is found only by the clock.

## What is herdr-specific

herdr is a terminal workspace manager with a CLI for agent sessions. Only `driver-herdr.sh` knows it. These are the calls it makes:

```bash
herdr agent list                                                   # JSON; state is .result.agents[].agent_status
herdr agent prompt <name> "<text>"                                 # send
herdr agent wait <name> --until idle --until done --until blocked  # wait, no clock of its own: wrap it in timeout
herdr agent read <name> --source recent-unwrapped --lines <n>      # read
herdr tab create --workspace <id> --cwd <dir> --label "<text>" --no-focus   # new tab, JSON with a pane id
herdr agent start <name> --kind claude --pane <pane id> -- --permission-mode auto
herdr pane read <pane id>                                          # the screen of a pane whose agent is gone
```

Also herdr-specific, and named as such where the skills mention them: tabs, panes and workspace ids; the state words; and the fact that `herdr agent start` reports success even when the session then exits on a start dialog (`references/quirks.md`).

`drv_start` reads the pane id from the JSON that `herdr tab create` prints. The first time you use it on a host, start one session by hand with the commands above and check that the pane id comes out, since that shape belongs to herdr and may change.

## Swapping the driver

Copy `driver-herdr.sh` to `driver-<name>.sh`, rewrite the five functions, set `DRIVER=driver-<name>.sh` in `loop.env`. A tmux sketch, to show the size of the job (untested):

```bash
drv_send()   { tmux send-keys -t "$1" -l "$2"; tmux send-keys -t "$1" Enter; }
drv_read()   { tmux capture-pane -p -J -t "$1" -S "-$2"; }
drv_status() { tmux has-session -t "$1" 2>/dev/null || { echo gone; return; }; echo unknown; }
drv_wait()   { sleep "$2"; }
drv_start()  { tmux new-session -d -s "$1" -c "$2" "claude --permission-mode ${PERMISSION_MODE:-auto}"; }
```

With that sketch `drv_status` cannot tell working from idle, so `wait.sh` settles as soon as the DONE line shows, and it never prints `ASKING`. A better tmux driver would read the screen for the session's own "working" mark.

Test a new driver with the plugin's `tests/run.sh` as a model: it runs every script against a stub driver made of three files.
