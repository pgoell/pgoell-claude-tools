import fs from 'node:fs';

// Brand theme bridge (added by the pgoell-claude-tools diagrams plugin).
// Reads a theme.css that follows plugins/diagrams/themes/README.md (two
// [data-theme="light"|"dark"] blocks) and returns a <style> element that
// overrides the viewer palette in every preset. Fills and viewer-only tokens
// the contract leaves optional are computed here as concrete rgba() values,
// so exported SVG and PNG files carry real colors.

const TYPES = ['frontend', 'backend', 'database', 'cloud', 'security', 'messagebus', 'external'];
const REQUIRED = [
  '--bg', '--grid', '--panel', '--panel-border', '--text', '--text-muted', '--text-dim',
  '--mask', '--arrow', '--arrow-emphasis', '--font-diagram',
  ...TYPES.map((type) => `--${type}-stroke`),
];

function parseBlocks(css) {
  const blocks = {};
  const source = css.replace(/\/\*[\s\S]*?\*\//g, '');
  for (const match of source.matchAll(/\[data-theme="(light|dark)"\]\s*\{([^}]*)\}/g)) {
    const vars = {};
    for (const decl of match[2].matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)) vars[decl[1]] = decl[2].trim();
    blocks[match[1]] = vars;
  }
  return blocks;
}

function rgbOf(value) {
  const hex = /^#([0-9a-f]{6})$/i.exec(value || '');
  if (hex) {
    const n = parseInt(hex[1], 16);
    return [n >> 16, (n >> 8) & 255, n & 255];
  }
  const fn = /^rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)/i.exec(value || '');
  return fn ? [Number(fn[1]), Number(fn[2]), Number(fn[3])] : null;
}

function withAlpha(value, alpha, name) {
  const rgb = rgbOf(value);
  if (!rgb) throw new Error(`Brand theme: ${name} must be #rrggbb or rgb()/rgba() to derive fills, got ${JSON.stringify(value)}.`);
  return `rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, ${alpha})`;
}

function complete(vars, mode, file) {
  const missing = REQUIRED.filter((name) => !vars[name]);
  if (missing.length) throw new Error(`Brand theme ${file}: [data-theme="${mode}"] is missing ${missing.join(', ')}.`);
  const out = { ...vars };
  const strength = parseFloat(vars['--fill-strength'] || (mode === 'dark' ? '30' : '16')) / 100;
  delete out['--fill-strength'];
  for (const type of TYPES) {
    out[`--${type}-fill`] ??= withAlpha(vars[`--${type}-stroke`], strength, `--${type}-stroke`);
  }
  out['--region-fill'] ??= withAlpha(vars['--cloud-stroke'], 0.05, '--cloud-stroke');
  out['--lane-fill'] ??= withAlpha(vars['--text'], 0.03, '--text');
  out['--lane-stroke'] ??= vars['--panel-border'];
  out['--text-faint'] ??= vars['--text-muted'];
  out['--toolbar-bg'] ??= vars['--panel'];
  out['--toolbar-border'] ??= vars['--panel-border'];
  out['--toolbar-text'] ??= vars['--text'];
  out['--toolbar-hover'] ??= vars['--mask'];
  out['--toolbar-menu-bg'] ??= vars['--mask'];
  return out;
}

export function brandThemeStyle(themePath) {
  if (!themePath) return '';
  const file = fs.statSync(themePath).isDirectory() ? `${themePath}/theme.css` : themePath;
  const blocks = parseBlocks(fs.readFileSync(file, 'utf8'));
  const rules = ['light', 'dark'].map((mode) => {
    if (!blocks[mode]) throw new Error(`Brand theme ${file}: no [data-theme="${mode}"] block.`);
    const body = Object.entries(complete(blocks[mode], mode, file))
      .map(([name, value]) => `      ${name}: ${value};`).join('\n');
    // [data-preset] lifts specificity above the built-in preset palettes and
    // also matches the off-DOM probe the export code uses to resolve tokens.
    return `    [data-theme="${mode}"][data-preset] {\n${body}\n    }`;
  });
  return `  <style id="archify-brand-theme">\n${rules.join('\n')}\n  </style>\n`;
}
