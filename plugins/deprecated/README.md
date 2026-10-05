# deprecated

Archive of superseded skills. They remain installable so old workflows keep resolving, but each skill is frozen, carries a deprecation banner, and names its replacement. Do not extend anything here; new work happens in the replacement plugin.

## Skills and their replacements

| Archived skill                | Moved from        | Replacement                                                                              |
| ----------------------------- | ----------------- | ---------------------------------------------------------------------------------------- |
| `crafting-presentations`      | `workbench`       | `presentations:creating-presentations`                                                   |
| `perfecting-presentations`    | `workbench`       | `presentations:creating-presentations` (the review loop is folded in as an opt-in phase) |
| `exporting-decks-to-pptx`     | `workbench`       | `presentations:exporting-presentations-to-pptx`                                          |
| `presentations`               | `writing`         | `presentations:designing-presentations`                                                  |
| `autopilot`                   | `workbench`       | `workbench:pilot` (Gates: none)                                                          |
| `copilot`                     | `workbench`       | `workbench:pilot` (Gates: design)                                                        |
| `dispatching-parallel-agents` | `workbench`       | `workbench:subagent-driven-development` (Parallel dispatch section)                      |
| `terse-mode`                  | `workbench`       | retired without replacement                                                              |
| `writing`                     | `writing`         | `writing:ghostwrite` (drafting) and `writing:coach` (learning to write)                  |
| `pyramid`                     | `writing`         | `writing:ghostwrite` (pyramid audits) and `writing:coach` (structure drill)              |
| `tech-doc`                    | `writing`         | `writing:ghostwrite` (tech docs from the repository)                                     |
| `frontend-design`             | `frontend-design` | `taste-skill:taste-skill` (for animation and UI craft, `emil:emil-design-eng`)           |

Installing this plugin alongside `presentations` duplicates the triggering surface for deck work; only install it if you need the old skill names.

## Credits

`skills/frontend-design/SKILL.md` comes from Anthropic's [`frontend-design`](https://github.com/anthropics/claude-plugins/tree/main/plugins/frontend-design) plugin by Prithvi Rajasekaran and Alexander Bricken, licensed under Apache 2.0. See `NOTICE`. Original additions in this plugin are MIT (`LICENSE`).
