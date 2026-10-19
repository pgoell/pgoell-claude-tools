# Copy Probe

The in-page probe for hard gate H8. It runs the rules and the tell scanner that `copy-lint.md` defines; read that file for what each rule ID means and which ones fail the gate.

Evaluate in the page after the geometry probe, with `noscale` set. Set `MODE` from `deck.md`. Returns hard failures in `issues` (gate H8) and warnings in `forJudges`.

```js
(() => {
  const MODE = 'presented'; // presented | keynote | briefing | reading
  const BUDGET = { presented: 20, keynote: 20, briefing: 50, reading: 200 }[MODE];
  const W = (s) => new RegExp(`\\b(?:${s})\\b`, 'i');
  const TOPIC_LABELS = /^(?:an? |the |our |key )?(?:overview|background|introduction|context|agenda|summary|executive summary|key takeaways|takeaways|next steps|conclusions?|results|findings|analysis|recommendations?|approach|methodology|market overview|market sizing|cost savings|financials|timeline|roadmap|team|about us|q&a|questions|discussion|appendix|objectives|goals|challenges|opportunities|benefits|risks|status update|update|why now|the problem|the solution|what we'll cover|what we will cover)(?: (?:overview|summary|update|analysis))?$/i;
  const COUNT = /^(?:the |our )?(?:two|three|four|five|six|seven|eight|nine|ten|\d+) (?:[\w-]+ ){0,2}(?:reasons|risks|ways|things|steps|pillars|priorities|considerations|takeaways|drivers|themes|areas|options|lessons|trends|challenges|questions|factors|principles|levers|opportunities|benefits|capabilities)\b/i;
  const HEDGES = W('may|might|could|can help|potentially|possibly|arguably|seems? to|appears? to|is important|are important|should consider');
  const BUZZWORDS = { 'leverag\\w*': 'use', 'empower\\w*': 'let, allow', 'streamlin\\w*': 'simplify', 'synerg\\w*': 'say what combines', 'unlock\\w*': 'say what becomes possible', 'elevat\\w*': 'improve, raise', 'seamless\\w*': 'drop it', 'transformative': 'say what changes', 'paradigm\\w*': 'model, approach', 'holistic\\w*': 'complete, whole', 'cutting-edge': 'new, name it', 'best-in-class|world-class': 'show the comparison', 'next-gen\\w*': 'new, name it', 'facilitat\\w*': 'say what you do', 'utili[sz]\\w*': 'use', 'going forward|moving forward': 'from now on', 'one-stop shop': 'single place', 'deep dive': 'look at, study', 'harness\\w*': 'use', 'actionable': 'drop it or say the action', 'impactful': 'say the effect', 'move the needle': 'say by how much', 'low-hanging fruit': 'quick wins, name them', 'north star': 'goal', 'robust': 'say what holds up' };
  const AI_VOCAB = W('underscor\\w*|showcas\\w*|pivotal|crucial|intricat\\w*|meticulous\\w*|vibrant|realm|boasts?|garner\\w*|bolster\\w*|enhanc\\w*|foster\\w*|aligns? with|interplay|enduring|groundbreaking|embark\\w*|navigat\\w* the|evolving landscape|plays? an? (?:key|crucial|pivotal|vital) role|setting the stage|the future looks bright|exciting times ahead|a step in the right direction');
  const P0_VOCAB = W("delv\\w*|tapestr\\w*|testament|ever-evolving|in today's (?:fast-paced|digital|rapidly)\\w*|unlock(?:s|ing)? the (?:full )?(?:power|potential)|game-chang\\w*");
  const VAGUE = W('(?:experts|analysts|observers|studies|research|industry reports?|many (?:companies|leaders|organi[sz]ations)|some (?:critics|people)) (?:say|says|argue|suggest|show|shows|agree|believe|indicate|have (?:cited|noted|shown))');
  const PATTERNS = {
    P1: /\bnot (?:just |only |merely |simply )?[^.;!?]{1,60}?,? but\b|\b(?:it'?s|this is|that'?s) not [^.;!?]{1,60}?[,;.] (?:it'?s|this is|that'?s)\b|\brather than\b/i,
    P2: /,\s*(?:not|no|never|without)\s+[^,.;!?]{1,30}[.!]?\s*$/i,
    P3: /\b(?:serves|stands|acts|functions) as\b|\bis a testament\b|\bmarks? an? (?:pivotal|turning|key)\b/i,
    P4: /,\s+(?:highlighting|underscoring|emphasi[sz]ing|showcasing|ensuring|reflecting|enabling|driving|fostering|paving|cementing|signal+ing|demonstrating|making)\b[^.;!?]*[.]?\s*$/i,
    P5: /\b[\w-]+, [\w-]+,? and [\w-]+\b|\b(\w+)\b[^.!?]{0,60}[.!?]\s+\1\b[^.!?]{0,60}[.!?]\s+\1\b/i,
  };
  const STRUCTURAL = /title|cover|section|divider|agenda|quote|appendix/i;
  const stage = document.querySelector('deck-stage');
  const slides = [...stage.children].filter(el => !['TEMPLATE', 'SCRIPT', 'STYLE'].includes(el.tagName));
  let notes = {};
  try { notes = JSON.parse(document.getElementById('speaker-notes')?.textContent || '{}'); } catch (e) {}
  const issues = [], forJudges = [];
  const fail = (n, rule, what) => issues.push({ gate: 'H8', slide: n, rule, what });
  const warn = (n, rule, what) => forJudges.push({ kind: 'copy', slide: n, rule, what });
  const clip = (s) => `"${s.replace(/\s+/g, ' ').trim().slice(0, 70)}"`;
  const words = (s) => (s.match(/[\w'%$€£.,-]+/g) || []).filter(w => /\w/.test(w));
  const px = (el) => parseFloat(getComputedStyle(el).fontSize);
  const lh = (el) => { const cs = getComputedStyle(el); return cs.lineHeight === 'normal' ? 1.2 * parseFloat(cs.fontSize) : parseFloat(cs.lineHeight); };
  const lines = (el) => Math.max(1, Math.round(el.getBoundingClientRect().height / lh(el)));
  const blockOf = (el) => { for (let n = el; n; n = n.parentElement) if (getComputedStyle(n).display !== 'inline') return n; return el; };
  const isFooter = (el) => !!el.closest('footer, .footer, .source, .slide-number, [data-role="footer"], [data-role="source"]');
  const upper = (el, text) => getComputedStyle(el).textTransform === 'uppercase' || (text === text.toUpperCase() && /[A-Z]/.test(text));
  const textRules = (n, text, where) => {
    Object.entries(BUZZWORDS).forEach(([re, hint]) => { const m = text.match(W(re)); if (m) warn(n, 'V1', `${where}: "${m[0]}" (try: ${hint})`); });
    let m;
    if ((m = text.match(AI_VOCAB))) warn(n, 'V2', `${where}: "${m[0]}"`);
    if ((m = text.match(P0_VOCAB))) fail(n, 'K5', `${where}: "${m[0]}"`);
    if ((m = text.match(VAGUE))) warn(n, 'V3', `${where}: "${m[0]}"; name the source`);
    if (/[\u2014\u2013\u00B7]/.test(text)) fail(n, /\u00B7/.test(text) ? 'K4' : 'C1', `${where}: banned character in ${clip(text)}`);
    text.split(/(?<=[.!?])\s+|\n+/).forEach(sentence => {
      Object.entries(PATTERNS).forEach(([id, re]) => { if (re.test(sentence)) warn(n, id, `${where}: ${clip(sentence)}`); });
      if (words(sentence).length > 25) warn(n, 'W2', `${where}: ${words(sentence).length}-word sentence ${clip(sentence)}`);
    });
    if (PATTERNS.P5.test(text) && !text.split(/(?<=[.!?])\s+/).some(s => PATTERNS.P5.test(s))) warn(n, 'P5', `${where}: repeated opener across sentences ${clip(text)}`);
  };
  const eyebrowSlides = [];
  let contentSlides = 0;
  slides.forEach((slide, i) => {
    const n = i + 1;
    const label = slide.dataset.screenLabel || '';
    const structural = STRUCTURAL.test(label);
    const blocks = new Set();
    const walk = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
    while (walk.nextNode()) {
      const t = walk.currentNode, el = t.parentElement;
      if (!t.textContent.trim() || el.closest('script, style, template, [aria-hidden="true"]')) continue;
      blocks.add(blockOf(el));
    }
    const all = [...blocks].filter(b => b.getBoundingClientRect().width > 0);
    const body = all.filter(b => !isFooter(b));
    if (!body.length) return;
    const heads = body.filter(b => /^H[1-3]$/.test(b.tagName) || b.dataset.role === 'title');
    const title = (heads.length ? heads : body).reduce((a, b) => (px(b) > px(a) ? b : a));
    const titleText = title.textContent.replace(/\s+/g, ' ').trim();
    // Title rules
    if (!structural) {
      contentSlides++;
      const tw = words(titleText).length, tl = lines(title);
      if (tw > 15 || tl > 2) fail(n, 'T1', `title ${tw} words, ${tl} lines: ${clip(titleText)}`);
      const bare = titleText.replace(/[.:!?]+$/, '');
      if (TOPIC_LABELS.test(bare)) fail(n, 'T2', `topic label in the title position: ${clip(titleText)}`);
      else if (tw <= 3 && !/\d/.test(titleText)) warn(n, 'T7', `possible topic label: ${clip(titleText)}`);
      if (COUNT.test(bare)) (tw <= 8 ? fail : warn)(n, 'T3', `count-only title: ${clip(titleText)}`);
      if (HEDGES.test(titleText)) warn(n, 'T4', `hedge in title: ${clip(titleText)}`);
      const halves = titleText.split(/;|,? (?:and|while|whereas) /i);
      if (titleText.includes(';') || (halves.length > 1 && halves.every(h => words(h).length >= 5))) warn(n, 'T5', `two claims? ${clip(titleText)}`);
      if (MODE === 'keynote' && tw > 8) warn(n, 'T8', `keynote title over 8 words: ${clip(titleText)}`);
      // K1 eyebrow: small uppercase block sitting above the title
      const tr = title.getBoundingClientRect();
      if (body.some(b => b !== title && !b.contains(title) && b.getBoundingClientRect().bottom <= tr.top + 4 && px(b) < 0.6 * px(title) && upper(b, b.textContent.trim()))) eyebrowSlides.push(n);
      // K2 accent word, K6 accent period
      const ts = getComputedStyle(title), full = titleText.length;
      [...title.querySelectorAll('*')].forEach(d => {
        const cs = getComputedStyle(d), dt = d.textContent.trim();
        if (!dt || dt.length >= full) return;
        if (dt === '.' && cs.color !== ts.color) warn(n, 'K6', `accent-colored period on ${clip(titleText)}`);
        else if (cs.fontStyle === 'italic' || cs.color !== ts.color || cs.fontFamily !== ts.fontFamily || cs.fontWeight !== ts.fontWeight) fail(n, 'K2', `accented "${dt}" inside title ${clip(titleText)}`);
      });
    }
    // Headings (sentence case)
    body.filter(b => /^H[1-6]$/.test(b.tagName) || b === title).forEach(h => {
      const ws = h.textContent.trim().split(/\s+/).slice(1).filter(w => w.length > 3 && /^[A-Za-z]/.test(w) && w !== w.toUpperCase());
      if (ws.length >= 3 && ws.filter(w => /^[A-Z]/.test(w)).length / ws.length >= 0.75) warn(n, 'T6', `title case: ${clip(h.textContent)}`);
    });
    // Word budget
    const bodyText = body.map(b => b.innerText || b.textContent).join('\n');
    const count = words(bodyText).length;
    if (!structural && count > BUDGET) warn(n, 'W1', `${count} words > ${BUDGET} (${MODE})`);
    textRules(n, bodyText, 'slide');
    if (notes[n]) textRules(n, String(notes[n]), 'notes');
    // Formatting
    body.forEach(b => {
      const t = b.textContent.trim(), cs = getComputedStyle(b);
      if (parseInt(cs.fontWeight) < 600 && b !== title) {
        const bold = [...b.querySelectorAll('strong, b, span')].find(s => getComputedStyle(s).display === 'inline' && parseInt(getComputedStyle(s).fontWeight) >= 600);
        if (bold) warn(n, 'F1', `bold "${bold.textContent.trim().slice(0, 40)}" inside ${clip(t)}`);
      }
      if ((cs.textTransform === 'uppercase' && words(t).length > 3) || /\b(?:[A-Z]{2,}\s+){2,}[A-Z]{2,}\b/.test(t)) warn(n, 'F2', `all-caps run ${clip(t)}`);
      if (cs.textDecorationLine.includes('underline') && !b.closest('a')) warn(n, 'F2', `underline ${clip(t)}`);
      const L = lines(b);
      if (L >= 2 && t.length / L > 80) warn(n, 'F4', `${Math.round(t.length / L)} chars per line ${clip(t)}`);
      if (cs.fontFamily.toLowerCase().includes('mono') && px(b) < 28 && !b.closest('code, pre')) warn(n, 'K7', `mono micro label ${clip(t)}`);
      if (/^0\d\b/.test(t) && !/process|timeline|agenda|step/i.test(label)) warn(n, 'K8', `sequence marker "${t.slice(0, 4)}" on a non-sequence slide`);
    });
    slide.querySelectorAll('ul, ol').forEach(list => {
      const items = [...list.children].filter(li => li.tagName === 'LI');
      if (items.length > 4 || items.length === 1) warn(n, 'F3', `list of ${items.length} items`);
      items.forEach(li => { if (lines(li) > 2) warn(n, 'F3', `list item runs ${lines(li)} lines ${clip(li.textContent)}`); });
    });
    // K3 stat-tile row
    const sizes = body.map(px).sort((a, b) => a - b), median = sizes[Math.floor(sizes.length / 2)];
    const tiles = [...slide.querySelectorAll('*')].filter(el => {
      const r = el.getBoundingClientRect();
      if (r.width < 100 || r.width > 0.45 * slide.getBoundingClientRect().width) return false;
      return [...el.querySelectorAll('*')].some(d => /^[\s\d.,%+×x$€£↑↓<>~-]*\d[\s\d.,%+×x$€£kKmMbB↑↓-]*$/.test(d.textContent.trim()) && px(d) >= 2 * median);
    }).filter((el, _, arr) => !arr.some(o => o !== el && el.contains(o)));
    const rows = {};
    tiles.forEach(el => { const r = el.getBoundingClientRect(); const k = Math.round(r.top / 8); (rows[k] = rows[k] || []).push(r); });
    Object.values(rows).forEach(rs => {
      if (rs.length < 3) return;
      const ws = rs.map(r => r.width), mx = Math.max(...ws), mn = Math.min(...ws);
      if (mn >= 0.85 * mx) fail(n, 'K3', `row of ${rs.length} stat tiles`);
    });
  });
  if (eyebrowSlides.length >= 3 && eyebrowSlides.length > contentSlides / 2) fail(eyebrowSlides[0], 'K1', `eyebrow label above the title on ${eyebrowSlides.length} of ${contentSlides} content slides: ${eyebrowSlides.join(', ')}`);
  return JSON.stringify({ issues, forJudges }, null, 2);
})();
```
