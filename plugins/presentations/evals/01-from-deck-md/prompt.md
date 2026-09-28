---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

I'm working on a presentation for our engineering leadership. Here is its deck.md. Save it as `deck.md` in the current directory first.

## Slide 01: Follow-the-sun on-call ends night pages for good

```yaml
slide_type: Title
headline: Follow-the-sun on-call ends night pages for good
visual: Title with team name and date, Platform Engineering, October 2026
speaker_notes: "Thirty seconds. Name the ask up front: approve the rotation for Q1."
```

## Slide 02: Night pages burn out our best engineers

```yaml
slide_type: Evidence
title: The problem
headline: Night pages burn out our best engineers
visual: Bar chart of pages per hour of day, spike between 01:00 and 04:00 CET
speaker_notes: "Walk them through the pager log from March, the early morning spike is the whole story. Two of the three people who left last year named on-call in their exit interview."
```

## Slide 03: Night pages fell from 41 to 6 per month in the pilot team

```yaml
slide_type: Evidence
title: The pilot
headline: Night pages fell from 41 to 6 per month in the pilot team
visual: Before and after hero numbers, 41 and 6, pilot ran June to August with the Singapore team
speaker_notes: "Stress that the six remaining pages were all real incidents, no noise."
```

## Slide 04: Singapore and Austin already cover our night hours

```yaml
slide_type: Transformation
title: How it works
headline: Singapore and Austin already cover our night hours
visual: World map strip with three 8-hour bands, Berlin, Singapore, Austin
speaker_notes: ""
```

## Slide 05: Approve the rotation for Q1 and we start on 12 January

```yaml
slide_type: Decision
title: The decision
headline: Approve the rotation for Q1 and we start on 12 January
visual: Three steps, approve now, train handover in December, go live 12 January
speaker_notes: "Pause after the ask. If they hesitate, offer a one-month trial."
```

## Slide 06: Questions and contacts

```yaml
slide_type: Closing
headline: Approve by Friday so December training can start
visual: Contact line, platform-oncall channel
speaker_notes: ""
```

Now create the slides for the deck.md of this presentation. Put the deck in `deck/` with the entry file `deck/index.html`, and keep the slide order from deck.md.

When the deck is done, screenshot every slide at 1920x1080 into `shots/slide-NN.png` (two-digit, 1-based, e.g. `shots/slide-01.png`) with headless Chrome, for example `chrome-headless-shell --no-sandbox --screenshot=shots/slide-01.png --window-size=1920,1080 --hide-scrollbars "file://$PWD/deck/index.html#1"` (use `chrome-headless-shell`, not `google-chrome`: it runs where the full browser cannot). Make sure each screenshot actually shows its own slide.
