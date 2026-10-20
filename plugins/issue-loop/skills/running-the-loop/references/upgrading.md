# Upgrading a loop folder

From 0.9.0 a loop folder holds its data and eight stubs. A stub is one file, copied under each script's name. It runs the same script from the installed plugin, so a plugin update reaches the folder with no copying. The loop's own rule answers live in `rules.local.md`, next to the plugin's rules.

Any folder made before 0.9.0 needs one upgrade, whatever version made it, and a folder made by hand too. Run it between tasks: a `wait.sh` still running keeps its old file, since `upgrade.sh` replaces files by rename, and the next brief comes from the new `next.sh`.

1. A hand-made folder with no `loop.env` needs one first. Copy `assets/loop.env` into the folder and fill in the implementer's name and checkout.
2. Run the upgrade as a dry run. The script is `scripts/upgrade.sh` in the plugin root, the folder that `next.sh` names in its exit-3 message. Outside a session, use `~/.claude/plugins/cache/pgoell-claude-tools/issue-loop/<version>/skills/running-the-loop/scripts/upgrade.sh`, with the version that `installed_plugins.json` names. In a session, use `${CLAUDE_SKILL_DIR}/scripts/upgrade.sh`:

   ```bash
   ~/.claude/plugins/cache/pgoell-claude-tools/issue-loop/<version>/skills/running-the-loop/scripts/upgrade.sh ~/loops/<project>
   ```

   Without a flag it prints what it would change and changes nothing.
3. Check the plan with the user.
4. Run the same command with `--apply`, once.

The plan lists these changes:

- Each script that a stub replaces, `lib.sh` included. The old file moves to `before-upgrade/`.
- `driver-herdr.sh`. It moves to `before-upgrade/`, since the plugin's copy runs now.
- An old full `rules.md`. Its `FILL:` answers go to `rules.local.md`, and the file moves to `before-upgrade/rules.md`. Before it writes, upgrade builds the brief from `rules.local.md` and compares it with the old `rules.md`. If they differ, it prints the difference and changes nothing.
- `ISSUE_LOOP_VERSION=latest` in `loop.env`, if the line is missing.
- `models.env`, if the folder has none. Check its values with the user.

A rerun keeps each earlier copy in `before-upgrade/` under a new name, `NAME.2` and so on. A second run on an upgraded folder changes nothing and says so.

Upgrade prints a warning when `next.sh` would refuse the result: a rule 3 kept whole without `{{CODER_MODEL}}` or `{{REVIEW_MODEL}}`, or a `FILL:` without an answer. Fix that in `rules.local.md` before the next task.

After the upgrade, edit `rules.local.md`, never `rules.md`. The orchestrator also rewrites the lines of `HANDOFF.md` that tell a successor to edit `rules.md` or to copy scripts. Upgrade never touches HANDOFF files.

Upgrade never touches `CLAUDE.md`, `CLAUDE.local.md`, the `HANDOFF` files, `ledger.tsv`, `orch-name`, the `task.*` files, or a custom driver. A custom driver stays where it is, and `DRIVER` in `loop.env` still names it.

To go back, move the files in `before-upgrade/` back into the folder under their names, and delete the stubs and `rules.local.md`.

Rules kept whole: upgrade prints "rule N: kept whole" for each rule of yours that differs from the plugin's rule beyond its `FILL:` answers. That rule no longer takes plugin changes. To take the plugin's rule again, delete its `## N` section in `rules.local.md` and answer its `FILL:` marks again as `## N.K` sections.

Rolling back a bad release: set `ISSUE_LOOP_VERSION` in `loop.env` to an exact version of 0.9.0 or later, such as `0.9.0`. A pin to an older version is refused, since those versions cannot run a folder of stubs. That version's folder must still be in the plugin cache. Claude Code marks old versions with `.orphaned_at` and may remove them. A missing version makes the stub exit 3 and list the versions it found. Set `latest` to return to the newest. `next.sh` takes the version once per task, so a changed pin applies from the next task.

A folder from 0.2.0 or earlier has no standing order. After the upgrade, the user runs `grant.sh` through its stub, in a terminal of their own, as `SKILL.md` describes. Until then `next.sh` refuses to send a brief.
