/* Deck editor overlay. Injected by server.py into the served deck, never into
 * the file. Every slide element carries data-de, its offset in the source. */
(() => {
  if (window.top !== window) return; // presenter iframes show the deck as is
  const stage = document.querySelector('deck-stage');
  if (!stage) return;
  let rev = document.currentScript.dataset.rev;

  // Same slide model as the hard gates, so numbers match #N and the review tools.
  const slides = () => [...stage.children].filter(el => !['TEMPLATE', 'SCRIPT', 'STYLE'].includes(el.tagName));
  const slideOf = (el) => slides().find(s => s.contains(el));
  const pos = (el) => +el.dataset.de;

  const host = document.createElement('div');
  const root = host.attachShadow({ mode: 'open' });
  root.innerHTML = `<style>
    :host { all: initial; font: 13px/1.4 system-ui, sans-serif; color: #eee; }
    .box { position: fixed; pointer-events: none; z-index: 2147483600; box-sizing: border-box; }
    .hover { border: 1px dashed #4da3ff; }
    .sel { border: 2px solid #4da3ff; }
    .panel { position: fixed; right: 12px; bottom: 12px; width: 300px; z-index: 2147483601;
      background: #16181d; border: 1px solid #333; border-radius: 8px; padding: 10px; display: grid; gap: 8px; }
    .crumbs { display: flex; flex-wrap: wrap; gap: 2px 4px; color: #9aa; }
    .crumbs button { all: unset; cursor: pointer; color: #cde; }
    .crumbs button:hover { text-decoration: underline; }
    textarea { font: inherit; color: inherit; background: #0d0e11; border: 1px solid #333; border-radius: 4px;
      padding: 6px; resize: vertical; min-height: 48px; }
    .status { color: #9aa; }
    .drop { background: #4da3ff; }
    .bad { border: 2px dashed #ff5a5a; }
    .gates { color: #ff8a8a; display: grid; gap: 2px; max-height: 120px; overflow: auto; }
  </style>
  <div class="boxes"></div>
  <div class="panel">
    <div class="crumbs"></div>
    <textarea placeholder="Note for Claude"></textarea>
    <div class="status"></div>
    <div class="gates"></div>
  </div>`;
  document.body.append(host);
  const $ = (q) => root.querySelector(q);
  const note = $('textarea');
  // Keys typed in the panel must not reach the engine's slide navigation.
  root.addEventListener('keydown', (e) => e.stopPropagation());

  let sel = [];
  let hover = null;
  let editing = null; // element whose text is being edited in place
  let dropLine = null; // screen rect of the reorder indicator
  let bad = []; // elements that fail a hard gate on the active slide
  let dragged = false; // swallow the click that ends a drag

  const name = (el) => el.tagName.toLowerCase() + [...el.classList].map(c => '.' + c).join('');
  const selector = (el) => {
    const slide = slideOf(el), parts = [];
    for (let n = el; n !== slide; n = n.parentElement) {
      const twins = [...n.parentElement.children].filter(c => c.tagName === n.tagName);
      parts.unshift(name(n) + (twins.length > 1 ? `:nth-of-type(${twins.indexOf(n) + 1})` : ''));
    }
    const label = slide.dataset.screenLabel;
    parts.unshift(label ? `section[data-screen-label="${label}"]` : `section:nth-of-type(${slides().indexOf(slide) + 1})`);
    return parts.join(' > ');
  };
  // Rect in authored canvas pixels, whatever the stage scale.
  const canvasRect = (el) => {
    const slide = slideOf(el), s = slide.getBoundingClientRect(), r = el.getBoundingClientRect();
    const k = slide.offsetWidth / s.width;
    return [r.left - s.left, r.top - s.top, r.width, r.height].map(v => Math.round(v * k));
  };

  const post = (path, body) => fetch('/__editor/' + path, { method: 'POST', body: JSON.stringify({ rev, ...body }) });

  let sendTimer;
  const changed = () => {
    sel = sel.filter(el => el.isConnected);
    const crumbs = $('.crumbs');
    crumbs.textContent = '';
    if (sel.length === 1) {
      const path = [];
      for (let n = sel[0]; n !== stage; n = n.parentElement) path.unshift(n);
      path.forEach((n, i) => {
        const b = document.createElement('button');
        b.textContent = name(n);
        b.onclick = () => { sel = [n]; changed(); };
        crumbs.append(i ? ' › ' : '', b);
      });
    }
    $('.status').textContent = sel.length
      ? `${sel.length} selected on slide ${slides().indexOf(slideOf(sel[0])) + 1}. Shift-click adds, double-click edits text, drag reorders, Esc clears.`
      : 'Click an element to select it. Ctrl+Z undoes an edit.';
    try { sessionStorage.setItem('deck-editor', JSON.stringify({ note: note.value, sel: sel.map(selector) })); } catch (e) {}
    clearTimeout(sendTimer);
    sendTimer = setTimeout(() => post('selection', {
      note: note.value,
      elements: sel.map(el => {
        const slide = slideOf(el);
        return { pos: pos(el), slide: slides().indexOf(slide) + 1, label: slide.dataset.screenLabel || '',
          selector: selector(el), rect: canvasRect(el) };
      }),
    }), 150);
  };
  note.addEventListener('input', changed);

  // Boxes are drawn in screen space each frame, so stage scale, rail and resize need no handling.
  const draw = () => {
    const boxes = $('.boxes');
    const want = [...bad.map(el => [el, 'bad']), ...sel.map(el => [el, 'sel']),
      ...(hover && !sel.includes(hover) ? [[hover, 'hover']] : []), ...(dropLine ? [[dropLine, 'drop']] : [])];
    while (boxes.children.length > want.length) boxes.lastChild.remove();
    while (boxes.children.length < want.length) boxes.append(document.createElement('div'));
    want.forEach(([el, kind], i) => {
      const r = el.getBoundingClientRect ? el.getBoundingClientRect() : el, b = boxes.children[i];
      b.className = 'box ' + kind;
      b.style.cssText = `left:${r.left}px;top:${r.top}px;width:${r.width}px;height:${r.height}px`;
    });
    requestAnimationFrame(draw);
  };
  draw();

  // The slide element under an event, or null outside the active slide.
  const target = (e) => {
    const el = e.target.closest && e.target.closest('[data-de]');
    return el && el !== stage && stage.contains(el) && slideOf(el)?.hasAttribute('data-deck-active') ? el : null;
  };

  window.addEventListener('mousemove', (e) => { hover = target(e); }, true);
  window.addEventListener('click', (e) => {
    if (e.target === host || editing) return;
    if (dragged) { dragged = false; return e.preventDefault(); }
    const el = target(e);
    if (el) e.preventDefault(); // links inside slides select, they do not navigate
    if (!el) sel = [];
    else if (e.shiftKey) sel = sel.includes(el) ? sel.filter(x => x !== el) : [...sel, el];
    else sel = [el];
    changed();
  }, true);
  window.addEventListener('keydown', (e) => {
    if (editing) return;
    if (e.key === 'Escape' && sel.length) { sel = []; changed(); }
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); op(e.shiftKey ? 'redo' : 'undo', () => ({})); }
  });
  stage.addEventListener('slidechange', () => { sel = []; hover = null; changed(); checkGates(); });

  // One edit at a time. The server answers with the new source offset of every element; a refusal
  // (stale page, undo, an edit the page cannot mirror) reloads from the file instead.
  let queue = Promise.resolve();
  const op = (name, body, reload) => queue = queue.then(async () => {
    const res = await post('op', { op: name, ...body() });
    const out = res.ok ? await res.json() : {};
    if (!out.moves || reload) return location.reload();
    rev = out.rev;
    stage.querySelectorAll('[data-de]').forEach(el => {
      if (el.dataset.de in out.moves) el.dataset.de = out.moves[el.dataset.de];
      else el.removeAttribute('data-de');
    });
    changed();
    checkGates();
  });

  // Text: double-click, type, Enter or click away to save, Esc to cancel.
  window.addEventListener('dblclick', (e) => {
    const el = target(e);
    if (!el || editing || !(el instanceof HTMLElement) || !el.textContent.trim()) return;
    const before = el.innerHTML;
    editing = el;
    sel = [el];
    el.contentEditable = 'plaintext-only';
    el.focus();
    const done = (save) => {
      el.removeEventListener('blur', onBlur);
      el.removeEventListener('keydown', onKey);
      el.removeAttribute('contenteditable');
      editing = null;
      if (!save) el.innerHTML = before;
      else if (el.innerHTML !== before) {
        op('text', () => ({ pos: pos(el), html: el.innerHTML.replace(/ data-de="\d+"/g, '') }), el.children.length > 0);
      }
    };
    const onBlur = () => done(true);
    const onKey = (k) => {
      if (k.key === 'Enter' && !k.shiftKey) { k.preventDefault(); done(true); }
      if (k.key === 'Escape') { k.stopPropagation(); done(false); }
    };
    el.addEventListener('blur', onBlur);
    el.addEventListener('keydown', onKey);
  }, true);

  // Reorder: drag the selected element among its siblings.
  window.addEventListener('pointerdown', (e) => {
    const el = sel.length === 1 && sel[0];
    if (!el || editing || e.button || e.altKey || e.shiftKey || !el.contains(e.target) || el.parentElement === stage) return;
    e.preventDefault();
    const sibs = [...el.parentElement.children].filter(c => c !== el && c.dataset.de);
    const first = sibs[0] && sibs[0].getBoundingClientRect(), own = el.getBoundingClientRect();
    const row = first && Math.abs(first.left - own.left) > Math.abs(first.top - own.top);
    let drop = null;
    const move = (m) => {
      if (!drop && Math.hypot(m.clientX - e.clientX, m.clientY - e.clientY) < 6) return;
      const at = row ? m.clientX : m.clientY;
      const mid = (c) => { const r = c.getBoundingClientRect(); return row ? r.left + r.width / 2 : r.top + r.height / 2; };
      const sib = sibs.reduce((a, b) => Math.abs(mid(a) - at) <= Math.abs(mid(b) - at) ? a : b, sibs[0]);
      if (!sib) return;
      const r = sib.getBoundingClientRect(), after = at > mid(sib);
      drop = { sib, after };
      dropLine = row ? { left: (after ? r.right : r.left) - 2, top: r.top, width: 4, height: r.height }
        : { left: r.left, top: (after ? r.bottom : r.top) - 2, width: r.width, height: 4 };
    };
    const up = () => {
      window.removeEventListener('pointermove', move, true);
      window.removeEventListener('pointerup', up, true);
      dropLine = null;
      if (!drop) return;
      dragged = true;
      const { sib, after } = drop;
      if ((after ? sib.nextElementSibling : sib.previousElementSibling) === el) return;
      const ids = { pos: pos(el), ref: pos(sib), after };
      sib[after ? 'after' : 'before'](el);
      op('move', () => ids);
    };
    window.addEventListener('pointermove', move, true);
    window.addEventListener('pointerup', up, true);
  }, true);

  // Hard gates H1, H2 and H7 on the active slide, condensed from creating-presentations'
  // references/hard-gates.md and measured through the stage scale instead of noscale. Failures the
  // slide already had when it was first shown are counted, not listed, so a new one stands out.
  const known = new Map();
  const checkGates = () => setTimeout(() => {
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
    bad = fresh.flatMap(([, els]) => els);
    const lines = fresh.map(([what]) => what);
    if (fails.length > fresh.length) lines.push(`${fails.length - fresh.length} gate failures were here before your edits.`);
    $('.gates').replaceChildren(...lines.map(what => Object.assign(document.createElement('div'), { textContent: what })));
  }, 300);

  // Reload when Claude (or anyone) changes a file the page loaded; keep note and selection where they still resolve.
  new EventSource('/__editor/events').onmessage = () => location.reload();
  customElements.whenDefined('deck-stage').then(() => requestAnimationFrame(() => {
    try {
      const saved = JSON.parse(sessionStorage.getItem('deck-editor') || '{}');
      note.value = saved.note || '';
      sel = (saved.sel || []).map(q => document.querySelector(q)).filter(el => el && el.dataset.de);
    } catch (e) {}
    changed();
    document.fonts.ready.then(checkGates);
  }));
})();
