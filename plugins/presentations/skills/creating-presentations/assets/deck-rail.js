/**
 * deck-rail.js, the thumbnail rail of <deck-stage>. Load before
 * deck-stage.js.
 *
 * A resizable left-hand column of per-slide thumbnails (static clones,
 * see deck-thumbs.js). Click to navigate; ↑/↓ with a thumbnail focused to
 * step between slides; drag to reorder and right-click for the slide menu
 * (both in deck-edit.js). Drag the rail's right edge to resize; width persists to
 * localStorage. Skipped slides carry `data-deck-skip` and are dimmed here.
 * The rail is suppressed in presenting mode, in the host's Preview mode
 * (ViewerMode='none'), on `noscale`, and via the `no-rail` attribute.
 *
 * Leaves one global, window.DeckRail, a class built once per stage:
 *   new DeckRail(stage)  builds .el (.rail) and .handle (.rail-resize)
 *   restore()            apply the stored width and hidden state
 *   enable()             turn the rail on (idempotent)
 *   render()             reconcile thumbs with stage._slides
 *   sync(follow)         mark the current thumb, scroll to it if follow
 *   scale()              rescale clones to the frame width
 *   width()              px the stage must leave free on the left
 *   setBlocked(on)       hard hide for presenting / preview mode
 *   setVisible(on)       the viewer's animated show/hide toggle
 *   setAspect()          follow the design size
 *   markSkip(i, on)      dim or undim one thumb
 *   destroy()            undo enable(), on disconnect
 * It calls back stage._go(i, reason) and stage._fit(), and hands each
 * thumb to stage._edit.wireThumb(entry).
 */
(() => {
  const css = `
    /* ── Thumbnail rail ──────────────────────────────────────────────────
       Fixed column on the left; each thumbnail is a static deep-clone of
       the light-DOM slide scaled into a 16:9 (or design-aspect) frame. The
       stage re-fits around it (see _fit); hidden during present / noscale
       / print so capture geometry and fullscreen output are unchanged. */
    .rail {
      position: fixed;
      left: 0;
      top: 0;
      bottom: 0;
      width: var(--deck-rail-w, 188px);
      background: #141414;
      border-right: 1px solid rgba(255,255,255,0.08);
      overflow-y: auto;
      overflow-x: hidden;
      padding: 12px 10px;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      gap: 12px;
      z-index: 2147482500;
      scrollbar-width: thin;
      scrollbar-color: rgba(255,255,255,0.18) transparent;
    }
    .rail::-webkit-scrollbar { width: 8px; }
    .rail::-webkit-scrollbar-track { background: transparent; margin: 2px; }
    .rail::-webkit-scrollbar-thumb {
      background: rgba(255,255,255,0.18);
      border-radius: 4px;
      border: 2px solid transparent;
      background-clip: content-box;
    }
    .rail::-webkit-scrollbar-thumb:hover {
      background: rgba(255,255,255,0.28);
      border: 2px solid transparent;
      background-clip: content-box;
    }
    :host([no-rail]) .rail,
    :host([noscale]) .rail { display: none; }
    .rail[data-presenting] { display: none; }
    /* User-driven show/hide (the TweaksPanel toggle) slides instead of
       popping. Transitions are gated on :host([data-rail-anim]), set only
       for the 200ms around the toggle, so window-resize and rail-width
       drag (which also call _fit) don't lag behind the cursor. */
    .rail[data-user-hidden] { transform: translateX(-100%); }
    :host([data-rail-anim]) .rail { transition: transform 200ms cubic-bezier(.3,.7,.4,1); }
    :host([data-rail-anim]) .stage { transition: left 200ms cubic-bezier(.3,.7,.4,1); }
    :host([data-rail-anim]) .canvas { transition: transform 200ms cubic-bezier(.3,.7,.4,1); }
    /* transition shorthand replaces rather than merges, repeat the base
       .overlay opacity/transform/filter transitions so visibility changes
       during the 200ms toggle window still fade instead of popping. */
    :host([data-rail-anim]) .overlay {
      transition: margin-left 200ms cubic-bezier(.3,.7,.4,1),
                  opacity 260ms ease,
                  transform 260ms cubic-bezier(.2,.8,.2,1),
                  filter 260ms ease;
    }
    :host([data-rail-anim]) .tapzones { transition: left 200ms cubic-bezier(.3,.7,.4,1); }

    .thumb {
      position: relative;
      display: flex;
      align-items: flex-start;
      gap: 8px;
      cursor: pointer;
      user-select: none;
    }
    .thumb .num {
      width: 16px;
      flex-shrink: 0;
      font-size: 11px;
      font-weight: 500;
      text-align: right;
      color: rgba(255,255,255,0.55);
      padding-top: 2px;
      font-variant-numeric: tabular-nums;
    }
    .thumb .frame {
      position: relative;
      flex: 1;
      min-width: 0;
      aspect-ratio: var(--deck-aspect);
      background: #fff;
      border-radius: 4px;
      outline: 2px solid transparent;
      outline-offset: 0;
      overflow: hidden;
      transition: outline-color 120ms ease;
    }
    .thumb:hover .frame { outline-color: rgba(255,255,255,0.25); }
    .thumb { outline: none; }
    .thumb:focus-visible .frame { outline-color: rgba(255,255,255,0.5); }
    .thumb[data-current] .num { color: #fff; }
    .thumb[data-current] .frame { outline-color: #D97757; }
    .thumb[data-skip] .frame { opacity: 0.35; }
    .thumb[data-skip] .frame::after {
      content: 'Skipped';
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(0,0,0,0.45);
      color: #fff;
      font-size: 10px;
      font-weight: 500;
      letter-spacing: 0.04em;
    }

    .rail-resize {
      position: fixed;
      left: calc(var(--deck-rail-w, 188px) - 3px);
      top: 0;
      bottom: 0;
      width: 6px;
      cursor: col-resize;
      z-index: 2147482600;
      touch-action: none;
    }
    .rail-resize:hover,
    .rail-resize[data-dragging] { background: rgba(255,255,255,0.12); }
    :host([no-rail]) .rail-resize,
    :host([noscale]) .rail-resize,
    .rail[data-presenting] + .rail-resize,
    .rail[data-user-hidden] + .rail-resize { display: none; }
  `;

  // Thumbs are keyed by slide element and reused across render() calls,
  // so a reorder/delete is an O(changed) DOM shuffle instead of an O(N)
  // teardown-and-re-clone. Each thumb starts as a lightweight shell (num +
  // empty frame); DeckThumbs materializes the clone lazily when the frame
  // scrolls into (or near) view, so only visible-ish slides pay the clone
  // + image-decode cost.
  class DeckRail {
    static get css() { return css; }

    constructor(stage) {
      this.stage = stage;
      const rail = document.createElement('div');
      rail.className = 'rail export-hidden';
      rail.setAttribute('data-noncommentable', '');
      rail.style.setProperty('--deck-aspect', stage.designWidth + '/' + stage.designHeight);
      stage._edit.wireRail(rail);

      // Rail resize handle, drag to set --deck-rail-w, persisted to
      // localStorage so the width survives reloads.
      const resize = document.createElement('div');
      resize.className = 'rail-resize export-hidden';
      resize.setAttribute('data-noncommentable', '');
      resize.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        resize.setPointerCapture(e.pointerId);
        resize.setAttribute('data-dragging', '');
        const move = (ev) => this._setWidth(ev.clientX);
        const up = () => {
          resize.removeEventListener('pointermove', move);
          resize.removeEventListener('pointerup', up);
          resize.removeEventListener('pointercancel', up);
          resize.removeAttribute('data-dragging');
          try { localStorage.setItem('deck-stage.railWidth', String(this.px)); } catch (err) {}
        };
        resize.addEventListener('pointermove', move);
        resize.addEventListener('pointerup', up);
        resize.addEventListener('pointercancel', up);
      });

      this.el = rail;
      this.handle = resize;
    }

    restore() {
      // Restore persisted rail width.
      let rw = 188;
      try {
        const s = localStorage.getItem('deck-stage.railWidth');
        if (s) rw = parseInt(s, 10) || rw;
      } catch (err) {}
      this._setWidth(rw);
      this._syncHidden();
    }

    enable() {
      // Idempotent, older host builds still post __omelette_rail_enabled.
      // no-rail guard keeps the observers/stylesheet walk off the cheap path
      // for presenter-popup thumbnail iframes (up to 9 per view).
      if (this.enabled || this.stage.hasAttribute('no-rail')) return;
      this.enabled = true;
      // Per-viewer preference, restored alongside rail width. Default on;
      // only a stored '0' (from the TweaksPanel toggle) hides it. A re-add
      // keeps the value it had.
      if (this.visible == null) {
        this.visible = true;
        try {
          if (localStorage.getItem('deck-stage.railVisible') === '0') this.visible = false;
        } catch (e) {}
      }
      this._clones = new DeckThumbs(this.stage, this);
      // Build the rail now that it's enabled, slotchange already fired,
      // so render's early-return skipped the initial build.
      this._syncHidden();
      this.render();
      this.stage._fit();
    }

    // Undoes enable(): the stage calls this on disconnect and enable()
    // again on a re-add, which rebuilds the thumbs and their observers.
    destroy() {
      if (this._railAnimTimer) clearTimeout(this._railAnimTimer);
      if (this._scaleRaf) cancelAnimationFrame(this._scaleRaf);
      this._scaleRaf = null;
      if (this._clones) this._clones.destroy();
      (this.thumbs || []).forEach((t) => t.thumb.remove());
      this.thumbs = [];
      this.enabled = false;
    }

    _setWidth(px) {
      const w = Math.max(120, Math.min(360, Math.round(px)));
      this.px = w;
      this.stage.style.setProperty('--deck-rail-w', w + 'px');
      this.stage._fit();
      // scale() forces a sync layout (frame.offsetWidth) then writes
      // N transforms. During a resize drag this runs per-pointermove;
      // coalesce to one per frame.
      if (!this._scaleRaf) {
        this._scaleRaf = requestAnimationFrame(() => {
          this._scaleRaf = null;
          this.scale();
        });
      }
    }

    width() {
      // State-based, no offsetWidth: the first _fit() can run before the
      // rail has had layout on some load paths, and a 0 there paints the
      // slide full-width for one frame before the post-slotchange _fit()
      // corrects it.
      const stage = this.stage;
      if (!this.enabled || !this.visible || stage.hasAttribute('no-rail')
          || stage.hasAttribute('noscale') || this.blocked) return 0;
      return this.px || 0;
    }

    setAspect() {
      this.el.style.setProperty('--deck-aspect', this.stage.designWidth + '/' + this.stage.designHeight);
    }

    setBlocked(on) {
      this.blocked = on;
      this._syncHidden();
    }

    // Per-viewer show/hide, driven by the TweaksPanel's auto-injected
    // "Thumbnail rail" toggle (or any author script). Independent of
    // whether the Tweaks panel itself is open, closing the panel
    // doesn't change rail visibility. Persists alongside rail width.
    setVisible(on) {
      const stage = this.stage;
      this.visible = on;
      try { localStorage.setItem('deck-stage.railVisible', on ? '1' : '0'); } catch (e) {}
      // Arm the transition, commit it, then flip state, otherwise the
      // browser coalesces both writes and nothing animates on show.
      stage.setAttribute('data-rail-anim', '');
      void this.el.offsetHeight;
      this._syncHidden();
      stage._fit();
      this.scale();
      clearTimeout(this._railAnimTimer);
      this._railAnimTimer = setTimeout(() => stage.removeAttribute('data-rail-anim'), 220);
    }

    _syncHidden() {
      // data-presenting is the hard hide (display:none) for flag-off,
      // presentation mode, and the host's Preview segment, instant, no
      // transition. data-user-hidden is the soft hide (translateX(-100%))
      // for the viewer's rail toggle, so show/hide slides under
      // :host([data-rail-anim]).
      const hard = !this.enabled || this.blocked;
      if (hard) this.el.setAttribute('data-presenting', '');
      else this.el.removeAttribute('data-presenting');
      if (!this.visible) this.el.setAttribute('data-user-hidden', '');
      else this.el.removeAttribute('data-user-hidden');
      // translateX hide leaves thumbs (tabIndex=0) in the tab order ,
      // inert keeps them unfocusable while the rail is off-screen.
      this.el.inert = hard || !this.visible;
    }

    render() {
      if (!this.enabled) { this.thumbs = []; return; }
      const rail = this.el;
      // FLIP: record each *materialized* thumb's top before the reconcile.
      // Off-screen (non-materialized) thumbs don't need the animation and
      // skipping their getBoundingClientRect saves a forced layout per
      // off-screen thumb on large decks.
      const prevTops = new Map();
      (this.thumbs || []).forEach(({ thumb, slide, host }) => {
        if (host) prevTops.set(slide, thumb.getBoundingClientRect().top);
      });
      const st = rail.scrollTop;

      // Reconcile: reuse thumbs that already exist for a slide, create
      // shells for new slides, drop thumbs for removed slides.
      const bySlide = new Map();
      (this.thumbs || []).forEach((t) => bySlide.set(t.slide, t));
      const next = [];
      this.stage._slides.forEach((slide) => {
        let t = bySlide.get(slide);
        if (t) bySlide.delete(slide);
        else t = this._makeThumb(slide);
        next.push(t);
      });
      // Orphans, slides removed since last render.
      bySlide.forEach((t) => {
        this._clones.unwatch(t);
        t.thumb.remove();
      });
      // Put thumbs into document order to match the slides. insertBefore
      // on an already-correctly-placed node is a no-op, so this is cheap
      // when nothing moved.
      next.forEach((t, i) => {
        const want = t.thumb;
        const at = rail.children[i];
        if (at !== want) rail.insertBefore(want, at || null);
        t.i = i;
        t.num.textContent = String(i + 1);
        if (t.slide.hasAttribute('data-deck-skip')) t.thumb.setAttribute('data-skip', '');
        else t.thumb.removeAttribute('data-skip');
      });
      this.thumbs = next;

      rail.scrollTop = st;
      if (prevTops.size) {
        const moved = [];
        this.thumbs.forEach(({ thumb, slide }) => {
          const old = prevTops.get(slide);
          if (old == null) return;
          const dy = old - thumb.getBoundingClientRect().top;
          if (Math.abs(dy) < 1) return;
          thumb.style.transition = 'none';
          thumb.style.transform = `translateY(${dy}px)`;
          moved.push(thumb);
        });
        if (moved.length) {
          // Commit the inverted positions before flipping the transition
          // on, otherwise the browser coalesces both style writes and
          // nothing animates.
          void rail.offsetHeight;
          moved.forEach((t) => {
            t.style.transition = 'transform 180ms cubic-bezier(.2,.7,.3,1)';
            t.style.transform = '';
          });
          setTimeout(() => moved.forEach((t) => { t.style.transition = ''; }), 220);
        }
      }
      requestAnimationFrame(() => this.scale());
      this.sync(false);
    }

    /** Create a lightweight thumb shell for one slide. The clone is
     *  materialized later by DeckThumbs. Event handlers read the thumb's
     *  *current* index (entry.i) so the same element can be reused across
     *  reorders. */
    _makeThumb(slide) {
      const stage = this.stage;
      const thumb = document.createElement('div');
      thumb.className = 'thumb';
      thumb.tabIndex = 0;
      const num = document.createElement('div');
      num.className = 'num';
      const frame = document.createElement('div');
      frame.className = 'frame';
      thumb.append(num, frame);

      const entry = { thumb, num, frame, slide, clone: null, host: null, i: -1 };
      // entry.i is refreshed on every render() reconcile pass, so
      // handlers read the thumb's current position without an O(N) scan.
      const idx = () => entry.i;

      thumb.addEventListener('click', () => stage._go(idx(), 'click'));
      // ↑/↓ step through the rail when a thumb has focus. _go clamps at the
      // ends and _applyIndex→sync scrolls the new current thumb into view;
      // we move focus to it (preventScroll, sync already scrolled) so a
      // held key walks the whole list. stopPropagation keeps this out of
      // the window-level key handler.
      thumb.addEventListener('keydown', (e) => {
        if (e.key !== 'ArrowUp' && e.key !== 'ArrowDown') return;
        if (e.metaKey || e.ctrlKey || e.altKey) return;
        e.preventDefault();
        e.stopPropagation();
        stage._go(idx() + (e.key === 'ArrowDown' ? 1 : -1), 'keyboard');
        const cur = this.thumbs && this.thumbs[stage._index];
        if (cur) cur.thumb.focus({ preventScroll: true });
      });
      stage._edit.wireThumb(entry);

      this._clones.watch(entry);
      return entry;
    }

    scale() {
      if (!this.thumbs || !this.thumbs.length) return;
      // Every frame is the same width; if it reads 0 the rail is
      // display:none (noscale / no-rail / presenting / print), leave the
      // clones as-is and re-run when the rail is revealed.
      const fw = this.thumbs[0].frame.offsetWidth;
      if (!fw) return;
      this.thumbScale = fw / this.stage.designWidth;
      this.thumbs.forEach(({ clone }) => {
        if (clone) clone.style.transform = 'scale(' + this.thumbScale + ')';
      });
    }

    sync(follow) {
      if (!this.thumbs) return;
      this.thumbs.forEach(({ thumb }, i) => {
        if (i === this.stage._index) {
          thumb.setAttribute('data-current', '');
          if (follow && typeof thumb.scrollIntoView === 'function') {
            thumb.scrollIntoView({ block: 'nearest' });
          }
        } else {
          thumb.removeAttribute('data-current');
        }
      });
    }

    markSkip(i, on) {
      if (this.thumbs && this.thumbs[i]) {
        if (on) this.thumbs[i].thumb.setAttribute('data-skip', '');
        else this.thumbs[i].thumb.removeAttribute('data-skip');
      }
    }
  }

  window.DeckRail = DeckRail;
})();
