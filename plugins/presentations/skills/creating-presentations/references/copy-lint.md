# Copy Lint

Deterministic checks on the words of a deck, run after generation as hard gate **H8 Copy lint** and, on the design side, against `deck.md` before any slide exists. The lists live here, not in prompts: naming a banned word in a prompt can prime it, so prompts carry the positive style contract (the active preset's `language.md`) and this file catches what slips through.

Most rules are warnings. The evidence for title rules is mostly vendor practice and no one has tested a lint rule's effect on output, so only the title length cap, the topic-label and count-only rules, banned characters, and the P0 tells fail the gate. Warnings go to `forJudges`: the clarity judge (or the default render check) weighs each one against the slide, and a warning that reads fine in context is dismissed, not fixed.

Tell lists age with each model release. Review the vocabulary lists when the model changes, and prefer structure rules, which last longer than word lists.

## Rules

Slide scope: title rules skip structural slides (a `data-screen-label` naming a title, cover, section, divider, agenda, quote, or appendix slide). The closing slide is not structural: its title names the decision and its consequence.

| ID | Rule                                                     | Detection                                                                                                                 | Result |
| -- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ------ |
| T1 | Title at most 15 words and two rendered lines            | word count; rendered lines = element height / line height                                                                 | fail   |
| T2 | Title is not a topic label                               | whole title matches the `TOPIC_LABELS` pattern (for example "Overview", "Market sizing", "Next steps")                    | fail   |
| T3 | Title is not count-only                                  | title of 8 words or fewer that opens with a count and a plural noun ("Three risks and how we cover them")                 | fail   |
| T4 | Title does not hedge                                     | `HEDGES` pattern: may, might, could, can help, potentially, possibly, is important                                        | warn   |
| T5 | One claim per title                                      | a semicolon, or "and"/"while"/"whereas" joining two sides of 5+ words each. A single claim with a qualifying "but" passes | warn   |
| T6 | Sentence case in titles and headings                     | 3+ words over 3 letters after the first, 75% or more of them capitalized                                                  | warn   |
| T7 | Possible topic label                                     | 3 words or fewer and no digit                                                                                             | warn   |
| T8 | Keynote titles are short claims                          | `deck_mode: keynote` and the title runs past 8 words (full sentence goes in the notes)                                    | warn   |
| C1 | Banned characters                                        | U+2014, U+2013, U+00B7 in rendered text or notes                                                                          | fail   |
| W1 | Words per slide within the deck-mode budget              | rendered words minus footer and source line; budget: presented 20, keynote 20, briefing 50, reading 200                   | warn   |
| W2 | Sentences of 25 words or fewer                           | split body text on `.`, `!`, `?`                                                                                          | warn   |
| V1 | No business buzzwords                                    | `BUZZWORDS` list, with plain replacements                                                                                 | warn   |
| V2 | No AI vocabulary                                         | `AI_VOCAB` list                                                                                                           | warn   |
| V3 | No vague attribution                                     | "experts say", "studies show", "industry reports suggest" and kin; name the source instead                                | warn   |
| P1 | "Not X but Y" only when X is a belief the audience holds | `not (just\|only\|merely) ... but`, "it's not X, it's Y", "rather than"                                                   | warn   |
| P2 | No clipped negative tail                                 | a clause ending ", not quarters." or ", no guessing."                                                                     | warn   |
| P3 | No copula dodges                                         | "serves as", "stands as", "acts as", "is a testament", "marks a pivotal"                                                  | warn   |
| P4 | No trailing -ing rider                                   | a clause ending ", highlighting ...", ", ensuring ...", ", enabling ..."                                                  | warn   |
| P5 | Triads for review                                        | "a, b, and c" lists, and three sentences opening with the same word ("One platform. One team. One contract.")             | warn   |
| F1 | No bold inside body copy                                 | a bold inline element (weight 600+) inside a text block that is not itself bold                                           | warn   |
| F2 | No all-caps runs or underline                            | `text-transform: uppercase` on text over 3 words, 3+ consecutive all-caps words, or underline outside a link              | warn   |
| F3 | Lists of 2 to 4 items, each at most two lines            | `ul`/`ol` item count; each `li` height / line height                                                                      | warn   |
| F4 | Line length 45 to 80 characters                          | a body block of 2+ lines averaging over 80 characters per line                                                            | warn   |

The title is the takeaway surface: the largest `h1` to `h3` (or `[data-role="title"]`) on the slide, or, when a slide has no heading, the text block with the largest rendered font size, footer excluded. If that block is a topic label, T2 fails even when a smaller subtitle carries the claim, because the label holds the dominant position.

Deck mode comes from the `deck_mode` key in the `deck.md` header (`presented`, `keynote`, `briefing`, `reading`); a missing header or key means `presented`.

## Tell scanner

The tell scanner checks the visual habits that mark a deck as AI-made, the "template chrome" in Anthropic's own frontend-design list. P0 tells fail H8; P1 tells warn.

| ID | Tell                                           | Detection                                                                                                                                                              | Result |
| -- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| K1 | Eyebrow label on every slide                   | a text block above the title, under 60% of its size, uppercase (by transform or by text), on more than half the non-structural slides (3 or more)                      | P0     |
| K2 | Italic or accent-colored word inside the title | a descendant of the title that is italic, or differs from the title in color, family, or weight, covering part but not all of the title text (a lone "." counts as K6) | P0     |
| K3 | Stat-tile row                                  | 3 or more boxes on one row (tops within 8 px, widths within 15%), each holding number-like text at 2x or more the slide's median text size                             | P0     |
| K4 | Middle dot                                     | U+00B7 in rendered text                                                                                                                                                | P0     |
| K5 | Banned vocabulary                              | `P0_VOCAB` list: the words with the strongest corpus evidence of LLM overuse                                                                                           | P0     |
| K6 | Accent-colored period closing a heading        | a heading's last child is "." in a color different from the heading                                                                                                    | P1     |
| K7 | Mono micro labels                              | text in a monospace family, under 28 px, outside `code` and `pre`                                                                                                      | P1     |
| K8 | Sequence numbers where nothing is a sequence   | "01", "02" style markers (two digits with a leading zero) on a slide whose screen label is not a process, timeline, or agenda                                          | P1     |

## Copy probe

The probe that runs these rules in the page, with its word lists and patterns, lives in `copy-probe.md`. Run it after the geometry probe from `hard-gates.md`.

## Design-side use

`designing-presentations` runs the same text rules on `deck.md` before rendering, with `MODE` set from the header's `deck_mode` (missing header or key means `presented`). Per slide block: T1 to T8 on `headline` (T1 by word count only, since nothing is rendered yet) and T6 on the short `title` label when present (a topic label is allowed there, as long as the rendered slide keeps it out of the dominant position); W1 on the on-screen words the `visual` brief names plus the headline; C1, V1 to V3, P1 to P5, and W2 on `title`, `headline`, the on-screen words in `visual`, and `speaker_notes`. The constants and `textRules` in `copy-probe.md` are plain JavaScript: copy them into a small Node script over the parsed front-matter, or apply them by reading. The DOM rules (F1 to F4, K1 to K3, K6 to K8) run only on the rendered deck.

## Fixing lint findings

Fix the sentence, not the symptom. A buzzword swap that leaves an empty claim still fails the reader. Rewrite toward the preset's `language.md`: one claim per title with its proof inside it, everyday words, the source's own numbers, and an ending on the last concrete fact. Never invent a number or name to make a title specific; if the source has no number, say what it does have.
