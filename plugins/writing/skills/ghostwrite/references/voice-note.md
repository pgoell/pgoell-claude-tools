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

- <habit>. [Applies to: <genre>.] Evidence: "<short quote from the owner's own writing>"

## Avoid

- <anti-pattern>. [Applies to: <genre>.] Evidence: <where it came from: sample, edit log, owner said so>

## Standards

- <what a piece must do or contain, e.g. "memos state the cost of doing nothing">. Applies to: <genre or all>. Evidence: <edit log, owner said so>

## Edit log

| Date       | Piece           | What the owner changed                       | Pattern                         |
| ---------- | --------------- | -------------------------------------------- | ------------------------------- |
| YYYY-MM-DD | <slug or title> | "<draft wording>" became "<owner's wording>" | <one-line name for the pattern> |
```

## Logging edits

After the owner edits a draft, compare their version with yours. Log edits that show a preference (word choice, sentence shape, what they cut, what they added), not typo fixes. When the same pattern appears in two or more pieces, propose it as an entry and add it only when the owner confirms. If the owner says outright "always do X", that counts as confirmed; still show the wording you will save. Add "Applies to: <genre>" when the owner or the evidence ties the habit to one genre.

The log also works against old entries. When the owner's edits go against an entry in two pieces, propose to narrow it (to a genre, a reader, a length) or drop it, and change it only when the owner confirms.

## Where a lesson goes

Sort each confirmed lesson by what it changes:

| The lesson changes                                                 | Goes to                         |
| ------------------------------------------------------------------ | ------------------------------- |
| Wording, sentence shape, tone, punctuation                         | Keep or Avoid                   |
| What a piece claims, what evidence it needs, its structure, length | Standards                       |
| What a particular reader knows, wants, or pushes back on           | The readers file (format below) |
| Only this piece                                                    | Nowhere; leave it in the draft  |

If a lesson mixes two of these ("shorter sentences, and lead with the number"), split it into two entries. Save the narrowest rule that captures it, and record why it matters, not only the preference.

## Optional drift check

Count, per 100 words, contractions and first-person pronouns in the draft and in the owner's samples. Report both numbers. Model revision reliably lowers both, so a large gap is a sign the draft has drifted toward model style. Report the gap; do not rewrite to close it unless the owner asks.

## The readers file

Notes on the readers the owner writes for again and again: a client, a steering group, a team, a blog audience. It saves asking the same reader questions for every memo, and it gives the fresh-reader test a real reader to play.

Location: `.pgoell/writing/readers.md` at the root of the current project (the git root, or the working directory without a repository). Readers differ by project, unlike voice, so this file is per project. The coach skill reads the same file.

### Rules

- One entry per reader. Start an entry only when the owner writes for that reader a second time, or asks for one.
- Every line carries its basis: **seen** (the reader said or did it), **owner** (the owner says so), or **guess** (an inference). Only the owner can turn a guess into seen or owner.
- Leave unknown fields empty. Do not invent a persona to fill the template.
- The current piece's reader wins. If the owner says this memo goes to a different person in the same client, ask about that person; do not reuse the entry.
- The readers file holds facts about the reader. What the owner's pieces must do for that reader belongs in the voice note's Standards.

### Format

```markdown
# Readers

## <reader name, e.g. "Client X steering group">

- Who: <role, situation, what they are trying to get done>. Basis: <seen | owner | guess>
- Already knows: <what you can skip explaining>. Basis: ...
- Needs explained: <terms or context they lack>. Basis: ...
- Wants from us: <decision support, reassurance, a number, ...>. Basis: ...
- Pushes back on: <what they challenged before, in their words if known>. Basis: ...
- Last updated: YYYY-MM-DD
```

### Using it

- **Step 2 (gather):** if the reader has an entry, show it in two lines and ask whether it still holds, instead of asking the reader questions from scratch.
- **Step 7 (fresh reader):** fill the fresh-reader prompt's `<reader>` from the entry, including what they already know and what they push back on.
- **Step 8 (learn):** when the owner reports how a reader reacted, propose the change to the entry and save it once the owner confirms.
