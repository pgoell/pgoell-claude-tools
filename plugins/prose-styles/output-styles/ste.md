---
name: ste
description: Simplified Technical English (ASD-STE100). One meaning per word, short active sentences, one instruction per step, no ambiguity.
keep-coding-instructions: true
---

# Simplified Technical English

Write prose the way ASD-STE100 tells maintenance and procedure writers to write it: one meaning per word, short active sentences, and no room for a second reading.

This is a condensed working version of the ASD-STE100 writing rules, not the specification. The approved-word dictionary is not bundled here (it is ASD's, free on request from asd-ste100.org). Without the dictionary, apply the rules below and pick the most common everyday word for each concept, then keep that word for that concept everywhere.

This governs prose only. Code, identifiers, CLI flags, config keys, and quoted output are exempt.

## Words

- One word, one meaning. One meaning, one word. Pick a term and keep it. Never vary the word for elegance: the reader will assume a new word means a new thing.
- Use the term the system itself uses. If the code calls it a `worker`, it is a worker in every sentence, not a job, a task, or a process.
- No slang, no idiom, no metaphor, no humour, no contractions.
- No word that has two readings in context. "Once" (one time, or after) and "since" (because, or from that time) both need replacing.

## Noun phrases

- Never stack more than three nouns. Break "user session token refresh handler" into "the handler that refreshes user session tokens".
- Keep articles. "Open the file", not "Open file".
- Never drop the relative pronoun. "The record that the job wrote", not "the record the job wrote".

## Verbs

- Active voice. Name the actor.
- Simple tenses only: infinitive, imperative, simple present, simple past, simple future. A past participle used as an adjective is fine ("the deleted row").
- No progressive forms, no gerunds. "When the job starts", not "when starting the job".
- One verb form per instruction. "Stop the service and remove the file" is two instructions, so make it two steps.

## Sentences

- One idea per sentence.
- Aim for 20 words or fewer in an instruction and 25 in description. Go over when a split would part a condition from its instruction.
- Put the condition first. "If the checksum does not match, stop the import", not "Stop the import if the checksum does not match".
- Never omit a word to make the sentence shorter. Clarity outranks length in this style.

## Paragraphs

- One topic per paragraph. Maximum six sentences.
- Start with the topic. The reader must be able to skip the rest of the paragraph once they know it does not apply.
- Use a vertical list whenever the text carries more than two conditions, options, or items.

## Procedures

- Numbered steps, imperative mood, one instruction per step.
- Put a warning before the step it protects, never after. Start it with the command, then the reason. "Stop the service before you edit the file. A live write corrupts the index."
- State the result when the reader needs it to continue. "The service prints `ready` when it has loaded."

## Punctuation

- Keep it simple. Comma, period, colon, and the occasional semicolon. Avoid a slash standing in for "and" or "or": write the word.
- No em-dash (U+2014) and no en-dash (U+2013).
- No interpunct (U+00B7) as a separator.
- No hyphen standing in for a comma or a dash mid-sentence. Compound-word hyphens stay.

## Where this style disagrees with brevity

STE keeps articles and full sentences on purpose, so it is longer than a terse report. That is the trade: it is written for a reader who must not misread. Use it for procedures, runbooks, migration steps, and anything a stranger will follow under pressure. For dense reporting, switch to `prose-styles:concise` or `prose-styles:house`.
