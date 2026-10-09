# Page contract

`<insights>/<date>.json` is what `render.py` renders, `note.py` turns into the
review note, and `remember.py` folds into memory. `render.py` checks every rule
marked **checked** and refuses to render until they hold.

```json
{
  "date": "2026-10-08",
  "window": ["2026-09-25", "2026-10-08"],
  "scope": {
    "main_sessions": 27,
    "subagent_files": 107,
    "newspaper_runs": 1,
    "projects": 5,
    "skipped_large": [{ "file": "...", "mb": 2182 }]
  },
  "newspaper_note": "From the 06:00 edition and its log. 10-08 took 13 min, exit 0.",
  "problems": [
    {
      "id": "10-08-01",
      "fingerprint": "pkill-self-match",
      "group": "dev",
      "status": "doc",
      "kind": "Command pattern",
      "title": "pkill -f kills the agent's own shell (exit code 144)",
      "yesterday": 4,
      "series": [0, 0, 0, 6, 8, 10, 2, 3, 0, 0, 13, 19, 17, 4],
      "projects": ["blattwerk", "trips", "kasten"],
      "what": "$ pkill -f 'uvicorn blattwerk.app:app --port 8765'; true\nExit code 144",
      "why": "The pattern also matches the bash -c that runs the command ...",
      "verified": true,
      "fix": [
        ["c", "plugins/guards/hooks/pkill-self-match"],
        ["d", "- ..."],
        ["a", "+ ..."]
      ],
      "destination": "pgoell-claude-tools/plugins/guards",
      "destination_note": "a PreToolUse hook",
      "action": "Opens a PR",
      "target": {
        "repo": "/home/pascal/Code/pgoell-claude-tools",
        "path": "plugins/guards/hooks/"
      },
      "evidence": ["0c8b4522 19:47", "13b1f03f"]
    }
  ],
  "seen": [
    {
      "pattern": "TLS failures on small sites",
      "where": "blattwerk, trips",
      "yesterday": 68,
      "total": 78,
      "why": "Dead supplier sites; the sites are the problem.",
      "fingerprint": "tls-small-sites"
    }
  ]
}
```

## Top level

- `date`, `window`, `scope`, `problems`, `seen`: required (**checked**).
  Copy `window` and the `scope` fields from the digest.
- `newspaper_note`: one line under the "Newspaper runs" heading, from the
  newspaper logs: how long each run took and how it exited.

## A problem

- `id`: `MM-DD-NN` of the analysed day, NN from 01 in the order you list
  them; unique (**checked**).
- `fingerprint`: a short lowercase slug naming the problem, not the day.
  Reuse the one memory already has for the same problem, so verdicts follow it
  across days.
- `group`: `dev` for your sessions, `news` for the newspaper's runs
  (**checked**).
- `status`: `doc` (documented, still happening), `rec` (recurring), `new`,
  `fade` (fading) (**checked**). `references/judging.md` says which.
- `kind`: a few words, such as "Command pattern", "Missing tool on host",
  "Skill defect", "Guard friction", "Correction", "Newspaper source".
- `title`: one line, what goes wrong, in plain words.
- `yesterday`, `series`: hits on the analysed day, and 14 daily counts, oldest
  first, ending with the analysed day (**checked**: exactly 14). Sum the
  digest series of every shape the problem groups. A problem from typed text
  counts the messages that show it.
- `projects`: chips, at most five; add `+N` for the rest.
- `what`: the error text or the quote, verbatim, short. A Bash error starts
  with the `$ command` line.
- `why`: the cause in two to four sentences.
- `verified`: true only when this run checked the cause against the live
  system (a process list, a file, a config, a grep of the destination). The
  page marks the rest as unverified.
- `fix`: the concrete change as `[tag, line]` pairs (**checked**): `c` for
  context (the file and the heading it goes under), `a` for a line added, `d`
  for a line removed. A command to run is one `c` line.
- `destination`: where the fix goes, a path or a note name. `destination_note`
  adds a few plain words after it.
- `action`: `Opens a PR`, `Adds a todo`, `Adds a feedback line` or
  `Watch only` (**checked**). `Opens a PR` needs `target.repo`, the absolute
  path of the repository (**checked**), and `target.path`, the file or folder.
- `evidence`: session ids (8 characters) with the Berlin time where it helps,
  or `edition 10-08` for a newspaper run.

## A seen row

Patterns that did not make a card: below the bar, rejected before and not
tripled, or the work's own noise. `pattern`, `where`, `yesterday`, `total`,
`why`, and `fingerprint` when the pattern has one, which lets the footer tell
whether an applied fix stopped it.
