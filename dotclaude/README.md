# dotclaude

My global Claude Code instructions, kept under version control. Not a plugin, and no marketplace lists it.

Link the file into place:

```sh
ln -sf ~/Code/pgoell-claude-tools/dotclaude/CLAUDE.md ~/.claude/CLAUDE.md
```

This repo is public, so private or machine-local sections (work accounts, hosts, credentials paths) go in `~/.claude/CLAUDE.private.md`. `CLAUDE.md` imports that file on its last line, and it stays out of git.

Hooks do not belong here. Put them in the [`guards`](../plugins/guards/) plugin.
