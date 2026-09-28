# Time Budget

Slides-per-minute heuristics by genre, recommended slide-count bands for common talk lengths, word budgets by deck mode, and speaker-notes sizing. This file is consulted in Phase 1 (intake captures genre, duration, and deck mode), in Phase 4 (word budgets and notes sizing), and in Phase 5 (Check E asserts the slide count is within the band; the copy lint checks the word budget).

## Slides per minute by genre

| Genre              | Typical minutes per slide | Notes                                            |
| ------------------ | ------------------------- | ------------------------------------------------ |
| Keynote            | 1.5 to 2                  | Sparse, story-driven; long pauses between slides |
| Executive briefing | 2 to 3                    | Per-slide depth; few slides, dense argument      |
| Training           | 1 to 2                    | Progressive reveals; staged complexity           |
| Pitch              | 1                         | Tight rhythm; one message per slide; brisk pace  |
| Technical talk     | 2 to 3                    | Code, diagrams, walkthroughs need think time     |

## Recommended slide-count bands by genre and duration

| Genre              | 5 min  | 10 min  | 15 min   | 20 min   | 30 min   | 45 min   | 60 min   |
| ------------------ | ------ | ------- | -------- | -------- | -------- | -------- | -------- |
| Keynote            | 3 to 4 | 6 to 8  | 9 to 12  | 12 to 16 | 18 to 24 | 25 to 35 | 30 to 45 |
| Executive briefing | 2 to 3 | 4 to 6  | 6 to 9   | 8 to 12  | 12 to 18 | 18 to 25 | 24 to 32 |
| Training           | 4 to 6 | 8 to 12 | 12 to 18 | 16 to 24 | 24 to 36 | 36 to 50 | 50 to 70 |
| Pitch              | 4 to 6 | 8 to 12 | 12 to 18 | 16 to 24 | n/a      | n/a      | n/a      |
| Technical talk     | 2 to 3 | 4 to 6  | 6 to 9   | 8 to 12  | 12 to 18 | 18 to 25 | 24 to 32 |

Pitch durations beyond 20 minutes are uncommon; if requested, treat as a hybrid pitch and briefing and use the executive-briefing band for the longer end.

## Word budgets by deck mode

Deck mode is captured at intake and written to the `deck_mode` key in the `deck.md` header (see `slide-brief-template.md`). It sets how much text a slide carries and how full the speaker notes are. The copy lint (`presentations:creating-presentations`, `references/copy-lint.md`) checks the budget.

| Deck mode   | Use                                              | Words per slide (on screen, excluding source line) | Headline form                        | Speaker notes         |
| ----------- | ------------------------------------------------ | -------------------------------------------------- | ------------------------------------ | --------------------- |
| `presented` | Spoken to a room or call; the speaker carries it | about 20                                           | Full-sentence action title           | Cues                  |
| `keynote`   | Large stage, story-led                           | fewer than 20; often only the headline             | Short claim title, still with a verb | Cues                  |
| `briefing`  | Walked through at a table, then left behind      | up to 50                                           | Full-sentence action title           | Cues                  |
| `reading`   | Sent ahead or forwarded; read without a speaker  | 75 to 200                                          | Full-sentence action title           | Optional fuller prose |

A slide over budget splits into two slides or moves detail to the notes or the Appendix; the text never shrinks to fit. A `reading` deck has no talk time, so the slide-count bands below do not apply to it; size it by the pyramid (one slide per reason or piece of evidence).

## Speaker-notes sizing

Speech runs at about 130 words a minute. Multiply the minutes planned for a slide (from the slides-per-minute table above) by 130 to get the most a speaker can say on it. Cue notes should prompt no more speech than that; prose notes in a `reading` deck should not exceed it either. A slide whose notes need more is doing two slides' work: split it.

## How Phase 5 uses the bands

Check E in `audit-checklist.md` compares the actual slide count in `deck.md` against the band lookup for the deck's genre and duration. If the count falls inside the band, the check passes. If the count falls outside the band and the user has deliberately overridden the default (for example, a 30-minute training deck that intentionally runs to 80 slides because of dense progressive reveals), the override is recorded under "User overrides" in `audit-report.md` and the check is marked as passed-with-override rather than failed.

## Adjustments and caveats

Appendix slides do not count toward the body band. If a deck has ten body slides plus four appendix slides, the band check uses ten, not fourteen. Training decks with progressive reveals (where a single conceptual slide is split into three or four reveal stages for pacing) may exceed the body band by the planned reveal count; record the reveal stages in `deck.md` so the audit can subtract them before checking the band.

The bands are starting points calibrated to the slides-per-minute table above. They are not laws. A keynote speaker with a very visual storytelling style might use twice as many slides as the band suggests because each slide is on screen for only seconds; an executive briefing presenter who walks the audience through a complex spreadsheet might use half as many because each slide is on screen for five minutes. Use the bands to challenge the deck, not to enforce a count.
