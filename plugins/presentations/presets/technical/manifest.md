# Preset: technical

## Who this serves

Engineers presenting to engineers: architecture reviews, design docs presented live, engineering deep dives, incident reviews, and platform or data-engineering talks. The audience reads diagrams and code closely, so the slides are dense by design. All copy in the example slides is fictional placeholder content for an invented checkout write-path review (RFC-142): a synchronous fraud call pushed p99 from 240 to 610 ms, and the team moves order writes to a transactional outbox with Kafka.

## Sources

- Layout grammar: assertion-evidence research and engineering-slide guidance from the presentation design systems report of 2026-09-28 (`reports/presentation-design-systems-2026-09-28/report.md` and `research/layouts-reference-decks.md`: Alley and Neeley 2005, Alley et al. 2006, Garner and Alley 2013, the Alley checklist, Mayer and Fiorella, BrightCarbon's 12-column grid).
- Diagram notation: the C4 model's rules for labelled boundaries and a key for every shape and color, and the engineering design-doc forms it borrows for structure slides (RFC header, ADR in Nygard's context, decision, consequences shape).
- Wording rules: the report's "Wording rules for `language.md`", adapted to engineering copy (identifiers, units, percentiles).
- Colors, fonts, and every example slide were built for this preset on 2026-09-28; no source deck was copied.

## Coverage

- `colors.css`: light `:root` scope and a `.dark` scope (the default for content slides), with the contract tokens, the chart group (`--chart-highlight`, `--chart-context`, `--chart-grid`, `--chart-threshold`, `--chart-1` to `--chart-3`), diagram tokens (`--node-service`, `--node-datastore`, `--node-queue`, `--node-external`, `--node-boundary` with fills, `--edge`, `--edge-highlight`), code tokens (`--code-bg`, `--code-fg`, `--code-keyword`, `--code-string`, `--code-comment`, `--code-number`, `--code-fn`, `--code-highlight-line`, `--code-gutter`), the type scale, the 12-column grid tokens, and stroke tokens.
- `typography.css`: Red Hat Display, Text, and Mono, vendored.
- `guidelines.md`: voice, the layout grammar, the diagram notation, color and type rules.
- `language.md`: ten rules for technical copy and a before and after table.
- `slides/`: TitleSlide, SectionDivider, ArchitectureSlide, SequenceSlide, DataFlowSlide, PipelineSlide, CodeSlide, TradeoffTableSlide, DecisionSlide, LatencyChartSlide, ClosingSlide. All are new for this preset; none is adapted from `default`. Each embeds a synced copy of the variable files, makes no network request, and opens in the light scope with `#light` in the URL (`#dark` forces dark).
- `assets/fonts/`: three vendored font files with their license.

## What this direction avoids

Cool graphite and paper neutrals with one amber trace-highlight accent and the Red Hat superfamily; avoids the near-black-and-orange Geist launch look (`product`), the navy-and-blue board paper (`analytical`), vendor icon sets and cloud logos in diagrams, and the neon-on-black "hacker" code slide.

## Decisions

- Amber is the only accent, so the highlighted path, the highlighted code lines, the story series, and the recommended option all read as "look here". In the light scope amber (`#B07400`) is for graphics only; `--accent-ink` (`#7F5200`) carries accent-colored text.
- Node types are color plus shape. The node colors were searched for the widest color-blindness separation, which put the queue in orange and the datastore in green; neither is ever used as an accent.
- Titles stay in Red Hat Display, even when they name an identifier: a mono run inside a title trips the copy lint's accent-word tell (K2) and reads as decoration.
- Diagram labels, table cells, and code sit at 28px to 32px (`--fs-label`, `--fs-table`), marked `data-role="label"` where the H7 probe would otherwise read them as body text. Body text stays at 36px.
- `--fs-h1` is 60px, not 72px: technical titles carry identifiers and numbers and must fit two lines on 11 columns.
- `--lh-code` is 1.4 so 16 lines of 28px code, the file path, and padding fit the 736px evidence area.
- Structure slides use `--bg-deep` in the dark scope so they stay distinct from dark content slides by background as well as composition.
- The latency chart renders from its `data-*` attributes (labels, series, threshold, annotation), like the default preset's charts, so the PPTX exporter can rebuild it.

## Contrast (WCAG 2.x)

Ratios on `--bg`, `--bg-elev`, `--bg-subtle`, computed with a script from the hex values.

| Token               | Light                               | Dark                |
| ------------------- | ----------------------------------- | ------------------- |
| `--fg`              | 16.32, 17.96, 15.05                 | 14.89, 13.55, 14.29 |
| `--fg-muted`        | 8.12, 8.94, 7.49                    | 8.89, 8.09, 8.54    |
| `--fg-subtle`       | 5.51, 6.06, 5.08                    | 6.09, 5.54, 5.84    |
| `--accent-ink`      | 6.14, 6.75, 5.66                    | 11.06, 10.07, 10.62 |
| `--accent`          | 3.57, 3.93, 3.29 (graphics only)    | 11.06, 10.07, 10.62 |
| `--node-service`    | 4.37, 4.81, 4.03                    | 5.52, 5.03, 5.30    |
| `--node-datastore`  | 4.86, 5.35, 4.48                    | 9.62, 8.76, 9.24    |
| `--node-queue`      | 5.64, 6.20, 5.20                    | 5.98, 5.44, 5.74    |
| `--node-external`   | 4.16, 4.58, 3.84                    | 6.09, 5.54, 5.84    |
| `--node-boundary`   | 3.52, 3.87, 3.24                    | 3.75, 3.41, 3.60    |
| `--edge`            | 4.16, 4.58, 3.84                    | 4.82, 4.38, 4.62    |
| `--chart-threshold` | 5.97, 6.57, 5.51                    | 7.12, 6.48, 6.83    |
| `--chart-context`   | 2.01 on `--bg` (deliberately quiet) | 2.24 on `--bg`      |

- `--fg` on every node fill holds 15.00 or more (light) and 9.62 or more (dark).
- Every code token holds 4.5:1 on `--code-bg` and on `--code-highlight-line`: light lowest is `--code-string` at 5.33 and 4.70, dark lowest is `--code-comment` at 6.36 and 5.08.
- Structure slides: `--fg-subtle` on `--bg-deep` is 6.41, `--accent` 11.66.

## Color-blindness check

Machado et al. (2009) simulation at full severity (the `colour-science` matrices), then CIEDE2000 between every pair of `--node-service`, `--node-datastore`, `--node-queue`, `--node-external`, and `--edge-highlight`. Target: 10 or more for every pair under every simulation.

| Scope | Normal                   | Protanopia                  | Deuteranopia            | Tritanopia                |
| ----- | ------------------------ | --------------------------- | ----------------------- | ------------------------- |
| Light | 16.8 (service, external) | 12.6 (datastore, highlight) | 11.7 (queue, highlight) | 12.8 (service, datastore) |
| Dark  | 17.6 (service, external) | 14.9 (datastore, highlight) | 13.9 (queue, highlight) | 16.1 (service, datastore) |

Each cell is the smallest pairwise difference and the pair that produced it. The SLO line against the amber story series stays at 12.3 or more (light) and 13.6 or more (dark) under all three simulations. Shapes and labels encode the same types, so no reading depends on color alone.

## Fonts

| Family          | File                                     | Source                                                                                                     | License | Size  |
| --------------- | ---------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ------- | ----- |
| Red Hat Display | `red-hat-display/RedHatDisplay-VF.woff2` | `RedHatOfficial/RedHatFont` at `6bb1048`, `fonts/Proportional/RedHatDisplay/webfonts/`, fetched 2026-09-28 | OFL-1.1 | 40 KB |
| Red Hat Text    | `red-hat-text/RedHatText-VF.woff2`       | same repository and commit, `fonts/Proportional/RedHatText/webfonts/`                                      | OFL-1.1 | 39 KB |
| Red Hat Mono    | `red-hat-mono/RedHatMono-VF.woff2`       | same repository and commit, `fonts/Mono/RedHatMono/webfonts/`                                              | OFL-1.1 | 29 KB |

- Version 1.030 variable fonts (weight 300 to 700; Display to 900), unmodified. Each `OFL.txt` is the repository's `OFL.txt` at the same commit.
- Reserved Font Name: the repository's `OFL.txt` and the fonts' own name table declare OFL-1.1 with no Reserved Font Name, but the older `LICENSE` file in the same repository (2021, Red Hat, Inc.) reserves "Red Hat". Treat the family as carrying the RFN: never subset or otherwise modify the files.
- Features: Red Hat Text and Display have `tnum`, `pnum`, and a slashed `zero`; Red Hat Mono is fixed-width (0.6 em advance, 16.8px at 28px). The fonts cover Latin only, with no arrows or math symbols (no U+2192, no U+2264): draw arrows in SVG and write "under 300 ms" or `< 300 ms`.
- No other bundled preset uses Red Hat as its primary sans.

## Verification

- Every slide rendered at 1920x1080 in both scopes (structure slides dark only) and checked by eye.
- The creating-presentations hard-gate probes (H1, H2, H6, H7, H9) and the copy probe (H8) ran against every slide in both scopes with no failures. Remaining warnings: word counts over the 50-word briefing budget on the code, table, decision, and sequence slides, which the grammar accepts for this preset.

## Gaps

- Not yet built for this voice: incident timeline, state machine, entity-relationship diagram, capacity or cost bar chart, dashboard of four to six metrics, and a before and after architecture pair. For other roles, restyle the `default` gallery layout with these variables.
- No `icons/` library by design: the diagram shape vocabulary replaces icons.
