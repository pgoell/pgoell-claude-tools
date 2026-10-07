---
name: tune
description: "Use when the user wants to reconfigure their personal newspaper through a short interview, for example \"tune my newspaper\", \"change the sections\", \"try another design\", \"which designs are there\", or \"/news:tune\". Walks through sections, depth, sources, interests, and design one question at a time, rewrites the vault config, shows the diff, and can re-render today's edition with another design for comparison. Not for one quick change (use news:feedback) or for building an edition (use news:edition)."
---

# Tune

Reconfigure the newspaper by interview. Every answer becomes a config change
under the rules in `../edition/references/feedback-rules.md`; read it first.

## Arguments

`/news:tune [topic] [--vault PATH] [--periodic FOLDER]`

`topic` narrows the interview to one of `sections`, `sources`, `depth`,
`interests`, `design`. Vault and periodic folder resolve as in the edition
skill. Below, `NP` is `<vault>/<periodic>/05 Newspaper`.

## Protocol

1. **Seed and snapshot.**
   `uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/seed.py" --vault "<vault>" --periodic "<periodic>"`, then
   `mkdir -p /tmp/news-tune && cp "NP/config/topics.yaml" "NP/config/design.yaml" /tmp/news-tune/`.
2. **Show the current shape** in a compact table: each section with depth,
   `max_stories`, `freshness_days`, query count and source names; then
   `interests`, `avoid`, the design, title and tagline. Add what the last two
   weeks of memory show (`uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/recent.py" --vault "<vault>" --days 14`):
   stories per section, and sections that often came up empty.
3. **Interview**, one question per message, multiple choice where it fits,
   in this order, skipping what `topic` excludes, until the user says done:
   1. Sections: keep, drop, rename, reorder, add (a new one needs a name,
      queries and, if known, sources).
   2. Depth and length per section (1 briefs, 2 short, 3 full) and
      `max_stories`.
   3. Sources: per section, which to add or drop; offer what the empty
      sections suggest.
   4. Freshness: how old a story may be per section.
   5. Interests and avoid lists.
   6. Design: list the installed designs (`ls "${CLAUDE_SKILL_DIR}/../edition/designs/"`,
      folders holding a `template.html.j2`), then title, tagline and colour
      or font overrides.
4. **Write the config** with the smallest edits that carry the answers, keep
   comments and order, and check the YAML parses. Add one changelog line per
   change to `NP/memory/changelog.md`.
5. **Show the diff**:
   `diff -u /tmp/news-tune/topics.yaml "NP/config/topics.yaml"; diff -u /tmp/news-tune/design.yaml "NP/config/design.yaml"`.
6. **Offer a design comparison** when today's edition exists (`NP/<today>.json`):
   for each design the user wants to see,
   `uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/render.py" --vault "<vault>" --periodic "<periodic>" --design <name> --out "NP/<today>.<name>.html"`,
   and give the wikilink `[[<periodic>/05 Newspaper/<today>.<name>.html]]` to open in kasten.
   These copies do not count as editions. When the user picks one, set
   `design:` in design.yaml, re-render the edition itself
   (`uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/render.py" --vault "<vault>" --periodic "<periodic>"`),
   and delete the comparison copies after asking.

## Self-Healing

- **A design is missing**: render.py falls back to `plain` with a warning. Say
  which designs are installed; do not write `design:` to a name that is not.
- **YAML breaks**: restore from `/tmp/news-tune/` and redo the edit.
- **The user wants to start over**: copy the defaults from
  `${CLAUDE_SKILL_DIR}/../edition/references/defaults/` over the config, after
  showing the diff and asking.
