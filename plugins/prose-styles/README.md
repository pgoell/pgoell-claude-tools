# prose-styles

Four Claude Code output styles that govern how the agent writes prose.

An output style is injected into the system prompt for the whole session, so it shapes every reply, commit message, PR body, and doc the agent produces until you switch it off. Unlike a skill, you do not invoke it per task.

All four set `keep-coding-instructions: true`, so Claude Code keeps its normal software-engineering behavior and only changes how it writes.

## Styles

| Style                  | What it does                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `prose-styles:orwell`  | Orwell's six rules from "Politics and the English Language" (1946). Short word over long, no stock phrase, active voice, cut every word that can go.                      |
| `prose-styles:concise` | Maximum density. Fragments legal, articles droppable, no preamble, no recap. Grammar yields to brevity, facts never do; final reports stay in full sentences.             |
| `prose-styles:ste`     | Simplified Technical English, condensed from ASD-STE100. One meaning per word, one instruction per step, condition before instruction. Built for procedures and runbooks. |
| `prose-styles:house`   | All three combined. Concision sets the shape, Orwell governs word choice, STE contributes vocabulary and ambiguity discipline only.                                       |

## Selecting one

```
/output-style prose-styles:house
```

Or pick it from the Output style list in `/config`. The choice persists for the project until you change it. Set it back with `/output-style default`.

## How `house` resolves the conflicts

STE and extreme concision contradict each other: STE demands full sentences, articles, and "never omit a word to shorten", while concision drops all three. In `house`, concision wins. STE contributes only its precision rules: one word per concept, no ambiguous pronoun, no noun stack over three, condition before instruction. Its sentence mechanics are dropped.

Use `ste` on its own when the reader must not misread: migration steps, runbooks, incident procedures, anything a stranger follows under pressure.

## Scope

Every style governs prose only. Code, identifiers, API names, CLI flags, config keys, error strings, and quoted file or command output are exempt in all four.

## Claude Code only

Codex has no output-style mechanism, so this plugin is not registered in `.agents/plugins/marketplace.json`. Its `.codex-plugin/plugin.json` exists to satisfy this repository's version-lockstep check and declares no `skills` path.

## Sources

- George Orwell, "Politics and the English Language" (1946). The six rules are quoted; the rest of `orwell.md` is original.
- ASD-STE100, Simplified Technical English. `ste.md` is a condensed working summary of the writing rules, written from scratch. No specification text is reproduced, and the approved-word dictionary is not bundled. Get the specification free from [asd-ste100.org](https://www.asd-ste100.org/).
