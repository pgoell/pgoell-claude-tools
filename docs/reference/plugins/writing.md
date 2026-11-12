---
type: Reference
title: The writing plugin
description: The ghostwrite and coach skills, and the voice, reader and coaching files they keep.
tags: [plugin, writing, ghostwrite, coach]
status: stable
---

# writing

Two skills with opposite rules about who writes the sentences. `ghostwrite` drafts a piece for you from your own facts; `coach` teaches you to write and never writes the piece.

**Runtimes:** Claude Code, Codex, Cursor

**Source:** vendored in `plugins/writing/`; see the [plugin README](../../../plugins/writing/README.md) for details and credits.

**Setup:** None beyond install.

## Skills

| Invocation            | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/writing:ghostwrite` | Draft a blog post, essay, talk script, memo, briefing, email, decision doc, README, how-to, design doc or PR description. Interviews you or takes dictation, uses only facts from you, your documents or the repository, marks every assumption inline, runs one review round that reports and never rewrites on its own, and hands back for your final edit. Also rewrites or reviews a draft you already have: a rewrite keeps every fact, hedge and attribution; a review reports and changes nothing. |
| `/writing:coach`      | Teach you through your own drafts. You write first; it raises one issue per round (point, then structure, then paragraphs, then sentences), explains the principle, shows a worked example on one of your sentences, has you revise and explain the change back, and logs recurring faults.                                                                                                                                                                                                               |

For slide decks use `/presentations:designing-presentations`; a talk script is a job for `/writing:ghostwrite`.

## Files the skills keep

| Path                              | Scope       | Holds                                                                              |
| --------------------------------- | ----------- | ---------------------------------------------------------------------------------- |
| `~/.pgoell/writing/voice-note.md` | Global      | Your confirmed voice habits, the standards your pieces must meet, and an edit log. |
| `~/.pgoell/writing/samples/`      | Global      | Two to five pieces you wrote yourself, if you have them.                           |
| `.pgoell/writing/readers.md`      | Per project | The readers you write for again and again.                                         |
| `.pgoell/writing/coach-log.md`    | Per project | The coach's intake, current drill, and fault log.                                  |

`ghostwrite` writes a draft to the file you name, or `<slug>.md` in the working directory; short pieces can stay in the chat.

## Comparing writing skills

`plugins/writing/judge/` holds a blind comparison you can run against any other writing skill: eleven cases and a judging protocol from Addy Osmani's [Clarity](https://github.com/addyosmani/clarity), and `compare.py`, which runs each case in a fresh session under every condition, has a second model judge the unnamed answers, and writes a report. The commands, the limits of the numbers and the last result are in the [plugin README](../../../plugins/writing/README.md).

## History and licence

Version 3.0.0 replaced the `writing`, `pyramid` and `tech-doc` skills, which now sit in the [deprecated](/reference/plugins/deprecated.md) plugin. Their pyramid audits, Diataxis quadrants, interview rules and argument critics live on as reference files inside the two skills. Version 3.2.0 added the rewrite and review routes, adapted from Clarity in this repository's own words. The plugin is MIT work; the two judge files vendored from Clarity keep their MIT licence, as the plugin's `NOTICE` records, and the README credits the sources its ideas come from.
