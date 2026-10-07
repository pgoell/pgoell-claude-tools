---
name: feedback
description: "Use when the user gives feedback on their personal newspaper and wants it applied now, for example \"less Polizeibericht\", \"more like #2026-10-07-evals-02\", \"GNZ is paywalled, drop it\", \"add Bruchköbel to the local section\", or \"/news:feedback shorter Deloitte stories\". Turns the free text into config changes in the vault, records them in the feedback note and changelog, and shows the config diff. Not for building an edition (use news:edition) or for a full reconfiguration interview (use news:tune)."
---

# Feedback

Apply one piece of newspaper feedback now instead of waiting for the next
edition to read it from the feedback note. The same rules govern all three
feedback channels, so read `../edition/references/feedback-rules.md` before
changing anything.

## Arguments

`/news:feedback "<text>" [--vault PATH] [--periodic FOLDER]`

Vault and periodic folder resolve as in the edition skill: the flag, else
`$KASTEN_VAULT` and `$KASTEN_PERIODIC_PATH`, else the working directory when it
holds the periodic folder, else ask. Below, `NP` is
`<vault>/<periodic>/05 Newspaper`. With no text, apply every item under
`## Open` in `NP/feedback.md` instead.

## Protocol

1. **Seed** so the config exists:
   `uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/seed.py" --vault "<vault>" --periodic "<periodic>"`.
2. **Snapshot** the config to diff against later:
   `mkdir -p /tmp/news-feedback && cp "NP/config/topics.yaml" "NP/config/design.yaml" /tmp/news-feedback/`.
3. **Resolve story ids.** For each `#<id>` in the text, find what it points
   at: `grep -F '"id": "<id>"' "NP/memory/stories.jsonl"`. Use its section,
   entities and key facts to read the item.
4. **Read the item** with the table in `feedback-rules.md`. When it can mean
   two different changes, ask the user one question with the options, then
   continue. This skill is interactive, so nothing stays under `## Open`.
5. **Change the config**: the smallest edit that does what was asked, comments
   and order kept. Check the YAML still parses.
6. **Record it**: a bullet at the top of `## Applied` in `NP/feedback.md`
   (removing the item from `## Open` if it came from there), and a line at the
   end of `NP/memory/changelog.md`, both in the formats `feedback-rules.md`
   gives.
7. **Show the diff**:
   `diff -u /tmp/news-feedback/topics.yaml "NP/config/topics.yaml"; diff -u /tmp/news-feedback/design.yaml "NP/config/design.yaml"`.
   Then say in one line when it takes effect: the next edition, or now if the
   user re-runs `/news:edition` for today.

## Self-Healing

- **No newspaper folder yet**: step 1 creates it; say that the config is the
  seeded default.
- **Story id not in memory**: the id is mistyped or older than memory. Show the
  three closest ids from `recent.py` (`uv run "${CLAUDE_SKILL_DIR}/../edition/scripts/recent.py" --vault "<vault>" --days 60`)
  and ask which one.
- **YAML breaks**: restore from the snapshot in `/tmp/news-feedback/` and redo
  the edit.
