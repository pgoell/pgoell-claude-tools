---
name: creating-diagrams
description: Use when the user wants an architecture, workflow, sequence, data-flow, or lifecycle (state) diagram as a polished standalone HTML file with inline SVG, light and dark modes, and image export. Takes a plain-language description, pasted Mermaid, or a repository to scan; renders through a bundled engine that validates layout geometry before delivery. Themeable, including themes derived from a presentations preset or a PowerPoint template so diagrams match a corporate brand.
---

# Creating Diagrams

Turn a question about a system into one validated, self-contained HTML diagram. The bundled engine (a vendored copy of archify, see the plugin `NOTICE`) takes a small typed JSON specification, lays it out, checks its geometry, and renders an interactive viewer: light and dark modes, pan and zoom, search, focus, guided views, presentation mode, and PNG, JPEG, WebP, SVG, and WebM export. Artifacts make no network requests.

In the commands below, `ENGINE` is the absolute path of this skill's `engine/` directory. The engine needs Node 18 or later and nothing else: no install, no `node_modules`.

## Inputs

- **A description** in plain language. Ask only about gaps that would change the diagram; mark the rest as assumptions in a card instead of inventing facts.
- **Pasted Mermaid.** Read it for topology and meaning, then author fresh JSON: `flowchart`/`graph` becomes `workflow` (or `architecture` for a component map), `sequenceDiagram` becomes `sequence`, `stateDiagram` becomes `lifecycle`. Never carry over Mermaid styling.
- **A repository.** Read entry points, service definitions, infra code (`docker-compose.yml`, Terraform, Kubernetes manifests, CI config), and the main call paths. Architecture components may cite source lines in `components[].sources`; the engine verifies every cited file and line against a pinned commit. Setup: `meta.repository` holds `url` (must match `git remote get-url origin`; a repo without an origin cannot be cited) and `revision` (the 40-character `git rev-parse HEAD`); pass `--repo-root $(git rev-parse --show-toplevel)`; cite paths relative to that top level, even when the user named a subdirectory; only committed content verifies. Details: the "Repository evidence" section of `$ENGINE/references/authoring-contract.md`. Draw only what the code shows.

## Workflow

Copy this checklist into the response and tick items off:

```
- [ ] 1. Check the engine and pick the diagram type
- [ ] 2. Resolve the theme
- [ ] 3. Write the JSON candidate
- [ ] 4. Validate and repair
- [ ] 5. Deliver
- [ ] 6. Browser check and visual review
- [ ] 7. Report
```

### 1. Check the engine and pick the type

Run `node --version`. Below 18 or missing: use the hand-drawn fallback at the end of this file and say so.

Choose the type from the question the reader asks:

| Type           | Use for                                                            |
| -------------- | ------------------------------------------------------------------ |
| `architecture` | Components, services, cloud and security boundaries, deployments   |
| `workflow`     | Processes, approval gates, tool calls, runbooks, CI/CD             |
| `sequence`     | API call chains, request lifecycles, async round trips             |
| `dataflow`     | Pipelines, ETL/ELT, lineage, governance, consumers                 |
| `lifecycle`    | State and status transitions, retries, waiting and terminal states |

When unsure, run `node "$ENGINE/bin/archify.mjs" guide "<the user's scenario>" --json`. When one question needs two types, draw two diagrams.

### 2. Resolve the theme

Read `../../themes/README.md` for the theme contract and selection order: prompt choice, then `.pgoell/diagrams/config.md`, then an offer to derive from a configured presentations preset, then `classic`. Bundled themes live in `../../themes/<name>/`; local ones in `.pgoell/diagrams/themes/<name>/` at the working repo root.

- **`classic`**: pass no flag. It is the engine's built-in palette.
- **Any other theme**: add `--theme <theme directory or theme.css>` to every `validate`, `deliver`, `preview`, and `render` command. The engine injects the theme into the artifact, computes node fills from the strokes, and uses the theme's font stack.
- **Brand colors wanted** ("match our PowerPoint", a client identity): read `references/theming.md`, derive a theme from the presentations preset or PPTX file, save it locally, then use it. Derive once; later diagrams resolve it from `.pgoell/diagrams/config.md`.

The engine also ships three alternative looks (`signal-flow`, `blueprint`, `editorial`) selected by `meta.visual_preset`. Use one only when the user asks for that style. A brand theme's colors override all four looks; the viewer's look menu still reads "Classic", which only names the layout decoration.

### 3. Write the JSON candidate

This is the "fast authoring path" that the engine's references mention. Read exactly three files: `$ENGINE/schemas/<type>.schema.json`, `$ENGINE/schemas/common.schema.json`, and one matching example in `$ENGINE/examples/`. Use the example for field shape, never for facts. New workflows use `schema_version: 2`.

Then write the candidate straight away. Do not plan coordinates in prose, and do not read renderer source before the first candidate exists.

- One obvious main path; side branches leave the nearest main-path node. At most 12 primary nodes.
- Space for labels, not like the examples. A relationship label needs a clear gap (edge to edge, not center to center) wider than `6.5px x characters + 13px`, plus 8px. The examples' 70 to 80px gaps fit only short labels. Stack nodes that share a vertical edge on one center line; different widths with offset centers trigger `endpoint-side-direction`.
- Architecture accepts free `pos` coordinates or `layout: {"mode": "grid"}` (fixed cell math); either works.
- Set `meta.quality_profile` to `"showcase"` unless the user asks for a dense map.
- Start with automatic routes and labels. Routing controls (`via`, `channelX`, `channelY`, `labelAt`, `fromSide`, `toSide`) come only when a diagnostic asks for one, one per repair. Moving or resizing nodes is always allowed.
- Component types are `frontend`, `backend`, `database`, `cloud`, `security`, `messagebus`, `external`; variants are `default`, `emphasis`, `security`, `dashed`.
- Relationship labels carry meaning (protocol, action, sync or async). Keep every meaningful one; deleting a label is never a layout fix.
- Omit `meta.subtitle`, `meta.visual_preset`, `meta.legend`, and `meta.engineering_profile` unless the user asks for what they control.
- Real product logos: put a built-in ID in a node's `brand` after `node "$ENGINE/bin/archify.mjs" brands "<name>" --json` finds it. Never infer a brand from a role like "database".

Save the candidate as `diagrams/<slug>.<type>.json` at the working repo root (next to the HTML), so the diagram can be edited and delivered again later. Read `$ENGINE/references/authoring-contract.md` when you need enums, spacing math, placement rules per type, or repository evidence.

### 4. Validate and repair

```bash
node "$ENGINE/bin/archify.mjs" validate <type> diagrams/<slug>.<type>.json --quality showcase --json [--theme <theme>] [--repo-root <repo>]
```

A showcase pass reports all 9 artifact checks with 0 errors and 0 warnings; a receipt with 4 checks is basic validation, not a pass. On failure, most diagnostics name a `subject`, its `evidence`, and `supportedFixes`; `layout/constraint` diagnostics carry the fix (often a `labelAt [x, y]`) only in the message text. Change only the diagnosed subject, apply the named fix, and validate again. Fix in this order: schema and quality profile, node overlap, edges through nodes and endpoint direction, crossings and corridors and border runs and segment rhythm, label clearance.

Keep going while the error count reaches a new minimum. If two rounds in a row do not improve it, stop and report the open diagnostics. A passing validation freezes the candidate: do not edit it afterward. For workflow v2 geometry questions, `validate workflow <file> --layout-json` prints the compiler's layout receipt.

### 5. Deliver

```bash
node "$ENGINE/bin/archify.mjs" deliver <type> diagrams/<slug>.<type>.json diagrams/<slug>.html --quality showcase --json [--theme <theme>] [--repo-root <repo>]
```

`deliver` validates a frozen snapshot again, renders, runs the artifact checks, and only then replaces the output, returning SHA-256 receipts for the specification and the artifact. A non-zero exit is a failure, and the previous file (if any) is untouched, so never inspect it as if it were new.

Output path: the path the user gives; otherwise `diagrams/<slug>.html` at the working repo root.

### 6. Browser check and visual review

```bash
node "$ENGINE/bin/archify.mjs" visual-check diagrams/<slug>.html --json
```

This opens the delivered file in headless Chrome at four desktop sizes (1440x900 up to 2048x1320), checks overflow and projected text size, and writes a receipt, a contact sheet, and light and dark PNG captures beside the artifact (`<slug>.visual-check.*`). It proves browser behavior, not polish, so its `visualReview` field always stays `pending`; your own review below is reported separately.

Then look yourself. Screenshot the delivered file in both modes and open the PNGs:

```bash
google-chrome --headless --hide-scrollbars --window-size=1600,1200 --screenshot=<scratch>/<slug>-light.png "file://<absolute path to diagrams/<slug>.html>"
google-chrome --headless --hide-scrollbars --window-size=1600,1200 --force-dark-mode --screenshot=<scratch>/<slug>-dark.png "file://<absolute path to diagrams/<slug>.html>"
```

`<scratch>` is any temporary directory outside the repo. Check that labels are legible, the main path is obvious, and brand colors are right in both modes. If you cannot view images, say the visual review was skipped. Read `$ENGINE/references/delivery-contract.md` for receipt fields and failure handling.

### 7. Report

Briefly: the HTML path and JSON source path, diagram type, theme (and whether derived this session), validation summary (`9/9 showcase, 0 errors, 0 warnings`), artifact SHA-256, browser check result, visual review result, repair rounds used, and anything drawn from assumption rather than source. Never report success for a non-zero command or a review you did not do.

## More engine commands

| Need                                       | Command                                                                     |
| ------------------------------------------ | --------------------------------------------------------------------------- |
| Diff two architecture versions             | `compare architecture <base.json> <head.json> <out.html> --json`            |
| Live-reloading preview while authoring     | `preview <type> <input.json> <out.html> --quality showcase`                 |
| Upgrade a v1 workflow to the v2 layout     | `migrate workflow <old.json> <new.json> --to-schema 2 --json`               |
| Brand from an official URL (network fetch) | `brands capture "<url>" --json`, then use the returned pinned `brand` value |
| Motion, guided stories, share cards        | Read `$ENGINE/references/viewer-runtime.md` first                           |
| Health check or a demo artifact            | `doctor`, `demo <dir>`                                                      |

## Fallback: hand-drawn SVG (no Node)

1. Pick the type and main path with `references/diagram-types.md`.
2. Resolve the theme as in step 2, then paste the resolved `theme.css` between the `THEME:START` and `THEME:END` comments of a copy of `references/template.html`.
3. Plan a grid and place every element from it, following `references/layout-and-review.md`.
4. Replace the sample SVG body (keep `<defs>` and the grid rect). Semantic classes only; no color literals anywhere.
5. Screenshot both modes with headless Chromium, review against the checklist in `references/layout-and-review.md`, and follow its repair order.

The fallback file has a theme toggle and SVG, PNG, and clipboard export, but no geometry validation and none of the engine's viewer features. Say which path you used.

## Related skills

- `presentations:creating-presentations` builds decks; export a diagram as SVG or PNG from the viewer's Export menu and place it on a slide, using a diagram theme derived from the same preset so the two match.
- `presentations:extracting-presets` turns a PPTX template or brand guide into the preset this skill derives diagram themes from.
- `workbench:crafting-html` covers standalone HTML artifacts that are not diagrams.

## Self-Healing

- **`node: command not found` or Node below 18**: use the hand-drawn fallback, or ask the user to install Node 18+.
- **`Brand theme ...: [data-theme="dark"] is missing ...`**: the theme file breaks the contract; add the named variables (see `../../themes/README.md`).
- **`Brand theme: --x-stroke must be #rrggbb or rgb()/rgba()`**: fills are computed from strokes, so strokes need plain color values, not `var()` or `color-mix()`.
- **`clean-flow/endpoint-side-direction` on stacked nodes although routing is automatic**: the two nodes' centers differ by a few pixels. Align their centers (same `x + width/2`).
- **An automatic label lands inside a node on a vertical edge**: apply the `labelAt` point the diagnostic's message gives.
- **Validation fails on geometry you did not touch**: re-read the diagnostic's `subject`; automatic port spread and routing move endpoints, so fix the subject named, not your guess.
- **`visual-check` reports Chrome unavailable**: report browser evidence as skipped; take screenshots with `google-chrome --headless --screenshot` if any Chromium exists, otherwise say the visual review was skipped.
- **A delivered file looks stale**: the last `deliver` failed and kept the previous artifact. Fix the diagnostics and deliver again.
- **Engine health**: `node "$ENGINE/bin/archify.mjs" doctor` checks renderers, schemas, and validators.
