/**
 * deck-thumbs.js, the slide pictures inside the <deck-stage> thumbnail
 * rail. Load before deck-stage.js.
 *
 * Each thumbnail is a static deep clone of its light-DOM slide, built only
 * when its frame scrolls near the rail viewport, re-cloned when the slide's
 * content changes, and re-styled when a `tweakchange` event fires.
 *
 * Leaves one global, window.DeckThumbs, a class built once per stage when
 * the rail is enabled:
 *   new DeckThumbs(stage, rail)  starts the observers; rail is the DeckRail
 *   watch(entry) / unwatch(entry)  start or stop lazy cloning of one thumb
 *   destroy()                    stops observers, timers and listeners
 *   DeckThumbs.building          true while a thumb builds its inert
 *                                <deck-stage> copy (the stage constructor
 *                                checks it)
 * An entry is the rail's {thumb, num, frame, slide, clone, host, i}. It
 * reads rail.thumbs, rail.px, rail.thumbScale, stage._slideSet and the
 * design size.
 */
(() => {
  // True only while a thumbnail builds its inert <deck-stage> copy.
  let SHELL = false;

  class DeckThumbs {
    static get building() { return SHELL; }

    constructor(stage, rail) {
      this.stage = stage;
      this.rail = rail;
      // Live thumbnail updates: watch the light-DOM slides for content
      // edits and re-clone just the affected thumb(s), debounced. Ignore
      // the data-deck-* / data-screen-label / data-om-validate attributes
      // the stage itself writes so nav and skip don't trigger
      // spurious refreshes.
      const OWN_ATTRS = /^data-(deck-|screen-label$|om-validate$)/;
      this._liveDirty = new Set();
      this._liveObserver = new MutationObserver((records) => {
        for (const r of records) {
          if (r.type === 'attributes' && OWN_ATTRS.test(r.attributeName || '')) continue;
          let n = r.target;
          while (n && n.parentElement !== stage) n = n.parentElement;
          if (n && stage._slideSet && stage._slideSet.has(n)) this._liveDirty.add(n);
        }
        if (this._liveDirty.size && !this._liveTimer) {
          this._liveTimer = setTimeout(() => {
            this._liveTimer = null;
            this._liveDirty.forEach((s) => this._refresh(s));
            this._liveDirty.clear();
          }, 200);
        }
      });
      this._liveObserver.observe(stage, {
        subtree: true, childList: true, characterData: true, attributes: true,
      });
      // Lazy thumbnail materialization, clone the slide only when its
      // frame scrolls into (or near) the rail viewport. rootMargin gives
      // ~4 thumbs of pre-load so fast scrolling doesn't flash blanks.
      this._railObserver = new IntersectionObserver((entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting && e.target.__deckThumb) {
            this._materialize(e.target.__deckThumb);
          }
        });
      }, { root: rail.el, rootMargin: '400px 0px' });
      // Tweaks typically change CSS vars / attrs OUTSIDE <deck-stage>
      // (on <html>, <body>, a wrapper div, or a <style> tag), which
      // _liveObserver can't see. Re-snapshot author CSS (constructable
      // sheet is shared by reference, so one replaceSync updates every
      // thumb shadow root) and re-sync each thumb host's attrs + custom
      // properties. In-slide DOM mutations are _liveObserver's job.
      // Debounced so slider drags don't thrash.
      this._onTweakChange = () => {
        clearTimeout(this._tweakTimer);
        this._tweakTimer = setTimeout(() => {
          this._thumbCssCache = null;
          (rail.thumbs || []).forEach((t) => {
            if (t.host) this._syncThumbShell(t);
          });
        }, 120);
      };
      window.addEventListener('tweakchange', this._onTweakChange);
    }

    watch(entry) {
      this._railObserver.observe(entry.frame);
      entry.frame.__deckThumb = entry;
    }

    unwatch(entry) {
      this._railObserver.unobserve(entry.frame);
    }

    destroy() {
      if (this._liveTimer) clearTimeout(this._liveTimer);
      if (this._tweakTimer) clearTimeout(this._tweakTimer);
      this._liveObserver.disconnect();
      this._railObserver.disconnect();
      window.removeEventListener('tweakchange', this._onTweakChange);
    }

    /** Thumbnails render in a nested shadow root, where author selectors
     *  that name the slide's ancestors (`deck-stage > section`, `body .x`,
     *  `html.dark .x`) match nothing and the clone inherits the rail's own
     *  color and font. So each thumb rebuilds the ancestor chain inside its
     *  shadow root: boxless (display:contents) copies of <html>, <body>,
     *  any wrappers and an inert <deck-stage>, attributes included, with
     *  the slide clone at the bottom. A linked sheet is attached as a copy
     *  of its <link>, because cssRules throws for linked sheets on file://
     *  and for cross-origin sheets; see _thumbCss for the exception. */
    _syncThumbSheets(entry) {
      const now = Array.from(document.styleSheets).filter((sh) => sh.ownerNode && !sh.disabled);
      const old = entry.sheets || [];
      const same = now.length === old.length && now.every((sh, i) => sh.ownerNode === old[i].src);
      const sr = entry.host.shadowRoot;
      entry.sheets = now.map((sh, i) => {
        const src = sh.ownerNode;
        const css = this._thumbCss(sh);
        const isStyle = css != null;
        let node = same ? old[i].node : (old.find((o) => o.src === src) || {}).node;
        if (node && (node.localName === 'style') !== isStyle) { node.remove(); node = null; }
        if (!node) {
          if (isStyle) {
            node = document.createElement('style');
            if (sh.media.mediaText) node.media = sh.media.mediaText;
          } else {
            // Linked sheets load async even from cache; keep the thumb
            // hidden until they have, so it never paints unstyled.
            node = src.cloneNode(true);
            node.removeAttribute('id');
            entry.pending = (entry.pending || 0) + 1;
            const done = () => {
              if (--entry.pending <= 0) { entry.pending = 0; entry.host.style.visibility = ''; }
            };
            node.addEventListener('load', done, { once: true });
            node.addEventListener('error', done, { once: true });
          }
        }
        if (isStyle && node.textContent !== css) node.textContent = css;
        return { node, src };
      });
      if (same && entry.sheets.every((n, i) => n.node === old[i].node)) return;
      old.forEach((o) => { if (!entry.sheets.some((n) => n.node === o.node)) o.node.remove(); });
      entry.sheets.forEach((n) => sr.insertBefore(n.node, entry.chain[0][0]));
    }

    /** CSS text for a sheet the thumb gets as a <style>, or null when it
     *  gets a copy of the <link>. :root matches only the document root, so
     *  it is pointed at the copied <html> (a class, same specificity). That
     *  needs the rules as text: always possible for an inline <style>, and
     *  for a linked sheet only where cssRules is readable (not file://).
     *  Unreadable, a linked `:root { --x }` still works by inheritance;
     *  `:root.dark .x` and non-custom properties under :root do not.
     *  Cached per sheet until the next tweakchange. */
    _thumbCss(sh) {
      const cache = this._thumbCssCache || (this._thumbCssCache = new WeakMap());
      if (cache.has(sh)) return cache.get(sh);
      const link = sh.ownerNode.localName !== 'style';
      let css = link ? null : '';
      try {
        css = Array.from(sh.cssRules, (r) => r.cssText).join('\n');
        if (link && !/:root\b/.test(css)) css = null;
      } catch (e) {}
      if (css) {
        css = css.replace(/:root\b/g, '.deck-thumb-root');
        // cssText keeps url() as written, relative to the sheet's own file.
        if (link) {
          css = css.replace(/url\((["']?)([^"')]+)\1\)/g, (m, q, u) => {
            if (/^(#|data:)/.test(u)) return m;
            try { return 'url("' + new URL(u, sh.href) + '")'; } catch (e) { return m; }
          });
        }
      }
      cache.set(sh, css);
      return css;
    }

    _syncThumbShell(entry) {
      const stage = this.stage;
      const de = document.documentElement;
      this._syncThumbSheets(entry);
      // Start from browser defaults, as <html> does, not from the rail's
      // own text styles, then take what the real <html> ended up with
      // (covers `:root { color }` in a sheet _thumbCss could not read).
      // line-height is left out: it reads back in px, not as a multiplier.
      const cs = getComputedStyle(de);
      entry.host.style.cssText = 'all:initial;position:absolute;inset:0;display:block;' +
        'color:' + cs.color + ';font-family:' + cs.fontFamily + ';font-size:' + cs.fontSize +
        ';font-weight:' + cs.fontWeight + ';font-style:' + cs.fontStyle +
        ';letter-spacing:' + cs.letterSpacing + ';text-align:' + cs.textAlign +
        ';direction:' + cs.direction + ';color-scheme:' + cs.colorScheme + ';' +
        (entry.pending ? 'visibility:hidden;' : '');
      // The real element also takes color and font-family from the
      // stage's own :host rule, which the inert copy does not have.
      const own = getComputedStyle(stage);
      entry.chain.forEach(([el, src]) => {
        for (let i = el.attributes.length - 1; i >= 0; i--) el.removeAttribute(el.attributes[i].name);
        for (const a of src.attributes) el.setAttribute(a.name, a.value);
        if (src === de) el.classList.add('deck-thumb-root');
        el.style.setProperty('display', 'contents', 'important');
        if (src === stage) {
          el.style.color = own.color;
          el.style.fontFamily = own.fontFamily;
        }
      });
    }

    _buildThumbShell(entry, clone) {
      const stage = this.stage;
      const host = document.createElement('div');
      const sr = host.attachShadow({ mode: 'open' });
      try { sr.adoptedStyleSheets = document.adoptedStyleSheets; } catch (e) {}
      // Ancestor chain, outermost first.
      const srcs = [];
      for (let n = stage; n; n = n.parentElement) srcs.unshift(n);
      entry.chain = [];
      let parent = sr;
      srcs.forEach((src) => {
        let el;
        if (src === stage) {
          SHELL = true;
          try { el = document.createElement(stage.localName); } finally { SHELL = false; }
        } else {
          el = document.createElement(src.localName.includes('-') ? 'div' : src.localName);
        }
        entry.chain.push([el, src]);
        parent.appendChild(el);
        parent = el;
      });
      parent.appendChild(clone);
      entry.host = host;
      this._syncThumbShell(entry);
      entry.frame.appendChild(host);
    }

    /** Lazily build the clone for a thumb that has scrolled into view. */
    _materialize(entry, refresh) {
      if (entry.host && !refresh) return;
      const dw = this.stage.designWidth, dh = this.stage.designHeight;
      let clone = entry.slide.cloneNode(true);
      clone.removeAttribute('id');
      clone.removeAttribute('data-deck-active');
      clone.querySelectorAll('[id]').forEach((el) => el.removeAttribute('id'));
      // Neuter heavy media; replace <video> with its poster so the box
      // keeps a visual. <iframe>/<audio> become empty placeholders.
      clone.querySelectorAll('iframe, audio, object, embed').forEach((el) => {
        el.removeAttribute('src');
        el.removeAttribute('srcdoc');
        el.removeAttribute('data');
        el.innerHTML = '';
      });
      clone.querySelectorAll('video').forEach((el) => {
        if (!el.poster) { el.removeAttribute('src'); el.innerHTML = ''; return; }
        const img = document.createElement('img');
        img.src = el.poster;
        img.alt = '';
        img.style.cssText = el.style.cssText + ';object-fit:cover;width:100%;height:100%;';
        img.className = el.className;
        el.replaceWith(img);
      });
      // Images: defer decode and let the browser pick the smallest
      // srcset candidate for the ~140px thumb. Same-URL clones reuse the
      // slide's decoded bitmap (URL-keyed cache), so the remaining cost
      // is paint/composite, lazy+async keeps that off the main thread.
      clone.querySelectorAll('img').forEach((el) => {
        el.loading = 'lazy';
        el.decoding = 'async';
        if (el.srcset) el.sizes = (this.rail.px || 188) + 'px';
      });
      // Custom elements inside the slide would have their
      // connectedCallback fire when the clone is appended. Replace them
      // with inert boxes so a component-heavy deck doesn't run N copies
      // of each component's mount logic in the rail. Children are
      // preserved so layout-wrapper elements (<my-column><h2>…</h2>)
      // still show their authored content; the querySelectorAll NodeList
      // is static, so nested custom elements in the moved subtree are
      // still visited on later iterations.
      const neuter = (el) => {
        const box = document.createElement('div');
        box.style.cssText = (el.getAttribute('style') || '') +
          ';background:rgba(0,0,0,0.06);border:1px dashed rgba(0,0,0,0.15);';
        box.className = el.className;
        // Preserve theming/i18n hooks so [data-*] / :lang() / [dir]
        // descendant selectors still match the neutered root.
        for (const a of el.attributes) {
          const n = a.name;
          if (n.startsWith('data-') || n.startsWith('aria-') ||
              n === 'lang' || n === 'dir' || n === 'role' || n === 'title') {
            box.setAttribute(n, a.value);
          }
        }
        while (el.firstChild) box.appendChild(el.firstChild);
        return box;
      };
      // querySelectorAll('*') returns descendants only, a custom-element
      // slide root (<my-slide>…</my-slide>) would slip through and upgrade
      // on append. Swap the root first.
      if (clone.tagName.includes('-')) clone = neuter(clone);
      clone.querySelectorAll('*').forEach((el) => {
        if (el.tagName.includes('-')) el.replaceWith(neuter(el));
      });
      clone.style.cssText += ';position:absolute;top:0;left:0;transform-origin:0 0;' +
        'pointer-events:none;width:' + dw + 'px;height:' + dh + 'px;' +
        'box-sizing:border-box;overflow:hidden;visibility:visible;opacity:1;';
      // Same :root rewrite for <style> blocks authored inside the slide.
      clone.querySelectorAll('style').forEach((st) => {
        st.textContent = st.textContent.replace(/:root\b/g, '.deck-thumb-root');
      });
      // A refresh swaps only the clone, so the shell and its loaded
      // sheets stay and the thumb does not flash.
      if (entry.host) entry.clone.replaceWith(clone);
      else this._buildThumbShell(entry, clone);
      entry.clone = clone;
      if (this.rail.thumbScale) clone.style.transform = 'scale(' + this.rail.thumbScale + ')';
      // Once materialized the IO callback is a no-op early-return ,
      // unobserve so scroll doesn't keep firing it.
      this._railObserver.unobserve(entry.frame);
    }

    /** Re-clone a single thumb (live-update path). No-op if the thumb
     *  hasn't been materialized yet, it'll pick up current content when
     *  it scrolls into view. */
    _refresh(slide) {
      const entry = (this.rail.thumbs || []).find((t) => t.slide === slide);
      if (!entry || !entry.host) return;
      this._materialize(entry, true);
    }
  }

  window.DeckThumbs = DeckThumbs;
})();
