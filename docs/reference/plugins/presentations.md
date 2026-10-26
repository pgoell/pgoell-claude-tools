---
type: Reference
title: The presentations plugin
description: The six presentations skills, the seven bundled presets, and the tools the skills reach for at runtime.
tags: [plugin, presentations, slides, pptx, presets]
status: stable
---

# presentations

The whole life of a slide deck in one plugin: content design, a native PowerPoint deck (the default output), an HTML deck with a presenter view and a review loop, a local editor for changes by hand, export of HTML decks to PowerPoint, and brand presets built from material you already have.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/presentations/`; see the [plugin README](../../../plugins/presentations/README.md) for details and credits.

**Setup:** [Set up the presentations plugin](/how-to/set-up-presentations.md)

**Tests:** `bash plugins/presentations/tests/run.sh` loads a three-slide deck in headless Chrome, removes and re-adds its `<deck-stage>`, and checks the shadow DOM, slot, rail thumbnails, keys and rail state, with no network. Last run 2026-10-19: 6 passed, 0 failed.

## Skills

| Invocation                                       | What it does                                                                                                                                                                                                                                                                                                                                                                                        |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/presentations:designing-presentations`         | Designs the content of a deck, from audience brief through competing storylines to a critiqued storyboard, and writes a markdown `deck.md` with per-slide front matter. Also audits an existing `deck.md`. Renders nothing.                                                                                                                                                                         |
| `/presentations:building-pptx-decks`             | Builds a native, structured `.pptx` from a `deck.md` or your content: preset colors and fonts in the Office theme, layouts with named placeholders, native charts, speaker notes. Fills a client template in place when the preset keeps one, and edits or extends an existing `.pptx` without rebuilding it. Checks every file for structure, text and type size, and renders it with LibreOffice. |
| `/presentations:creating-presentations`          | Builds a multi-slide HTML deck styled from a preset, on a bundled deck-stage engine with a two-window presenter view for Teams, Zoom or Meet. Every build runs render checks; the full review-to-done loop is opt-in.                                                                                                                                                                               |
| `/presentations:editing-presentations`           | Starts a local editor on a deck (a standard-library Python server and an overlay script). You click slide elements and type a note; the agent reads the selection with slide, selector and source lines.                                                                                                                                                                                            |
| `/presentations:exporting-presentations-to-pptx` | Converts a finished HTML deck into a native, structured `.pptx`: it measures the rendered slides in headless Chrome, then writes theme, layouts, text boxes, native charts and speaker notes with a `pptxgenjs` generator written fresh for each deck.                                                                                                                                              |
| `/presentations:extracting-presets`              | Turns brand material (PPTX templates, PDF guidelines, example decks) into a reusable preset: colors, typography, assets and example slides rebuilt as HTML.                                                                                                                                                                                                                                         |

The usual order: `designing-presentations` writes `deck.md` and `building-pptx-decks` builds it as PowerPoint. Ask for HTML, a browser deck or the presenter view and `creating-presentations` renders it instead; `editing-presentations` then opens it for changes by hand, and `exporting-presentations-to-pptx` converts it to PowerPoint later. A bare ask for a deck, with no `deck.md`, storyline or content, starts at `designing-presentations`, which asks for the material first; an ask with a `deck.md`, a settled storyline or its own content goes straight to the builder.

## Presets

Styling comes only from presets; the contract is in [presets/README.md](../../../plugins/presentations/presets/README.md). Seven ship with the plugin, each with vendored open fonts, a shared chart token group, its own layout grammar and a gallery of example slides (141 in all):

| Preset       | For                                                                                 |
| ------------ | ----------------------------------------------------------------------------------- |
| `default`    | The neutral fallback when nothing else fits, with the full gallery.                 |
| `analytical` | Decks read by or presented to decision makers: claim plus number.                   |
| `keynote`    | Stage talks, one idea per slide, dark by default.                                   |
| `product`    | Launches and engineering all-hands.                                                 |
| `editorial`  | Data stories and readouts.                                                          |
| `workshop`   | Training and mixed or low-vision audiences.                                         |
| `technical`  | Architecture reviews, design docs presented live, and incident reviews; dark first. |

Project presets live under `.pgoell/presentations/presets/<name>/` at the root of the repo you work in, and `.pgoell/presentations/config.md` picks one. With no choice made, the deck skills pick the bundled preset that fits the deck's use and say why. A project preset made from a client PowerPoint template keeps the template under `pptx/`, so PowerPoint decks are filled into it rather than drawn from the preset's tokens.
