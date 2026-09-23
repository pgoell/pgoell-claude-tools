# Themes

A theme packages one brand or look for diagrams: a single `theme.css` that sets the variables the diagram template reads. Skills carry the procedures; themes carry the values. Themes live in two homes that share this contract:

- **Bundled themes** in this directory. They ship with the plugin; `classic` lives here.
- **Local themes** in `.pgoell/diagrams/themes/<name>/` at the root of the repo being worked in. They are user-owned and never ship with the plugin. The `creating-diagrams` skill writes derived themes (from a presentations preset or a PowerPoint file) here.

## Directory shape

```
themes/<name>/
  theme.css     required. Two blocks, [data-theme="light"] and [data-theme="dark"], each setting every required variable.
  manifest.md   optional for bundled themes, required for derived ones. Source (preset name or PPTX file and date), the mapping used, contrast results, gaps.
```

## Variables

Required in both blocks:

| Variable                                    | Role                                                                                          |
| ------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `--bg`                                      | Page and export background                                                                    |
| `--grid`                                    | Background grid lines, a faint step off `--bg`                                                |
| `--panel`, `--panel-border`                 | Diagram card and summary cards                                                                |
| `--text`, `--text-muted`, `--text-dim`      | Node names; sublabels and edge labels; footer and annotations                                 |
| `--mask`                                    | Opaque color behind nodes and edge labels. Must be fully opaque, close to panel               |
| `--arrow`, `--arrow-emphasis`               | Default edges; the main path                                                                  |
| `--fill-strength`                           | Percentage of the stroke color mixed into node fills (light ~16%, dark ~30%)                  |
| `--frontend-stroke` ... `--external-stroke` | The seven semantic colors: frontend, backend, database, cloud, security, messagebus, external |
| `--font-diagram`                            | Font stack for all SVG text                                                                   |

Optional:

| Variable                                                                                     | Default when absent                                                     |
| -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `--<type>-fill` for any of the seven                                                         | `color-mix()` of the stroke at `--fill-strength`                        |
| `--region-fill`                                                                              | Cloud stroke at 5%                                                      |
| `--lane-fill`, `--lane-stroke`                                                               | Text color at 3%; `--panel-border`                                      |
| `--font-ui`                                                                                  | `--font-diagram` (page header, cards, footer; hand-drawn template only) |
| `--text-faint`                                                                               | `--text-muted` (engine viewer chrome)                                   |
| `--toolbar-bg`, `--toolbar-border`, `--toolbar-text`, `--toolbar-hover`, `--toolbar-menu-bg` | Panel, border, text, and mask colors (engine viewer toolbar)            |

## Rules

- Theme names are kebab-case and name the brand or look, for example `acme-corp` or `classic`.
- Values only. No selectors other than the two `[data-theme]` blocks, no imports, no `url()`, no web fonts. A diagram must render offline, so fonts come from the stack and fall back to system faces.
- The seven `*-stroke` values and `--text` are plain `#rrggbb` or `rgb()`/`rgba()`. The engine computes fills from them and rejects `var()` or `color-mix()` there.
- Contrast floors, checked in both modes: `--text` and `--text-muted` at least 4.5:1 against `--bg` and `--mask`; every `*-stroke` and `--arrow` at least 3:1 against `--bg`. A brand color that fails (bright greens and yellows on white often do) gets a darker step of the same hue for that mode, recorded in the manifest.
- The seven semantic strokes stay distinguishable from each other: no two within the same hue family unless one is `--external-stroke`.
- Consumers: the engine reads `theme.css` through `--theme` and embeds a completed copy in each artifact; the hand-drawn template embeds a verbatim copy between its `THEME` markers. Either way the theme file stays the source of truth. Changing a bundled theme is a plugin change and bumps the plugin version.

## Selection

Consumers resolve the active theme in this order:

1. An explicit choice in the prompt: a theme name, a path to a theme directory, or a presentations preset or PPTX file to derive from. A derivation saves the theme and writes `.pgoell/diagrams/config.md`, so the next diagram resolves at step 2. A derived theme takes the preset's name; a diagram theme and a preset sharing a name is intended.
2. `.pgoell/diagrams/config.md` at the working repo root: its `## Theme` section selects by `Name:` (resolved against local themes first, then bundled) or `Path:` (any directory following this contract).
3. A presentations preset configured in `.pgoell/presentations/config.md` with no matching diagram theme yet: offer once to derive one from it (see the skill's `references/theming.md`). Skip the offer when the prompt already asks to match that preset or brand; that is step 1, and it derives directly.
4. Otherwise `classic`, and the consumer states that it used `classic`.
