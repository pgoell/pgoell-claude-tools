---
type: Reference
title: The diagrams plugin
description: The creating-diagrams skill, its bundled engine, and how themes give diagrams a brand's colors.
tags: [plugin, diagrams, svg, html, themes]
status: stable
---

# diagrams

Architecture, workflow, sequence, data-flow and lifecycle diagrams as one self-contained HTML file. A bundled engine lays the diagram out and checks its geometry before it hands anything over. The viewer has light and dark modes, pan and zoom, search, a presentation mode, and PNG, JPEG, WebP, SVG and WebM export, and makes no network requests.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/diagrams/`; see the [plugin README](../../../plugins/diagrams/README.md) for details and credits. The engine is a port of [tt-a1i/archify](https://github.com/tt-a1i/archify) (MIT); the hand-drawn fallback adapts [Cocoon-AI/architecture-diagram-generator](https://github.com/Cocoon-AI/architecture-diagram-generator) (MIT). `plugins/diagrams/NOTICE` lists every change.

**Setup:** [Set up the diagrams plugin](/how-to/set-up-diagrams.md)

## Skills

| Invocation                    | What it does                                                                                                                                                                                                                                                                                                                                                                                          |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/diagrams:creating-diagrams` | Draws a diagram from a description, pasted Mermaid or a scan of a repository. The agent writes a typed JSON spec; the engine lays it out, routes edges, runs nine geometry checks, and checks the result in headless Chrome. It can also compare two versions of an architecture and verify cited source lines against the repo. Without Node 18 or later it falls back to a hand-drawn SVG template. |

## Themes

Every color comes from a theme; the contract is in [themes/README.md](../../../plugins/diagrams/themes/README.md). The plugin ships `classic`. The skill can derive a brand theme from a presentations preset or straight from a `.pptx` or `.potx` file, and saves it under `.pgoell/diagrams/themes/<name>/` in your repo.

## Evals

`plugins/diagrams/evals/` holds 11 `claude plugin eval` cases that test when `creating-diagrams` fires. Cases 01 to 03 are triggers, one per input or diagram form the skill description names: the skill must fire. Case 01 asks for an architecture from a plain description, 02 pastes a Mermaid sequence diagram, and 03 asks for an order lifecycle as a state diagram. No case asks for a repository scan, since no one knows what the eval sandbox holds. Cases 21 to 23 are negatives (a one-paragraph REST vs gRPC answer, a fix to a pasted Python function, a SQL query): the skill may not fire.

The plugin has one skill, so no case tests a near-miss between sibling skills.

Cases 31 to 35 are near-misses outside the plugin: the skill may not fire, and an `llm` grader checks the reply. Case 31 asks for a slide deck from notes (presentations). Case 32 asks for a bar chart of monthly revenue, a chart and not a diagram. Case 33 asks for a slide preset from a PowerPoint template (`presentations:extracting-presets`); the diagrams description also names PowerPoint themes. Case 34 asks for Mermaid source for a README, and case 35 for an ASCII box diagram for a docstring; in both the user wants text, not an HTML file.

Every case allows only Skill, Read, Glob and Grep, so no case needs network or a shell, and none can write a file. The graders match the full name `diagrams:creating-diagrams`.

No one has run the suite yet; a run costs money, so the user decides when. Run from `plugins/diagrams`:

```bash
claude plugin eval . --trust-plugin --tag core --runs 1 -j 4 --max-cost-usd 5 --no-publish
```
