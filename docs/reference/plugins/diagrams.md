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
