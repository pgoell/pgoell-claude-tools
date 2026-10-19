/* Deck editor: hard gates H1, H2 and H7 on the active slide, condensed from
 * creating-presentations' references/hard-gates.md and measured through the
 * stage scale instead of noscale. Loaded by server.py before overlay.js, which
 * calls DeckGates once and runs the returned check after each edit. Failures
 * the slide already had when it was first shown are counted, not listed, so a
 * new one stands out. */
window.DeckGates = ({ slides, out, onBad }) => {
  const known = new Map();
  return () => setTimeout(() => {
    const slide = slides().find(s => s.hasAttribute('data-deck-active'));
    if (!slide) return;
    const S = slide.getBoundingClientRect(), k = slide.offsetWidth / S.width, fails = [];
    const gist = (el) => `"${el.textContent.trim().replace(/\s+/g, ' ').slice(0, 30)}"`;
    const fail = (gate, what, ...els) => fails.push([gate + ' ' + what, els]);
    const texts = [...slide.querySelectorAll('*')].filter(el => el.children.length === 0 && el.textContent.trim())
      .map(el => [el, el.getBoundingClientRect()]).filter(([, r]) => r.width && r.height);
    texts.forEach(([el, r], a) => {
      const t = 2 / k;
      if (r.right > S.right + t || r.bottom > S.bottom + t || r.left < S.left - t || r.top < S.top - t) fail('H1', `${gist(el)} leaves the slide`, el);
      texts.slice(a + 1).forEach(([other, o]) => {
        const ox = Math.min(r.right, o.right) - Math.max(r.left, o.left), oy = Math.min(r.bottom, o.bottom) - Math.max(r.top, o.top);
        if (ox > 4 / k && oy > 4 / k) fail('H2', `${gist(el)} overlaps ${gist(other)}`, el, other);
      });
      if (el.textContent.trim().length <= 2 || el.closest('[aria-hidden="true"]')) return;
      const tagged = el.closest('[data-role]')?.dataset.role;
      const role = tagged ? (['footer', 'source'].includes(tagged) ? 'footer' : ['caption', 'label', 'legend'].includes(tagged) ? 'caption' : 'body')
        : el.closest('footer, .footer, .source, .slide-number') ? 'footer'
        : el.closest('figcaption, th, td, svg, [class*="caption"], [class*="label"], .meta') ? 'caption' : 'body';
      const floor = { body: 36, caption: 28, footer: 24 }[role];
      const m = el instanceof SVGElement && el.getScreenCTM && el.getScreenCTM();
      const px = parseFloat(getComputedStyle(el).fontSize) * (m ? Math.hypot(m.a, m.b) * k : 1);
      if (px < floor - 0.5) fail('H7', `${role} text ${gist(el)} is ${px.toFixed(0)}px, floor ${floor}px`, el);
    });
    if (!known.has(slide)) known.set(slide, new Set(fails.map(([what]) => what)));
    const fresh = fails.filter(([what]) => !known.get(slide).has(what));
    onBad(fresh.flatMap(([, els]) => els));
    const lines = fresh.map(([what]) => what);
    if (fails.length > fresh.length) lines.push(`${fails.length - fresh.length} gate failures were here before your edits.`);
    out.replaceChildren(...lines.map(what => Object.assign(document.createElement('div'), { textContent: what })));
  }, 300);
};
