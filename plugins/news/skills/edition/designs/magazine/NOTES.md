# Magazin

A weekend-supplement layout for a daily paper. The lead runs as a full-bleed photo with the headline set under it; each section opens on a large accent numeral.
Importance sets the scale: 3 is a feature with a big 3:2 image (sides alternate per section, image sticks while the text scrolls), 2 is a 4:3 card in a 1 to 3 column grid, 1 is a text-only tile.
A missing image is a deliberate tinted plate: a feature becomes a typographic cover with two-column text, a card shows the source and tags set in italic.

## Fonts

- `--font-head`: Fraunces (variable, opsz 120 to 144 for display, italic for decks and masthead)
- `--font-body`: Source Serif 4
- `--font-meta`: Inter Tight (meta lines, kickers, follow-up boxes)

## Palette tokens (light / dark)

- `--paper` #f7f4ee / #151412
- `--paper-2` #efe9df / #1f1d1a (plates, weather, no-image panels)
- `--ink` #1b1a18 / #ede8df, `--ink-2` #3d3a35 / #cbc5ba
- `--muted` #7b756b / #958e82, `--rule` #d9d2c5 / #34312c
- `--accent` #b5401f / #ec7a52 (terracotta, the only colour)

## What I would tune

- Fraunces at display size has sharp hairlines; on low-DPI screens the lead headline can look thin. Weight 400 is the safe fallback.
- The page runs long on phones (about 35,000px); a collapsed summary for importance 2 on mobile would shorten it.
- Meta labels are German for de stories and English for en; section and page chrome are German only.
- The text-only plate uses tags; with no tags it shows only the source.
