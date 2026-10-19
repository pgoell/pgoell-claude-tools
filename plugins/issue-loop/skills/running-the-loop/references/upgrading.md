# Upgrading an old loop folder

`init.sh` never overwrites a file, so a loop folder keeps the scripts of the version that made it. Find the version that made the folder and follow its list, top to bottom: each list holds every script that folder needs anew. The README's "After an update to" notes on `/reload-plugins` and `HANDOFF.md` are about the running orchestrator, not the scripts; after the list, do each note for a version newer than the folder, oldest first.

Why the order matters:

- A folder from 0.2.0 or earlier has no standing order, so a brief or a takeover may wait for the user's go. The new `next.sh` refuses to send without the order, so copy `next.sh` and `start.sh` only after the user has run `grant.sh`; until then the old ones keep the loop going, with a go from the user now and then.
- Copy the scripts a step names together, all or none. The old `next.sh` never removes `task.notified`, so a stale line could settle the next task's wait, and the old `notify.sh` never writes it (0.6.0 or earlier: a finished task with its pane scrolled up sits until `STALLED`). The new `wait.sh` with a 0.1.0 `next.sh` says `TIMEOUT` only once ever.
- Take new rule text clause by clause: compare your `rules.md` with `assets/rules.md` and take each new or changed clause. Copying the whole file would drop your `FILL:` answers.

## Made by 0.1.0, 0.2.0, or by hand

1. A hand-made folder with no `loop.env` needs one first: `grant.sh` reads the implementer's name and checkout from it.
2. Run `init.sh` on the folder again. It adds the files the folder lacks: `grant.sh`, `takeover-check.sh` and the two `standing-order` templates, and for a 0.1.0 folder `notify.sh`.
3. Copy `lib.sh` and `driver-herdr.sh` anew from the skill's `assets/`.
4. Go through "The standing order" in `SKILL.md` with the user, who then runs `grant.sh`. Start the implementer anew once, so that it reads the order.
5. Copy `next.sh`, `start.sh`, `notify.sh` and `wait.sh` anew from `assets/`, all four at once.
6. Copy `gate.sh` anew from `assets/`.
7. Take the new clauses from `assets/rules.md` into your `rules.md`. For a 0.1.0 folder that includes rule 19.

## Made by 0.3.0 to 0.6.0

1. Copy `lib.sh`, `start.sh`, `next.sh`, `notify.sh`, `wait.sh` and `gate.sh` anew from the skill's `assets/`, all at once. A folder from 0.3.x also copies `driver-herdr.sh` anew.
2. Take the new clauses from `assets/rules.md` into your `rules.md`.

## Made by 0.6.1 to 0.7.0

1. Copy `gate.sh` anew from the skill's `assets/`. The new gate fails a ticked box that names no test after `Test:` or `Proof:` on its line.
2. Take the new sentence of rule 5 from `assets/rules.md` into your `rules.md`.
