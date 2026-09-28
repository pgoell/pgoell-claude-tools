---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

Build a 6-slide deck for our CFO on the cloud migration. Her brief: cost first, very easy to read. Slide 1 is the title; slide 2 must be the cost bottom line.

Figures:

- Current on-premises run cost: EUR 2.4M per year
- Projected cloud run cost: EUR 1.7M per year, so EUR 0.7M saved per year
- One-time migration cost: EUR 0.9M
- Payback period: 16 months
- Risk buffer already included in the projection: EUR 0.2M

Other points: the data centre lease ends in December 2027, the migration runs in three waves over 2027, and finance needs to approve the one-time budget by 15 November.

Put the deck in `deck/` with the entry file `deck/index.html`.

When the deck is done, screenshot every slide at 1920x1080 into `shots/slide-NN.png` (two-digit, 1-based, e.g. `shots/slide-01.png`) with headless Chrome, for example `chrome-headless-shell --no-sandbox --screenshot=shots/slide-01.png --window-size=1920,1080 --hide-scrollbars "file://$PWD/deck/index.html#1"` (use `chrome-headless-shell`, not `google-chrome`: it runs where the full browser cannot). Make sure each screenshot actually shows its own slide.
