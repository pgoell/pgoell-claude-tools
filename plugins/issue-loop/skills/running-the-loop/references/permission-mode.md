# Questions a session stops on

"Permission mode" in `SKILL.md` sets how the loop's sessions start. A session may still stop on a question. There are two kinds, and they get different answers:

- **The go-ahead question** about a pasted brief or a takeover ("your message was only a pasted block", `Reply "go"`, `Confirm with one word ("go")`, or a menu whose first item runs the brief). With the standing order in place it should be rare. "go" is the user's word: you and the scripts may say it only for what the standing order covers, which is a brief that `next.sh` sent and a takeover that `takeover-check.sh` passes. `next.sh` and `start.sh` answer it for those: `start.sh` only for a session that `HANDOFF.md` names as the successor, started in the loop folder, and neither for a screen that says `TAKEOVER FAIL` or `STOPPED`. If it shows up later for the same brief or takeover, answer it the same way. A session that wants a go for anything else (a side session's first message, a wider task, a merge the rules reserve) gets no "go" from you: tell the user.
- **A tool permission question** (only with `PERMISSION_MODE=auto`), or a hook that refused a command. This is not yours to approve. Read the screen, tell the user what the session wants and why, and wait for the user's answer. If the session can do the task another way, tell it to, or tell it to end with BLOCKED.

`references/quirks.md`, "The go-ahead question", tells how the question came about and how the scripts spot it.
