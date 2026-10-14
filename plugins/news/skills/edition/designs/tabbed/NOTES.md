# Tabbed

The Heimatblatt look, cut into tabs. Every section is one tab, so an edition
can carry as many stories as the config allows without growing into one long
scroll. Fonts, tokens, story layout and the framed "Aus der Region" block are
Heimatblatt's; see `../heimatblatt/NOTES.md`. `overrides:` set for Heimatblatt
carry over unchanged.

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
- No storage: kasten's pane sandboxes the page without `allow-same-origin`, so
  `localStorage` throws. The open tab lives in the URL hash.

## What I would tune

- With 14 or more sections the phone strip hides most tabs off screen; a fade
  at the right edge would show that the strip scrolls.
- Swiping between tabs on a phone would suit the format, at the cost of more
  script.
