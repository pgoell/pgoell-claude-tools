# deprecated

Archive of superseded and retired skills. They remain installable so old workflows keep resolving, but each skill is frozen, carries a deprecation banner, and names its replacement or says it retired without one. Do not extend anything here; new work happens in the replacement plugin.

## Skills and their replacements

| Archived skill                   | Moved from        | Replacement                                                                                                                                                              |
| -------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `crafting-presentations`         | `workbench`       | `presentations:creating-presentations`                                                                                                                                   |
| `perfecting-presentations`       | `workbench`       | `presentations:creating-presentations` (the review loop is folded in as an opt-in phase)                                                                                 |
| `exporting-decks-to-pptx`        | `workbench`       | `presentations:exporting-presentations-to-pptx`                                                                                                                          |
| `presentations`                  | `writing`         | `presentations:designing-presentations`                                                                                                                                  |
| `autopilot`                      | `workbench`       | retired without replacement (its successor `pilot` is archived too)                                                                                                      |
| `copilot`                        | `workbench`       | retired without replacement (its successor `pilot` is archived too)                                                                                                      |
| `dispatching-parallel-agents`    | `workbench`       | retired without replacement (its successor `subagent-driven-development` is archived too)                                                                                |
| `terse-mode`                     | `workbench`       | retired without replacement                                                                                                                                              |
| `writing`                        | `writing`         | `writing:ghostwrite` (drafting) and `writing:coach` (learning to write)                                                                                                  |
| `pyramid`                        | `writing`         | `writing:ghostwrite` (pyramid audits) and `writing:coach` (structure drill)                                                                                              |
| `tech-doc`                       | `writing`         | `writing:ghostwrite` (tech docs from the repository)                                                                                                                     |
| `frontend-design`                | `frontend-design` | `taste-skill:taste-skill` in Claude Code, `taste-skill:design-taste-frontend` in Codex; for animation and UI craft in Claude Code, `emil:emil-design-eng` (not in Codex) |
| `pilot`                          | `workbench`       | retired without replacement                                                                                                                                              |
| `using-workbench`                | `workbench`       | retired without replacement                                                                                                                                              |
| `brainstorming`                  | `workbench`       | retired without replacement                                                                                                                                              |
| `writing-spec`                   | `workbench`       | retired without replacement                                                                                                                                              |
| `writing-plans`                  | `workbench`       | retired without replacement                                                                                                                                              |
| `visualizing-options`            | `workbench`       | retired without replacement                                                                                                                                              |
| `test-driven-development`        | `workbench`       | retired without replacement                                                                                                                                              |
| `subagent-driven-development`    | `workbench`       | retired without replacement                                                                                                                                              |
| `systematic-debugging`           | `workbench`       | retired without replacement                                                                                                                                              |
| `verification-before-completion` | `workbench`       | retired without replacement                                                                                                                                              |
| `crafting-html`                  | `workbench`       | retired without replacement                                                                                                                                              |
| `crafting-design-systems`        | `workbench`       | retired without replacement                                                                                                                                              |

Installing this plugin alongside `presentations` or `writing` duplicates the triggering surface for their work; only install it if you need the old skill names.

## Credits

`skills/frontend-design/SKILL.md` comes from the [`frontend-design`](https://github.com/anthropics/skills/tree/ef740771ac901e03fbca3ce4e1c453a96010f30a/skills/frontend-design) skill in Anthropic's `anthropics/skills` repository by Prithvi Rajasekaran and Alexander Bricken, licensed under Apache 2.0. See `NOTICE`, which pins the commit. Original additions in this plugin are MIT (`LICENSE`).

The skills moved from `workbench` include content derived from the [Superpowers](https://github.com/obra/superpowers) plugin by Jesse Vincent, version 5.0.7, MIT-licensed; `NOTICE` lists the derived files and carries the upstream license text. The `crafting-html` reference gallery under `skills/crafting-html/references/` comes from [`ThariqS/html-effectiveness`](https://github.com/ThariqS/html-effectiveness) at commit `5d64f68`, which declared no license at that commit; see `NOTICE` for the full attribution. U+2014 and U+2013 codepoints in that gallery were substituted at port time per this repo's lint convention.
