# Designs

Each design is a folder holding `template.html.j2`, a Jinja2 template rendered
with one variable, `edition` (contract in `../references/edition-contract.md`),
plus a `preview.html` rendered from a sample edition. `config/design.yaml` in
the vault names the design by its folder name; `render.py --design NAME`
overrides it for one render.

| Design        | State                                                       |
| ------------- | ----------------------------------------------------------- |
| `plain`       | Fallback. Used when the configured design is not installed. |
| `broadsheet`  | Planned                                                     |
| `magazine`    | Planned                                                     |
| `swiss`       | Planned                                                     |
| `briefing`    | Planned (the seeded default)                                |
| `heimatblatt` | Planned                                                     |

A design must:

- set every story's anchor `id` to `story.id` and show the id small and muted,
  so the reader can write "more like #id" in the feedback note;
- show source, language, published time and the link to the original;
- mark follow-ups: the `update_note` and links to earlier coverage;
- show `feedback_hint`, `recent_feedback` when set, and a link to `previous`;
- declare its colours and fonts as custom properties on `:root` (`--paper`,
  `--ink`, `--accent`, `--muted`, `--rule`, `--font-head`, `--font-body`) and
  end its CSS with the overrides hook:
  `{% if edition.design_overrides %}<style>:root{ {% for k,v in edition.design_overrides.items() %}--{{k}}:{{v}};{% endfor %} }</style>{% endif %}`;
- work in kasten's HTML pane: one self-contained file, inline CSS, no fetch,
  light and dark through `prefers-color-scheme`, no horizontal scroll at phone
  width with a 16px gutter.
