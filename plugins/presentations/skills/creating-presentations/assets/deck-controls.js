/**
 * deck-controls.js, the ways a viewer moves through a <deck-stage> deck.
 * Load before deck-stage.js.
 *
 *  - keyboard: ←/→, PgUp/PgDn, Space, Home/End, number keys, R to reset.
 *  - bottom-center overlay with prev/next, slide count and a Reset (R)
 *    hint; it fades out on idle and stays hidden while presenting.
 *  - tap zones for touch: left third back, right third forward.
 *
 * Leaves one global, window.DeckControls, a class built once per stage:
 *   new DeckControls(stage)  builds .tapzones and .overlay for the shadow root
 *   connect() / disconnect() add and remove the window key and mouse listeners
 *   flash()                  show the overlay, hide it again after idle
 *   hide()                   hide it now (presenting mode)
 *   setCurrent(n), setTotal(n)
 *   offset(railPx)           keep overlay and tap zones beside the rail
 * It calls back stage._go(i, reason), stage._advance(dir, reason) and
 * stage._edit.onKey(e), and reads stage._slides and stage._presenting.
 */
(() => {
  const OVERLAY_HIDE_MS = 1800;

  const css = `
    /* Tap zones for mobile, back/forward thirds like Stories.
       Transparent, no visible UI, don't block the overlay. */
    .tapzones {
      position: fixed;
      inset: 0;
      display: flex;
      z-index: 2147482000;
      pointer-events: none;
    }
    .tapzone {
      flex: 1;
      pointer-events: auto;
      -webkit-tap-highlight-color: transparent;
    }
    /* Only activate tap zones on coarse pointers (touch devices). */
    @media (hover: hover) and (pointer: fine) {
      .tapzones { display: none; }
    }

    .overlay {
      position: fixed;
      left: 50%;
      bottom: 22px;
      transform: translate(-50%, 6px) scale(0.92);
      filter: blur(6px);
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 4px;
      background: #000;
      color: #fff;
      border-radius: 999px;
      font-size: 12px;
      font-feature-settings: "tnum" 1;
      letter-spacing: 0.01em;
      opacity: 0;
      pointer-events: none;
      transition: opacity 260ms ease, transform 260ms cubic-bezier(.2,.8,.2,1), filter 260ms ease;
      transform-origin: center bottom;
      z-index: 2147483000;
      user-select: none;
    }
    .overlay[data-visible] {
      opacity: 1;
      pointer-events: auto;
      transform: translate(-50%, 0) scale(1);
      filter: blur(0);
    }

    .btn {
      appearance: none;
      -webkit-appearance: none;
      background: transparent;
      border: 0;
      margin: 0;
      padding: 0;
      color: inherit;
      font: inherit;
      cursor: default;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      height: 28px;
      min-width: 28px;
      border-radius: 999px;
      color: rgba(255,255,255,0.72);
      transition: background 140ms ease, color 140ms ease;
      -webkit-tap-highlight-color: transparent;
    }
    .btn:hover { background: rgba(255,255,255,0.12); color: #fff; }
    .btn:active { background: rgba(255,255,255,0.18); }
    .btn:focus { outline: none; }
    .btn:focus-visible { outline: none; }
    .btn::-moz-focus-inner { border: 0; }
    .btn svg { width: 14px; height: 14px; display: block; }
    .btn.reset {
      font-size: 11px;
      font-weight: 500;
      letter-spacing: 0.02em;
      padding: 0 10px 0 12px;
      gap: 6px;
      color: rgba(255,255,255,0.72);
    }
    .btn.reset .kbd {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 16px;
      height: 16px;
      padding: 0 4px;
      font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
      font-size: 10px;
      line-height: 1;
      color: rgba(255,255,255,0.88);
      background: rgba(255,255,255,0.12);
      border-radius: 4px;
    }

    .count {
      font-variant-numeric: tabular-nums;
      color: #fff;
      font-weight: 500;
      padding: 0 8px;
      min-width: 42px;
      text-align: center;
      font-size: 12px;
    }
    .count .sep { color: rgba(255,255,255,0.45); margin: 0 3px; font-weight: 400; }
    .count .total { color: rgba(255,255,255,0.55); }

    .divider {
      width: 1px;
      height: 14px;
      background: rgba(255,255,255,0.18);
      margin: 0 2px;
    }
  `;

  class DeckControls {
    static get css() { return css; }

    constructor(stage) {
      this.stage = stage;
      this._hideTimer = null;
      this._onKey = this._onKey.bind(this);
      // Keep overlay visible while mouse moves; hide after idle.
      this._onMouseMove = () => this.flash();

      // Tap zones (mobile): left third = back, right third = forward.
      const tapzones = document.createElement('div');
      tapzones.className = 'tapzones export-hidden';
      tapzones.setAttribute('aria-hidden', 'true');
      tapzones.setAttribute('data-noncommentable', '');
      const tzBack = document.createElement('div');
      tzBack.className = 'tapzone tapzone--back';
      const tzMid = document.createElement('div');
      tzMid.className = 'tapzone tapzone--mid';
      tzMid.style.pointerEvents = 'none';
      const tzFwd = document.createElement('div');
      tzFwd.className = 'tapzone tapzone--fwd';
      tzBack.addEventListener('click', (e) => {
        e.preventDefault();
        stage._advance(-1, 'tap');
      });
      tzFwd.addEventListener('click', (e) => {
        e.preventDefault();
        stage._advance(1, 'tap');
      });
      tapzones.append(tzBack, tzMid, tzFwd);

      // Overlay: compact, solid black, with clickable controls.
      const overlay = document.createElement('div');
      overlay.className = 'overlay export-hidden';
      overlay.setAttribute('role', 'toolbar');
      overlay.setAttribute('aria-label', 'Deck controls');
      overlay.setAttribute('data-noncommentable', '');
      overlay.innerHTML = `
        <button class="btn prev" type="button" aria-label="Previous slide" title="Previous (←)">
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 3L5 8l5 5"/></svg>
        </button>
        <span class="count" aria-live="polite"><span class="current">1</span><span class="sep">/</span><span class="total">1</span></span>
        <button class="btn next" type="button" aria-label="Next slide" title="Next (→)">
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3l5 5-5 5"/></svg>
        </button>
        <span class="divider"></span>
        <button class="btn reset" type="button" aria-label="Reset to first slide" title="Reset (R)">Reset<span class="kbd">R</span></button>
      `;

      overlay.querySelector('.prev').addEventListener('click', () => stage._advance(-1, 'click'));
      overlay.querySelector('.next').addEventListener('click', () => stage._advance(1, 'click'));
      overlay.querySelector('.reset').addEventListener('click', () => stage._go(0, 'click'));

      this.tapzones = tapzones;
      this.overlay = overlay;
      this._countEl = overlay.querySelector('.current');
      this._totalEl = overlay.querySelector('.total');
    }

    connect() {
      window.addEventListener('keydown', this._onKey);
      window.addEventListener('mousemove', this._onMouseMove, { passive: true });
    }

    disconnect() {
      window.removeEventListener('keydown', this._onKey);
      window.removeEventListener('mousemove', this._onMouseMove);
      if (this._hideTimer) clearTimeout(this._hideTimer);
    }

    setCurrent(n) { this._countEl.textContent = String(n); }
    setTotal(n) { this._totalEl.textContent = String(n); }

    /** Overlay is centred on the viewport via left:50% + translate(-50%);
     *  marginLeft shifts the centre by railPx/2 so it lands in the middle
     *  of the [railPx, innerWidth] stage region. Tapzones just inset. */
    offset(railPx) {
      this.overlay.style.marginLeft = (railPx / 2) + 'px';
      this.tapzones.style.left = railPx + 'px';
    }

    flash() {
      // Host posts __omelette_presenting while in fullscreen/tab presentation
      // mode, suppress the nav footer entirely (both hover and slide-change
      // flash) so the audience sees clean slides.
      if (this.stage._presenting) return;
      this.overlay.setAttribute('data-visible', '');
      if (this._hideTimer) clearTimeout(this._hideTimer);
      this._hideTimer = setTimeout(() => {
        this.overlay.removeAttribute('data-visible');
      }, OVERLAY_HIDE_MS);
    }

    hide() {
      this.overlay.removeAttribute('data-visible');
      if (this._hideTimer) clearTimeout(this._hideTimer);
    }

    _onKey(e) {
      const stage = this.stage;
      // Ignore when the user is typing.
      const t = e.target;
      if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
      // The slide menu and its delete dialog take Escape (and the dialog
      // swallows nav keys) while open.
      if (stage._edit.onKey(e)) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;

      const key = e.key;
      let handled = true;

      if (key === 'ArrowRight' || key === 'PageDown' || key === ' ' || key === 'Spacebar') {
        stage._advance(1, 'keyboard');
      } else if (key === 'ArrowLeft' || key === 'PageUp') {
        stage._advance(-1, 'keyboard');
      } else if (key === 'Home') {
        stage._go(0, 'keyboard');
      } else if (key === 'End') {
        stage._go(stage._slides.length - 1, 'keyboard');
      } else if (key === 'r' || key === 'R') {
        stage._go(0, 'keyboard');
      } else if (/^[0-9]$/.test(key)) {
        // 1..9 jump to that slide; 0 jumps to 10.
        const n = key === '0' ? 9 : parseInt(key, 10) - 1;
        if (n < stage._slides.length) stage._go(n, 'keyboard');
      } else {
        handled = false;
      }

      if (handled) {
        e.preventDefault();
        this.flash();
      }
    }
  }

  window.DeckControls = DeckControls;
})();
