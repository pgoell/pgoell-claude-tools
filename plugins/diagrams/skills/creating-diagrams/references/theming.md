# Theming

The theme contract (variables, rules, selection order) lives in `../../../themes/README.md` at the plugin root. This file covers the two jobs around it: applying a theme to a diagram, and deriving a new theme from brand material you already have.

## Applying a theme

1. Resolve the theme in the contract's selection order.
2. Copy the resolved `theme.css` verbatim between the `THEME:START` and `THEME:END` comments in the diagram, replacing the classic block.
3. Never write a color literal into the SVG or the page CSS. Every color comes from a variable, which is what makes a theme swap a one-block edit.
4. State which theme you used, and where it came from, in your reply.

## Deriving a theme from brand material

Two sources work. Prefer the first when both exist: a preset has already been through brand review.

- **A presentations preset**, local under `.pgoell/presentations/presets/<name>/` (the `presentations:extracting-presets` skill builds these from a PPTX template or PDF brand guide), or any directory following that preset contract. Read `colors.css`, `typography.css` when present, and `manifest.md` for color restrictions ("graphics only", "fails as text on white").
- **A PowerPoint file** (`.pptx` or `.potx`) directly. Unpack it (`uv run python -m zipfile -e deck.pptx workdir` works on every platform) and read `ppt/theme/theme1.xml`: `<a:clrScheme>` carries `dk1`, `lt1`, `dk2`, `lt2`, `accent1` to `accent6`, `hlink`; `<a:fontScheme>` carries the heading (`majorFont`) and body (`minorFont`) Latin typefaces. A template can carry several themes; use the one the slide masters reference.

Map the source onto the contract:

| Diagram variable                       | From a preset                                            | From a PPTX theme                              |
| -------------------------------------- | -------------------------------------------------------- | ---------------------------------------------- |
| `--bg` (light)                         | `--bg`                                                   | `lt1`                                          |
| `--panel`, `--mask` (light)            | `--bg-elev`                                              | `lt1` (or `lt2` when `lt1` is also `--bg`)     |
| `--panel-border`, `--grid`             | `--border`                                               | `lt2`, darkened until visible on `--bg`        |
| `--text`, `--text-muted`, `--text-dim` | `--fg`, `--fg-muted`, `--fg-subtle`                      | `dk1`, `dk2`, `dk2` lightened                  |
| `--arrow`                              | `--fg-muted`                                             | `dk2`                                          |
| `--arrow-emphasis`, `--backend-stroke` | `--accent`, or its text-safe ramp step when it fails 3:1 | `accent1`                                      |
| `--frontend-stroke`                    | `--accent-partner`, else the next raw brand color        | `accent2`                                      |
| `--database-stroke`                    | next raw brand color of a new hue                        | `accent3`                                      |
| `--cloud-stroke`                       | next raw brand color of a new hue                        | `accent4`                                      |
| `--messagebus-stroke`                  | next raw brand color of a new hue                        | `accent5`                                      |
| `--security-stroke`                    | `--status-danger`, or a brand red when one exists        | a red among the accents, else `accent6`        |
| `--external-stroke`                    | `--fg-muted` or a brand gray                             | `dk2` or a gray accent                         |
| `--font-diagram`, `--font-ui`          | the body and heading stacks from `typography.css`        | `minorFont`, `majorFont`, then system fallback |

The primary brand color goes to `--backend-stroke` because services are the most common node, so the diagram reads as on-brand at a glance.

Assign in this order: backend, security, external, then frontend, database, cloud, messagebus. When a table cell yields a color whose hue sits within 30 degrees of one already assigned (corporate palettes often hold three greens or two reds), the contract's distinct-hue rule wins: skip that color and take the next candidate. Candidates, in order:

1. The cell's own source from the table.
2. The remaining raw brand colors, skipping any that fail contrast in both modes (a near-black used as the dark `--bg` is useless as a stroke).
3. The preset's `--status-*` colors (info, warning, success).
4. The classic theme's stroke for the same role, darkened or lightened to pass contrast. This is off-brand; say so in the manifest.

Record every skip and every fallback in the manifest.

Dark mode:

- From a preset: its `.dark` or `[data-theme="dark"]` scope supplies `--bg`, `--fg`, and the muted steps. When the preset has no dark scope, use its deepest brand color (`--bg-inverse`, a navy, a deep green) as `--bg`.
- From a PPTX: `dk2` as `--bg` when it is dark enough for white text, otherwise `dk1`.
- Strokes: reuse the light-mode hues, lightened until each clears 3:1 on the dark `--bg`. Set `--fill-strength` to about 30%.
- `--mask` in dark mode is an opaque step slightly lighter than `--bg`. Never use an `rgba()` value: the mask exists to hide lines.
- Preset values in `rgba()` (dark scopes often use them for muted text, surfaces, and borders): flatten each over the mode's `--bg` to an opaque hex before checking contrast. `--text-*` and `--panel-border` may stay `rgba()` in the theme, `--mask` never.

Fonts: diagrams render offline, so name the brand face first and follow it with system faces (`"Brand Sans", "Segoe UI", Arial, sans-serif`). Where the brand face is not installed, the diagram falls back to the system face; say so when you hand over a screenshot. A monospace face is not required. Sans-serif corporate faces work fine at the template's sizes.

Contrast: check every pair the contract names, in both modes, before saving. A throwaway script is the quickest check:

```bash
uv run python -c '
def l(h):
    c=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    c=[x/12.92 if x<=0.03928 else ((x+0.055)/1.055)**2.4 for x in c]
    return .2126*c[0]+.7152*c[1]+.0722*c[2]
a,b="#86BC24","#FFFFFF"; x,y=sorted([l(a),l(b)],reverse=True); print(round((x+.05)/(y+.05),2))'
```

When a brand color fails, darken it (light mode) or lighten it (dark mode) in steps of the same hue until it passes, and use the brand's own darker or lighter ramp step when the preset has one (for example a `--brand-green-dark`). Record every adjusted color in the manifest.

Save the result:

1. Write `.pgoell/diagrams/themes/<name>/theme.css`, named after the preset or brand (kebab-case), in the contract's two-block shape.
2. Write `manifest.md` beside it: source (preset path or PPTX file name and date), the mapping table as actually applied, adjusted colors with before and after contrast ratios, skipped colors, and gaps (a missing dark mode, an uninstalled font).
3. Write or update `.pgoell/diagrams/config.md` so later diagrams pick the theme up without asking:

   ```markdown
   ## Theme

   Name: <name>
   ```

4. Render the template's sample diagram with the new theme in both modes (see `layout-and-review.md`, section 6) and look at it before using the theme for real work.

A derived theme is user-owned: it lives in the working repo, not in the plugin, and needs no plugin change.
