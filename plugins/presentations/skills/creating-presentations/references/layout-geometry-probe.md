# Layout Geometry Probe (H9)

Hard gate H9 from `hard-gates.md`. Serve the deck and set `noscale` on `<deck-stage>` as that file describes, then evaluate the probe below in the page. Its `issues` go into `hard-gates.json` and its `forJudges` into `for-judges.json`, as that file's "Output" section says.

Measures what H1 and H2 miss: collisions of non-text boxes, content escaping its container, content crammed against the canvas edge, near-miss alignment, gaps too tight to read as separate, and too many elements on one slide. Balance and empty space are judgment calls (asymmetry and a single big number are both deliberate designs), so the probe routes them to `forJudges` instead of failing.

## Definitions

Definitions the probe uses:

- **Box**: an element with a visible surface (background color or image, border, or shadow), or an `img`, `svg`, `canvas`, `video`, `iframe`, or `table`. An element covering at least 90% of the slide in both axes is a background layer and is ignored; so are descendants of an `svg` or `table` (the container counts once).
- **Text block**: the nearest block-level ancestor of a rendered text node.
- **Unit**: every box and text block. Units in a DOM ancestor relation are never compared with each other.
- **Structural slide**: a slide whose `data-screen-label` names a title, cover, section, divider, quote, closing, statement, question, number, or image slide. Empty-region warnings skip these.
- **Footer**: content inside `footer`, `.footer`, `.slide-number`, or any element marked `data-role="footer"`, which includes a section tracker at the top of the slide.

## Thresholds

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

## Probe

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
    const structural = /title|cover|section|divider|quote|closing|statement|question|number|image/i.test(slide.dataset.screenLabel || '');
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
