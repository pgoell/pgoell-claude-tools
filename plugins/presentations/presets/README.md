# Presets

A preset packages one brand or context for reuse: colors, typography, assets, and example slides rebuilt as HTML. Skills carry the procedures; presets carry the content. Presets live in two homes that share this contract:

- **Bundled presets** in this directory, next to `skills/` at the plugin root. They ship with the plugin: `default` plus six voice presets (see Bundled presets below).
- **Local presets** in `.pgoell/presentations/presets/<name>/` at the root of the repo being worked in. They are user-owned, never ship with the plugin, and are where the `extracting-presets` skill places new presets by default.

## Directory shape

```
presets/<name>/
  manifest.md     required. The preset's single home for provenance: who the preset serves, sources and their dates, coverage, extraction decisions, gaps, and one direction line naming the generic default the preset's look avoids. All other preset files carry rules and values only.
  colors.css      required. :root CSS custom properties for colors (including the chart group below), font sizes, and layout grid tokens, plus optional variant scopes (for example .dark or .inverse) that override the semantic variables.
  typography.css  optional. :root font stack overrides, plus @font-face rules for vendored fonts that point at assets/fonts/ by relative path.
  guidelines.md   optional. Brand expression guidance with no variable to ride on: personality attributes, tone of voice, imagery rules, and a `## Layout grammar` section. Consumers read it before composing slides and review finished slides against it.
  language.md     optional. A positive style contract for slide copy: what good copy does (everyday words, active voice, one claim per title with its proof inside), before/after title rewrites, the anti-fabrication rule (never add a fact, figure, name, or arithmetic the source lacks), plus brand terminology, citations, and required legal language. Consumers apply it to every written surface and honor its legal elements, which can dictate footer content and back-cover legal blocks. A preset without one falls back to default/language.md.
  assets/         optional. Wordmarks and brand imagery. SVG preferred, it inlines as text.
    fonts/<family>/  optional. Vendored font files (woff2), unmodified, each family with its license as OFL.txt (or the family's own license file). Provenance and license go in the manifest.
  icons/          optional. Brand icon library as one SVG per icon, organized in subdirectories, with an index.tsv (one row per icon: path, name, variant, category, section, aliases, keywords, colors) and a README.md documenting search and usage. Monochrome icons use currentColor so CSS color recolors them; consumers grep the index, then inline the SVG. Icons come only from this library, never drawn freehand; a preset without one gets no icons.
  slides/         optional. Example slides as self-contained HTML on a 1920x1080 canvas.
    index.tsv     required when slides/ exists. One row of tags per slide file, from the closed vocabulary in TAGS.md, so consumers can search every gallery by role, move, and form.
```

## Layout grammar

Each bundled preset is a layout grammar, not only a palette. It declares its grid as layout tokens in `colors.css` (for example `--grid-cols`, `--grid-col`, `--grid-gutter`, and zone tokens such as `--tracker-top`, `--title-top`, `--body-top`, `--body-bottom`) and documents in `guidelines.md` under `## Layout grammar` how its slides use that grid: the column splits, where the title and the evidence sit, and the compositions that set the preset apart. A preset's grid tokens win over the 12-column, 32 px gutter default in the `creating-presentations` skill. Consumers read the grammar before composing and build any layout the gallery lacks from it.

## Chart tokens

Charts read a dedicated token group in `colors.css`, declared in `:root` and again in every variant scope that changes the background:

| Token                                | Required | Job                                                                                                                                       |
| ------------------------------------ | -------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `--chart-highlight`                  | yes      | The story series in highlight mode: the one bar, line, or point the title names. Usually `var(--accent)`; at least 3:1 on `--bg`.         |
| `--chart-context`                    | yes      | Every series that is not the story. A quiet gray, deliberately low contrast (about 2 to 3:1).                                             |
| `--chart-grid`                       | yes      | Gridlines, lighter than axis labels. Usually `var(--border)`.                                                                             |
| `--chart-1` to `--chart-6`           | `-1` yes | Categorical series in fixed order, only for charts where the categories are the point. Declare as many as the preset supports, at most 6. |
| `--chart-seq-1` to `--chart-seq-<n>` | no       | Sequential scale, lightest to darkest.                                                                                                    |
| `--chart-div-1` to `--chart-div-<n>` | no       | Diverging scale, with the neutral midpoint in the middle.                                                                                 |

Highlight mode is the default: one series in `--chart-highlight`, the rest in `--chart-context`, labels placed next to the marks instead of a legend, and `font-variant-numeric: tabular-nums lining-nums` on chart labels and tables. Categorical colors should each clear 3:1 on `--bg` and stay distinct under a color-vision-deficiency simulation; a color that does not clear 3:1 is recorded in the manifest and only ever appears with a direct label. A deck that needs more series than the preset declares splits the chart. A custom property declared as `var(--accent)` in `:root` resolves there, so a dark scope must redeclare `--chart-highlight` (and `--border-accent`) to pick up the dark accent.

### Optional token families

Some presets declare token families for content only they draw. Any preset that draws the same content should reuse these names:

| Family                                                                                 | Declared by | Job                                                                                  |
| -------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------ |
| `--node-*` (for example `--node-service`, `--node-service-fill`), `--edge`, `--edge-*` | `technical` | Diagram nodes by type, each a stroke plus a fill, and the edges between them         |
| `--code-*` (for example `--code-bg`, `--code-keyword`, `--code-highlight-line`)        | `technical` | Code panels: background, syntax colors, the highlighted line, the line-number gutter |
| `--image-placeholder`, `--scrim`                                                       | `keynote`   | The fill of an empty image slot, and the overlay that carries text on a photo        |

When the preset's `--accent` is too light for text, it declares `--accent-ink`, a darker step that holds 4.5:1 on `--bg`, `--bg-elev`, and `--bg-subtle`, for accent-colored words and numbers.

## Rules

- Preset names are kebab-case and name the brand or context, for example `acme-corp` or `default`.
- Example slides are self-contained: inline `<style>` opening with a synced copy of the preset's variable blocks (`colors.css`, plus `typography.css` when present, stay the source of truth), every color and font read from variables declared there, no network requests. The one permitted difference in the synced copy is the `../` prefix on `@font-face` URLs, because slides sit one level below `assets/`. Imagery either inlines (SVG as text, small rasters as base64) or, when inlining would force lossy recompression, stays at source quality in the preset's `assets/` and is referenced by relative path; slides open standalone from the preset directory either way.
- Example slides meet the type floors on the 1920x1080 canvas: body at least 36px, captions and chart labels at least 28px, footer and source line at least 24px, never shrunk to fit. These are starting points, checked in decks by hard gate H7.
- Example slides carry no template chrome: no tracked uppercase eyebrows, accent-colored periods, italic accent words, mono micro labels, 01 / 02 numbering where nothing is a sequence, or middle-dot meta strings. The action title is the dominant heading. A source template that breaks a floor or uses chrome is rebuilt without it, and the manifest records the decision.
- Official assets only. Wordmarks and logos come from a brand portal or files the user provides, never redrawn from memory.
- Fonts are vendored, never fetched: unmodified woff2 files plus their license under `assets/fonts/<family>/`, loaded by relative path. Never subset or otherwise modify a family that carries a Reserved Font Name (IBM Plex, Source Sans 3); the OFL counts subsetting as modification.
- Every text tier (`--fg`, `--fg-muted`, `--fg-subtle`) holds 4.5:1 or better on `--bg`, `--bg-elev`, and `--bg-subtle` in every scope, and so does the accent used for text (`--accent`, or `--accent-ink` when declared).
- Every slide file has exactly one row in `slides/index.tsv`, tagged from the vocabulary in `TAGS.md` next to this file; add, change, or remove the row in the same change as the slide.
- Keep presets small and grow the collection slowly, slide by slide. A preset is a curated gallery, not an archive of every deck.
- Adding or changing a bundled preset is a plugin change: bump the plugin version across the marketplace repo's lockstep sites (minor for a new preset, patch for extending one). Local `.pgoell` presets need no repo change.

## Selection

Consumers resolve the active preset in this order:

1. An explicit choice in the prompt wins, either a preset name or a path to a preset directory.
2. `.pgoell/presentations/config.md` at the working repo root: its `## Preset` section selects by `Name:` (resolved against local presets first, then bundled ones) or `Path:` (any directory following this contract).
3. Local presets come next. Exactly one local preset: it applies, and the consumer states which preset was used. Several local presets: ask the user which one to use.
4. With no local preset, pick the bundled preset that fits the deck's use from the table below, state the choice and the reason, and offer the alternatives in one line. When the use is unclear and the user is present, ask. When nothing points elsewhere, use `default`.

## Bundled presets

| Preset       | Voice                                                                                        | Suits                                                                                         |
| ------------ | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `default`    | Quiet: near-white, ink, one green accent, Figtree                                            | General-purpose decks and proposals when nothing else fits; the neutral starting point        |
| `analytical` | Claim plus number: white, navy, blue accent, Plex Serif and Sans                             | Decks read by or presented to decision makers: board papers, strategy reviews, business cases |
| `keynote`    | One idea per slide, dark by default, Inter                                                   | Stage talks and town halls in dark rooms; not for decks read alone                            |
| `product`    | Short declaratives: near-achromatic, signal orange, Geist                                    | Launches, product reviews, engineering all-hands                                              |
| `editorial`  | Sentence headlines on tinted paper, claret accent, Newsreader and Source Sans 3              | Data stories, research readouts, reports presented as decks                                   |
| `workshop`   | Invitational: warm paper, teal accent, Fraunces and Atkinson Hyperlegible Next               | Training, facilitation, mixed and low-vision audiences                                        |
| `technical`  | Dense and exact: graphite, amber path highlight, Red Hat Display, Text, and Mono; dark first | Engineering deep dives, architecture reviews, design docs presented live, incident reviews    |

A `deck.md` with `deck_mode: keynote` points to `keynote`; `reading` and `briefing` point to `analytical` or `editorial`.

Presets are created and extended by the `extracting-presets` skill and consumed by the `creating-presentations` skill.
