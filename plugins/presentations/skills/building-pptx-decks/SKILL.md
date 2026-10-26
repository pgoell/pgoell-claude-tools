---
name: building-pptx-decks
description: Use when the user wants a slide deck as PowerPoint, which is the default when no format is named. Builds a native, editable .pptx from a deck.md, a settled storyline, or their content, styled from a preset or filled into a client template; also edits or extends an existing .pptx in place. A bare deck ask with nothing to build from goes to designing-presentations first. For an HTML deck with a presenter view, see creating-presentations.
---

# Building PowerPoint Decks

PowerPoint is the default output of this plugin: most decks end up in a client's hands as a file they edit. This skill builds that file natively, so every title sits in a placeholder, every color comes from the theme, and every slide hangs off a layout. A consultant can then restyle it from the Design tab, reset a slide, or add one that matches the rest.

Three routes, by what the deck starts from:

| Starts from                                             | Route                                                        | Tool                                   |
| ------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------------- |
| A preset (bundled or local) and no client template      | **Build**: a structured deck written from scratch            | `pptxgenjs` (Node)                     |
| A client template (`.pptx` or `.potx`)                  | **Fill**: copy the template's layouts and fill them in place | `assets/pptx_tool.py`, slide XML edits |
| An existing deck to change (edit, add, remove, reorder) | **Edit**: the same in-place route as Fill                    | `assets/pptx_tool.py`, slide XML edits |

Never rebuild an existing deck from scratch to change it, and never redraw a client template: both throw away the masters, fonts and layouts the recipient checks first. `pptxgenjs` writes new files only; it cannot open one.

## Dependencies

Check each when its step starts.

- **Node and `pptxgenjs`** (Build only). Try `node -e "require('pptxgenjs')"`; when it fails, install into a scratch prefix: `npm install --prefix /tmp/pptx-node pptxgenjs` and run scripts with `NODE_PATH=/tmp/pptx-node/node_modules`.
- **Python 3** runs the two shipped scripts, standard library only: `python3 <this skill's dir>/assets/pptx_tool.py` and `assets/pptx_check.py`. `uv run python3 ...` works the same.
- **python-pptx** (optional, Fill and Edit) for structured reads: `uv run --with python-pptx python3 script.py`.
- **LibreOffice** for the render check: a local `soffice`, or a container (`for rt in podman docker nerdctl; do command -v "$rt" && break; done`, then `<rt> run --rm -v "$PWD:/data" --entrypoint soffice docker.io/linuxserver/libreoffice --headless --convert-to pdf --outdir /data /data/deck.pptx`). Rasterize the PDF with `pdftoppm -r 96 -png deck.pdf slide` or PyMuPDF through `uv`.

## Step 1: Gather the content

A `deck.md` from `designing-presentations` is the source brief: its header gives `deck_mode`, `governing_idea` and `preset`; each slide block gives `slide_type`, `headline`, an optional short `title`, `visual` (the proof object), `speaker_notes` and `sources`. Without one, compose from the storyline or content the user gave. A bare ask with nothing to compose from ("a deck about our Q3 results") goes to `designing-presentations` first; build what it writes.

Nothing is invented: every figure, name, date and calculation on a slide or in the notes comes from the material. When a headline needs a number the material lacks, write the claim with what it does have and tell the user what is missing.

Write every surface to the active preset's `language.md` (fall back to `../../presets/default/language.md`).

## Step 2: Pick the route and resolve the style

1. An attached `.pptx` the user wants changed: **Edit**. Skip to Step 3.
2. A client template named or attached, or a preset with a `pptx/template.pptx` (or `.potx`): **Fill**.
3. Otherwise **Build** from a preset. Resolve it in the plugin's usual order: the prompt or the `deck.md` header `preset` key; `.pgoell/presentations/config.md` (`## Preset`, `Name:` or `Path:`); the single local preset in `.pgoell/presentations/presets/`; else the bundled preset that fits the deck's use, stated with its reason (`../../presets/README.md`, "Bundled presets"; `default` when nothing points elsewhere). A brand the user names but no preset covers: offer `extracting-presets` first.

Output path: `deck.pptx` next to the `deck.md`, or the name the user gives. Never overwrite the user's original when editing: write `<name>-edited.pptx` unless told otherwise.

## Step 3: Build, fill or edit

- **Build**: read [references/from-preset.md](references/from-preset.md) before writing any code. It maps the preset onto the Office theme, turns the layout grammar into slide layouts with named placeholders, and covers proof objects, charts and the `pptxgenjs` traps that corrupt files.
- **Fill** and **Edit**: read [references/from-template.md](references/from-template.md). It covers reading the template, choosing layouts, the `pptx_tool.py` commands for adding, copying, dropping and cleaning slides, and the XML rules for editing text without losing formatting.

Speaker notes carry the `deck.md` notes as written; a slide with no notes in the source gets none. Set the document title and author.

## Step 4: Check the file

Never hand over an unchecked deck. Run all four, fix in the generator (Build) or the slide XML (Fill, Edit), and run them again:

1. **Structure**: `python3 assets/pptx_check.py deck.pptx`. Errors are files PowerPoint repairs or refuses even when LibreOffice opens them; fix every one. It also lists every text size in use and warns on text under the floor and on leftover placeholder text.
2. **Content**: `python3 assets/pptx_tool.py text deck.pptx`. Compare against the source: every headline verbatim, slide order, no missing or invented figure, notes carried. Run the copy lint in `../creating-presentations/references/copy-lint.md` over that text (title rules, banned characters, the deck mode's word budget), taking rendered title lines from the render.
3. **Type floors**: body 20 pt (18 pt at the least), captions, chart labels and table cells 14 pt, footer and source line 12 pt. Never shrink text to fit and never turn on autofit: split the slide, cut words, or move detail to the notes. A client template's own smaller sizes stand when editing it.
4. **Render**: convert to PDF with LibreOffice, rasterize every page, and look at each one. Expect a few real defects on a first render: text running out of its box, overlap, uneven gaps, titles at different heights, low contrast, a chart label in another style. When the host has subagents, hand the PNGs to a fresh one with the defect list above; it sees what the builder no longer does. LibreOffice substitutes fonts it lacks, so treat glyph shapes as approximate and geometry and color as real.

Two fix rounds by default, three at most; then report what is still open. Without LibreOffice or a container engine, deliver the file and say plainly that the layout was not render-checked.

## Step 5: Hand over

Give the file path, the preset or template used and why, which charts (if any) went in as pictures instead of native charts, every typo fixed in the source text, and anything still open from Step 4. For a deck that must be flawless, offer a per-slide review by fresh subagents, one per slide, each given the source block and the render.

## Self-Healing

- `require('pptxgenjs')` fails: install into the scratch prefix (Dependencies) and set `NODE_PATH`.
- `pptx_check.py` reports an error in a part the generator wrote: fix the generator option named in [references/from-preset.md](references/from-preset.md), "Traps", and rebuild; never patch the zipped file by hand.
- PowerPoint (the user's) reports the file needs repair while the check passes: ask for the exact message, then unpack the file and look for the part it names.
- LibreOffice hangs: run it in the container, or with a fresh profile (`-env:UserInstallation=file:///tmp/lo-profile`).
- A brand font is missing on this host: the render uses a fallback; trust geometry with about 10% slack on boxes in that font and say so.

## Cross-references

- `designing-presentations` writes the `deck.md` this skill builds from.
- `creating-presentations` builds an HTML deck instead, with a presenter view, when the user asks for HTML or a browser deck.
- `exporting-presentations-to-pptx` converts an existing HTML deck to PowerPoint; it shares this skill's Build reference.
- `extracting-presets` turns a client template into a preset, keeping the template for the Fill route.
