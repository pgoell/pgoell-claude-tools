# Pilot Step 5: Subagent dispatch

How pilot hands slices to subagents in step 5 (medium and large lanes). `SKILL.md` keeps the lane branches, the slice gate, and the commit discipline.

**Subagent dispatch (Claude Code):** see `claude-code-adapter.md` for the full pattern. Summary:

- Independent tasks (no shared files, no ordering dependency): multiple `Agent` calls in one message.
- Shared-state tasks: one agent at a time, sequential.
- Trivial polish (rename one symbol, one-line lint fix): main session if files are already loaded; otherwise a subagent.

**Subagent dispatch (Codex):** see `codex-adapter.md`. Use Codex's task or subagent equivalent if installed; else execute tasks sequentially in the main session with explicit context-reset discipline.

**Subagent dispatch (Cursor):** use the `Task` tool with a focused prompt per slice. For independent tasks, send several `Task` calls in one message; shared-state tasks go one at a time. Each `Task` call returns an agent ID; to send work back to the same agent, call `Task` again with that ID and put the feedback in the prompt. Read the `Task` tool's own schema for the names of the agent ID and model fields; name a more capable model only if the schema has a model field. Tool table: `../../using-workbench/references/cursor-tools.md`.

Each subagent prompt must include: the slice text it owns, which files to touch, the relevant commits that preceded it, the acceptance criteria.

**Project-specific rebuild discipline.** When the profile's `## Project-specific rules` requires a rebuild or regen step before tests (for example "rebuild PyO3 binding before pytest"), include that step in the subagent's prompt as an explicit acceptance criterion. Otherwise the subagent observes phantom errors from stale artifacts.
