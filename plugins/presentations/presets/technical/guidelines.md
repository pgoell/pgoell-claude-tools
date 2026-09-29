# Guidelines: technical preset

## Voice

Precise and dense. Each title states the design decision or the finding, with the number that proves it. The slide shows the system: a component map, a sequence, a pipeline, the code, the measured curve. Engineers read diagrams and code closely, so the slide can hold more than a keynote slide, as long as the structure carries it.

## Use it for

Engineering deep dives, architecture reviews, design docs presented live, incident reviews, and platform or data-engineering talks. It suits shared screens and meeting rooms. For a product launch or an all-hands, use `product`; for a board paper, use `analytical`.

## Layout grammar

Engineering-docs grammar: the design doc and the architecture review, presented. The slide is an assertion plus its evidence (Alley's assertion-evidence slides, which grew out of engineering and science talks), and the evidence is almost always a drawing of the system. Sources are the engineering and assertion-evidence sections of the presentation design systems report (Alley and Neeley 2005, Garner and Alley 2013, the Alley checklist, the Mayer and Fiorella multimedia principles), the consulting grid research for the 12-column grid (BrightCarbon), and the C4 model's diagram notation (labelled boundaries, a key whenever shape or color carries meaning).

### Grid

- 12 columns of 122px with 24px gutters between 96px side margins (`--grid-col`, `--grid-gutter`, `--slide-pad-x`); column `n` starts at `96 + n * 146` px. BrightCarbon recommends 12 columns for 16:9 because they split into 6, 4, 3, and 2.
- Top margin 64px (`--slide-pad-y`), tighter than the other presets, because the evidence needs the height.
- Common splits: 12 (diagram as hero), 9 + 3 (code panel and its callout), 3 + 3 + 3 + 3 (data-flow stages, tradeoff table), 2 + 10 (ADR side headings and text), 4 + 8 (section tracker and section title).

### Fixed positions

| Element       | Position                                                         | Size                      |
| ------------- | ---------------------------------------------------------------- | ------------------------- |
| Action title  | top left at 64px, 11 columns wide, at most two lines             | `--fs-h1` (60px)          |
| Evidence area | from `--evidence-top` (232px) to 112px above the bottom edge     | 1728 x 736px              |
| Source line   | bottom left, 40px from the bottom edge, only on slides with data | `--fs-micro` (24px)       |
| Diagram key   | last row of the evidence area, left aligned                      | `--fs-label` (28px), sans |

The evidence area starts at 232px whether the title runs one line or two, so a diagram never jumps between slides. Draw every diagram as one inline SVG at 1:1 in a `1728 x 736` view box, so SVG font sizes are true pixels.

### Density

- Up to 60 words per content slide, counting diagram labels and table cells but not code. A code slide holds 15 to 25 lines. Titles and body run in `presented` or `briefing` mode; the copy lint's 50-word briefing budget is a warning here, not a limit.
- 8 to 14 nodes per diagram with labels at 28px or more. A larger system splits across slides (context map, then one slide per zone) or builds up over several slides.
- At most 20 layout units per slide: a diagram is one SVG, a table is one table, a code listing is one `pre`.
- Three type sizes per slide: title 60px, evidence 28px to 36px, source 24px. Density comes from structure (diagrams, tables, tight grids), never from smaller type.
- Whitespace stance: the diagram takes the whole evidence area; leftover space sits around the diagram's outer edge, not between title and evidence.

### Diagram notation

Every node type has a color and a shape, so color is never the only cue (C4: a key explains every shape and color; WCAG 1.4.1: color is not the only visual means).

| Type      | Shape                                        | Tokens                                        |
| --------- | -------------------------------------------- | --------------------------------------------- |
| Service   | rounded rectangle, 12px radius               | `--node-service`, `--node-service-fill`       |
| Datastore | cylinder                                     | `--node-datastore`, `--node-datastore-fill`   |
| Queue     | rectangle with three message ticks at right  | `--node-queue`, `--node-queue-fill`           |
| External  | square-cornered rectangle, dashed stroke     | `--node-external`, `--node-external-fill`     |
| Boundary  | dashed container, text label inside top left | `--node-boundary`, no fill                    |
| Edge      | 3px line with a solid arrowhead              | `--edge`                                      |
| Path      | 6px line, the one path the title names       | `--edge-highlight` (the accent)               |
| Return    | dashed edge (sequence diagrams)              | `--edge` or `--edge-highlight`, dash `10 8`   |
| Gate      | diamond (pipelines)                          | `--fg-muted` stroke on `--bg-elev`            |
| Stage     | rounded rectangle, neutral (pipelines)       | `--fg-subtle` stroke on `--bg-elev`           |
| Terminal  | pill (pipelines)                             | `--fg-subtle` stroke; accent when on the path |

- Node labels are identifiers in `--font-mono` at 28px, centered, at most 13 characters in a 240px node. Name the component the way the code and the dashboards do (`checkout-api`, `orders.v1`), never a prettified name.
- Trust boundaries (VPC, cluster, account, third party) are labelled dashed containers. Every node sits inside the boundary that owns it.
- Route edges orthogonally, with no crossings between edges. A fan-out may share a trunk.
- Number edges only when order matters (sequence diagrams, numbered steps in an incident timeline). A component map carries no numbers.
- Add the shape key (a row of small shapes with their names) only when shapes carry meaning, which on component maps and data-flow diagrams they do. Sequence and pipeline diagrams use universal notation and go without.
- Diagram text on lines and lifelines sits on a halo of the surface color (`paint-order: stroke`), so a line never cuts a label.

### Signature moves

1. **The diagram is the hero.** Component maps, sequences, data flows, and pipelines fill the full 12-column evidence area, drawn in the notation above, with one accent path.
2. **Identifiers in mono, everywhere but the title.** Service names, topics, tables, file paths, owners, and flags appear in Red Hat Mono at 28px or more in diagrams, tables, and body. The title stays in the sans (a mono run in a title reads as an accent word).
3. **Design-doc structure slides.** The title slide is an RFC header (doc id, claim, then a ruled Status, Owner, Reviewers, Decision by row); the section divider is the deck's real section list with the current one marked; the decision slide is an ADR (context, options, decision, consequences); the closing slide is actions with owners and dates, plus the next review and its pass condition.
4. **Code with a margin note.** A code panel on 9 columns, one highlighted band of 2 or 3 lines, and a callout on the remaining 3 columns whose accent rule sits level with the band.

### Never

- A bullet list as the only evidence on a content slide.
- Vendor logos, product icons, or cloud-provider icon sets in diagrams (the shape vocabulary replaces them).
- Diagonal or crossing edges, 3D, drop shadows, gradients, glow.
- More than one highlighted path per diagram, or an accent used for anything but that path, the highlighted code lines, the story series, or the recommended option.
- A legend box for a chart (label the lines at their ends).
- Code below 28px, code screenshots, or code without its file path.

### Layouts built for this grammar

TitleSlide (RFC header), SectionDivider (section tracker), ArchitectureSlide (13-node component map, three boundaries, one path), SequenceSlide (5 lifelines, 10 numbered messages, synchronous fragment, one highlighted async return), DataFlowSlide (sources to ingestion to storage to consumers), PipelineSlide (stages, two gates, a highlighted failure branch), CodeSlide (16 lines, three highlighted, margin callout), TradeoffTableSlide (3 options by 6 criteria, recommended column tinted), DecisionSlide (ADR), LatencyChartSlide (p50, p95, p99 with SLO line and regression annotation), ClosingSlide (actions, owners, next review), IncidentTimelineSlide (8 milestones on one axis, the detect-and-escalate phase bracketed), FlameGraphSlide (one hot tower in amber, three callouts above), AnnotatedTerminalSlide (command output with highlighted bands and margin labels), BeforeAfterBenchmarkSlide (one load test as reported and corrected, on one scale), CapacityCurveSlide (a 4-step reasoning chain beside the p99-by-load curve), ReferenceNumbersSlide (11 spans in one unit, right aligned), StateMachineSlide (5 states and 6 transitions, one state in amber), TalkMapSlide (the agenda, then the same map as progress).

## Color

- One accent, amber, marks the one thing the title names: the path in a diagram, the highlighted code lines, the story series in a chart, the recommended option in a table, the current section on a divider, the next review on the closing slide. Use `--accent-ink` for accent-colored text.
- Node colors mean node types and nothing else. The SLO or budget line uses `--chart-threshold`, always dashed and labelled.
- Content slides default to the `.dark` scope. For a bright room or a printed review, drop `.dark` from content slides and keep it on structure slides. Structure slides use `--bg-deep` in both cases, so they stay distinct by background and composition.

## Type

- Red Hat Display for titles at 60px and above; Red Hat Text for body, labels, tables, and captions; Red Hat Mono for code and identifiers only, never for decoration or micro labels.
- Tables, chart labels, and dates use tabular figures (`font-variant-numeric: tabular-nums lining-nums`).
- A number and its unit never break across lines: join them with a no-break space (`140&nbsp;ms`).

## Imagery

Diagrams of the real system, drawn in the notation above, and real dashboards or traces when a screenshot is the evidence, cropped to the part that proves the point. No stock photography, no device mockups, no icons.
