---
tags: [core]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash, Agent]
runs: 3
---

What's wrong with the intro to my blog post? I keep writing intros like this and I want to learn to write better ones, not have you do it for me.

I've been thinking a lot lately about code review, and about how the way we do it on my team has changed over the last year or so. When I first joined, reviews were something of an afterthought, and there was a tendency for pull requests to sit for days before anyone would take a look at them. There were various reasons for this, including the fact that everyone was busy and that there wasn't really any clear ownership. Over time, and after a number of retrospectives, we made the decision to try something different, which involved the implementation of a rotating reviewer role. It's been interesting to see the effects of this. What I actually want to argue in this post is that small teams should stop treating review as a favour and make it someone's job each day.
