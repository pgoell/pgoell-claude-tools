# Hard Gates

Deterministic probes for the H rules. Run them with any driveable Chromium (browser MCP tools or a small Puppeteer script); the probes themselves are plain JavaScript evaluated in the page. Every failure here is a confirmed fix item with no judging step.

| Gate | What it checks                 | Probe                                         |
| ---- | ------------------------------ | --------------------------------------------- |
| H1   | No clipped text                | Geometry and contrast probe                   |
| H2   | No overlapping text            | Geometry and contrast probe                   |
| H3   | No broken assets (incl. fonts) | Geometry probe, plus console, network, fonts  |
| H4   | No console errors              | Console, network, fonts                       |
| H5   | Typography lint (codepoints)   | Grep                                          |
| H6   | Contrast floor                 | Geometry and contrast probe                   |
| H7   | Minimum type size              | Type size probe                               |
| H8   | Copy lint                      | `copy-lint.md` (copy probe plus tell scanner) |
| H9   | Layout geometry                | Layout geometry probe                         |

All thresholds below are tunable defaults. When a deck's `deck-standards.md` changes one, it wins.

## Serving the deck

Serve over HTTP, not `file://` (webfonts, `BroadcastChannel`, and some CDN loads behave differently on opaque origins):

```bash
uv run python -m http.server 8123 --directory <deck-dir> &
```

Run online if the deck loads fonts or icons from CDNs, otherwise fallback fonts cause false H1, H3, H7, and H9 results.

## Slide model

For decks built by this skill, slides are the direct element children of `<deck-stage>` (excluding `template`, `script`, `style`). Inactive slides stay in the DOM with `visibility: hidden` but keep full layout, so geometry probes cover every slide without navigating. Before probing, set the `noscale` attribute on `<deck-stage>` so all rects are in authored canvas pixels (default 1920x1080), then remove it:

```js
document.querySelector('deck-stage').setAttribute('noscale', '');
// ... probe ...
document.querySelector('deck-stage').removeAttribute('noscale');
```

For other deck engines, identify the slide container, make all slides laid out (visible or visibility-hidden, not display-none), and adapt `slides` in the probe below.

## Geometry and contrast probe (H1, H2, H3, H6)

Evaluate in the page; returns hard failures in `issues` and judged-lane material in `forJudges` (decorative bleed, borderline contrast). Hand `forJudges` to the visual judge alongside the screenshots; never auto-fix from it.

```js
(() => {
  const stage = document.querySelector('deck-stage');
  const slides = [...stage.children].filter(el => !['TEMPLATE', 'SCRIPT', 'STYLE'].includes(el.tagName));
  const issues = [];
  const gist = (el) => `"${el.textContent.trim().replace(/\s+/g, ' ').slice(0, 50)}"`;
  const srgb = (c) => { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
  const lum = ({ r, g, b }) => 0.2126 * srgb(r) + 0.7152 * srgb(g) + 0.0722 * srgb(b);
  const parse = (s) => { const m = (s || '').match(/rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)(?:,\s*([\d.]+))?\)/); return m ? { r: +m[1], g: +m[2], b: +m[3], a: m[4] === undefined ? 1 : +m[4] } : null; };
  const bgOf = (el) => {
    for (let n = el; n && n !== document.documentElement; n = n.parentElement) {
      const cs = getComputedStyle(n);
      if (cs.backgroundImage !== 'none') return null; // judged visually (S13)
      const c = parse(cs.backgroundColor);
      if (c && c.a >= 0.95) return c;
    }
    return { r: 255, g: 255, b: 255 };
  };
  const forJudges = [];
  slides.forEach((slide, i) => {
    const n = i + 1;
    const sr = slide.getBoundingClientRect();
    const texts = [...slide.querySelectorAll('*')].filter(el => el.children.length === 0 && el.textContent.trim());
    let textClipped = false;
    texts.forEach(el => {
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height) return;
      if (r.right > sr.right + 2 || r.bottom > sr.bottom + 2 || r.left < sr.left - 2 || r.top < sr.top - 2) {
        textClipped = true;
        issues.push({ gate: 'H1', slide: n, what: `${gist(el)} extends past the slide edge` });
      }
      // Decorative markers (accent dots, ghost numerals, prompt glyphs) are exempt from H6.
      if (el.textContent.trim().length <= 2) return;
      const fg = parse(getComputedStyle(el).color), bg = bgOf(el);
      if (fg && bg) {
        const [hi, lo] = [lum(fg), lum(bg)].sort((a, b) => b - a);
        const ratio = (hi + 0.05) / (lo + 0.05);
        if (ratio < 3) {
          issues.push({ gate: 'H6', slide: n, what: `${gist(el)} contrast ${ratio.toFixed(2)}:1 < 3:1` });
        } else if (ratio < 4.5 && parseFloat(getComputedStyle(el).fontSize) < 24) {
          forJudges.push({ kind: 'borderline-contrast', slide: n, what: `${gist(el)} contrast ${ratio.toFixed(2)}:1` });
        }
      }
    });
    if (!textClipped && (slide.scrollWidth > slide.clientWidth + 2 || slide.scrollHeight > slide.clientHeight + 2)) {
      forJudges.push({ kind: 'bleed', slide: n, what: `content ${slide.scrollWidth}x${slide.scrollHeight} exceeds canvas ${slide.clientWidth}x${slide.clientHeight} without clipping text` });
    }
    for (let a = 0; a < texts.length; a++) for (let b = a + 1; b < texts.length; b++) {
      const ra = texts[a].getBoundingClientRect(), rb = texts[b].getBoundingClientRect();
      if (!ra.width || !rb.width) continue;
      const ox = Math.min(ra.right, rb.right) - Math.max(ra.left, rb.left);
      const oy = Math.min(ra.bottom, rb.bottom) - Math.max(ra.top, rb.top);
      if (ox > 4 && oy > 4) issues.push({ gate: 'H2', slide: n, what: `${gist(texts[a])} overlaps ${gist(texts[b])}` });
    }
    [...slide.querySelectorAll('img')].forEach(img => {
      if (img.complete && img.naturalWidth === 0) issues.push({ gate: 'H3', slide: n, what: `broken image ${img.src.split('/').pop()}` });
    });
  });
  return JSON.stringify({ slides: slides.length, issues, forJudges }, null, 2);
})();
```

Contrast caveats: the probe handles flat backgrounds only; semi-transparent text colors and layered translucent backgrounds come out approximate. Treat H6 results within 0.3 of the threshold as "verify on the screenshot" rather than auto-fail.

## Console, network, fonts (H4, H3)

After loading and stepping once through all slides (End key, then Home):

- H4: read the console log; any `error`-level entry fails unless its resource is on the constitution's H4 allowlist (favicons, optional state probes some deck engines fire).
- H3 network half: list failed requests (status >= 400 or blocked); fonts, CSS, JS, images all count, same allowlist exemption.
- H3 font half: evaluate `[...document.fonts].map(f => ({ family: f.family, weight: f.weight, status: f.status }))`. A family where every face errored fails the gate. A family with a loaded base weight but errored heavier weights (common with local-first font strategies) renders with synthesized bold; report it to the visual judge as portability info instead of failing.

## Typography lint (H5)

Grep the deck source for the constitution's banned codepoints (default U+2014, U+2013, U+00B7). Only flag matches in rendered text: skip hits inside `<script>` and `<style>` blocks and inside HTML comments.

```bash
grep -nP '[\x{2014}\x{2013}\x{00B7}]' <deck>.html
```

## Type size probe (H7)

Checks the rendered font size of every text element by role on the 1920x1080 canvas (set `noscale` first, as for the geometry probe). Floors are starting points, derived from the exporter's 0.5 pt per px constant: body 36 px (18 pt; the preset target is 40), captions, chart labels, and table cells 28 px, footer and source line 24 px. Roles come from an explicit `data-role` attribute when the slide sets one (`body`, `caption`, `label`, `footer`, `source`), otherwise from context: text inside `footer`, `.footer`, `.source`, or `.slide-number` is footer; text inside `figcaption`, `th`, `td`, an `<svg>`, `.meta`, or an element whose class contains `caption` or `label` is caption; everything else is body. Mark small text with `data-role` when its class does not say what it is. SVG text is measured at its effective size (computed size times the SVG's scale), because a chart drawn in a small viewBox and stretched renders larger than its `font-size` says.

More than three distinct sizes among body and caption text on one slide goes to `forJudges`, not `issues`: the three-size rule is a type-scale rule the visual judge checks against the screenshot.

```js
(() => {
  const FLOOR = { body: 36, caption: 28, footer: 24 };
  const MAX_SIZES = 3;
  const stage = document.querySelector('deck-stage');
  const slides = [...stage.children].filter(el => !['TEMPLATE', 'SCRIPT', 'STYLE'].includes(el.tagName));
  const issues = [], forJudges = [];
  const gist = (el) => `"${el.textContent.trim().replace(/\s+/g, ' ').slice(0, 50)}"`;
  const role = (el) => {
    const tagged = el.closest('[data-role]')?.dataset.role;
    if (tagged) return ['footer', 'source'].includes(tagged) ? 'footer' : ['caption', 'label'].includes(tagged) ? 'caption' : 'body';
    if (el.closest('footer, .footer, .source, .slide-number')) return 'footer';
    if (el.closest('figcaption, th, td, svg, [class*="caption"], [class*="label"], .meta')) return 'caption';
    return 'body';
  };
  const size = (el) => {
    const px = parseFloat(getComputedStyle(el).fontSize);
    if (el instanceof SVGElement && el.getScreenCTM) {
      const m = el.getScreenCTM();
      return m ? px * Math.hypot(m.a, m.b) : px;
    }
    return px;
  };
  slides.forEach((slide, i) => {
    const n = i + 1;
    const els = new Set();
    const walk = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
    while (walk.nextNode()) {
      const t = walk.currentNode, el = t.parentElement;
      if (!t.textContent.trim() || el.closest('script, style, template, [aria-hidden="true"]')) continue;
      els.add(el);
    }
    const sizes = new Set();
    els.forEach(el => {
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height || el.textContent.trim().length <= 2) return;
      const rl = role(el), px = size(el);
      if (rl !== 'footer') sizes.add(Math.round(px));
      if (px < FLOOR[rl] - 0.5) issues.push({ gate: 'H7', slide: n, what: `${rl} text ${gist(el)} renders at ${px.toFixed(1)}px < ${FLOOR[rl]}px` });
    });
    if (sizes.size > MAX_SIZES) forJudges.push({ kind: 'type-sizes', slide: n, what: `${sizes.size} text sizes: ${[...sizes].sort((a, b) => b - a).join(', ')}px` });
  });
  return JSON.stringify({ issues, forJudges }, null, 2);
})();
```

The fix for an H7 failure is never a smaller floor or a squeezed line height. Split the slide, cut words, or move detail into the speaker notes.

## Copy lint (H8)

The copy probe, its word lists, and the tell scanner live in `copy-lint.md`. H8 fails only on the items that file marks hard-fail; every warning goes to `forJudges` for the clarity judge (or the default render check) to weigh.

## Layout geometry probe (H9)

Measures what H1 and H2 miss: collisions of non-text boxes, content escaping its container, content crammed against the canvas edge, near-miss alignment, gaps too tight to read as separate, and too many elements on one slide. Balance and empty space are judgment calls (asymmetry and a single big number are both deliberate designs), so the probe routes them to `forJudges` instead of failing.

Definitions the probe uses:

- **Box**: an element with a visible surface (background color or image, border, or shadow), or an `img`, `svg`, `canvas`, `video`, `iframe`, or `table`. An element covering at least 90% of the slide in both axes is a background layer and is ignored; so are descendants of an `svg` or `table` (the container counts once).
- **Text block**: the nearest block-level ancestor of a rendered text node.
- **Unit**: every box and text block. Units in a DOM ancestor relation are never compared with each other.
- **Structural slide**: a slide whose `data-screen-label` names a title, cover, section, divider, quote, or closing slide. Empty-region warnings skip these.

Thresholds are tunable defaults in the `T` object:

| Check               | Default                                                  | Result    |
| ------------------- | -------------------------------------------------------- | --------- |
| Box collision       | two units (at least one a box) overlap > 4 px both axes  | fail      |
| Escaping container  | a unit extends > 2 px past its nearest box ancestor      | fail      |
| Edge margin         | a unit sits 1 to 47 px from a canvas edge (not bleeding) | fail      |
| Near-miss alignment | left, top, or box right edges differ by > 1 and <= 8 px  | fail      |
| Minimum gap         | adjacent units in different parents closer than 12 px    | fail      |
| Element count       | more than 20 units (30 for briefing and reading decks)   | fail      |
| Centroid imbalance  | content centroid off center by > 12% x or > 25% y        | forJudges |
| Large empty region  | largest empty rectangle > 35% of the content area        | forJudges |

Top edges of two text blocks are compared only when they share a font size (different sizes align on baselines, which the judge checks by eye). Siblings in one parent (rows of a list, cells of a bar) may touch. Footer content is exempt from the edge-margin and near-miss checks; a unit that touches or crosses an edge is treated as a deliberate bleed and exempt from the edge-margin check (H1 still catches clipped text).

```js
(() => {
  const T = { overlap: 4, escape: 2, margin: 48, nearMiss: [1, 8], minGap: 12, maxUnits: 20,
              centroid: { x: 0.12, y: 0.25 }, emptyShare: 0.35, cell: 40, pad: 80 };
  // Set T.maxUnits = 30 for deck_mode briefing or reading.
  const stage = document.querySelector('deck-stage');
  const slides = [...stage.children].filter(el => !['TEMPLATE', 'SCRIPT', 'STYLE'].includes(el.tagName));
  const issues = [], forJudges = [];
  const gist = (el) => `<${el.tagName.toLowerCase()}> "${el.textContent.trim().replace(/\s+/g, ' ').slice(0, 40)}"`;
  const alpha = (c) => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return 0; const p = m[1].split(','); return p.length > 3 ? +p[3] : 1; };
  const BOX_TAGS = ['IMG', 'SVG', 'CANVAS', 'VIDEO', 'IFRAME', 'TABLE'];
  const isBox = (el) => {
    if (BOX_TAGS.includes(el.tagName.toUpperCase())) return true;
    const cs = getComputedStyle(el);
    return alpha(cs.backgroundColor) > 0.05 || cs.backgroundImage !== 'none' || cs.boxShadow !== 'none'
      || ['Top', 'Right', 'Bottom', 'Left'].some(s => parseFloat(cs[`border${s}Width`]) > 0 && cs[`border${s}Style`] !== 'none');
  };
  const blockOf = (el) => {
    for (let n = el; n; n = n.parentElement) if (getComputedStyle(n).display !== 'inline') return n;
    return el;
  };
  const related = (a, b) => a.contains(b) || b.contains(a);
  const inFooter = (el) => !!el.closest('footer, .footer, .slide-number, [data-role="footer"]');
  slides.forEach((slide, i) => {
    const n = i + 1, S = slide.getBoundingClientRect(), W = S.width, H = S.height;
    const structural = /title|cover|section|divider|quote|closing/i.test(slide.dataset.screenLabel || '');
    const full = (r) => r.width >= 0.9 * W && r.height >= 0.9 * H;
    const inside = (el) => el.parentElement?.closest('svg, table') && slide.contains(el.parentElement.closest('svg, table'));
    const units = new Map();
    slide.querySelectorAll('*').forEach(el => {
      if (el.closest('script, style, template') || inside(el)) return;
      const r = el.getBoundingClientRect();
      if (r.width < 1 || r.height < 1 || full(r)) return;
      if (isBox(el)) units.set(el, { el, r, box: true });
    });
    const walk = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
    while (walk.nextNode()) {
      const t = walk.currentNode;
      if (!t.textContent.trim() || t.parentElement.closest('script, style, template') || inside(t.parentElement)) continue;
      const b = blockOf(t.parentElement);
      if (b === slide || units.has(b)) continue;
      const r = b.getBoundingClientRect();
      if (r.width < 1 || r.height < 1 || full(r)) continue;
      units.set(b, { el: b, r, box: false });
    }
    const U = [...units.values()].map(u => ({ ...u, x: u.r.left - S.left, y: u.r.top - S.top, R: u.r.right - S.left, B: u.r.bottom - S.top }));
    const push = (what) => issues.push({ gate: 'H9', slide: n, what });
    // Element count
    if (U.length > T.maxUnits) push(`${U.length} elements > ${T.maxUnits}`);
    // Escaping container
    U.forEach(u => {
      for (let p = u.el.parentElement; p && p !== slide; p = p.parentElement) {
        const pu = units.get(p);
        if (!pu || !pu.box) continue;
        const pr = pu.r, e = T.escape;
        if (u.r.left < pr.left - e || u.r.top < pr.top - e || u.r.right > pr.right + e || u.r.bottom > pr.bottom + e)
          push(`${gist(u.el)} escapes its container ${gist(p)}`);
        break;
      }
    });
    // Edge margin
    U.forEach(u => {
      if (inFooter(u.el)) return;
      const d = [u.x, u.y, W - u.R, H - u.B];
      if (d.some(v => v <= 1)) return; // touches or crosses an edge: deliberate bleed
      const m = Math.min(...d);
      if (m < T.margin) push(`${gist(u.el)} sits ${Math.round(m)}px from the canvas edge < ${T.margin}px`);
    });
    // Pairwise checks
    const seen = new Set();
    for (let a = 0; a < U.length; a++) for (let b = a + 1; b < U.length; b++) {
      const A = U[a], B = U[b];
      if (related(A.el, B.el)) continue;
      const ox = Math.min(A.R, B.R) - Math.max(A.x, B.x), oy = Math.min(A.B, B.B) - Math.max(A.y, B.y);
      if ((A.box || B.box) && ox > T.overlap && oy > T.overlap) push(`${gist(A.el)} collides with ${gist(B.el)}`);
      const siblings = A.el.parentElement === B.el.parentElement;
      const gap = ox > 0 ? Math.max(B.y - A.B, A.y - B.B) : oy > 0 ? Math.max(B.x - A.R, A.x - B.R) : null;
      if (gap !== null && gap >= 0 && gap < T.minGap && !siblings) push(`${gist(A.el)} and ${gist(B.el)} only ${gap.toFixed(1)}px apart < ${T.minGap}px`);
      if (inFooter(A.el) || inFooter(B.el)) continue;
      const centered = (u) => !u.box && getComputedStyle(u.el).textAlign === 'center';
      const sameSize = A.box || B.box || getComputedStyle(A.el).fontSize === getComputedStyle(B.el).fontSize;
      const edges = [['left', A.x, B.x, !centered(A) && !centered(B)], ['top', A.y, B.y, sameSize], ['right', A.R, B.R, A.box && B.box]];
      edges.forEach(([name, ea, eb, on]) => {
        const d = Math.abs(ea - eb), k = `${name}:${Math.round(Math.min(ea, eb))}:${Math.round(Math.max(ea, eb))}`;
        if (on && d > T.nearMiss[0] && d <= T.nearMiss[1] && !seen.has(k)) {
          seen.add(k);
          push(`near-miss ${name} edges ${Math.round(ea)} vs ${Math.round(eb)}px: ${gist(A.el)} / ${gist(B.el)}`);
        }
      });
    }
    // Centroid imbalance (judged)
    let area = 0, cx = 0, cy = 0;
    U.forEach(u => { const w = Math.max(0, Math.min(u.R, W) - Math.max(u.x, 0)), h = Math.max(0, Math.min(u.B, H) - Math.max(u.y, 0)); area += w * h; cx += (u.x + u.R) / 2 * w * h; cy += (u.y + u.B) / 2 * w * h; });
    if (area) {
      const dx = (cx / area - W / 2) / W, dy = (cy / area - H / 2) / H;
      if (Math.abs(dx) > T.centroid.x || Math.abs(dy) > T.centroid.y)
        forJudges.push({ kind: 'imbalance', slide: n, what: `content centroid off center by ${(dx * 100).toFixed(0)}% x, ${(dy * 100).toFixed(0)}% y` });
    }
    // Largest empty rectangle in the content area (judged)
    if (!structural) {
      const cols = Math.floor((W - 2 * T.pad) / T.cell), rows = Math.floor((H - 2 * T.pad) / T.cell);
      const heights = new Array(cols).fill(0);
      let best = 0;
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          const x0 = T.pad + c * T.cell, y0 = T.pad + r * T.cell;
          const busy = U.some(u => u.x < x0 + T.cell && u.R > x0 && u.y < y0 + T.cell && u.B > y0);
          heights[c] = busy ? 0 : heights[c] + 1;
        }
        const st = [];
        for (let c = 0; c <= cols; c++) {
          const h = c < cols ? heights[c] : 0;
          while (st.length && heights[st[st.length - 1]] >= h) {
            const top = heights[st.pop()], left = st.length ? st[st.length - 1] + 1 : 0;
            best = Math.max(best, top * (c - left));
          }
          st.push(c);
        }
      }
      const share = best / (cols * rows);
      if (share > T.emptyShare) forJudges.push({ kind: 'empty-region', slide: n, what: `largest empty region covers ${(share * 100).toFixed(0)}% of the content area` });
    }
  });
  return JSON.stringify({ issues, forJudges }, null, 2);
})();
```

H9 findings name elements by tag and text; when a finding is wrong for a deliberate design (a caption that is meant to overlap its image, say), change the design or record the exemption in the deck's `deck-standards.md`, never loosen the default silently.

## Per-slide screenshots

Capture after the probe, with `noscale` removed and the thumbnail rail suppressed so judges see what the audience sees. Resize the viewport to 1920x1080, then for each slide navigate to `<url>#N` (1-based), reload if the hash change does not repaint, wait for the slide to be active, and screenshot to `.deck-review/round-<R>/slide-NN.png`. The deck hides its overlay chrome after about two seconds of mouse idle; avoid moving the mouse between navigate and capture. Keep screenshots at the full 1920x1080; never downscale them for the judges, since small text is exactly what they must read. The default render check writes to `.deck-review/check-<N>/` instead of `round-<R>/`.

Fallback without a driveable browser: the deck-stage print stylesheet lays one slide per page, so

```bash
chromium --headless --print-to-pdf=deck.pdf 'http://localhost:8123/<deck>.html'
pdftoppm -png -r 96 deck.pdf slide
```

produces equivalent per-slide images (console and network gates still need a live page).

## Output

Collect all gate results into `.deck-review/round-<R>/hard-gates.json`: one entry per issue with gate, slide, and evidence string, plus a `pass` boolean per gate for H1 to H9. Hard-gate failures skip review and verification; they go straight onto the fix list. Merge every probe's `forJudges` entries (and the H8 warnings) into `for-judges.json` next to it; the judges receive that file, and nothing in it is auto-fixed.
