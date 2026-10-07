# Feedback rules

How a feedback item becomes a config change. The `edition`, `feedback` and
`tune` skills all follow these rules, so the three channels change config the
same way.

## Where things live

All paths sit under `<vault>/<periodic>/05 Newspaper/`:

- `feedback.md`: the reader's note. Items under `## Open` wait; items under
  `## Applied` are done.
- `config/topics.yaml`: sections, queries, sources, depth, `max_stories`,
  `freshness_days`, `exclude`, `interests`, `avoid`, `blocked_sources`.
- `config/design.yaml`: `design`, `title`, `tagline`, `overrides`.
- `memory/changelog.md`: one line per applied change.
- `memory/stories.jsonl`: what ran. Look up a story id here (`recent.py` or a
  plain search for `"id": "<id>"`) to see what "more like #id" points at.

## From item to change

| The reader says                     | Change                                                                                                      |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| more like #id                       | add the story's main entities or theme to `interests`; raise its section's `max_stories` by 1 if it was cut |
| less like #id, not interested in X  | add the theme to `avoid`, or to that section's `exclude` when it is section-specific                        |
| add a place, company, person, topic | add queries to the closest section; a new beat gets a new section only when the reader asks for one         |
| source X is paywalled, broken, bad  | remove it from `sources` or move its domain to `blocked_sources`; note a free alternative if known          |
| use source X                        | add it to that section's `sources` with a one-line `notes`                                                  |
| shorter, longer, more detail        | change that section's `depth` (1 briefs, 2 short, 3 full) or `max_stories`                                  |
| older news is fine, only today      | change that section's `freshness_days`                                                                      |
| look, colours, fonts, design        | `design.yaml` (`design`, or `overrides` tokens such as `accent`, `font-body`)                               |

Make the smallest change that does what the reader asked. Never delete a
section, a source or an interest the item did not name.

## Recording it

For each applied item:

1. Edit the YAML, keeping its comments and order.
2. Move the bullet from `## Open` to the top of `## Applied` as
   `- YYYY-MM-DD: <the reader's words> -> <what changed>`.
3. Append `- YYYY-MM-DD: <what changed> (<the reader's words, short>)` to
   `memory/changelog.md`. The edition footer shows the three newest lines.

An item you cannot read with confidence stays under `## Open`, with an
indented sub-bullet `- Frage: <one question>` (or `Question:` when the item is
in English). Do not guess. An item that already has your question and an
answer under it is now clear: apply it.

The YAML must still parse after the edit:
`uv run --with pyyaml python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' <file>`.
