# The wait, in detail

Step 3 of "One turn of the loop" in `SKILL.md` runs `wait.sh` in the background and acts on the word it prints. This page holds what that step needs past the table: how `wait.sh` watches after `TIMEOUT`, and how the implementer's own word reaches you.

## Past the time limit

`wait.sh` says `TIMEOUT` once per task. Started again, it watches on at the same pace with no limit, so a task that ends at minute 104 is seen at minute 105. Do not stand in for it with a loop of your own: such a loop once polled too seldom, and a finished task sat unseen. If you must write one, it polls at least every 30 seconds. The clock is yours as well: each time the shell call ends with no word, look at the task's age (`task.start` holds the start), also when you never saw a `TIMEOUT` yourself. At 130 minutes stop the task and tell the user.

## The implementer's own word

By rule 19 of the brief the implementer runs `notify.sh` as its last tool call, and one line lands in your tab: `impl settled: DONE #41` (or `BLOCKED #41: reason`). The line comes before the report: the implementer still has to write it, so its state is `working` for a minute more and the DONE line is not on the screen yet. `notify.sh` also writes the line to `task.notified` in the loop folder, sent or not, and `wait.sh` settles on that file once the implementer no longer works: a pane scrolled up hides the DONE line from the screen read. `wait.sh` stays the fallback, since the line may never come. Only `next.sh` removes the file, so when you send the implementer more words within the same task (after a `BLOCKED`, `ASKING` or `STALLED`), run `rm -f task.notified` before you start `wait.sh` again: an old line with this task's token would settle the new wait at the first pause.

## The other words

| Word      | Meaning                              | Do                                                                                                                                                  |
| --------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TIMEOUT` | the task is older than 100 minutes   | read the screen first. In merge or deploy: let it finish. Else send "finish by rule 10 now" once. Then start `wait.sh` again at once                |
| `ASKING`  | the session waits on a question      | read the screen. See "Permission mode" in `SKILL.md`                                                                                                |
| `STALLED` | no work for 20 minutes, no DONE line | read the screen. If the last line is an API error, send "carry on where you stopped" once. If a suite run or a CI wait shows, start `wait.sh` again |
| `GONE`    | no session has that name             | the session died. Tell the user; start a new one with `start.sh` once the checkout is clean                                                         |
