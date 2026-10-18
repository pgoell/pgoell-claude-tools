---
type: How-to Guide
title: Set up the diagrams plugin
description: Install Node and a Chromium browser for the diagram engine, and choose a theme for a project in .pgoell/diagrams/.
tags: [diagrams, themes, setup]
status: stable
---

# Set up the diagrams plugin

`/diagrams:creating-diagrams` renders through a bundled engine. It needs no install step of its own.

1. Install Node 18 or later. Without it, the skill draws the diagram by hand as SVG instead, and says so.
2. Install a Chromium browser (Chrome, Chromium or Edge). The skill uses it, headless, to check the delivered file and review it in light and dark mode. Without one, it skips that check and says so.

## Check it worked

```bash
node --version
```

Then ask for a diagram, such as "draw the request flow of this repo". The skill reports the engine's checks.

## Choose a theme for a project (optional)

The bundled theme is `classic`. To match a brand, ask the skill to derive a theme from a `presentations` preset or a PowerPoint template. It saves the theme under `.pgoell/diagrams/themes/<name>/` and writes `.pgoell/diagrams/config.md`, so later diagrams in that project use it. To pick a theme by hand, write that file at the repository root:

```markdown
## Theme

Name: classic
```

The theme contract is in [themes/README.md](../../plugins/diagrams/themes/README.md). See [the diagrams reference page](/reference/plugins/diagrams.md).
