# Designs

Each design is a folder holding `template.html.j2`, a Jinja2 template rendered
with one variable, `edition` (contract in `../references/edition-contract.md`),
plus notes and a screenshot. `config/design.yaml` in
the vault names the design by its folder name; `render.py --design NAME`
overrides it for one render.

A template may pull in other files with `{% include %}` or `{% import %}`.
`render.py` looks for a name in the design's folder first, then in `designs/`,
so templates name every such file from `designs/` (`'heimatblatt/base.css.j2'`).
A folder counts as a design only when it holds `template.html.j2`.

- `heimatblatt/` holds the parts that `heimatblatt` and `tabbed` share:
  `macros.html.j2` (story meta, follow-ups, photo, paragraphs, the emblem) and
  the CSS in three parts, `base.css.j2` (palette, page, masthead),
  `story.css.j2` (ornament, story parts) and `layout.css.j2` (lead, sections,
  the home region). Each template adds its own CSS between and after them, so
  a change to a part shows in both designs, and `tabbed` needs the
  `heimatblatt/` folder to render.
- `tabbed/sports.html.j2` draws the tournament tree and the league tables.
- `briefing/style.css.j2` and `magazine/style.css.j2` hold each design's CSS
  below its palette; they share nothing with other designs.

| Design        | Idea                                                                                  |
| ------------- | ------------------------------------------------------------------------------------- |
| `heimatblatt` | The default. A warm Kinzig valley local paper; the `local` section framed in green.   |
| `briefing`    | A calm one-column morning brief with a sticky index and "Seit gestern" up front.      |
| `broadsheet`  | A German print front page: Fraktur masthead, columns with hairline rules.             |
| `magazine`    | A weekend supplement: full-bleed lead, big section numerals, scale set by importance. |
| `swiss`       | A Swiss modernist 12-column grid in Inter, one signal red.                            |
| `tabbed`      | The heimatblatt look, one tab per section; for editions too long to scroll.           |
| `plain`       | Fallback. Used when the configured design is not installed.                           |

Each design folder also holds `NOTES.md` (the idea, fonts, tokens, what its
designer would tune) and `shot-mobile-light.png`, the top of its sample page
at phone width.

A design must:

- set every story's anchor `id` to `story.id` and show the id small and muted,
  so the reader can write "more like #id" in the feedback note;
- show source, language, published time (`story.published_display`, already
  in Berlin time) and the link to the original;
- mark follow-ups: the `update_note` and links to earlier coverage;
- show `feedback_hint`, `recent_feedback` when set, and a link to `previous`;
- declare its colours and fonts as custom properties on `:root` (`--paper`,
  `--ink`, `--accent`, `--muted`, `--rule`, `--font-head`, `--font-body`) and
  end its CSS with the overrides hook:
  `{% if edition.design_overrides %}<style>:root{ {% for k,v in edition.design_overrides.items() %}--{{k}}:{{v}};{% endfor %} }</style>{% endif %}`;
- draw a story's optional `bracket` (a tournament tree or a Swiss stage), or leave it out: only
  `tabbed` draws one, and the other designs show the summary alone;
- work in kasten's HTML pane: render to one self-contained file, inline CSS, no fetch,
  light and dark through `prefers-color-scheme`, no horizontal scroll at phone
  width with a 16px gutter.
