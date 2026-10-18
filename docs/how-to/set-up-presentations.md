---
type: How-to Guide
title: Set up the presentations plugin
description: Install the tools the presentations skills use, and choose a preset for a project in .pgoell/presentations/.
tags: [presentations, presets, setup]
status: stable
---

# Set up the presentations plugin

A finished deck is plain HTML and opens from `file://` with nothing installed. The tools below come in only for presenting, checking and exporting, and each skill checks for them when it reaches the step that needs one.

## Install what the skills use

| Tool                                   | Used by                                                                                                                                                                       |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A Chromium browser (Chrome, Edge, Arc) | `creating-presentations` to present (the presenter view needs Chromium) and, headless, to screenshot slides; `editing-presentations` to show the editor; `extracting-presets` |
| `uv`                                   | `creating-presentations` serves the deck for its checks; `exporting-presentations-to-pptx` and `extracting-presets` run their Python through it                               |
| Python 3.9 or later (or `uv`)          | `editing-presentations` runs its local server (standard library only)                                                                                                         |
| `podman`, `docker` or `nerdctl`        | `exporting-presentations-to-pptx` and `extracting-presets` render PowerPoint files with LibreOffice when the host has no `soffice`                                            |

`designing-presentations` writes markdown and needs none of them. Without a container engine, the export still delivers the `.pptx` and says that its layout went unchecked.

The deck render check and the review loop also need the host to run subagents.

## Choose a preset for a project (optional)

With nothing configured, `/presentations:creating-presentations` picks the bundled preset that fits the deck and says why. To fix the choice for a project, work at the root of that project's repository:

1. To use a bundled preset (`default`, `analytical`, `keynote`, `product`, `editorial`, `workshop`, `technical`), create `.pgoell/presentations/config.md`:

   ```markdown
   ## Preset

   Name: analytical
   ```

   `Path: <directory>` instead of `Name:` points at any directory that follows the preset contract.
2. To use your own brand, run `/presentations:extracting-presets` with a PowerPoint template, PDF guidelines or example decks. It writes the preset to `.pgoell/presentations/presets/<name>/`. A single local preset is used without any `config.md`; with several, name one in `config.md` or the skill asks.

## Check it worked

Ask for a short deck, such as "build a three-slide deck on our Q3 results". The skill names the preset it used and why.

The preset contract is in [presets/README.md](../../plugins/presentations/presets/README.md). See [the presentations reference page](/reference/plugins/presentations.md) for the five skills.
