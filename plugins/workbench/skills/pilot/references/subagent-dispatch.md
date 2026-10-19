# Pilot Step 5: Subagent dispatch

How pilot hands slices to subagents in step 5 (medium and large lanes). `SKILL.md` keeps the lane branches, the slice gate, and the commit discipline.

**Subagent dispatch (Claude Code):** see `claude-code-adapter.md` for the full pattern. Summary:

- Independent tasks (no shared files, no ordering dependency): multiple `Agent` calls in one message.
- Shared-state tasks: one agent at a time, sequential.
- Trivial polish (rename one symbol, one-line lint fix): main session if files are already loaded; otherwise a subagent.

**Subagent dispatch (Codex):** see `codex-adapter.md`. Use Codex's task or subagent equivalent if installed; else execute tasks sequentially in the main session with explicit context-reset discipline.

Each subagent prompt must include: the slice text it owns, which files to touch, the relevant commits that preceded it, the acceptance criteria.

**Project-specific rebuild discipline.** When the profile's `## Project-specific rules` requires a rebuild or regen step before tests (for example "rebuild PyO3 binding before pytest"), include that step in the subagent's prompt as an explicit acceptance criterion. Otherwise the subagent observes phantom errors from stale artifacts.
