# Activity page contract

`collect.py` writes `<activity>/<date>.json`. You add two keys through a notes
file, `render.py --notes` saves them into that JSON and checks every rule
marked **checked**, and `link_daily.py` reads the result.

## What collect.py writes

```json
{
  "date": "2026-10-09",
  "sources": {
    "github": "ok",
    "ci": "ok",
    "ledger": "ok",
    "usage": "ok",
    "vault": "ok"
  },
  "repos": [
    {
      "name": "blattwerk",
      "slug": "pgoell/blattwerk",
      "url": "https://github.com/pgoell/blattwerk",
      "sessions": 34,
      "subagent_files": 97,
      "commits": 110,
      "commit_list": [
        {
          "sha": "1a2b3c4d",
          "subject": "fix: ...",
          "url": "https://github.com/..."
        }
      ],
      "commits_url": "https://github.com/pgoell/blattwerk/commits?since=...",
      "prs_opened": 29,
      "prs_merged": 30,
      "prs_open": 1,
      "issues_opened": 97,
      "issues_closed": 74,
      "loop_tasks": 9,
      "loop_minutes": 566,
      "tokens": 354060738,
      "cost": 479.55,
      "merged": [
        { "number": 209, "title": "fix: ...", "url": "https://github.com/..." }
      ],
      "merged_url": "https://github.com/pgoell/blattwerk/pulls?q=..."
    }
  ],
  "open_prs": [
    {
      "repo": "kasten",
      "number": 179,
      "title": "feat(mobile): ...",
      "url": "https://github.com/pgoell/kasten/pull/179",
      "created": "2026-10-10",
      "age_days": 0,
      "stale": false,
      "draft": false,
      "insights": false,
      "session": {
        "id": "1fd6ccc5-...",
        "resume": "claude --resume 1fd6ccc5-...",
        "url": "https://claude.ai/code/session_..."
      }
    }
  ],
  "failed_ci": [
    {
      "repo": "blattwerk",
      "branch": "fix/x",
      "workflow": "CI",
      "failures": 2,
      "url": "https://github.com/..."
    }
  ],
  "ledger": [
    {
      "date": "2026-10-09",
      "issues": "210 212 199",
      "prs": "213",
      "minutes": "95",
      "closed": "5",
      "opened": "3 (0/2/0/1)",
      "not_fixed": "-",
      "notes": "#212 unproven in headed Chrome",
      "repo": "blattwerk",
      "pr_urls": ["https://github.com/pgoell/blattwerk/pull/213"]
    }
  ],
  "usage": { "tokens": 553005725, "cost": 631.84 },
  "cron": [
    { "job": "news", "date": "2026-10-09", "state": "ok", "log": "/home/..." }
  ],
  "vault": { "notes": 23, "folders": [["01 Periodic", 10]] },
  "scope": { "own_runs_skipped": 2, "skipped_large": [] },
  "needs": [],
  "shipped": {}
}
```

- `sources`: `ok` or the reason a source gave nothing. The page prints every
  source that is not `ok`. Never fill a gap by hand.
- `repos`: one row per repository with any activity on the day or an open PR.
  `vault` is every session in a private folder; `other` is every session
  outside a repository under the code root. `tokens` and `cost` are `null`
  where ccusage had no row.
- `open_prs`: every PR of yours open now, oldest first. `stale` means older
  than 7 days. `insights` means an insights fix waits on it. `session` is set
  when a transcript recorded that a session opened the PR. Its `url` opens the
  claude.ai session the local one was bridged to, and one such session can
  cover many local ones; `resume` names the exact local session.
- `failed_ci`: runs of the day that failed, one per branch and workflow, when
  no later run there passed.
- `ledger`: the day's issue-loop task lines, cells as written.
- `cron`: `ok`, `failed, exit N`, or `running or died` (the log has no exit
  line).

## What you add

Write this to `/tmp/activity-notes-<date>.json`:

```json
{
  "needs": [
    {
      "headline": "8 kasten mobile PRs wait for review",
      "why": "PRs 179 to 186 build on each other; none merges until you look.",
      "links": [
        { "label": "#179", "url": "https://github.com/pgoell/kasten/pull/179" }
      ],
      "resume": "1fd6ccc5-a329-4d6a-a10d-37ffd97e6c29"
    }
  ],
  "shipped": {
    "blattwerk": "30 PRs: editor fixes for keys, focus and touch. CI now runs WebKit."
  }
}
```

### A needs item

- `headline`: what waits, at most 80 characters (**checked**). Name the repo
  and the number or count.
- `why`: one line on why it matters, at most 160 characters (**checked**).
  Quote the number or the ledger words that make it matter.
- `links`: `label` and `url` pairs. Every `url` must stand in the collected
  data (**checked**). Give one link per PR or run the item covers, so a series
  is one item with all its links. An item with no URL in the data, such as a
  failed cron job, has no links; name the log path in `why`.
- `resume`: optional, the full `session.id` of one open PR the item covers
  (**checked** against the data). The page prints `claude --resume <id>`.
- Order the items by how much they block: the first five go into the daily
  note.

### shipped

One entry per repo that merged a PR: the repo `name` (**checked**) and a
summary of at most two sentences and 300 characters (**checked**), built from
`merged` titles and that repo's `ledger` lines only.

### Every text

No em-dash, no en-dash, no interpunct, no hyphen used as punctuation
(**checked**).

## What render.py works out

Totals, and the outlier marks in the churn table: a cell is marked when it
reaches its limit (sessions 40, commits 100, PRs opened 20, issues opened 30,
loop minutes 480, cost 200 dollars).
