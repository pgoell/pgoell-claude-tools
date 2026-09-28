---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

Make a deck about our Q3 onboarding changes for the department heads. I need to email it as one attachment, so it has to be a single HTML file: `deck/onboarding.html`.

Content:

- New hires now get laptop and accounts on day one instead of day four (IT pre-provisions from the signed contract).
- Every new hire gets a named buddy for the first 30 days; 38 buddies volunteered across 9 teams.
- The first-week checklist went from 47 items to 12; the rest moved into the first month.
- Early results from 22 July to 30 September: time to first merged change dropped from 11 days to 4 days; new-hire survey score rose from 3.1 to 4.4 out of 5.
- Ask: every department head nominates at least two more buddies by 31 October.

Keep it to 5 or 6 slides.

When the deck is done, screenshot every slide at 1920x1080 into `shots/slide-NN.png` (two-digit, 1-based, e.g. `shots/slide-01.png`) with headless Chrome, for example `chrome-headless-shell --no-sandbox --screenshot=shots/slide-01.png --window-size=1920,1080 --hide-scrollbars "file://$PWD/deck/onboarding.html#1"` (use `chrome-headless-shell`, not `google-chrome`: it runs where the full browser cannot). Make sure each screenshot actually shows its own slide.
