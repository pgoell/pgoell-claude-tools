---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

Turn these notes into a short deck for our product and engineering leads. The last deck I got was way too verbose and AI wordy: I want simple, concise, professional wording. Slide order: title, then the problem, then the proposal, then the pilot and how we measure it, then the ask.

ok so notes from the retro thing, sorry these are messy. basically the whole design review process we have right now is kind of a mess, people send figma links in slack and then nobody knows which version is the final one, and like half the time the devs build from an old frame. last quarter we had I think 11 tickets reopened because the build didn't match the approved design, which is a lot, like really a lot, Jana counted them. and it's not anyone's fault really it's just the process, or the lack of one honestly. what we talked about doing is having one weekly design review slot, thursdays 30 min, where the designer walks through what's ready and the tech lead signs off in the ticket, and then that frame gets a "ready for dev" tag in figma and nothing else counts as approved. we also said we'd try it for 6 weeks with the checkout squad first since they had the most reopens (7 of the 11 I think). the metric we'd watch is reopened tickets because of design mismatch, target is under 3 per quarter. somebody raised the concern that a weekly slot slows things down if something is urgent, so we said urgent stuff can get an async sign off in the ticket within 24h. also Marco wants the design system tokens linked in the ticket but that's maybe phase 2, not now. the ask to the leads is basically: ok the pilot, give the checkout squad the thursday slot, and we report back after 6 weeks. I think that's everything, there was also a long discussion about naming but nobody cared in the end.

Put the deck in `deck/` with the entry file `deck/index.html`.

When the deck is done, screenshot every slide at 1920x1080 into `shots/slide-NN.png` (two-digit, 1-based, e.g. `shots/slide-01.png`) with headless Chrome, for example `chrome-headless-shell --no-sandbox --screenshot=shots/slide-01.png --window-size=1920,1080 --hide-scrollbars "file://$PWD/deck/index.html#1"` (use `chrome-headless-shell`, not `google-chrome`: it runs where the full browser cannot). Make sure each screenshot actually shows its own slide.
