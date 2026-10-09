---
name: editing-presentations
description: Use when the user wants to change an existing HTML deck by hand in the browser, or wants to point at slide elements instead of describing them. Starts a local editor on a deck from the creating-presentations skill, and reads what the user selected there. Triggers on requests like "open the deck editor", "let me edit this deck myself", "I selected something, fix it", or "change this" while the editor runs. For building a deck or reviewing it to done, see the creating-presentations skill.
---

# Editing Presentations

A local editor for the HTML decks the `creating-presentations` skill builds. The user clicks elements in the running deck and types a note; the host agent reads the selection from a file and edits the source. The deck HTML and its stylesheet on disk stay the only source: the editor and the agent take turns on the same files, and the browser reloads when either one writes.

## Dependencies

- Python 3.9 or later runs the server (`python3`, or `uv run python` when the host has only `uv`). Standard library only, nothing to install.
- A Chromium-based browser shows the editor. The same binary on `PATH`, headless, takes the selection screenshot; without one the screenshot step is skipped and everything else works.

## Start the editor

Run the server in the background from this skill's directory and give the user the URL it prints:

```bash
python3 assets/server.py <path/to/deck.html> [port]
```

The port defaults to 4747. The server binds to 127.0.0.1 only. When the session runs on a remote machine, the user forwards the port first (`ssh -L 4747:127.0.0.1:4747 <host>`) and opens the same URL locally.

What the server does:

- Serves the deck from the highest directory its `../` references reach, so a shared engine or asset folder outside the deck directory resolves.
- Adds a `data-de` attribute (the element's offset in the source file) to every element inside `<deck-stage>` and appends the overlay script. Both exist only in the served page, never in the file.
- Watches every file the page loaded and reloads the browser when one changes. The slide, the note, and the selection survive the reload where the selected elements still exist.

One server edits one deck file. Stop it when the user is done (`pkill -f '[s]erver.py'`).

## Read the selection

In the editor the user clicks an element to select it, shift-clicks to add more, clicks a name in the panel's path to step up to a parent, and types a note. Every change lands in `.deck-editor/selection.json` next to the deck:

```json
{
  "deck": "/abs/path/index.html",
  "updated": "2026-10-09T22:07:31+0200",
  "note": "make these two match",
  "screenshot": "curl -s http://127.0.0.1:4747/__editor/shot",
  "elements": [
    {
      "slide": 4,
      "label": "04 Status quo",
      "selector": "section[data-screen-label=\"04 Status quo\"] > div.cards3 > div.card:nth-of-type(2)",
      "file": "/abs/path/index.html",
      "lines": [112, 129],
      "rect": [680, 300, 560, 440],
      "html": "<div class=\"card\">...</div>",
      "pos": 28013
    }
  ]
}
```

When the user says "this", "these", "the selected one", or refers to something on screen while the editor runs, read that file before anything else. Per element: `slide` is the 1-based slide number, `label` its `data-screen-label`, `lines` the first and last line of the element in `file`, `html` the element's source text (cut at 4000 characters), and `rect` its box on the 1920x1080 canvas as x, y, width, height. An empty `elements` list means nothing is selected: ask what the user means.

To see the selection, run the command in `screenshot`. It renders the selected slide in headless Chrome with a pink outline around each selected element, writes `.deck-editor/selection.png`, and prints the path; read that image. Take it when the note is about how something looks, and skip it for copy changes.

## Edit and hand back

Edit the deck files with the usual tools, at the lines the selection names. The deck contract, the canvas rules, and the type floors from the `creating-presentations` skill apply to every edit. The browser reloads on save; the selection file then describes the new source, so read it again before a follow-up change.

## Self-healing

- `Address already in use`: another editor holds the port. Pass a different port, or stop the old server.
- The page loads without styles or engine (404s in the server's terminal are silent; check the browser console): the deck references a file above the served root through CSS. Start the server on a copy of the deck that keeps those files below the deck's own `../` reach.
- `403 forbidden`: the page was opened under another host name. Use `127.0.0.1` or `localhost` with the server's port.
- The screenshot command prints `no Chrome or Chromium binary on PATH`: skip the screenshot and work from `html`, `lines`, and `rect`.
- `elements` is empty although the user selected something: the file changed between the click and the write. Ask the user to click again.
