# Upgrading an old loop folder

`init.sh` never overwrites a file, so a loop folder keeps the scripts of the version that made it. Find the version that made the folder and follow its list, top to bottom: each list holds every copy that folder needs. The README's "After an update to" notes on `/reload-plugins` and `HANDOFF.md` are about the running orchestrator, not the scripts; after the list, do each note for a version newer than the folder, oldest first.

Why the order matters:

- A folder from 0.2.0 or earlier has no standing order, so a brief or a takeover may wait for the user's go. The new `next.sh` refuses to send without the order, so copy `next.sh` and `start.sh` only after the user has run `grant.sh`; until then the old ones keep the loop going, with a go from the user now and then.
- Copy the scripts a step names together, all or none. The old `next.sh` never removes `task.notified`, so a stale line could settle the next task's wait, and the old `notify.sh` never writes it (0.6.0 or earlier: a finished task with its pane scrolled up sits until `STALLED`). The new `wait.sh` with a 0.1.0 `next.sh` says `TIMEOUT` only once ever.
- Take new rule text clause by clause from `assets/rules.md`: copying the whole file would drop your `FILL:` answers.

## Made by 0.1.0

1. Run `init.sh` on the folder again. It adds `notify.sh`, `grant.sh`, `takeover-check.sh` and the two `standing-order` templates.
2. Copy `lib.sh` anew from the skill's `assets/`.
3. Go through "The standing order" in `SKILL.md` with the user, who then runs `grant.sh`. Start the implementer anew once, so that it reads the order.
4. Copy `next.sh`, `start.sh`, `notify.sh` and `wait.sh` anew from `assets/`, all four at once.
5. Copy `gate.sh` anew from `assets/`.
6. Take rule 19 and the new clauses of rules 2, 5, 9, 12 and 14 from `assets/rules.md` into your `rules.md`.

## Made by 0.2.0, or by hand

1. A hand-made folder with no `loop.env` needs one first: `grant.sh` reads the implementer's name and checkout from it.
2. Run `init.sh` on the folder again. It adds `grant.sh`, `takeover-check.sh` and the two `standing-order` templates.
3. Copy `lib.sh` anew from the skill's `assets/`.
4. Go through "The standing order" in `SKILL.md` with the user, who then runs `grant.sh`. Start the implementer anew once, so that it reads the order.
5. Copy `next.sh`, `start.sh`, `notify.sh` and `wait.sh` anew from `assets/`, all four at once.
6. Copy `gate.sh` anew from `assets/`.
7. Take the new clauses of rules 5, 12 and 14 from `assets/rules.md` into your `rules.md`.

## Made by 0.3.0 to 0.6.0

1. Copy `next.sh`, `notify.sh` and `wait.sh` anew from the skill's `assets/`, all three at once.
2. Copy `gate.sh` anew from `assets/`.
3. Take the new sentence of rule 5 from `assets/rules.md` into your `rules.md`.

## Made by 0.6.1 to 0.7.0

1. Copy `gate.sh` anew from the skill's `assets/`. The new gate fails a ticked box that names no test after `Test:` or `Proof:` on its line.
2. Take the new sentence of rule 5 from `assets/rules.md` into your `rules.md`.
