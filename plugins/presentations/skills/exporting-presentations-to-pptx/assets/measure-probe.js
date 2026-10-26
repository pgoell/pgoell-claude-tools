// Geometry probe for the PPTX export. Reads what the browser actually laid out,
// so the exporter places boxes and breaks lines where the HTML does instead of
// estimating from CSS. Runs in the page: inject it as a script, or evaluate it
// through a browser tool. Writes JSON into <pre id="geom"> and returns it.
//
// Output, one entry per slide (sections of <deck-stage>, or the whole page for
// a single gallery slide), coordinates in canvas px relative to the slide:
//   { n, label, w, h, items: [...] }
//   text:  rect, lines (the rendered line breaks), fontPx, weight, italic,
//          color, align, lineHeightPx, letterSpacingPx, family, role
//   box:   rect, fill, fillAlpha, border {w, color}, radius, shadow, image
//   img:   rect, src            svg: rect, data (its data-* attributes), id
//   table: rect, rows (cell text)
(async () => {
  await document.fonts.ready;
  const stage = document.querySelector('deck-stage');
  if (stage) stage.setAttribute('noscale', '');
  const slides = stage ? [...stage.children].filter((el) => el.tagName === 'SECTION') : [document.body];
  const px = (v) => Math.round(parseFloat(v) || 0);
  const rgba = (c) => (c.match(/rgba?\(([^)]+)\)/) || [, ''])[1].split(',').map(Number);
  const alpha = (c) => { const p = rgba(c); return p.length < 3 ? 0 : p.length > 3 ? p[3] : 1; };
  const hex = (c) => { const p = rgba(c); return p.length < 3 ? null : p.slice(0, 3).map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase(); };
  const lines = (block) => {
    const out = [];
    let cur = null, top = null;
    const walk = document.createTreeWalker(block, NodeFilter.SHOW_TEXT);
    while (walk.nextNode()) {
      const t = walk.currentNode, re = /\S+\s*/g;
      let m;
      while ((m = re.exec(t.data))) {
        const r = document.createRange();
        r.setStart(t, m.index);
        r.setEnd(t, m.index + m[0].trimEnd().length);
        const b = r.getClientRects()[0];
        if (!b) continue;
        if (top === null || Math.abs(b.top - top) > b.height / 2) {
          if (cur !== null) out.push(cur.trim());
          cur = '';
          top = b.top;
        }
        cur += m[0];
      }
    }
    if (cur !== null) out.push(cur.trim());
    return out;
  };
  const result = slides.map((slide, i) => {
    const S = slide.getBoundingClientRect();
    const rect = (el) => { const r = el.getBoundingClientRect(); return { x: px(r.left - S.left), y: px(r.top - S.top), w: px(r.width), h: px(r.height) }; };
    const items = [];
    slide.querySelectorAll('*').forEach((el) => {
      if (el.closest('script, style, template') || el.parentElement?.closest('svg, table')) return;
      const cs = getComputedStyle(el), r = el.getBoundingClientRect();
      if (r.width < 1 || r.height < 1) return;
      const tag = el.tagName.toLowerCase();
      if (tag === 'img') return items.push({ kind: 'img', rect: rect(el), src: el.currentSrc });
      if (tag === 'svg' || tag === 'canvas') return items.push({ kind: 'svg', rect: rect(el), data: { ...el.dataset }, id: el.id || null });
      if (tag === 'table') return items.push({ kind: 'table', rect: rect(el), rows: [...el.rows].map((tr) => [...tr.cells].map((td) => td.textContent.trim())) });
      const border = parseFloat(cs.borderTopWidth) > 0 && cs.borderTopStyle !== 'none';
      if (alpha(cs.backgroundColor) > 0.05 || border || cs.boxShadow !== 'none' || cs.backgroundImage !== 'none') {
        items.push({ kind: 'box', rect: rect(el), fill: alpha(cs.backgroundColor) > 0.05 ? hex(cs.backgroundColor) : null, fillAlpha: alpha(cs.backgroundColor),
          border: border ? { w: px(cs.borderTopWidth), color: hex(cs.borderTopColor) } : null, radius: px(cs.borderTopLeftRadius),
          shadow: cs.boxShadow !== 'none' ? cs.boxShadow : null, image: cs.backgroundImage !== 'none' ? cs.backgroundImage : null });
      }
      const ownText = [...el.childNodes].some((n) => n.nodeType === 3 && n.data.trim());
      if (ownText && cs.display !== 'inline') {
        items.push({ kind: 'text', rect: rect(el), lines: lines(el), fontPx: px(cs.fontSize), weight: +cs.fontWeight, italic: cs.fontStyle === 'italic',
          color: hex(cs.color), align: cs.textAlign, lineHeightPx: px(cs.lineHeight) || null, letterSpacingPx: parseFloat(cs.letterSpacing) || 0,
          family: cs.fontFamily.split(',')[0].replace(/"/g, ''), role: el.dataset.role || el.className || tag });
      }
    });
    return { n: i + 1, label: slide.dataset?.screenLabel || document.title, w: px(S.width), h: px(S.height), items };
  });
  if (stage) stage.removeAttribute('noscale');
  const pre = document.createElement('pre');
  pre.id = 'geom';
  pre.hidden = true;
  pre.textContent = JSON.stringify(result);
  document.body.appendChild(pre);
  return result;
})();
