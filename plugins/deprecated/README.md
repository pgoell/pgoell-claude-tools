# deprecated

Archive of superseded skills. They remain installable so old workflows keep resolving, but each skill is frozen, carries a deprecation banner, and names its replacement. Do not extend anything here; new work happens in the replacement plugin.

## Skills and their replacements

| Archived skill                | Moved from        | Replacement                                                                                                                                                              |
| ----------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `crafting-presentations`      | `workbench`       | `presentations:creating-presentations`                                                                                                                                   |
| `perfecting-presentations`    | `workbench`       | `presentations:creating-presentations` (the review loop is folded in as an opt-in phase)                                                                                 |
| `exporting-decks-to-pptx`     | `workbench`       | `presentations:exporting-presentations-to-pptx`                                                                                                                          |
| `presentations`               | `writing`         | `presentations:designing-presentations`                                                                                                                                  |
| `autopilot`                   | `workbench`       | `workbench:pilot` (Gates: none)                                                                                                                                          |
| `copilot`                     | `workbench`       | `workbench:pilot` (Gates: design)                                                                                                                                        |
| `dispatching-parallel-agents` | `workbench`       | `workbench:subagent-driven-development` (Parallel dispatch section)                                                                                                      |
| `terse-mode`                  | `workbench`       | retired without replacement                                                                                                                                              |
| `writing`                     | `writing`         | `writing:ghostwrite` (drafting) and `writing:coach` (learning to write)                                                                                                  |
| `pyramid`                     | `writing`         | `writing:ghostwrite` (pyramid audits) and `writing:coach` (structure drill)                                                                                              |
| `tech-doc`                    | `writing`         | `writing:ghostwrite` (tech docs from the repository)                                                                                                                     |
| `frontend-design`             | `frontend-design` | `taste-skill:taste-skill` in Claude Code, `taste-skill:design-taste-frontend` in Codex; for animation and UI craft in Claude Code, `emil:emil-design-eng` (not in Codex) |

Installing this plugin alongside `presentations` duplicates the triggering surface for deck work; only install it if you need the old skill names.

## Credits

`skills/frontend-design/SKILL.md` comes from the [`frontend-design`](https://github.com/anthropics/skills/tree/ef740771ac901e03fbca3ce4e1c453a96010f30a/skills/frontend-design) skill in Anthropic's `anthropics/skills` repository by Prithvi Rajasekaran and Alexander Bricken, licensed under Apache 2.0. See `NOTICE`, which pins the commit. Original additions in this plugin are MIT (`LICENSE`).
