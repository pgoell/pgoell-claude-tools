# presentations

Skills covering the full presentation lifecycle: content design, HTML deck building with an integrated perfecting loop, native PowerPoint export, and brand preset extraction.

## Skills

| Skill                             | What it does                                                                                                                                                 |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `designing-presentations`         | Content design from sourced audience brief through competing storylines and written checks. Produces a `deck.md`; no rendering.                              |
| `creating-presentations`          | Builds multi-slide HTML decks styled from a preset, with a deck-stage engine, a two-window presenter view, default render checks, and an opt-in review loop. |
| `exporting-presentations-to-pptx` | Converts a finished HTML deck into native, editable PowerPoint (real text boxes, autoshapes, embedded images, speaker notes).                                |
| `extracting-presets`              | Turns brand material (PPTX templates, PDF guidelines, example decks) into reusable presets: CSS variables, assets, icon libraries, example slides.           |

The typical flow: `designing-presentations` writes `deck.md`, `creating-presentations` renders and perfects the deck, `exporting-presentations-to-pptx` produces the editable file when someone needs PowerPoint.

## Presets

Styling flows through presets, packs of CSS variables, guidance files, assets, and example slides. The full contract lives in [presets/README.md](presets/README.md). Two homes:

- **Bundled**: `presets/` in this plugin. Ships with the plugin; seven presets, each with vendored open fonts, a `language.md` style contract, the shared chart token group, and its own layout grammar (grid tokens in `colors.css`, a `## Layout grammar` section in `guidelines.md`, and a gallery of eleven or more slides built to it):
  - `default`: the quiet direction (off-white, one green accent, Figtree) with the full proof-object gallery. The fallback when nothing else fits.
  - `analytical`: claim plus number for decks read by or presented to decision makers (white, navy, blue accent, IBM Plex Serif and Sans).
  - `keynote`: one idea per slide for stage talks, dark by default (Inter).
  - `product`: short declaratives for launches and engineering all-hands (near-achromatic, signal orange, Geist).
  - `editorial`: sentence headlines and newsroom chart grammar for data stories and readouts (tinted paper, claret, Newsreader and Source Sans 3).
  - `workshop`: invitational titles for training and mixed or low-vision audiences (warm paper, teal, Fraunces and Atkinson Hyperlegible Next).
  - `technical`: dense diagrams, code, and tradeoff tables for engineering deep dives, architecture reviews, design docs presented live, and incident reviews; dark first (graphite, amber path highlight, Red Hat Display, Text, and Mono).
- **Local**: `.pgoell/presentations/presets/<name>/` at the root of the repo you are working in. User-owned, created by `extracting-presets`, never shipped.

Preset selection: an explicit prompt choice wins; otherwise `.pgoell/presentations/config.md` (`## Preset` section with `Name:` or `Path:`); otherwise the single local preset (a question when several exist); otherwise the bundled preset that fits the deck's use, named with its reason, with `default` as the fallback.

```markdown
<!-- .pgoell/presentations/config.md -->

## Preset

Name: acme-corp
```

## Runtime dependencies

No install-time setup. At runtime the skills reach for tools when a branch needs them: a Chromium-based browser (presenting, headless screenshots), `uv` (ad hoc Python for PPTX/PDF work and a local HTTP server), and a container engine (rendering source PPTX decks during preset extraction). Each skill degrades gracefully and says so when a tool is missing.
