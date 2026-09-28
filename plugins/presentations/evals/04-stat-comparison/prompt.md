---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

We ran a 3-month pilot of our new delivery pipeline with two teams. Build a short deck (4 to 5 slides) for the engineering all-hands showing what changed. Slide 1 is the title; slide 2 must show the before and after comparison.

| Metric                  | Before pilot | After pilot |
| ----------------------- | ------------ | ----------- |
| Lead time for a change  | 9 days       | 2 days      |
| Change failure rate     | 18%          | 7%          |
| Deploys per week        | 3            | 14          |
| Time to restore service | 6 hours      | 45 minutes  |

Context: the pilot teams were Payments and Search. The next step is rolling the pipeline out to four more teams in Q1, and we need one volunteer platform engineer per team.

Put the deck in `deck/` with the entry file `deck/index.html`.

When the deck is done, screenshot every slide at 1920x1080 into `shots/slide-NN.png` (two-digit, 1-based, e.g. `shots/slide-01.png`) with headless Chrome, for example `chrome-headless-shell --no-sandbox --screenshot=shots/slide-01.png --window-size=1920,1080 --hide-scrollbars "file://$PWD/deck/index.html#1"` (use `chrome-headless-shell`, not `google-chrome`: it runs where the full browser cannot). Make sure each screenshot actually shows its own slide.
