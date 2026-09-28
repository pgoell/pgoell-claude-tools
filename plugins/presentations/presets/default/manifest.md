# Preset: default

## Who this serves

The neutral out-of-the-box preset for the `creating-presentations` skill, and the "quiet" visual direction: a near-white canvas, ink text, grays for everything secondary, one green accent with one job, and a deep blue-green scope for structure slides. All copy in the example slides is fictional placeholder content for an invented "Acme" platform-modernization proposal.

## Sources

- Own design work by the plugin author, originally produced with an AI design tool (claude.ai/design) in 2026 and maintained here as the source of truth. No external brand portal applies; there is nothing to cite back to.
- Neutralized for general reuse in 2026-07: raw variables renamed to `--brand-*` descriptive names, all wordmarks replaced with a placeholder, example copy rewritten.
- Rebuilt in 2026-09 against the AI presentation quality report (`reports/ai-presentation-quality-2026-09-28/report.md`, ranks 1, 2, 4, 6, 12, 13, and 20): larger type scale, template chrome removed, copy rewritten as action titles, `language.md` added, and nine proof-object layouts added.
- Revised in 2026-09 against the presentation design systems report (`reports/presentation-design-systems-2026-09-28/report.md`, "Conclusions", recommendations 1 and 2): DM Sans replaced by a face with tabular figures, the bright green moved to graphics only with a text-safe step, and the chart token group added.

## Coverage

- `colors.css`: raw brand layer (`--brand-green`, `--brand-green-ink`, `--brand-ember`, `--brand-deep`, ...), semantic layer (`--bg`, `--fg`, `--accent`, `--accent-ink`, ...), status colors, the chart group (`--chart-highlight`, `--chart-context`, `--chart-grid`, `--chart-1` to `--chart-4`, in both scopes), slide type scale with role floors (body 40px, captions and labels 28px, footer and source line at least 24px), spacing, radius, shadows, motion, and a `.dark` variant scope.
- `typography.css`: font stacks (Figtree, vendored in `assets/fonts/figtree/`, and JetBrains Mono, not vendored, with system fallbacks). The gallery uses only the sans stack.
- `language.md`: positive style contract, the rule against adding facts, and before/after title rewrites.
- `slides/`: nineteen example layouts, each self-contained with an embedded synced copy of the variable files and no network requests.
  - Content layouts, each led by an action title: Content, Stat (one big number that states the title's claim, with a before and after bar that shows where it comes from), Comparison, Capabilities (claim and evidence rows), Timeline.
  - Proof-object layouts, where the object under the title proves it: ChartInsight (line chart on two thirds, an insight callout on the last third with an arrow to the point), BarChart (one highlighted bar, the rest gray, direct labels, no legend), Waterfall, Table (the column the title names is highlighted), Process (5 steps at most), Matrix (2x2), ExecSummary (each bullet is the title of a later slide, word for word), ImageOverlay (full-bleed image with a dark overlay carrying the title), Diagram (boxes and connectors in inline SVG).
  - Charts are drawn from data. The chart element carries its numbers as `data-*` attributes (`data-chart` = `bar`, `line`, `waterfall`, or `scatter`; `data-labels` and `data-series` as JSON; `data-highlight` for the index the accent marks; `data-unit`; plus `data-orientation`, `data-totals`, or `data-marker-*` where the type needs them), and an inline script draws the SVG from those same values, so the picture and the markup agree and the PPTX exporter can rebuild a native chart.
  - ImageOverlay's image is a stand-in: a schematic store map drawn in inline SVG, since the gallery ships no photos. Real decks place a real evidence image there (a photo, map, or screenshot that shows the claim) of at least 1920x1080, never a stock photo.
  - Text below 36px carries `data-role="label"`, `"caption"`, or `"source"` (or a class naming its role) so gate H7 applies the right floor.
  - Structure layouts, visibly different from content (display-size type, no footer, dark scope for Divider, Quote, and Closing): Title, SectionDivider, Quote, Closing.
  - Opt-in for longer decks only: Agenda and SectionDivider. A short deck goes straight from Title to content.
- `assets/`: `placeholder-wordmark.svg` (generic) and `fonts/figtree/` (the font file and its `OFL.txt`).

## What this direction avoids

The quiet direction is built to avoid the "template chrome" default that Claude-made decks converge on, which this preset's earlier gallery carried. It no longer has: tracked uppercase eyebrows above headings, accent-colored periods, accented or underlined words inside headlines, monospace micro labels, "01 / 10" slide counters, 01 to 04 numbering on lists that are not sequences, middle-dot meta strings, a row of three stat tiles, a grid of three icon-topped cards, freehand icons, a decorative motif, and a full-width accent rule above the footer.

It also sits apart from two other convergent looks: warm cream with a serif display face and a terracotta accent, and near-black with a single acid-green accent. Its canvas is near-white, not cream; its dark scope is blue-green and carries no accent color.

## Extraction decisions

- One accent, one job: `--accent` (bright green) marks the single thing to look at, such as the current agenda item, the new state in a comparison, or the milestone a timeline title names. Ink and grays carry everything else. `--accent-partner` (ember) stays only as a second chart series color.
- The bright green `--brand-green` (#86BC24) measures 2.2:1 on the light background, so `--accent` appears only in graphics that do not carry data alone (rules, dots, markers). Accent-colored text uses `--accent-ink`, set to the new `--brand-green-ink` (#567817: 4.9:1 on `--bg`, 4.6:1 on `--bg-subtle`, 5.1:1 on white). The older `--brand-green-dark` (#5C8A18) measures only 3.9:1 on `--bg` and stays a pressed-state value, not a text color. In the dark scope the bright green clears 6:1, so `--accent-ink` points back at it there.
- Charts read `--chart-highlight` for the story series, set to the text-safe green (the bright green falls under the 3:1 floor for chart marks), and `--chart-context` for the rest. The four categorical colors (green, cobalt, wine, rose in light; their lighter steps in dark) pass a Machado 2009 protan, deutan, and tritan simulation at CIEDE2000 14 or more and clear 3:1 on the background. Ember left the charts: next to the green it forms a red-green pair that merges under deuteranopia, so `--accent-partner` now matches `--chart-2`.
- Figtree replaces DM Sans. DM Sans has no tabular figures, so numbers in tables and chart axes could not align. Figtree keeps the quiet geometric direction (a similar build and an x-height of 0.500 of the em, close to DM Sans), carries a `tnum` feature, needs 20 KB for the latin variable file, and has no Reserved Font Name. Inter would be the obvious alternative but is the most cited "AI deck" font; IBM Plex Sans and Source Sans 3 belong to the analytical and editorial presets.
- `--fg-subtle` darkened from #8A8682 to #6F6B68 (about 5:1 on `--bg`) so source lines and footers stay legible at 28px. In the dark scope `--fg-inverse-subtle` rose from 50% to 62% opacity (6.0:1 on `--brand-deep`, 5.3:1 on the elevated surface), and the dark override of `--accent-fg` was dropped: off-white on the bright green measured 2.2:1, ink measures 8.6:1.
- The footer is optional: a source line on the left when the slide shows numbers, the wordmark on the right when the brand needs it. No rule, no slide counter. Structure slides carry no footer.
- At most three text sizes per slide. The type tokens name their roles; never shrink text below the floors to make it fit.
- The `.dark` scope keys off `--brand-deep`; SectionDivider, Quote, and Closing apply it with the `dark` class.
- The UI-card type scale that existed in the source token sheet was dropped; only the slide scale ships.
- Figtree ships unmodified as `assets/fonts/figtree/Figtree-Variable.woff2` (npm `@fontsource-variable/figtree@5.3.0`, `files/figtree-latin-wght-normal.woff2`, fetched 2026-09-28 via jsDelivr; OFL-1.1, no Reserved Font Name; 20 KB) with the package's license as `OFL.txt`. Slides load it by relative path, so they render identically offline and make no network request.
- The ember stripe motif (`assets/motif-blocks.svg`) was removed in the 2026-09 rebuild: it was decoration with no information.

## Gaps

- The wordmark is a placeholder ("ACME" with an accent dot, as the inline `.wordmark` component in slides and `assets/placeholder-wordmark.svg`). Swap it for a real brand's official wordmark before any external use.
- No `guidelines.md`: this preset carries no brand personality or imagery rules beyond `language.md` and the notes above.
- No `icons/` library, so example slides use no icons.
