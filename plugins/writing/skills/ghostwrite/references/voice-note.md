# Voice note and edit log

The voice note is a short list of the owner's confirmed writing habits and anti-patterns, plus the standards their pieces must meet. It grows from real edits the owner makes, not from a profile the model writes.

Location: `~/.pgoell/writing/voice-note.md`, one global file, because the owner's voice does not change between projects. The coach skill reads the same file.

## Why it stays short

Two to five owner samples give about as much style signal as twenty-five, and long profiles do no better than short ones on independent measures. What moves a draft toward the owner is content they supplied and their own final edit. So the note holds a handful of rules the owner agrees with, and nothing else.

## Starting a note

1. Ask for two to five pieces the owner wrote themselves (not ones a model drafted, not another writer's). Save them under `~/.pgoell/writing/samples/` if the owner agrees.
2. Read them and propose at most five entries: habits to keep and habits to avoid, each with a short quote from the samples as evidence. Propose only habits that recur across at least two samples, and write each as something you can see in a sentence ("opens with the ask, then the reason"), not as a trait ("direct", "warm").
3. Ask the owner to confirm, change, or drop each entry. Write only confirmed entries.
4. If the owner has no samples, start with an empty note and the plain-register defaults below. The edit log will fill it.

If the owner has written down writing preferences elsewhere (a memory file, a style note), offer to seed the note from them, entry by entry, with the owner confirming each.

## Plain-register defaults

These apply when the note is silent:

- Short, common words; active verbs; concrete nouns.
- No signature moves: no rhetorical-question openers, no "not X but Y" set pieces, no rule-of-three lists for rhythm, no one-line zingers at the end of a paragraph.
- No persona or tone pass layered on top of the owner's words.
- No invented anecdotes, quotes, or numbers.
- No em-dashes, en-dashes, or middle-dot separators.

## File format

```markdown
# Voice note

## Keep

- <habit>. Evidence: "<short quote from the owner's own writing>"

## Avoid

- <anti-pattern>. Evidence: <where it came from: sample, edit log, owner said so>

## Standards

- <what a piece must do or contain, e.g. "memos state the cost of doing nothing">. Applies to: <genre or all>. Evidence: <edit log, owner said so>

## Edit log

| Date       | Piece           | What the owner changed                       | Pattern                         |
| ---------- | --------------- | -------------------------------------------- | ------------------------------- |
| YYYY-MM-DD | <slug or title> | "<draft wording>" became "<owner's wording>" | <one-line name for the pattern> |
```

## Logging edits

After the owner edits a draft, compare their version with yours. Log edits that show a preference (word choice, sentence shape, what they cut, what they added), not typo fixes. When the same pattern appears in two or more pieces, propose it as an entry and add it only when the owner confirms. If the owner says outright "always do X", that counts as confirmed; still show the wording you will save.

## Where a lesson goes

Sort each confirmed lesson by what it changes:

| The lesson changes                                                 | Goes to                                           |
| ------------------------------------------------------------------ | ------------------------------------------------- |
| Wording, sentence shape, tone, punctuation                         | Keep or Avoid                                     |
| What a piece claims, what evidence it needs, its structure, length | Standards                                         |
| What a particular reader knows, wants, or pushes back on           | The readers file (`readers.md` in the references) |
| Only this piece                                                    | Nowhere; leave it in the draft                    |

If a lesson mixes two of these ("shorter sentences, and lead with the number"), split it into two entries. Save the narrowest rule that captures it, and record why it matters, not only the preference.

## Optional drift check

Count, per 100 words, contractions and first-person pronouns in the draft and in the owner's samples. Report both numbers. Model revision reliably lowers both, so a large gap is a sign the draft has drifted toward model style. Report the gap; do not rewrite to close it unless the owner asks.
