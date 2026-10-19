/**
 * presenter-notes.js, the speaker-notes panel of presenter.html: shows the
 * current slide's notes as light markdown, edits them, keeps unsaved edits
 * in localStorage, and writes them into the deck HTML file ("Save to deck").
 * Loaded by presenter.html before its own script.
 *
 * Leaves one global, window.PresenterNotes(opts), which wires the panel
 * and returns {render(), receive(notesArray), edit()}.
 *   opts.refs      the presenter's element refs (notes, notesEdit, editBtn,
 *                  saveBtn, notesNum)
 *   opts.editsKey  localStorage key for unsaved edits
 *   opts.deckPath  the deck file, relative to presenter.html
 *   opts.state     () => {index, total}, the current slide
 *   opts.channel   () => the BroadcastChannel to the deck, or null
 */
window.PresenterNotes = function (opts) {
  const { refs, editsKey, deckPath, state, channel } = opts;
  let notes = [];
  let notesJson = '';

  // Unsaved note edits, {slideIndex: text}, persisted to localStorage so
  // nothing is lost across reloads until "Save to deck" writes them into
  // the deck HTML file. The deck window reads the same key when it
  // broadcasts notes (file:// pages share one localStorage origin).
  let overlay = {};
  try {
    const stored = JSON.parse(localStorage.getItem(editsKey) || 'null');
    if (stored && typeof stored === 'object') overlay = stored;
  } catch (e) {}
  let editing = false;
  let editSlide = -1;
  let editTimer = null;

  function applyOverlay(arr) {
    const merged = arr.slice();
    Object.keys(overlay).forEach((k) => {
      const i = parseInt(k, 10);
      if (i >= 0) merged[i] = String(overlay[k]);
    });
    return merged;
  }

  // --- Notes: lazy-load from the deck window (window.opener) so we have
  //     them even if BroadcastChannel arrives later. Unreachable on file://
  //     (opaque origins); the deck also sends notes over the channel. ----
  // Notes are authored either as an array (0-indexed) or as an object keyed
  // by 1-based slide number; normalize to the array shape.
  function normalizeNotes(parsed) {
    if (Array.isArray(parsed)) return parsed;
    if (parsed && typeof parsed === 'object') {
      const out = [];
      Object.keys(parsed).forEach((k) => {
        const n = parseInt(k, 10);
        if (n >= 1) out[n - 1] = String(parsed[k]);
      });
      return out;
    }
    return [];
  }

  function loadNotesFromOpener() {
    try {
      const doc = window.opener && window.opener.document;
      if (!doc) return false;
      const tag = doc.getElementById('speaker-notes');
      if (!tag) return false;
      const parsed = normalizeNotes(JSON.parse(tag.textContent || '[]'));
      if (parsed.length) { notes = applyOverlay(parsed); return true; }
    } catch (e) {}
    return false;
  }
  // Try repeatedly while the opener is still resolvable, handles the
  // race where the popup opens before the deck's notes script has parsed.
  if (!loadNotesFromOpener()) {
    let tries = 0;
    const iv = setInterval(() => {
      if (loadNotesFromOpener() || ++tries > 20 || !window.opener || window.opener.closed) {
        clearInterval(iv);
        renderNotes();
      }
    }, 200);
  }

  // --- Markdown (display only; editing always shows the raw text) --------
  function escapeHtml(s) {
    return s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  }
  function inlineMd(s) {
    return escapeHtml(s)
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\*([^*]+)\*/g, '<em>$1</em>');
  }
  function renderMd(text) {
    const out = [];
    let list = null;
    const closeList = () => { if (list) { out.push('</' + list + '>'); list = null; } };
    text.split('\n').forEach((line) => {
      const t = line.trim();
      let m;
      if ((m = t.match(/^[-*]\s+(.*)/))) {
        if (list !== 'ul') { closeList(); out.push('<ul>'); list = 'ul'; }
        out.push('<li>' + inlineMd(m[1]) + '</li>');
      } else if ((m = t.match(/^\d+[.)]\s+(.*)/))) {
        if (list !== 'ol') { closeList(); out.push('<ol>'); list = 'ol'; }
        out.push('<li>' + inlineMd(m[1]) + '</li>');
      } else if ((m = t.match(/^#{1,4}\s+(.*)/))) {
        closeList();
        out.push('<h4>' + inlineMd(m[1]) + '</h4>');
      } else if (!t) {
        closeList();
      } else {
        closeList();
        out.push('<p>' + inlineMd(t) + '</p>');
      }
    });
    closeList();
    return out.join('');
  }

  // --- Render -----------------------------------------------------------
  function renderNotes() {
    const s = state();
    refs.notesNum.textContent = s.total
      ? 'Slide ' + (s.index + 1) + ' of ' + s.total
      : '';
    if (editing) {
      // Only touch the textarea when the slide changed; rewriting .value on
      // every heartbeat would jump the cursor mid-typing.
      if (editSlide !== s.index) {
        commitEditValue();
        editSlide = s.index;
        refs.notesEdit.value = notes[s.index] || '';
      }
      return;
    }
    const txt = (notes[s.index] || '').trim();
    if (txt) {
      refs.notes.innerHTML = renderMd(notes[s.index]);
      refs.notes.classList.remove('empty');
    } else {
      refs.notes.textContent = 'No notes for this slide.';
      refs.notes.classList.add('empty');
    }
  }

  // --- Note editing -------------------------------------------------------
  function updateDirty() {
    const dirty = Object.keys(overlay).length > 0;
    refs.saveBtn.classList.toggle('dirty', dirty);
    if (!('showOpenFilePicker' in window)) {
      refs.saveBtn.disabled = true;
      refs.saveBtn.title = 'Saving to the file needs a Chromium browser';
    } else {
      refs.saveBtn.disabled = !dirty;
    }
  }

  function storeEdit(i, text) {
    if ((notes[i] || '') === text) return;
    notes[i] = text;
    overlay[String(i)] = text;
    try { localStorage.setItem(editsKey, JSON.stringify(overlay)); } catch (e) {}
    updateDirty();
  }

  function commitEditValue() {
    clearTimeout(editTimer);
    editTimer = null;
    if (editSlide >= 0) storeEdit(editSlide, refs.notesEdit.value);
  }

  function setEditing(on) {
    if (on === editing) return;
    editing = on;
    refs.editBtn.textContent = on ? 'Done' : 'Edit';
    refs.notes.style.display = on ? 'none' : '';
    refs.notesEdit.style.display = on ? 'block' : 'none';
    if (on) {
      editSlide = state().index;
      refs.notesEdit.value = notes[state().index] || '';
      refs.notesEdit.focus();
    } else {
      commitEditValue();
      editSlide = -1;
      renderNotes();
    }
  }

  refs.editBtn.addEventListener('click', () => setEditing(!editing));
  refs.notesEdit.addEventListener('input', () => {
    clearTimeout(editTimer);
    editTimer = setTimeout(commitEditValue, 300);
  });
  refs.notesEdit.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { e.preventDefault(); setEditing(false); }
  });

  // --- Save to deck: rewrite the #speaker-notes block in the deck HTML ---
  // Pure string surgery so it can be exercised independently of the file
  // picker. Notes are written as an object keyed by 1-based slide number
  // (the shape the decks are authored with), skipping empty entries; "<" is
  // escaped so note text can never terminate the script tag.
  function rewriteDeckHtml(text, notesArr) {
    const obj = {};
    for (let i = 0; i < notesArr.length; i++) {
      if ((notesArr[i] || '').trim()) obj[String(i + 1)] = notesArr[i];
    }
    const json = JSON.stringify(obj, null, 2).replace(/</g, '\\u003c');
    const block = '<script type="application/json" id="speaker-notes">\n'
      + json + '\n</' + 'script>';
    const existing = /<script[^>]*\bid=["']speaker-notes["'][^>]*>[\s\S]*?<\/script>/;
    if (existing.test(text)) return text.replace(existing, block);
    const anchor = text.match(/<script[^>]*\bsrc=["'][^"']*deck-stage\.js["']/);
    if (anchor) return text.slice(0, anchor.index) + block + '\n' + text.slice(anchor.index);
    return text.replace(/<\/body>/i, block + '\n</body>');
  }

  let deckFileHandle = null;
  async function saveToDeck() {
    commitEditValue();
    if (!Object.keys(overlay).length) return;
    try {
      if (!deckFileHandle) {
        const picked = await window.showOpenFilePicker({
          types: [{ description: 'Deck HTML', accept: { 'text/html': ['.html', '.htm'] } }],
        });
        const expected = decodeURIComponent(deckPath.split('/').pop());
        if (picked[0].name !== expected
            && !confirm('Picked "' + picked[0].name + '" but this presenter belongs to "'
              + expected + '". Write the notes into it anyway?')) {
          return;
        }
        deckFileHandle = picked[0];
      }
      const file = await deckFileHandle.getFile();
      const text = await file.text();
      if (text.indexOf('<deck-stage') === -1) {
        alert('That file does not contain a <deck-stage> element. Pick the deck file: '
          + decodeURIComponent(deckPath));
        deckFileHandle = null;
        return;
      }
      const w = await deckFileHandle.createWritable();
      await w.write(rewriteDeckHtml(text, notes));
      await w.close();
      overlay = {};
      try { localStorage.removeItem(editsKey); } catch (e) {}
      updateDirty();
      // Refresh the deck window's in-DOM notes tag so its broadcasts match
      // the file now that the overlay is gone.
      const bc = channel();
      bc && bc.postMessage({ type: 'notes-set', notes: notes.slice() });
      refs.saveBtn.textContent = 'Saved';
      setTimeout(() => { refs.saveBtn.textContent = 'Save to deck'; }, 1600);
    } catch (e) {
      if (e && e.name === 'AbortError') return; // picker cancelled
      alert('Save failed: ' + (e && e.message ? e.message : e));
    }
  }
  refs.saveBtn.addEventListener('click', saveToDeck);

  notes = applyOverlay(notes);
  updateDirty();

  return {
    render: renderNotes,
    // Notes arrive over the channel because window.opener.document is
    // unreachable on file:// (opaque origins). Local unsaved edits win
    // over whatever the deck broadcasts, and re-render only on change
    // so the heartbeat's re-sends don't reset the notes scroll position.
    receive(arr) {
      const merged = applyOverlay(arr);
      const j = JSON.stringify(merged);
      if (j !== notesJson) { notesJson = j; notes = merged; renderNotes(); }
    },
    edit() { setEditing(true); },
  };
};
