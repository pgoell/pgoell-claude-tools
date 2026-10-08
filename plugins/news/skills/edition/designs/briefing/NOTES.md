# Briefing

A calm morning brief for the phone over coffee, after Espresso, Semafor and FirstFT.
One reading column (38rem) with a slim index: sticky chips on the phone, a sticky
table of contents with minutes per section on the desktop. "Seit gestern" sits first
and gathers every follow-up; stories are compact units with a floated thumbnail that
the summary wraps around, and the dek in teal italic carries the "why it matters".

Fonts: Newsreader (head and body, optical sizes), Instrument Sans (UI, meta, index).

Tokens (light / dark):

- --paper #f8f6f1 / #141716, --paper-2 #efece4 / #1c201f
- --ink #1d1f1e / #e7e3da, --ink-2 #3c403e / #c9c5bc
- --muted #6c706c / #8f948f, --rule #dcd8ce / #2e3331
- --accent #1e5c58 / #7fbfb5 (deep teal), --accent-soft #e2ebe7 / #1d2b29
- --flag #a8471f / #e39a72 (follow-ups only)
- --font-head, --font-body, --font-ui, --measure, --bar

Rules: importance 3 with an image gets a wide 2:1 picture (lead 16:9); everything else
a thumbnail (square on phone, 4:3 on desktop). An image-less opener gets a teal left
rule; image-less small stories simply run full width. Broken images remove their own
figure (onerror). Reading time is (headline + summary words) / 220 per section.

JS: about 15 lines, an IntersectionObserver that marks the current index entry and
keeps the active chip in view on the phone. The page works without it.

To tune: the summaries are long for a "brief", so the page runs 22k px on desktop;
a per-story "mehr" fold or shorter summaries for importance 1 would help. The desktop
index column is empty space below the TOC; weather or briefs could live there. The
"Seit gestern" box repeats the lead's update note; fine with 2 items, may want a cap.
