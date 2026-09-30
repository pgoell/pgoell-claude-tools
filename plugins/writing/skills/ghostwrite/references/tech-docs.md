# Tech docs

Compact reference for READMEs, how-to guides, tutorials, reference pages, explanations, design docs, and PR descriptions. Facts come from the repository and from commands you ran, never from memory.

## Sourcing rules

- Read the code and the existing docs before writing anything. Quote names, flags, paths, and defaults exactly as the code has them.
- Run every command the doc tells the reader to run, where the environment allows: install, build, test, the CLI's `--help`, the example itself. Paste real output, trimmed if long.
- A command you could not run is marked `[unverified: <reason>]`. A value you could not find is `<unknown>`.
- Rationale ("we chose X because") comes from the owner or an existing doc, never from you. Without a source, leave it out or mark `[owner: why X?]`.
- PR descriptions: what changed comes from the diff and commit messages; how it was tested comes from commands you ran or the owner reported; why comes from the owner.

## The four quadrants (Diataxis)

Each doc serves one reader need. Pick one and confirm it with the owner.

| Quadrant    | Reader need   | Shape                                                                               | Drift signs to avoid                                                                           |
| ----------- | ------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Tutorial    | Learning      | "What you will build", numbered steps, expected output after each step, one path    | Option tables (reference), branching "if you want Y" (how-to), theory detours (explanation)    |
| How-to      | A task        | One-sentence goal, prerequisites, numbered steps, a check that it worked            | Celebration, teaching every output (tutorial), long "why" preamble (explanation), option dumps |
| Reference   | Lookup        | Schema-shaped: one entry per command, function, endpoint, or key, in a fixed layout | Second-person hand-holding, narrative paragraphs, inline procedures                            |
| Explanation | Understanding | Context, how it works, trade-offs, when to use it versus the alternatives           | Numbered procedures (how-to), option tables (reference), "quickstart" framing                  |

A README is usually a short how-to (install and first use) with links to the rest. A design doc is an explanation with a decision in it; treat the decision like a work document and run the pyramid audits on it.

Brief cross-links to another quadrant are fine ("for a walkthrough, see the tutorial").

## Reference schemas

Fill the matching schema; mark missing required fields `<unknown>` and list them for the owner.

- **CLI command.** Required: name, synopsis (one usage line), description (one paragraph), options (flag, argument, default, description), arguments (name, required, description, or "none"), exit codes (at least 0 and each documented non-zero code), examples (one minimal, one with options). Optional: environment variables, files read or written, see also, since.
- **Function or method.** Required: name, signature, one-paragraph description, parameters (name, type, required, description, or "takes no parameters"), return value and type, exceptions raised, examples (one minimal, one idiomatic). Optional: see also, since, deprecation.
- **REST endpoint.** Required: method and path, authentication, path parameters, query parameters (name, type, required, default, description), request body, response body, status codes, one full example request and response. Optional: custom headers, rate limits, since.
- **Configuration key.** Required: key, type, default, allowed values, description, example, effect when changed. Optional: required or not, related keys, since.
- **Error code.** Required per error: code, message text, cause, resolution. Optional: related errors, since. Use one entry per error, or one table for a short list.

## Word swaps

Swap these only when the swap leaves a correct sentence. The mechanical ones are safe in almost every case; the rest need judgement, so flag them rather than replace them.

| Term                  | Replacement               | Mechanical |
| --------------------- | ------------------------- | ---------- |
| in order to           | to                        | yes        |
| utilize               | use                       | yes        |
| make use of           | use                       | yes        |
| due to the fact that  | because                   | yes        |
| are able to           | can                       | yes        |
| at this point in time | now                       | yes        |
| e.g.                  | for example               | yes        |
| i.e.                  | that is                   | yes        |
| execute (a command)   | run                       | yes        |
| uncheck, deselect     | clear                     | yes        |
| e-mail                | email                     | yes        |
| simply, just, easy    | (drop)                    | no         |
| please                | (drop)                    | no         |
| hit (a key)           | press                     | no         |
| whitelist, blacklist  | allowlist, blocklist      | no         |
| master (branch)       | main, if the repo uses it | no         |

"Simply" and "easy" tell a stuck reader they are slow; drop them unless the owner insists. Match the repository's own terms over any list.
