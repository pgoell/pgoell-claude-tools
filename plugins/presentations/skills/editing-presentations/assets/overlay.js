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
  </style>
  <div class="boxes"></div>
  <div class="panel">
    <div class="crumbs"></div>
    <textarea placeholder="Note for Claude"></textarea>
    <div class="status"></div>
  </div>`;
  document.body.append(host);
  const $ = (q) => root.querySelector(q);
  const note = $('textarea');
  // Keys typed in the panel must not reach the engine's slide navigation.
  root.addEventListener('keydown', (e) => e.stopPropagation());

  let sel = [];
  let hover = null;

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
      ? `${sel.length} selected on slide ${slides().indexOf(slideOf(sel[0])) + 1}. Shift-click adds, Esc clears.`
      : 'Click an element to select it.';
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
    const want = [...sel.map(el => [el, 'sel']), ...(hover && !sel.includes(hover) ? [[hover, 'hover']] : [])];
    while (boxes.children.length > want.length) boxes.lastChild.remove();
    while (boxes.children.length < want.length) boxes.append(document.createElement('div'));
    want.forEach(([el, kind], i) => {
      const r = el.getBoundingClientRect(), b = boxes.children[i];
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
    if (e.target === host) return;
    const el = target(e);
    if (el) e.preventDefault(); // links inside slides select, they do not navigate
    if (!el) sel = [];
    else if (e.shiftKey) sel = sel.includes(el) ? sel.filter(x => x !== el) : [...sel, el];
    else sel = [el];
    changed();
  }, true);
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && sel.length) { sel = []; changed(); }
  });
  stage.addEventListener('slidechange', () => { sel = []; hover = null; changed(); });

  // Reload when Claude (or anyone) changes a file the page loaded; keep note and selection where they still resolve.
  new EventSource('/__editor/events').onmessage = () => location.reload();
  customElements.whenDefined('deck-stage').then(() => requestAnimationFrame(() => {
    try {
      const saved = JSON.parse(sessionStorage.getItem('deck-editor') || '{}');
      note.value = saved.note || '';
      sel = (saved.sel || []).map(q => document.querySelector(q)).filter(el => el && el.dataset.de);
    } catch (e) {}
    changed();
  }));
})();
