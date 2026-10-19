/* Deck editor: the direct edits on the slide. Loaded by server.py before
 * overlay.js, which calls DeckEditorTools once and keeps the selection state;
 * state reads and writes sel, editing, dragged and dropLine there. It adds the
 * text, reorder and free-move listeners, so overlay.js calls it after its own
 * pointer and key listeners, and returns buildTools for the panel chips. The
 * name must differ from the deck engine's globals (deck-edit.js owns DeckEdit). */
window.DeckEditorTools = ({ stage, target, pos, slideOf, op, changed, $, state }) => {
  // Text: double-click, type, Enter or click away to save, Esc to cancel.
  window.addEventListener('dblclick', (e) => {
    const el = target(e);
    if (!el || state.editing || !(el instanceof HTMLElement) || !el.textContent.trim()) return;
    const before = el.innerHTML;
    state.editing = el;
    state.sel = [el];
    el.contentEditable = 'plaintext-only';
    el.focus();
    const done = (save) => {
      el.removeEventListener('blur', onBlur);
      el.removeEventListener('keydown', onKey);
      el.removeAttribute('contenteditable');
      state.editing = null;
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
  window.addEventListener('dragstart', (e) => { if (target(e)) e.preventDefault(); }, true); // no native image drag
  window.addEventListener('pointerdown', (e) => {
    const el = state.sel.length === 1 && state.sel[0];
    if (!el || state.editing || e.button || e.altKey || e.shiftKey || !el.contains(e.target) || el.parentElement === stage) return;
    // The press itself stays native, so a double-click still selects its word for the text edit.
    const sibs = [...el.parentElement.children].filter(c => c !== el && c.dataset.de);
    const first = sibs[0] && sibs[0].getBoundingClientRect(), own = el.getBoundingClientRect();
    const row = first && Math.abs(first.left - own.left) > Math.abs(first.top - own.top);
    let drop = null;
    const move = (m) => {
      if (!drop && Math.hypot(m.clientX - e.clientX, m.clientY - e.clientY) < 6) return;
      document.documentElement.style.userSelect = 'none';
      getSelection().removeAllRanges();
      const at = row ? m.clientX : m.clientY;
      const mid = (c) => { const r = c.getBoundingClientRect(); return row ? r.left + r.width / 2 : r.top + r.height / 2; };
      const sib = sibs.reduce((a, b) => Math.abs(mid(a) - at) <= Math.abs(mid(b) - at) ? a : b, sibs[0]);
      if (!sib) return;
      const r = sib.getBoundingClientRect(), after = at > mid(sib);
      drop = { sib, after };
      state.dropLine = row ? { left: (after ? r.right : r.left) - 2, top: r.top, width: 4, height: r.height }
        : { left: r.left, top: (after ? r.bottom : r.top) - 2, width: r.width, height: 4 };
    };
    const up = () => {
      window.removeEventListener('pointermove', move, true);
      window.removeEventListener('pointerup', up, true);
      document.documentElement.style.userSelect = '';
      state.dropLine = null;
      if (!drop) return;
      state.dragged = true;
      const { sib, after } = drop;
      if ((after ? sib.nextElementSibling : sib.previousElementSibling) === el) return;
      const ids = { pos: pos(el), ref: pos(sib), after };
      sib[after ? 'after' : 'before'](el);
      op('move', () => ids);
    };
    window.addEventListener('pointermove', move, true);
    window.addEventListener('pointerup', up, true);
  }, true);

  // Free move, opt-in: Alt+drag or Alt+arrows shift an element with the CSS translate property, which
  // leaves flex and grid flow alone. Meant for diagram parts and things already placed absolutely.
  const shift = (el) => {
    const t = getComputedStyle(el).translate.split(' ').map(parseFloat), s = slideOf(el);
    const inner = el instanceof SVGElement && !(el instanceof SVGSVGElement) && el.parentNode.getScreenCTM();
    const scale = s.getBoundingClientRect().width / s.offsetWidth;
    return { x: t[0] || 0, y: t[1] || 0, scale, unit: inner ? Math.hypot(inner.a, inner.b) : scale };
  };
  const place = (el, x, y) => { el.style.translate = `${+x.toFixed(1)}px ${+y.toFixed(1)}px`; };
  const saveShift = (el) => op('style', () => ({ pos: pos(el), props: { translate: el.style.translate } }));
  window.addEventListener('pointerdown', (e) => {
    const hit = e.altKey && !e.button && !state.editing && target(e);
    const el = hit && (state.sel.find(s => s.contains(hit)) || hit);
    if (!el || el.parentElement === stage) return;
    e.preventDefault();
    state.sel = [el];
    changed();
    const from = shift(el);
    const move = (m) => {
      state.dragged = true;
      place(el, from.x + (m.clientX - e.clientX) / from.unit, from.y + (m.clientY - e.clientY) / from.unit);
    };
    const up = () => {
      window.removeEventListener('pointermove', move, true);
      window.removeEventListener('pointerup', up, true);
      if (state.dragged) saveShift(el);
    };
    window.addEventListener('pointermove', move, true);
    window.addEventListener('pointerup', up, true);
  }, true);
  let nudgeTimer;
  window.addEventListener('keydown', (e) => {
    const el = state.sel.length === 1 && !state.editing && state.sel[0];
    if (!e.altKey || !e.key.startsWith('Arrow') || !el || el.parentElement === stage) return;
    e.preventDefault(); // Alt+Left is "back" in the browser
    const from = shift(el), step = (e.shiftKey ? 10 : 1) * from.scale / from.unit;
    place(el, from.x + step * ((e.key === 'ArrowRight') - (e.key === 'ArrowLeft')), from.y + step * ((e.key === 'ArrowDown') - (e.key === 'ArrowUp')));
    clearTimeout(nudgeTimer);
    nudgeTimer = setTimeout(() => saveShift(el), 400);
  });

  // Handles: one chip per property in the panel. Drag the label to scrub, or type a number.
  // Gap, padding and font size go to every element of the same kind on the slide, as one rule in
  // <style id="deck-edits"> scoped by the slide's label. Width is an inline style on the one element.
  const live = document.head.appendChild(document.createElement('style')); // mirrors rules written this session
  const TOOLS = [
    ['font', 'font-size', 'font-size', (el) => el instanceof HTMLElement && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())],
    ['gap', 'gap', 'column-gap', (el) => /flex|grid/.test(getComputedStyle(el).display)],
    ['pad', 'padding', 'padding-top', (el) => el instanceof HTMLElement && !el.matches('img, video, canvas')],
    ['width', 'width', 'width', (el) => el.matches('img, svg, video, canvas')],
  ];
  const setProp = (el, prop, probe, px, prior, commit) => {
    const slide = slideOf(el), label = slide.dataset.screenLabel, path = [];
    for (let n = el; n !== slide; n = n.parentElement) path.unshift(n.tagName.toLowerCase() + [...n.classList].map(c => '.' + CSS.escape(c)).join(''));
    const peers = prop === 'width' ? [el] : [...slide.querySelectorAll(path.join(' '))];
    const props = prop === 'width' ? { width: px, height: 'auto' } : { [prop]: px };
    const inline = () => peers.forEach(p => Object.entries(props).forEach(([k, v]) => p.style.setProperty(k, v)));
    peers.forEach(p => prior.has(p) || prior.set(p, p.style.getPropertyValue(prop)));
    inline();
    if (!commit) return;
    if (prop !== 'width' && label) {
      // Try the rule first. It only stands when it wins the cascade on this element.
      const rule = `[data-screen-label="${label.replace(/["\\]/g, '\\$&')}"] ${path.join(' ')}`;
      const before = live.textContent;
      peers.forEach(p => p.style.setProperty(prop, prior.get(p)));
      live.textContent += `${rule} { ${prop}: ${px}; }\n`;
      if (Math.abs(parseFloat(getComputedStyle(el).getPropertyValue(probe)) - parseFloat(px)) < 0.5) {
        return op('rule', () => ({ selector: rule, props }));
      }
      live.textContent = before;
      inline();
    }
    peers.forEach(p => op('style', () => ({ pos: pos(p), props })));
  };
  const buildTools = () => {
    const tools = $('.tools'), el = state.sel.length === 1 && !state.editing && state.sel[0];
    tools.replaceChildren();
    if (!el) return;
    TOOLS.filter(([, , , fits]) => fits(el)).forEach(([label, prop, probe]) => {
      const chip = document.createElement('label'), grip = document.createElement('span'), input = document.createElement('input');
      const prior = new Map();
      grip.textContent = label;
      input.type = 'number';
      input.min = 0;
      input.value = Math.round(parseFloat(getComputedStyle(el).getPropertyValue(probe)) || 0);
      const set = (commit) => setProp(el, prop, probe, Math.max(0, +input.value) + 'px', prior, commit);
      input.addEventListener('input', () => set(false));
      input.addEventListener('change', () => set(true));
      grip.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        grip.setPointerCapture(e.pointerId);
        const from = +input.value;
        grip.onpointermove = (m) => { input.value = Math.max(0, Math.round(from + m.clientX - e.clientX)); set(false); };
        grip.onpointerup = () => { grip.onpointermove = grip.onpointerup = null; set(true); };
      });
      chip.append(grip, input);
      tools.append(chip);
    });
    if (el.tagName === 'IMG') {
      const swap = document.createElement('button'), file = Object.assign(document.createElement('input'), { type: 'file', accept: 'image/*' });
      swap.textContent = 'swap image';
      swap.onclick = () => file.click();
      file.onchange = async () => {
        const f = file.files[0];
        if (!f) return;
        // A deck that inlines its images keeps doing so; otherwise the file goes to the deck's assets/.
        const src = (el.getAttribute('src') || '').startsWith('data:')
          ? await new Promise(done => { const r = new FileReader(); r.onload = () => done(r.result); r.readAsDataURL(f); })
          : await (await fetch('/__editor/upload?' + encodeURIComponent(f.name), { method: 'POST', body: f })).text();
        el.src = src;
        op('attr', () => ({ pos: pos(el), name: 'src', value: src }));
      };
      tools.append(swap);
    }
  };
  return { buildTools };
};
