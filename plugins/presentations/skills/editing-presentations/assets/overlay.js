/* Deck editor overlay. Injected by server.py into the served deck, never into
 * the file. Every slide element carries data-de, its offset in the source.
 * server.py loads overlay-edit.js and overlay-gates.js before this script. */
(() => {
  if (window.top !== window) return; // presenter iframes show the deck as is
  const stage = document.querySelector('deck-stage');
  if (!stage) return;
  let rev = document.currentScript.dataset.rev;
  const canSend = 'send' in document.currentScript.dataset; // hosted editor: feedback goes out as a GitHub issue

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
    .tools { display: flex; flex-wrap: wrap; gap: 4px; }
    .tools:empty { display: none; }
    .tools > * { border: 1px solid #4da3ff; border-radius: 4px; padding: 2px 6px; display: flex; gap: 4px; align-items: center; }
    .tools span { cursor: ew-resize; user-select: none; }
    .tools input[type=number] { all: unset; width: 44px; color: #fff; }
    .tools button { all: unset; cursor: pointer; }
    .pin { border: 2px solid #ff9f1a; }
    .pin::before { content: attr(data-n); position: absolute; left: -2px; top: -20px; background: #ff9f1a; color: #000; padding: 0 6px; }
    .ink { position: fixed; pointer-events: none; z-index: 2147483600; }
    .ink polyline { fill: none; stroke: #ff2d2d; stroke-width: 6; stroke-linecap: round; stroke-linejoin: round; }
    .row { display: flex; flex-wrap: wrap; gap: 4px; }
    .row button { all: unset; cursor: pointer; border: 1px solid #555; border-radius: 4px; padding: 2px 8px; }
    .row button.on { background: #ff2d2d; border-color: #ff2d2d; }
    .panel.min > :not(.row), .panel.min .row > :not([data-do=hide]) { display: none; }
    .panel.min { width: auto; }
    .list { display: grid; gap: 2px; max-height: 110px; overflow: auto; }
    .list:empty { display: none; }
    .list button { all: unset; cursor: pointer; color: #9aa; float: right; }
    .gates { color: #ff8a8a; display: grid; gap: 2px; max-height: 120px; overflow: auto; }
  </style>
  <div class="boxes"></div>
  <svg class="ink"></svg>
  <div class="panel">
    <div class="crumbs"></div>
    <div class="tools"></div>
    <textarea placeholder="Note for Claude"></textarea>
    <div class="row">
      <button data-do="add" title="Keep this selection and note as a numbered comment">Add comment</button>
      <button data-do="draw" title="Draw on the slide">Draw</button>
      <button data-do="copy" title="Copy all comments, sources and screenshots as one prompt">Copy prompt</button>
      ${canSend ? '<button data-do="send" title="File all comments, sources and screenshots as a GitHub issue">Send</button>' : ''}
      <button data-do="clear" title="Drop all comments and drawings">Clear</button>
      <button data-do="hide" title="Shrink or restore this panel">Hide</button>
      ${canSend ? '<button data-do="decks" title="Back to the list of decks">Decks</button>' : ''}
    </div>
    <div class="list"></div>
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
  let comments = []; // kept feedback: { els, slide, note }
  const ink = new Map(); // slide -> strokes, each a flat list of canvas x, y
  let drawing = false;
  let inkShown = null; // what the ink layer last rendered
  const activeSlide = () => slides().find(s => s.hasAttribute('data-deck-active'));

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
    buildTools();
    $('.status').textContent = sel.length
      ? `${sel.length} selected on slide ${slides().indexOf(slideOf(sel[0])) + 1}. Shift-click adds, double-click edits text, drag reorders, the chips above resize, Alt+drag or Alt+arrows move freely, Esc clears.`
      : drawing ? 'Drawing: drag on the slide. Esc or Draw stops.' : 'Click an element to select it. Ctrl+Z undoes an edit.';
    comments = comments.filter(c => c.slide.isConnected);
    $('.list').replaceChildren(...comments.map((c, i) => {
      const row = document.createElement('div'), drop = document.createElement('button');
      row.textContent = `${i + 1}. Slide ${slides().indexOf(c.slide) + 1}: ${c.note || 'no text'}`;
      drop.textContent = '\u2715';
      drop.onclick = () => { comments.splice(i, 1); changed(); };
      row.append(drop);
      return row;
    }));
    $('[data-do=draw]').className = drawing ? 'on' : '';
    inkShown = null;
    const n = (s) => slides().indexOf(s);
    try {
      sessionStorage.setItem('deck-editor', JSON.stringify({ note: note.value, sel: sel.map(selector),
        comments: comments.map(c => ({ note: c.note, slide: n(c.slide), sel: c.els.filter(el => el.isConnected).map(selector) })),
        ink: [...ink].filter(([s]) => s.isConnected).map(([s, strokes]) => [n(s), strokes]) }));
    } catch (e) {}
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
    const shown = activeSlide();
    const pins = comments.flatMap((c, i) => c.slide === shown ? c.els.filter(el => el.isConnected).map(el => [el, 'pin', i + 1]) : []);
    const want = [...pins, ...bad.map(el => [el, 'bad']), ...sel.map(el => [el, 'sel']),
      ...(hover && !sel.includes(hover) ? [[hover, 'hover']] : []), ...(dropLine ? [[dropLine, 'drop']] : [])];
    while (boxes.children.length > want.length) boxes.lastChild.remove();
    while (boxes.children.length < want.length) boxes.append(document.createElement('div'));
    want.forEach(([el, kind, n], i) => {
      const r = el.getBoundingClientRect ? el.getBoundingClientRect() : el, b = boxes.children[i];
      b.className = 'box ' + kind;
      b.dataset.n = n || '';
      b.style.cssText = `left:${r.left}px;top:${r.top}px;width:${r.width}px;height:${r.height}px`;
    });
    if (shown) {
      const r = shown.getBoundingClientRect(), svg = $('.ink');
      svg.style.cssText = `left:${r.left}px;top:${r.top}px;width:${r.width}px;height:${r.height}px`;
      if (inkShown !== shown) {
        inkShown = shown;
        svg.setAttribute('viewBox', `0 0 ${shown.offsetWidth} ${shown.offsetHeight}`);
        svg.innerHTML = (ink.get(shown) || []).map(s => `<polyline points="${s.join(' ')}"/>`).join('');
      }
    }
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
    if (drawing) return e.preventDefault();
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
    if (e.key === 'Escape' && (sel.length || drawing)) { sel = []; drawing = false; changed(); }
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); op(e.shiftKey ? 'redo' : 'undo', () => ({})); }
  });
  stage.addEventListener('slidechange', () => { sel = []; hover = null; changed(); checkGates(); });

  // Feedback as one prompt: numbered comments and drawings pile up over many slides, and "Copy prompt"
  // puts them on the clipboard with sources and screenshot paths, ready to paste into the session.
  const addComment = () => {
    if (!sel.length && !note.value.trim()) return;
    comments.push({ els: sel, slide: sel[0] ? slideOf(sel[0]) : activeSlide(), note: note.value.trim() });
    sel = [];
    note.value = '';
  };
  const copyPrompt = async (send) => {
    addComment();
    changed();
    const used = slides().filter(s => comments.some(c => c.slide === s) || (ink.get(s) || []).length);
    if (!used.length) { $('.status').textContent = 'Nothing to copy yet: add a comment or draw on a slide.'; return; }
    $('.status').textContent = 'Building the prompt and its screenshots...';
    const res = await post(send ? 'issue' : 'prompt', { size: [used[0].offsetWidth, used[0].offsetHeight], slides: used.map(s => ({
      n: slides().indexOf(s) + 1, pos: pos(s), label: s.dataset.screenLabel || '', strokes: ink.get(s) || [],
      comments: comments.map((c, i) => ({ n: i + 1, note: c.note, slide: c.slide,
        elements: c.els.filter(el => el.isConnected).map(el => ({ pos: pos(el), selector: selector(el), rect: canvasRect(el) })) }))
        .filter(c => c.slide === s).map(({ slide, ...c }) => c),
    })) });
    const text = await res.text();
    if (send) {
      if (res.ok) { comments = []; ink.clear(); changed(); }
      $('.status').textContent = res.ok ? `Sent as ${text}` : text;
      return;
    }
    try {
      await navigator.clipboard.writeText(text);
      $('.status').textContent = `Copied ${comments.length} comments from ${used.length} slides. Paste the prompt into the session.`;
    } catch (e) { // clipboard refused: leave the prompt where Ctrl+C reaches it
      note.value = text;
      note.select();
      $('.status').textContent = 'The browser blocked the clipboard. The prompt is in the note box: press Ctrl+C.';
    }
  };
  $('.row').addEventListener('click', (e) => {
    const act = e.target.dataset.do;
    if (act === 'decks') return location.assign('/__decks/');
    if (act === 'copy' || act === 'send') return copyPrompt(act === 'send');
    if (act === 'add') addComment();
    if (act === 'draw') drawing = !drawing;
    if (act === 'clear') { comments = []; ink.clear(); }
    if (act === 'hide') e.target.textContent = $('.panel').classList.toggle('min') ? 'Editor' : 'Hide';
    changed();
  });
  window.addEventListener('pointerdown', (e) => {
    const slide = drawing && !e.button && e.target !== host && activeSlide();
    if (!slide) return;
    e.preventDefault();
    e.stopImmediatePropagation();
    const S = slide.getBoundingClientRect(), k = slide.offsetWidth / S.width, stroke = [];
    const add = (m) => { stroke.push(Math.round((m.clientX - S.left) * k), Math.round((m.clientY - S.top) * k)); inkShown = null; };
    ink.set(slide, [...(ink.get(slide) || []), stroke]);
    add(e);
    const up = () => {
      window.removeEventListener('pointermove', add, true);
      window.removeEventListener('pointerup', up, true);
      changed();
    };
    window.addEventListener('pointermove', add, true);
    window.addEventListener('pointerup', up, true);
  }, true);

  // One edit at a time. The server answers with the new source offset of every element; a refusal
  // (stale page, undo, an edit the page cannot mirror) reloads from the file instead.
  let queue = Promise.resolve();
  const op = (name, body, reload) => queue = queue.then(async () => {
    const res = await post('op', { op: name, ...body() });
    const out = res.ok ? await res.json() : {};
    if (!out.moves || reload) return location.reload();
    rev = out.rev;
    stage.querySelectorAll('[data-de]').forEach(el => {
      const to = out.moves[el.dataset.de];
      if (to === undefined) el.removeAttribute('data-de');
      else if (String(to) !== el.dataset.de) el.dataset.de = to; // untouched slides keep their thumbnails
    });
    changed();
    checkGates();
  });

  // Text edit, reorder, free move and the panel chips (overlay-edit.js). They read and write the
  // selection state through these accessors, and add their listeners after the ones above.
  const { buildTools } = DeckEditorTools({ stage, target, pos, slideOf, op, changed, $, state: {
    get sel() { return sel; }, set sel(v) { sel = v; },
    get editing() { return editing; }, set editing(v) { editing = v; },
    get dragged() { return dragged; }, set dragged(v) { dragged = v; },
    set dropLine(v) { dropLine = v; },
  } });

  // Hard gates H1, H2 and H7 on the active slide (overlay-gates.js).
  const checkGates = DeckGates({ slides, out: $('.gates'), onBad: (els) => { bad = els; } });

  // Reload when Claude (or anyone) changes a file the page loaded; keep note and selection where they still resolve.
  new EventSource('/__editor/events').onmessage = () => location.reload();
  customElements.whenDefined('deck-stage').then(() => requestAnimationFrame(() => {
    try {
      const saved = JSON.parse(sessionStorage.getItem('deck-editor') || '{}');
      note.value = saved.note || '';
      const find = (qs) => (qs || []).map(q => document.querySelector(q)).filter(el => el && el.dataset.de);
      sel = find(saved.sel);
      comments = (saved.comments || []).map(c => ({ note: c.note, slide: slides()[c.slide], els: find(c.sel) })).filter(c => c.slide);
      (saved.ink || []).forEach(([i, strokes]) => slides()[i] && ink.set(slides()[i], strokes));
    } catch (e) {}
    changed();
    document.fonts.ready.then(checkGates);
  }));
})();
