# Readers file

Notes on the readers the owner writes for again and again: a client, a steering group, a team, a blog audience. It saves asking the same reader questions for every memo, and it gives the fresh-reader test a real reader to play.

Location: `.pgoell/writing/readers.md` at the root of the current project (the git root, or the working directory without a repository). Readers differ by project, unlike voice, so this file is per project. The coach skill reads the same file.

## Rules

- One entry per reader. Start an entry only when the owner writes for that reader a second time, or asks for one.
- Every line carries its basis: **seen** (the reader said or did it), **owner** (the owner says so), or **guess** (an inference). Only the owner can turn a guess into seen or owner.
- Leave unknown fields empty. Do not invent a persona to fill the template.
- The current piece's reader wins. If the owner says this memo goes to a different person in the same client, ask about that person; do not reuse the entry.
- The readers file holds facts about the reader. What the owner's pieces must do for that reader belongs in the voice note's Standards.

## Format

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

## Using it

- **Step 2 (gather):** if the reader has an entry, show it in two lines and ask whether it still holds, instead of asking the reader questions from scratch.
- **Step 7 (fresh reader):** fill the fresh-reader prompt's `<reader>` from the entry, including what they already know and what they push back on.
- **Step 8 (learn):** when the owner reports how a reader reacted, propose the change to the entry and save it once the owner confirms.
