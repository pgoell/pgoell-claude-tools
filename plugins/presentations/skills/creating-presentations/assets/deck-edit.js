/**
 * deck-edit.js, editing a <deck-stage> deck from its thumbnail rail:
 * drag a thumbnail to reorder, or right-click it for Skip / Move up /
 * Move down / Delete, where Delete opens a Cancel/Delete confirm dialog.
 * Load before deck-stage.js.
 *
 * Leaves one global, window.DeckEdit, a class built once per stage:
 *   new DeckEdit(stage)  builds .menu (.ctxmenu) and .confirm
 *                        (.confirm-backdrop) for the shadow root
 *   wireRail(railEl)     edge auto-scroll while dragging
 *   wireThumb(entry)     right-click and drag handlers on one thumb
 *   close()              close the menu and the dialog
 *   onKey(e)             true when the menu or dialog took the key
 *   onDocClick           capture-phase window click handler
 * It changes the light-DOM slides itself, then calls back
 * stage._edited(detail, index, showOverlay), which dispatches `deckchange`
 * and reads the slides again. It reads stage._slides, stage._index and
 * stage._rail.thumbs, and dims a skipped thumb via stage._rail.markSkip.
 */
(() => {
  const css = `
    .thumb[data-dragging] { opacity: 0.35; }
    .thumb::before {
      content: '';
      position: absolute;
      left: 24px;
      right: 0;
      height: 3px;
      border-radius: 2px;
      background: #D97757;
      opacity: 0;
      pointer-events: none;
    }
    .thumb[data-drop="before"]::before { top: -8px; opacity: 1; }
    .thumb[data-drop="after"]::before { bottom: -8px; opacity: 1; }

    .ctxmenu {
      position: fixed;
      min-width: 150px;
      padding: 4px;
      background: #242424;
      border: 1px solid rgba(255,255,255,0.12);
      border-radius: 7px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.45);
      z-index: 2147483100;
      display: none;
      font-size: 12px;
    }
    .ctxmenu[data-open] { display: block; }
    .ctxmenu button {
      display: block;
      width: 100%;
      appearance: none;
      border: 0;
      background: transparent;
      color: #e8e8e8;
      font: inherit;
      text-align: left;
      padding: 6px 10px;
      border-radius: 4px;
      cursor: pointer;
    }
    .ctxmenu button:hover:not(:disabled) { background: rgba(255,255,255,0.08); }
    .ctxmenu button:disabled { opacity: 0.35; cursor: default; }
    .ctxmenu hr {
      border: 0;
      border-top: 1px solid rgba(255,255,255,0.1);
      margin: 4px 2px;
    }

    /* Delete-confirm popup, matches the SPA's ConfirmDialog layout
       (title + message body, depressed footer with Cancel / Delete). */
    .confirm-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,0.45);
      z-index: 2147483200;
      display: none;
      align-items: center;
      justify-content: center;
    }
    .confirm-backdrop[data-open] { display: flex; }
    .confirm {
      width: 320px;
      max-width: calc(100vw - 32px);
      background: #2a2a2a;
      color: #e8e8e8;
      border: 1px solid rgba(255,255,255,0.12);
      border-radius: 12px;
      box-shadow: 0 12px 32px rgba(0,0,0,0.5);
      overflow: hidden;
      font-family: inherit;
      animation: deck-confirm-in 0.18s ease;
    }
    @keyframes deck-confirm-in {
      from { opacity: 0; transform: scale(0.96); }
      to { opacity: 1; transform: scale(1); }
    }
    .confirm .body { padding: 20px 20px 16px; }
    .confirm .title { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
    .confirm .msg { font-size: 13px; line-height: 1.5; color: rgba(255,255,255,0.65); }
    .confirm .footer {
      padding: 14px 20px;
      background: #1f1f1f;
      border-top: 1px solid rgba(255,255,255,0.08);
      display: flex;
      justify-content: flex-end;
      gap: 8px;
    }
    .confirm button {
      appearance: none;
      font: inherit;
      font-size: 13px;
      font-weight: 500;
      padding: 8px 16px;
      border-radius: 8px;
      cursor: pointer;
    }
    .confirm .cancel {
      background: transparent;
      border: 0;
      color: rgba(255,255,255,0.8);
    }
    .confirm .cancel:hover { background: rgba(255,255,255,0.08); }
    .confirm .danger {
      background: #c96442;
      border: 1px solid rgba(0,0,0,0.15);
      color: #fff;
      box-shadow: 0 1px 3px rgba(166,50,68,0.3), 0 2px 6px rgba(166,50,68,0.18);
    }
    .confirm .danger:hover { background: #b5563a; }
  `;

  class DeckEdit {
    static get css() { return css; }

    constructor(stage) {
      this.stage = stage;
      this._menuIndex = -1;
      // Capture-phase close so a click anywhere dismisses the menu, but
      // ignore clicks that land inside the menu itself, otherwise the
      // capture handler runs before the menu's own (bubble) handler and
      // clears _menuIndex out from under it.
      this.onDocClick = (e) => {
        if (this.menu && e.composedPath && e.composedPath().includes(this.menu)) return;
        this._closeMenu();
      };

      const menu = document.createElement('div');
      menu.className = 'ctxmenu export-hidden';
      menu.setAttribute('data-noncommentable', '');
      menu.innerHTML = `
        <button type="button" data-act="skip">Skip slide</button>
        <button type="button" data-act="up">Move up</button>
        <button type="button" data-act="down">Move down</button>
        <hr>
        <button type="button" data-act="delete">Delete slide</button>
      `;
      menu.addEventListener('click', (e) => {
        const act = e.target && e.target.getAttribute && e.target.getAttribute('data-act');
        if (!act) return;
        const i = this._menuIndex;
        this._closeMenu();
        if (act === 'skip') this._toggleSkip(i);
        else if (act === 'up') this._moveSlide(i, i - 1);
        else if (act === 'down') this._moveSlide(i, i + 1);
        else if (act === 'delete') this._openConfirm(i);
      });
      menu.addEventListener('contextmenu', (e) => e.preventDefault());

      // Delete-confirm dialog, mirrors the SPA's ConfirmDialog layout.
      const confirm = document.createElement('div');
      confirm.className = 'confirm-backdrop export-hidden';
      confirm.setAttribute('data-noncommentable', '');
      confirm.innerHTML = `
        <div class="confirm" role="dialog" aria-modal="true">
          <div class="body">
            <div class="title">Delete slide?</div>
            <div class="msg">This slide will be removed from the deck.</div>
          </div>
          <div class="footer">
            <button type="button" class="cancel">Cancel</button>
            <button type="button" class="danger">Delete</button>
          </div>
        </div>
      `;
      confirm.addEventListener('click', (e) => {
        if (e.target === confirm) this._closeConfirm();
      });
      confirm.querySelector('.cancel').addEventListener('click', () => this._closeConfirm());
      confirm.querySelector('.danger').addEventListener('click', () => {
        const i = this._confirmIndex;
        this._closeConfirm();
        this._deleteSlide(i);
      });

      this.menu = menu;
      this.confirm = confirm;
    }

    wireRail(rail) {
      // Edge auto-scroll while dragging a thumb near the rail's top/bottom
      // so off-screen drop targets are reachable. Native dragover fires
      // continuously while the pointer is stationary, so a per-event nudge
      // (ramped by edge proximity) is enough, no rAF loop needed.
      rail.addEventListener('dragover', (e) => {
        if (this._dragFrom == null) return;
        const r = rail.getBoundingClientRect();
        const EDGE = 40;
        const dt = e.clientY - r.top;
        const db = r.bottom - e.clientY;
        if (dt < EDGE) rail.scrollTop -= Math.ceil((EDGE - dt) / 3);
        else if (db < EDGE) rail.scrollTop += Math.ceil((EDGE - db) / 3);
      });
    }

    /** entry.i is the thumb's current index, refreshed on every rail
     *  render, so the same element can be reused across reorders. */
    wireThumb(entry) {
      const stage = this.stage;
      const thumb = entry.thumb;
      const idx = () => entry.i;
      thumb.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        this._open(idx(), e.clientX, e.clientY);
      });
      thumb.draggable = true;
      thumb.addEventListener('dragstart', (e) => {
        this._dragFrom = idx();
        thumb.setAttribute('data-dragging', '');
        e.dataTransfer.effectAllowed = 'move';
        try { e.dataTransfer.setData('text/plain', String(this._dragFrom)); } catch (err) {}
      });
      thumb.addEventListener('dragend', () => {
        thumb.removeAttribute('data-dragging');
        this._clearDrop();
        this._dragFrom = null;
      });
      thumb.addEventListener('dragover', (e) => {
        if (this._dragFrom == null) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        const r = thumb.getBoundingClientRect();
        this._setDrop(idx(), e.clientY < r.top + r.height / 2 ? 'before' : 'after');
      });
      thumb.addEventListener('drop', (e) => {
        if (this._dragFrom == null) return;
        e.preventDefault();
        const i = idx();
        const r = thumb.getBoundingClientRect();
        let to = e.clientY >= r.top + r.height / 2 ? i + 1 : i;
        if (this._dragFrom < to) to--;
        const from = this._dragFrom;
        this._clearDrop();
        this._dragFrom = null;
        if (to !== from) this._moveSlide(from, to);
      });
    }

    _deleteSlide(i) {
      const s = this.stage, slides = s._slides;
      const slide = slides[i];
      if (!slide || slides.length <= 1) return;
      let index = s._index;
      const wasCurrent = i === index;
      if (i < index || (wasCurrent && i === slides.length - 1)) index--;
      slide.remove();
      s._edited({ action: 'delete', from: i, slide }, index, true);
    }

    _toggleSkip(i) {
      const s = this.stage;
      const slide = s._slides[i];
      if (!slide) return;
      const on = !slide.hasAttribute('data-deck-skip');
      if (on) slide.setAttribute('data-deck-skip', '');
      else slide.removeAttribute('data-deck-skip');
      s._rail.markSkip(i, on);
      s._edited({ action: on ? 'skip' : 'unskip', from: i, slide });
    }

    _moveSlide(i, j) {
      const s = this.stage, slides = s._slides;
      if (j < 0 || j >= slides.length || j === i) return;
      const slide = slides[i];
      const ref = j < i ? slides[j] : slides[j].nextSibling;
      // Track the active slide across the reorder so the same content
      // stays on screen.
      const cur = s._index;
      let index = cur;
      if (cur === i) index = j;
      else if (i < cur && j >= cur) index = cur - 1;
      else if (i > cur && j <= cur) index = cur + 1;
      s.insertBefore(slide, ref);
      s._edited({ action: 'move', from: i, to: j, slide }, index, false);
    }

    _setDrop(i, where) {
      // dragover fires at pointer-event rate; touch only the previous
      // and new target rather than sweeping all N thumbs.
      const thumbs = this.stage._rail.thumbs;
      const t = thumbs && thumbs[i];
      if (this._dropOn && this._dropOn !== t) {
        this._dropOn.thumb.removeAttribute('data-drop');
      }
      if (t) t.thumb.setAttribute('data-drop', where);
      this._dropOn = t || null;
    }

    _clearDrop() {
      if (this._dropOn) this._dropOn.thumb.removeAttribute('data-drop');
      this._dropOn = null;
    }

    _open(i, x, y) {
      const slides = this.stage._slides;
      this._menuIndex = i;
      const slide = slides[i];
      const skip = slide && slide.hasAttribute('data-deck-skip');
      this.menu.querySelector('[data-act="skip"]').textContent = skip ? 'Unskip slide' : 'Skip slide';
      this.menu.querySelector('[data-act="up"]').disabled = i <= 0;
      this.menu.querySelector('[data-act="down"]').disabled = i >= slides.length - 1;
      this.menu.querySelector('[data-act="delete"]').disabled = slides.length <= 1;
      // Place, then clamp to viewport after it's measurable.
      this.menu.style.left = x + 'px';
      this.menu.style.top = y + 'px';
      this.menu.setAttribute('data-open', '');
      const r = this.menu.getBoundingClientRect();
      const nx = Math.min(x, window.innerWidth - r.width - 4);
      const ny = Math.min(y, window.innerHeight - r.height - 4);
      this.menu.style.left = Math.max(4, nx) + 'px';
      this.menu.style.top = Math.max(4, ny) + 'px';
    }

    close() {
      this._closeMenu();
      this._closeConfirm();
    }

    onKey(e) {
      // Confirm dialog swallows nav keys while open; Escape cancels. Enter
      // is left to the focused button's native activation so Tab→Cancel
      // →Enter activates Cancel, not the window-level confirm path.
      if (this.confirm.hasAttribute('data-open')) {
        if (e.key === 'Escape') { this._closeConfirm(); e.preventDefault(); }
        return true;
      }
      if (e.key === 'Escape' && this.menu.hasAttribute('data-open')) {
        this._closeMenu();
        e.preventDefault();
        return true;
      }
      return false;
    }

    _closeMenu() {
      this.menu.removeAttribute('data-open');
      this._menuIndex = -1;
    }

    _openConfirm(i) {
      this._confirmIndex = i;
      this.confirm.querySelector('.title').textContent = 'Delete slide ' + (i + 1) + '?';
      this.confirm.setAttribute('data-open', '');
      const btn = this.confirm.querySelector('.danger');
      if (btn && btn.focus) btn.focus();
    }

    _closeConfirm() {
      this.confirm.removeAttribute('data-open');
      this._confirmIndex = -1;
    }
  }

  window.DeckEdit = DeckEdit;
})();
