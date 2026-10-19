# Codex Adapter for Workbench Pilot

This doc maps the pilot skill's tool references to Codex equivalents. The pilot `SKILL.md` uses Claude Code tool names by default; this adapter is consulted when the runtime is Codex. Cursor readers: see the Cursor paragraph in `subagent-dispatch.md`.

## Tool name mapping

| `SKILL.md` reference            | Codex equivalent                                                                                                 |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `Skill`                         | `skill`                                                                                                          |
| `Agent` (subagent)              | Codex's task or subagent equivalent if installed; otherwise sequential execution in the main session (see below) |
| `Monitor`                       | `run_in_background` plus a polling loop, or Codex's monitoring primitive if present                              |
| `Bash`, `Read`, `Write`, `Edit` | Equivalent Codex tools (see `../../using-workbench/references/codex-tools.md` for the broader table)             |
| `gh`                            | Same; invoked via the shell tool                                                                                 |

## Subagent strategy on Codex

`workbench:subagent-driven-development` is best-effort on Codex. The pilot skill expects a fresh subagent per slice or bounded task (a plan task that is not itself a slice; see `SKILL.md` step 5). If Codex's runtime exposes such a primitive, use it. If it does not, fall back to **sequential execution in the main session with explicit context-reset discipline**:

1. Treat each slice or bounded task as its own logical scope.
2. Before starting one, write a one-line context-reset note: `--- starting slice <n>: <title> ---` (a bounded task keeps its slice number). This is for legibility, not behavior.
3. Execute it end-to-end (write code, run tests, commit) before moving to the next.
4. After completing it, write a one-line note: `--- completed slice <n> ---`.
5. Continue with the next slice or bounded task.

Sequential fallback gives up parallel fanout but preserves the per-slice discipline of subagent-driven-development.

## Slice-gate pausing (the `slices` gate)

When the `slices` gate is active, pause after each slice's or bounded task's review gates pass: present the diff summary and stop issuing further actions until the user responds, using whatever mechanism Codex uses to yield control back to the user (the Codex equivalent of Claude Code ending its turn). Do not simulate the user's approve or resteer decision.

## CI polling shape (step 8)

Use `run_in_background` to launch the polling loop, or Codex's monitoring primitive if it has one. The query is the same:

```bash
gh pr view <pr> --json statusCheckRollup -q '.statusCheckRollup[] | "\(.status):\(.conclusion // "")"'
```

Loop with a sleep interval that respects Codex's runtime budget; aim for 30-60 seconds between polls during normal CI runs.

## Subagent error recovery

If Codex's subagent primitive errors, recover the same way as Claude Code: from the main session, inspect partial work via `git status` / `git diff`, continue in the main session if the partial work survived, note "Continuing from subagent state" in the next commit body.

## Common Codex caveats

- **No `Monitor` equivalent in some runtimes.** Use the polling fallback; do not skip step 8.
- **Tool names are case-sensitive.** `skill` is lowercase on Codex; `Skill` is uppercase on Claude Code.
- **Same `gh` and `git` semantics.** GitHub CLI behavior is identical; Conventional Commits enforcement still applies.

## What this adapter does NOT cover

- A live Codex CI test of pilot's flow; runtime-parity validation remains future work.
- Auto-detection of which runtime is active inside `SKILL.md`. The agent reads the appropriate adapter doc based on the runtime they know they are running in.

## See also

- `SKILL.md`: the pilot orchestration.
- `claude-code-adapter.md`: the Claude Code side.
- `../../using-workbench/references/codex-tools.md`: broader Codex tool table.
