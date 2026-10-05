# Cutting a skill

Adapted from swyx's `skill-cutter` (MIT). Read this when the user asks to cut, trim, shorten, simplify, or de-slop a skill, or to make it trigger less eagerly. A long skill alone is not a reason to cut it.

The goal is lower context cost and fewer false triggers, with every behavior the skill exists for still intact. Line count is evidence, not the target.

## Mode

- **Audit:** the user asks for a review or for candidate cuts. Report; edit nothing.
- **Cut:** the user asks to cut. Edit files inside that skill only. Commit, push, and edits to other skills or consumers still need their own request.

## Find the behavioral core

Read the whole `SKILL.md`, its frontmatter, and only the references it routes to for the tasks in question. Then write down two lists:

1. The concrete requests that should trigger the skill.
2. The decisions a capable agent would get wrong without it.

Anything that serves neither list is a cut candidate.

## Classify before cutting

Sort each rule by how binding it is:

| Force                 | Treatment                                           |
| --------------------- | --------------------------------------------------- |
| Invariant             | Keep, stated narrowly.                              |
| Required for one task | Keep, scoped to that task.                          |
| Gate tied to a risk   | Name the risk and the proof it needs; nothing more. |
| Recommendation        | Mark as optional, or condense.                      |
| Nice-to-have          | Move off the main path, or delete.                  |

Then sort each passage by content:

| Content                                                    | Default                                                   |
| ---------------------------------------------------------- | --------------------------------------------------------- |
| Non-obvious domain constraint, or a fragile required order | Keep                                                      |
| Useful optional expert advice                              | Condense, mark optional                                   |
| General knowledge, ordinary engineering advice             | Delete                                                    |
| Rule already enforced by system or repo instructions       | Delete                                                    |
| Duplicate instruction or example                           | Keep the clearest one                                     |
| Project- or incident-specific rule in a general skill      | Move or delete                                            |
| Stale, unverifiable, or overclaimed fact                   | Verify, qualify, or delete                                |
| Detail one variant needs                                   | Move to a reference the skill loads only for that variant |

Record which row justified each material keep, move, or delete. Never dress up a house preference as a provider or tool requirement.

## Check the gates

```text
user outcome + higher-level invariants + risks the action creates
  = blocking acceptance criteria. Everything else is advice.
```

Flag text that:

- turns a recommendation into a checklist step;
- asks a broken component to approve its own repair;
- coordinates work that is unrelated or read-only;
- keeps gathering proof after the outcome is already established.

For a bounded task, more than one or two gates added by the skill each need a direct correctness, privacy, security, data-integrity, or irreversible-action reason.

## Narrow the trigger

The frontmatter `description` sits in context on every turn and decides routing. Make it narrow and concrete:

- name the user intents and artifacts that should fire it;
- drop "any task", "all requests", and bare product-name triggers unless the skill really should fire on everything;
- add short exclusions for nearby tasks that should not fire it;
- keep every trigger rule in the description, since the body loads only after activation;
- in this repo, keep `.codex-plugin/plugin.json` `interface` text in line with the narrowed description.

Do not narrow so far that explicit requests stop matching. Confirm with the trigger eval in Description Optimization.

## Apply the cut

Prefer deletion to compression.

Keep:

- task-specific decision rules and failure modes;
- domain safety and permission boundaries;
- exact tool or file contracts that are easy to misuse;
- routing to references the skill needs only under some conditions;
- controls on exact targets, permissions, privacy, secrets, user data, migrations, rollback, and irreversible actions, wherever that risk exists.

Delete:

- explanations aimed at a novice human, which the agent already knows;
- full product catalogs, copied manuals, speculative edge cases;
- ceremony that fits only one project or incident;
- repeated summaries, principles, checklists, and completion language;
- history that does not change what the agent does next;
- side improvements dressed up as prerequisites.

Do not keep text because it is correct. Do not swap readable instructions for dense slogans. Do not move bulk into references to make `SKILL.md` look shorter. Do not delete scripts, assets, or references because they look unused; find their callers first.

For a provider claim that may have changed, check current primary docs.

## Prove nothing broke

A cut is a skill edit, so run the iteration loop from `SKILL.md` with the pre-cut version as baseline (snapshot it first). Pass rate must hold; tokens and time should fall. If the description changed, run the trigger eval too. A cut that loses a passing assertion is wrong, however much it saved.

## Report

- before and after: lines, words, files;
- the behavioral contract that remains;
- a short keep, condense, move, delete table with reasons;
- trigger changes and new exclusions;
- validation run, with results;
- material left alone on purpose because its value was unclear.

For an audit, also state the stop condition and why each remaining gate is required or tied to a risk.
