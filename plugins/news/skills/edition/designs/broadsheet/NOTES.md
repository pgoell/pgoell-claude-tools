# Broadsheet

Idea: a quality German print front page (FAZ, NYT print). Fraktur masthead over a double rule,
a lead with a 16:9 photo and justified two-column text beside a narrow "Kurz notiert" rail with
the weather, then each section behind a heavy rule as a three-column grid with hairline column rules.

Fonts: UnifrakturMaguntia (masthead), Playfair Display (headlines, deks), Source Serif 4 (body, small caps meta).

Tokens: --paper #f6f1e7 / dark #10141c, --paper-2, --ink #1b1a17 / #e7e1d2, --ink-2, --muted,
--rule (heavy rules), --hair (hairlines), --accent #8a1c1c / #e08a74, --font-mast, --font-head, --font-body, --gap.

Layout rules: importance 3 spans two columns (picture 2:1 on top, body in two columns, drop cap when
there is no picture); a section of 4 stretches its last story over two columns with the picture beside it.
Column and row rules sit in the gutters as pseudo-elements and the grid clips the outer ones.
Phones: one column, ragged right (no rivers where the browser lacks a hyphenation dictionary).

Would tune: justified text in narrow columns relies on hyphens:auto (headless Chrome on Linux has
no dictionary, so the screenshots show rivers; Safari and Firefox hyphenate). A no-image top story beside a
long neighbour leaves white space below it.
