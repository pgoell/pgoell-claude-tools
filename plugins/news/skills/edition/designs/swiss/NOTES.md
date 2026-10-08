# Raster

Swiss modernist newspaper on a strict 12-column grid. Columns 1-2 hold a sticky hanging tab per section
(red tabular number, name, kicker); columns 3-12 hold the copy. Hierarchy comes from size and weight only,
one signal red marks numbers, follow-ups and "Neu:". Every image is 3:2; a story without one gets a grey
panel with its story number (6.1) in red, so the gap reads as part of the system.

Fonts: Inter (variable, opsz 14-32, 400-800) for everything; tabular lining figures for numbers and meta.

Tokens (light / dark):

- --paper #fbfbf8 / #121212
- --ink #111111 / #ececea
- --accent #e2001a / #ff4a4a
- --muted #6b6b66 / #9a9a94
- --rule #d6d6d0 / #33332f
- --panel #eeeee9 / #1d1d1b (placeholder fill)
- --font-head, --font-body: Inter stack

Layout rules: lead = headline over 10 cols, image 6 + side column 4 (dek, Neu, earlier coverage, meta),
summary under the image. Section: first story image 6 + text 4; the rest pair up 5 + 5; an odd last story
spans 10 cols lying on its side so no card stands alone. Briefs in two columns with section label.
Phone: tabs become a header row, single column, placeholders shrink to a numbered strip.

Would tune: the first story's
text column runs longer than its image when summaries are long; page is long because every summary is
shown in full, so importance 1 stories could drop to headline + two lines; Inter's ß and quotes at display
sizes deserve a look with Schibsted Grotesk as an alternative head face.
