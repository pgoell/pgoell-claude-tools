# Platform Mechanics

How the platforms that run skills (Claude Code, claude.ai, the API code execution tool) discover, load, render, and constrain them. Read this when picking frontmatter beyond `name` and `description`, deciding where a skill lives, bundling scripts, diagnosing triggering, or preparing a claude.ai upload.

Facts are drawn from the Claude Code skills documentation (code.claude.com/docs/en/skills) and the claude.ai custom-skills article (support.claude.com, article 12512198), as of July 2026. Version gates are noted where recent Claude Code releases changed behavior.

Contents: [Where skills live](#where-skills-live-claude-code) | [Invocation states](#invocation-states-claude-code) | [Frontmatter reference](#frontmatter-reference-claude-code) | [Arguments and substitutions](#arguments-and-substitutions) | [Dynamic context injection](#dynamic-context-injection) | [Content lifecycle](#skill-content-lifecycle-claude-code) | [Triggering and the listing](#triggering-and-the-skill-listing-claude-code) | [Portability and platform limits](#portability-and-platform-limits) | [Canonical sources](#canonical-sources)

## Where skills live (Claude Code)

| Level      | Path                               | Applies to                     |
| ---------- | ---------------------------------- | ------------------------------ |
| Enterprise | managed settings                   | all users in the organization  |
| Personal   | `~/.claude/skills/<name>/SKILL.md` | all of the user's projects     |
| Project    | `.claude/skills/<name>/SKILL.md`   | this project only              |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`  | wherever the plugin is enabled |

- Same-name precedence: enterprise overrides personal, personal overrides project, and a skill at any level overrides a bundled skill of the same name. Plugin skills are namespaced (`plugin-name:skill-name`), so they never conflict with other levels. A skill beats a `.claude/commands/` file of the same name.
- **The typed `/command` comes from the directory name**, not the frontmatter `name`, which is a display label only. The one exception is a plugin-root `SKILL.md`, where frontmatter `name` sets the command (fallback: the plugin directory name). Name the directory with the same care as the description: it is the invocation surface.
- Monorepos: project skills also load from `.claude/skills/` in every parent directory up to the repository root, and nested `.claude/skills/` below the working directory are discovered on demand when Claude works on files there. A nested skill that clashes with another name gets a directory-qualified command (`apps/web:deploy`); its description is annotated with the directory it applies to, and Claude picks the variant matching the files it is working on. Invoking the unqualified name loads the root skill plus an appended list of the qualified variants (v2.1.203+).
- Live reload: Claude Code watches the personal, project, and `--add-dir` skill directories, so adding, editing, or removing a skill there takes effect within the current session. Plugin skill directories are not watched; run `/reload-plugins` after editing those. A top-level skills directory created after session start needs a restart. This matters for the iteration loop: edits to personal and project skills are testable immediately.

## Invocation states (Claude Code)

Three states, controlled by two frontmatter fields:

| Frontmatter                      | User can invoke | Claude can invoke | Description in context |
| -------------------------------- | --------------- | ----------------- | ---------------------- |
| (default)                        | yes             | yes               | every turn             |
| `disable-model-invocation: true` | yes             | no                | no                     |
| `user-invocable: false`          | no              | yes               | every turn             |

- `disable-model-invocation: true` also blocks programmatic invocation through the Skill tool, prevents the skill from being preloaded into subagents, and (v2.1.196+) stops scheduled tasks from firing with the skill as their prompt.
- `user-invocable: false` changes menu visibility only, nothing else: it is for background knowledge that is not actionable as a command (a `legacy-system-context` skill, say, where `/legacy-system-context` is not a meaningful action). It does not block Skill-tool access; use `disable-model-invocation` for that.

## Frontmatter reference (Claude Code)

All fields are optional in Claude Code. `description` is recommended (without it, the first paragraph of the body is used for matching), and `name` defaults to the directory name. claude.ai uploads, by contrast, require both `name` and `description` (see [Portability and platform limits](#portability-and-platform-limits)).

Beyond `name`, `description`, `disable-model-invocation`, and `user-invocable`:

| Field              | Effect                                                                                                                                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `when_to_use`      | Extra trigger context (phrases, example requests) appended to the description in the skill listing; counts toward the same 1,536-character cap                                                                                       |
| `argument-hint`    | Autocomplete hint for expected arguments, e.g. `[issue-number]` or `[filename] [format]`                                                                                                                                             |
| `arguments`        | Declares named positional arguments for `$name` substitution; names map to positions in order                                                                                                                                        |
| `allowed-tools`    | Tools Claude may use without permission prompts while the skill is active. A grant, not a restriction: every other tool stays callable under normal permission rules. For project skills it takes effect only after workspace trust  |
| `disallowed-tools` | Tools removed from Claude's pool while the skill is active (e.g. `AskUserQuestion` for an autonomous loop); the restriction clears on the next user message                                                                          |
| `model`            | Model override while the skill is active, for the rest of the current turn only; accepts `/model` values or `inherit`                                                                                                                |
| `effort`           | Reasoning-effort override (`low` to `max`) while the skill is active. Including the word `ultrathink` anywhere in the body likewise requests deeper reasoning                                                                        |
| `context`          | Set to `fork` to run the skill in an isolated subagent: the body becomes the subagent's prompt, with no access to conversation history. Only meaningful for explicit task instructions; a guidelines-only skill forked returns noise |
| `agent`            | Subagent type for `context: fork`: `Explore`, `Plan`, `general-purpose` (the default), or any custom agent. Explore and Plan skip CLAUDE.md and git status to keep their context small                                               |
| `hooks`            | Hook configuration scoped to the skill's lifecycle: the deterministic enforcement route when instructions alone do not hold                                                                                                          |
| `paths`            | Glob patterns; the skill auto-loads only when Claude works on matching files. Deterministic scoping that no amount of description wording achieves                                                                                   |
| `shell`            | `bash` (default) or `powershell` for [dynamic context injection](#dynamic-context-injection) commands; `powershell` targets Windows and requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`                                                 |

## Arguments and substitutions

Skills are parameterizable. When invoked as `/skill-name foo bar`, the argument text substitutes into the body:

| Placeholder             | Expands to                                                                                                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$ARGUMENTS`            | the full argument string as typed                                                                                                                                                                 |
| `$ARGUMENTS[N]`, `$N`   | the Nth argument, 0-based, with shell-style quoting (`"hello world"` counts as one argument)                                                                                                      |
| `$name`                 | named positionals declared in the `arguments` frontmatter field, mapped in order                                                                                                                  |
| `${CLAUDE_SKILL_DIR}`   | the directory containing `SKILL.md`. **Always use this for bundled script paths** (`python3 ${CLAUDE_SKILL_DIR}/scripts/helper.py`) so the path survives installation at any level or as a plugin |
| `${CLAUDE_PROJECT_DIR}` | the project root (v2.1.196+); also resolves inside `allowed-tools` rules, so a permission rule can match the same path the body uses                                                              |
| `${CLAUDE_SESSION_ID}`  | the current session id, for logging and session-scoped files                                                                                                                                      |
| `${CLAUDE_EFFORT}`      | the current effort level, for effort-adaptive instructions                                                                                                                                        |

If the body contains no `$ARGUMENTS`, arguments are appended to the rendered content as `ARGUMENTS: <value>`, so the agent still sees them. Escape a literal dollar sign before a digit, `ARGUMENTS`, or a declared argument name with a backslash (`\$1.00`).

## Dynamic context injection

In Claude Code, a `` !`command` `` placeholder in the skill body runs at render time, before Claude sees anything; the command's output replaces the placeholder. This is preprocessing, not a tool call: fresh git state, PR data, or environment info arrives already inlined, costing zero agent turns.

- The inline form is recognized only when `!` starts a line or follows whitespace. Multi-line commands use a fenced code block opened with `` ```! ``.
- Substitution is a single pass: command output is not re-scanned for further placeholders.
- The `shell` frontmatter field selects `bash` (default) or `powershell` (Windows, requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`).
- Execution is not guaranteed: the `disableSkillShellExecution` setting (typically deployed as managed policy) replaces each command with a policy notice instead of running it. A skill that relies on injection should still read sensibly when the output is missing.
- Eval note: an injection-using skill renders differently on every run. With-skill eval runs are only comparable when the injected state (the diff, the PR) is pinned by the test setup.

## Skill content lifecycle (Claude Code)

- Invoked skill content enters the conversation as a single message and stays there for the rest of the session. The file is not re-read on later turns, so write guidance that must apply throughout a task as standing instructions, not one-time steps.
- Re-invoking a skill whose rendered content is unchanged adds a short "already loaded" note instead of a second copy (v2.1.202+). Changed arguments or new injection output append the full content again.
- Auto-compaction keeps the first 5,000 tokens of each invoked skill, under a combined 25,000-token budget filled most-recent-first; older skills can drop out entirely. Put the rules that must survive a long session early in the body.
- If a skill seems to stop influencing behavior mid-session, the content is usually still in context and the model is simply preferring other approaches. Strengthen the description and instructions, enforce deterministically with skill-scoped hooks, or re-invoke the skill after compaction. Check this mechanical explanation before rewriting the skill's wording.

## Triggering and the skill listing (Claude Code)

The listing Claude sees contains every skill's name plus its description (and `when_to_use`), and it is budgeted:

- The combined `description` plus `when_to_use` text is truncated at 1,536 characters per skill in the listing (a configurable default, `skillListingMaxDescChars`). Front-loading the key use case is therefore a hard requirement, not a style preference: anything past the cut simply never reaches the model.
- The whole listing gets a budget of roughly 1% of the model's context window (also a configurable default, `skillListingBudgetFraction`). On overflow, descriptions are dropped starting with the least-invoked skills, so a lightly used skill can lose its description entirely. `/doctor` estimates the listing's context cost; the Skills row in `/context` shows the post-budget size.
- Malformed frontmatter YAML fails silently: the body loads with empty metadata, so `/skill-name` still works but Claude has no description to match against and the skill never auto-triggers. This is the first thing to check when a skill that should trigger never does (`claude --debug` shows the parse error).
- For skills tied to particular files, the `paths` field scopes auto-loading deterministically and spends no description budget doing it.

## Portability and platform limits

Skills follow the Agent Skills open standard (agentskills.io), which works across multiple AI tools. Claude Code extends the standard, and skills leaning on the extensions are not portable to other consumers (claude.ai custom skills, Codex, other tools):

- Claude Code extensions: invocation control (`disable-model-invocation`, `user-invocable`), forked execution (`context: fork`, `agent`), dynamic context injection, and the execution overrides (`model`, `effort`, `hooks`, `paths`, `disallowed-tools`). A skill meant to travel treats these as progressive enhancement, or avoids them. `allowed-tools` is in the agentskills.io spec itself, but marked experimental, and support varies between platforms.

**claude.ai custom skills** (uploaded as a zip; the `.skill` files emitted by `package_skill.py` are this shape):

- `name` (64 characters maximum) and `description` (200 characters maximum) are required. The 200-character cap is far tighter than the 1,024-character spec limit, so a description that validates for Claude Code can still exceed claude.ai's limit. Target the tightest platform the skill ships to.
- The documented dependency field is `dependencies` (for example `python>=3.8, pandas>=1.5.0`), where the agentskills.io spec uses the advisory `compatibility` field.
- Archive structure: the zip must contain the skill folder as its root, never loose files, and the folder name must match the skill name.

  ```text
  my-skill.zip
  └── my-skill/
      ├── SKILL.md
      └── scripts/, references/, ...
  ```

- Requires code execution to be enabled; skills are then enabled per skill under Customize > Skills. Available on all plans.
- Post-upload, verify triggering manually: try several prompts that should trigger the skill, check Claude's thinking to confirm it loads, and iterate on the description when it misses.

**API code execution skills**: packages cannot be installed at runtime; every dependency must be pre-installed in the container. Claude Code and claude.ai can install packages (PyPI, npm) when a skill runs; the API cannot. Bundled scripts that must run there should stick to the standard library or vendor what they need.

## Canonical sources

- Agent Skills open standard and evaluation guide: https://agentskills.io
- Claude Code skills reference: https://code.claude.com/docs/en/skills
- Anthropic skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Example skills to use as templates: https://github.com/anthropics/skills/tree/b9e19e6f44773509fbdd7001d77ff41a49a486c1
