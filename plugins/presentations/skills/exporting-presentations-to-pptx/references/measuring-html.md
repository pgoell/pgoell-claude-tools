# Measuring the rendered HTML

The browser has already laid the deck out. Read its boxes, line breaks and computed styles instead of estimating text height from CSS: `assets/measure-probe.js` (in this skill) walks every slide and returns what was drawn, in canvas pixels relative to the slide. The `building-pptx-decks` skill uses the same probe on preset gallery slides.

## Run it

Any Chromium-based browser works. With a browser tool that can evaluate JavaScript in a page, open the deck and evaluate the probe file's contents; the result is the return value. Without one, inject it and dump the DOM with headless Chrome:

```bash
PROBE="<this skill's dir>/assets/measure-probe.js"
sed "s#</body>#<script src=\"file://$PROBE\"></script></body>#" deck/index.html > deck/.geom.html
chrome --headless --no-sandbox --disable-gpu --window-size=1920,1080 \
  --allow-file-access-from-files --virtual-time-budget=5000 \
  --dump-dom "file://$PWD/deck/.geom.html" > geom-dom.html
python3 -c 'import html,json,re,sys; m=re.search(r"<pre id=\"geom\"[^>]*>(.*?)</pre>", open(sys.argv[1]).read(), re.S); json.dump(json.loads(html.unescape(m.group(1))), open("geom.json","w"), indent=1)' geom-dom.html
rm deck/.geom.html
```

The copy sits next to the original so relative paths to fonts, images and the engine scripts still resolve; delete it afterwards. `--virtual-time-budget` lets fonts load and the probe finish before the dump. Use `chrome-headless-shell`, `chromium` or `msedge.exe` with the same flags where that is the installed binary. A deck that loads webfonts over HTTP is measured from a local server instead (`uv run python -m http.server 8123 --directory deck`, then `http://localhost:8123/.geom.html`).

For a deck on the `<deck-stage>` engine the probe sets `noscale` first, so coordinates are authored canvas pixels whatever the window size, and covers every slide without navigating (inactive slides keep their layout). A single gallery slide is measured as one slide.

## What comes back

One entry per slide: `{ n, label, w, h, items }`, where `label` is the slide's `data-screen-label` and `w` and `h` are the canvas size (1920 x 1080 for decks from `creating-presentations`). Items, in document order, so later items paint over earlier ones:

| `kind`  | Fields                                                                                                                                                  |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `text`  | `rect`, `lines` (the text as the browser broke it), `fontPx`, `weight`, `italic`, `color`, `align`, `lineHeightPx`, `letterSpacingPx`, `family`, `role` |
| `box`   | `rect`, `fill` (hex or null), `fillAlpha`, `border` (`w`, `color`), `radius`, `shadow` (CSS value), `image` (CSS background image)                      |
| `img`   | `rect`, `src`                                                                                                                                           |
| `svg`   | `rect`, `data` (the element's `data-*` attributes, where chart data lives), `id`                                                                        |
| `table` | `rect`, `rows` (cell text)                                                                                                                              |

An element with both a surface and its own text yields a `box` and a `text` item with the same rect. Mixed inline styling (one bold word in a sentence) comes back as the block's style; read the slide's markup for runs.

Convert with the canvas constants: inches = px / (W / 13.333), points = px x 960 / W. For W = 1920 that is px / 144 and px / 2.
