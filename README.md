# pgoell-claude-tools

A plugin marketplace for Claude Code, Codex and Cursor. Its plugins ship skills, output styles and hooks. Each skill lives in one directory that all three runtimes share, so no skill is copied per runtime. The marketplace lists 25 plugins: 20 kept in this repository, 4 tracked from upstream repositories, and the `deprecated` archive of superseded skills, which the count includes.

## Install

### Claude Code

```
/plugin marketplace add pgoell/pgoell-claude-tools
/plugin install <plugin>@pgoell-claude-tools
```

For example, `/plugin install research@pgoell-claude-tools`.

### Codex

```
codex plugin marketplace add pgoell/pgoell-claude-tools
codex
/plugins
```

### Cursor

Import the repository as a team marketplace or copy a plugin folder; see [Install in Cursor](docs/how-to/install-in-cursor.md).

Skills run as `/<plugin>:<skill>`, for example `/research:research`. Start with the [getting started tutorial](docs/tutorials/getting-started.md). Not every plugin reaches every runtime; [runtimes](docs/reference/runtimes.md) lists which go where and why.

## Plugins

Work tools:

- [atlassian](docs/reference/plugins/atlassian.md): Jira and Confluence.
- [google-workspace](docs/reference/plugins/google-workspace.md): Gmail and Calendar through the `gws` CLI.
- [databricks](docs/reference/plugins/databricks.md): Databricks CLI work and live docs lookups.
- [terminal](docs/reference/plugins/terminal.md): drive interactive terminal programs through tmux.

Workflow:

- [agent-system-management](docs/reference/plugins/agent-system-management.md): audit agent instructions, capture session learnings, create skills.
- [runtime-bridge](docs/reference/plugins/runtime-bridge.md): align Claude Code and Codex project setup.
- [research](docs/reference/plugins/research.md): research a topic and write a sourced report.
- [critique](docs/reference/plugins/critique.md): critique an idea from several independent angles.
- [playground](docs/reference/plugins/playground.md): single-file HTML playgrounds with live preview.
- [file-size](docs/reference/plugins/file-size.md): cap authored files at 5000 tokens on commit, push and CI.

Writing and learning:

- [writing](docs/reference/plugins/writing.md): ghostwrite from your own facts, or get coached to write it yourself.
- [learning](docs/reference/plugins/learning.md): Socratic quizzes and a blind-spot survey before new work.

Decks and diagrams:

- [presentations](docs/reference/plugins/presentations.md): design, build, edit and export slide decks styled by brand presets.
- [diagrams](docs/reference/plugins/diagrams.md): validated, themeable architecture and flow diagrams as HTML.

Daily pages:

- [news](docs/reference/plugins/news.md): a personal daily newspaper in a kasten vault.
- [insights](docs/reference/plugins/insights.md): what went wrong in yesterday's sessions, and what the agents did.

Claude Code only:

- [issue-loop](docs/reference/plugins/issue-loop.md): one session drives another through a repo's GitHub issues.
- [prose-styles](docs/reference/plugins/prose-styles.md): output styles for prose (`orwell`, `concise`, `ste`, `house`).
- [guards](docs/reference/plugins/guards.md): a hook that blocks shell commands known to fail.
- [session-title](docs/reference/plugins/session-title.md): a hook that names each session after folder, branch and start time.

Tracked from upstream, not vendored:

- [ponytail](docs/reference/plugins/ponytail.md): pushes for the simplest solution that works.
- [emil](docs/reference/plugins/emil.md): Emil Kowalski's UI polish and animation skills.
- [taste-skill](docs/reference/plugins/taste-skill.md): frontend design skills against generic output.
- [vercel](docs/reference/plugins/vercel.md): Vercel's React, Next.js and deploy skills.

Archive:

- [deprecated](docs/reference/plugins/deprecated.md): superseded skills kept for old workflows, each pointing at its replacement.

## Documentation

The [documentation](docs/index.md) holds tutorials, setup guides, reference pages and explanations. [`dotclaude/`](dotclaude/README.md) holds the maintainer's global Claude Code instructions and is not a plugin. [AGENTS.md](AGENTS.md) holds the conventions for contributors.
