# Tabbed

The Heimatblatt look, cut into tabs. Every section is one tab, so an edition
can carry as many stories as the config allows without growing into one long
scroll. Fonts, tokens, story layout and the framed "Aus der Region" block are
Heimatblatt's; see `../heimatblatt/NOTES.md`. `overrides:` set for Heimatblatt
carry over unchanged. The template imports Heimatblatt's `macros.html.j2` and
includes its three CSS parts, then adds the tab strip, the bracket and the
tables (`sports.html.j2`).

## Tabs

- A sticky strip under the masthead: "Titelseite", then one tab per section in
  config order, each with its story count. The home section's tab is green.
- At desktop width the strip wraps to a second row; at phone width it scrolls
  sideways on its own, so the page never scrolls sideways.
- "Titelseite" holds the lead and "Heute in dieser Ausgabe": every section with
  its count and its first three headlines, each a link into its tab.
- There is no "In Kürze" block. A brief sits at the foot of its own section's
  tab under "Außerdem" ("Außerdem aus der Region" in the home section).
- The footer (previous edition, feedback hint, recent feedback) shows under
  every tab.

## Script

- A few lines of inline script show one panel at a time. A link to `#sec-<id>`
  or to any story id opens the tab that holds it, on click and on load, so a
  follow-up link `YYYY-MM-DD.html#<story id>` from a later edition lands on the
  right tab and scrolls to the story below the strip.
- Panels hide only once the script has run (`.js` on `<html>`). Without script
  every panel shows and the page reads as one scroll.
- A sideways swipe (60px or more, at least twice as wide as tall) opens the
  next or the previous tab, without wrapping. A swipe that starts in the tab
  strip, a bracket or a table stays with that element, which scrolls sideways
  itself.
- No storage: kasten's pane sandboxes the page without `allow-same-origin`, so
  `localStorage` throws. The open tab lives in the URL hash.

## Bracket

Modelled on the lolesports.com stage view. The macros live in
`sports.html.j2`, the CSS in `sports.css.j2`.

- A story with `bracket` gets it under its text, across the story's full
  width: one column per round, left to right, each under a grey band with its
  name.
- Each side shows its tag from `bracket.tags` in a small mono box, then the
  name, then the score. The winner is bold with an accent bar at its left edge, an
  accent score and an accent tag box; the loser is muted. A match not played
  has a dashed frame and its `when` in accent.
- Knockout (no match carries `record`): every match sits in an equal slot, so
  each round centres between the matches that feed it. When the next round has
  half as many matches, an elbow joins each pair to the match it feeds;
  otherwise short rules join the columns.
- Swiss (any match carries `record`): matches stack from the top, and a band
  starts each run of matches with the same record: the record, then one green
  dot per win and one red dot per loss. No lines, because a Swiss pairing does
  not feed one match.
- At phone width the bracket scrolls sideways inside its own box; the page
  never does.

## Tables

- A section with `tables` ends with "Tabellen": one fold per league, the first
  open, each with its matchday and a link to sportschau.de. Columns are rank
  with a rise or fall arrow, club, games, won, drawn, lost, goals, difference
  and points.
- At phone width won, drawn, lost and goals hide, so the table fits without
  scrolling; the wrapper still scrolls sideways if a club name runs long.

## What I would tune

- With 14 or more sections the phone strip hides most tabs off screen; a fade
  at the right edge would show that the strip scrolls.
