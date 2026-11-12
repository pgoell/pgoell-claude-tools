# Shipping Skills in a Plugin Marketplace Repo

Read this when the skill under construction lives in a repo that distributes plugins: a marketplace manifest at the repo root (`.claude-plugin/marketplace.json` for Claude Code, `.agents/plugins/marketplace.json` for Codex) and a directory of plugins. In such a repo, writing SKILL.md is only half the job. The skill must be registered, versioned, and tested the way the host repo expects, or it ships broken (unregistered, version-check failures on push, stale index docs).

Adapted from the `agent-system-management:creating-skills` skill's convention-probe workflow, condensed to the principles.

## Discover conventions before writing

Be discovery-first: resolve the host repo's conventions at runtime from what already exists, and never invent values that existing files can answer. Before creating any file, establish:

- **Marketplace manifests.** Which of the Claude Code and Codex manifests exist. Write entries only into the ones present; a Claude-only repo gets no `.codex-plugin` files.
- **Plugin directory.** Where existing plugins live (`plugins/`, `.claude/plugins/`, ...). Locate it by finding an existing `*/.claude-plugin/plugin.json`.
- **Author and license.** Read both from an existing plugin manifest. Only ask the user when no plugin exists yet.
- **Index docs.** Whether README.md, CLAUDE.md, or AGENTS.md carry a section listing plugins or skills. Update only docs that already index; do not introduce a new index.
- **The lockstep version set.** Grep for an existing plugin's exact version string to find every file that repeats it (plugin manifest, marketplace entry, docs tables). The set's size varies per repo; never assume it is just the manifest.
- **Repo checks.** Format hooks, linters, commit-message conventions (`git log` shows whether Conventional Commits are in use), and any version-bump enforcement in git hooks or CI. Finding these before pushing beats finding them as push failures.

Present the detected conventions to the user in one block and get a confirmation before writing files.

## Wire the skill in

For a skill that starts a **new plugin**:

1. Plugin manifest at `<plugin-dir>/<plugin>/.claude-plugin/plugin.json`: name, version (start at `0.1.0` unless the repo's existing plugins suggest otherwise), description, author and license per the discovered conventions. Codex repos also need `.codex-plugin/plugin.json`.
2. Marketplace entry: add the plugin to the `plugins` array of each marketplace manifest present. Edit the existing file in place; never rewrite it wholesale.
3. Index docs: add a row or section in whatever shape the doc already uses.

For a skill added to an **existing plugin**: no new manifests. Update the plugin's skill list in the index docs, and bump the plugin version.

## Version discipline

Every change to a plugin's contents is a plugin change: creating or editing a skill, fixing a bundled script, even tuning a description. Bump the plugin version with the change. New skills are minor bumps; fixes, docs, and description tuning are patch bumps unless behavior changes materially. Whatever the lockstep set contains, every member must agree after the commit. Repos commonly enforce this with a pre-push hook or CI check, so a forgotten bump surfaces as a blocked push.

## Tests

Two cheap layers, applied when the host repo has (or wants) a test layout. Match the naming and output conventions of whatever tests already exist.

**Structure test** (bash plus `jq`, offline, fast, run per commit). Asserts what `scripts/quick_validate.py` cannot see from inside one skill directory: the plugin manifest parses, its version matches the marketplace entry and the rest of the lockstep set, and each reference file is both present and mentioned in SKILL.md. Run `quick_validate.py` for the per-skill frontmatter and link checks, and keep the repo-level assertions in the structure test.

**Trigger regression test** (slow, one real Claude subprocess per prompt, run at PR time). Verifies the skill still auto-triggers on a realistic prompt after description edits or the arrival of neighboring skills. Keep one prompt file per distinct entry path of the skill, one or two sentences, action-led with a concrete object ("Create a bug ticket in the TEST project about a login error", never "help with jira"). Add a near-miss prompt asserted NOT to trigger when overtriggering is a risk. Drop-in runner:

```bash
#!/usr/bin/env bash
# Usage: run-test.sh [--not] <expected-skill> <prompt-file>
# Verifies Claude auto-triggers (or, with --not, stays quiet on) the expected skill.
set -euo pipefail

NEGATIVE=false
if [ "${1:-}" = "--not" ]; then
    NEGATIVE=true
    shift
fi

EXPECTED_SKILL="$1"
PROMPT="$(cat "$2")"
LOG_FILE=$(mktemp)
trap 'rm -f "$LOG_FILE"' EXIT

plugin_flag=""
if [ -n "${PLUGIN_DIR:-}" ]; then
    plugin_flag="--plugin-dir $PLUGIN_DIR"
fi

if command -v gtimeout &>/dev/null; then _to="gtimeout 60"; elif command -v timeout &>/dev/null; then _to="timeout 60"; else _to=""; fi
# EFFORT: pass the session's effort, so the test matches real use.
status=0
$_to claude -p "$PROMPT" $plugin_flag --effort "${EFFORT:-medium}" --verbose --output-format stream-json > "$LOG_FILE" 2>&1 || status=$?
if [ "$status" -eq 124 ]; then
    # A timeout is no answer: neither a trigger nor a quiet pass.
    echo "  [SKIP] Claude did not answer within 60 seconds"
    exit 2
fi

SKILL_PATTERN="\"skill\":\"([^\"]*:)?${EXPECTED_SKILL}\""
if grep -qE "$SKILL_PATTERN" "$LOG_FILE"; then
    if $NEGATIVE; then
        echo "  [FAIL] Skill '$EXPECTED_SKILL' was triggered"
        exit 1
    fi
    echo "  [PASS] Skill '$EXPECTED_SKILL' was triggered"
else
    if $NEGATIVE; then
        echo "  [PASS] Skill '$EXPECTED_SKILL' was not triggered"
    else
        echo "  [FAIL] Skill '$EXPECTED_SKILL' was NOT triggered"
        exit 1
    fi
fi
```

The grep pattern matches both bare and plugin-namespaced skill names (`"skill":"creating-skills"` and `"skill":"agent-system-management:creating-skills"`). Exit code 2 means Claude did not answer in time: rerun that test, and count it as neither pass nor fail. Trigger tests cost tens of seconds each, so wire them into PR checks, not per-commit hooks.

## Commit conventions

Follow the host repo's commit style. With Conventional Commits, scope by plugin: `feat(<plugin>): add <skill> skill` for new skills, `chore(<plugin>): tune <skill> description` for description work, and keep the version bump in the same commit as the change it versions.
