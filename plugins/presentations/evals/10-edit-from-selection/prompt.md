---
max_turns: 20
timeout_seconds: 400
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

I have the deck editor open on `deck/index.html` and selected something. Do what my note says.

First save these two files so you have what I have on disk.

`deck/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>On-call</title>
<style>
:root { --ink: #111; --paper: #fff; }
section { background: var(--paper); color: var(--ink); padding: 100px; }
.cards { display: flex; gap: 32px; }
.card p { font-size: 40px; }
</style>
<style>deck-stage:not(:defined){visibility:hidden}</style>
</head>
<body>
<deck-stage>
  <section data-screen-label="01 Title">
    <h1>Follow-the-sun on-call</h1>
  </section>
  <section data-screen-label="02 Pilot">
    <h1>The pilot cut night pages</h1>
    <div class="cards">
      <div class="card">
        <p>Night pages fell from 41 to 6</p>
      </div>
      <div class="card">
        <p>Night pages fell from 41 to 6</p>
      </div>
    </div>
  </section>
</deck-stage>
<script src="deck-stage.js"></script>
</body>
</html>
```

`deck/.deck-editor/selection.json`:

```json
{
  "deck": "deck/index.html",
  "updated": "2026-10-09T10:00:00+0200",
  "note": "this one should say: Median time to acknowledge held at 4 minutes",
  "screenshot": "curl -s http://127.0.0.1:4747/__editor/shot",
  "elements": [
    {
      "slide": 2,
      "label": "02 Pilot",
      "selector": "section[data-screen-label=\"02 Pilot\"] > div.cards > div.card:nth-of-type(2) > p",
      "file": "deck/index.html",
      "lines": [26, 26],
      "rect": [1010, 300, 600, 96],
      "html": "<p>Night pages fell from 41 to 6</p>",
      "pos": 612
    }
  ]
}
```
