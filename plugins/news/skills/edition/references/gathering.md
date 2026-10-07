# Gathering

How to find each section's candidate stories. Read it before step 4 of the
edition protocol, and paste the section brief below into every gatherer.

## What works

Learned from the first sample edition (2026-10-07):

- **Scrape the outlet's section page, then read each article's meta.** WebSearch
  finds the outlet; a plain fetch of its section page lists article links; a
  fetch of each article gives `og:title`, `og:description`, `og:image`,
  `article:published_time` or JSON-LD `datePublished`, and the `<p>` text once
  `<script>` and `<style>` are stripped. `curl -sL` with a desktop Chrome
  User-Agent (`-A "Mozilla/5.0 (X11; Linux x86_64) Chrome/128.0 Safari/537.36"`)
  is faster than WebFetch and gets through more sites. Use WebFetch when curl
  is not allowed.
- **Search with the month and year.** "Gelnhausen Nachrichten Oktober 2026"
  beats "Gelnhausen Nachrichten". Do not search "tagesschau <date>": it returns
  TV listings; scrape `tagesschau.de/inland` and `/ausland` instead.
- **Skip `blocked_sources`** in topics.yaml. They refuse scripted fetches or the
  search tool, and every turn spent on them is lost. Use secondary coverage.
- **Paywalls.** When the body is placeholder text (GNZ prints Lorem ipsum), use
  only `og:description` and look for the same item on a free source (MKK-Echo
  often republishes what GNZ paywalls).

## Freshness

A story is a candidate when it was published within the section's
`freshness_days` (topics.yaml, default 2) before the edition date. News
sections use 1 to 2 days; AI Evals uses 14 and Deloitte and Allianz use 7,
because those beats rarely have daily news. A page without a date (leaderboards,
release notes, benchmark reviews) needs a date from its text ("as of",
"Submitted on"); mark such a date as approximate in `key_facts`.

## Images

`og:image`, absolute https, hotlinked. Use `null` when there is none, when it
is relative, when it is a generic site thumbnail shared by every page (Epoch AI
reviews, the arXiv logo), or when it is an auto-generated chart. A null image
is fine; a wrong one is not.

## Section brief (one gatherer per section)

Fan out: with the Agent tool (Claude Code) or `spawn_agent` (Codex), start one
gatherer per section, all at once, and wait for every result. Without a
subagent tool, run the brief yourself for each section in turn. Fill the
brackets from topics.yaml and from `recent.py --section <id>`:

```text
You gather news for one section of a personal daily newspaper.
Section: <name> (id <id>). Edition date: <YYYY-MM-DD>. Window: stories published
on or after <edition date minus freshness_days>.
Queries: <queries>. Sources to check first: <sources with notes>.
Exclude: <exclude>, plus the reader's avoid list: <avoid>. Weigh: <interests>.
Never fetch these domains: <blocked_sources>.
Already reported (do not return these unless something new happened):
<recent.py output for this section>

Method: scrape each source's section page for article links, read each
article's og meta, published time and body text. Use WebSearch with the month
and year to find more. Stay inside the window.

Return up to <max_stories + 3> candidates as a JSON array, best first, each:
{"headline", "dek", "summary" (60-180 words, in the article's language,
plain text, \n\n between paragraphs, facts only, no opinion), "lang", "url",
"source", "published" (ISO 8601), "image" ({"src","alt","credit"} or null),
"importance" (1-3), "tags", "entities", "key_facts" (2-4 short facts),
"repeat_of" (the id of an already-reported story this continues, or null),
"whats_new" (when repeat_of is set: only what is new, else null)}.
Write the summary from the article text you fetched, never from memory. If
the window holds nothing worth reading, return [] and say why in one line.
```

At depth 2 ask for 40 to 80 word summaries; at depth 1 ask only for headline,
url, source and published, which become briefs.

## Weather

No weather API. Take the day's outlook for `weather.place` from a regional
source (hessenschau's "Hessen am Abend" carries one) or a search for
"Wetter <place> heute". Give whole degrees; set `weather` to null when nothing
credible turns up rather than guessing.
