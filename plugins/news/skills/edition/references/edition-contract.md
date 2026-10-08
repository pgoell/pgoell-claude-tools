# Edition contract

This file is authoritative. `scripts/validate.py` checks it, every design in
`designs/` renders it, and `scripts/remember.py` reads it. Change all three
together.

An edition is one JSON file, `<newspaper>/YYYY-MM-DD.json`, beside the page
rendered from it, `<newspaper>/YYYY-MM-DD.html`. Templates are Jinja2
(`designs/<name>/template.html.j2`), rendered with one variable, `edition`:

```yaml
edition:
  title: str # masthead, from config/design.yaml, e.g. "Der Gelnhäuser Morgen"
  tagline: str # under the masthead, from config/design.yaml
  date: "YYYY-MM-DD"
  date_display: str # e.g. "Mittwoch, 7. Oktober 2026"
  number: int # issue number, from seed.py
  weather: { place: str, summary: str, high_c: int, low_c: int } | null # weather.py fills it from Open-Meteo when null
  previous: str | null # relative href to the previous edition, e.g. "2026-10-06.html", from seed.py
  lead: story # the front-page lead; it does not repeat in a section
  sections: [{ id: str, name: str, kicker: str | null, local: bool, stories: [story] }] # 4 to 10 sections, config order; local is optional, true on the home section from topics.yaml
  briefs: [{ headline: str, url: str, source: str, section: str }] # one-liners, "in brief"; section is a section id
  feedback_hint: str # how to give feedback, naming the feedback note's path
  recent_feedback: [str] # optional; the newest applied changes, "YYYY-MM-DD: what changed"
  design_overrides: { token: value } # set by render.py from design.yaml, never written by hand
  generated_display: str # set by render.py: render time in Europe/Berlin, "7.10., 06:12"

story:
  id: str # "<edition date>-<slug>-NN", e.g. "2026-10-07-anthropic-01"; the HTML anchor
  headline: str # in the source language
  dek: str | null # sub-headline
  summary: str # words by importance (3: 90-150, 2: 50-90, 1: 25-45), source language, plain text, \n\n between paragraphs
  lang: "de" | "en" | ...
  url: str # the original article
  source: str # outlet name
  published: str # ISO 8601 datetime, or "YYYY-MM-DD" when the source gives only a day
  published_display: str # set by render.py: `published` in Europe/Berlin, "7.10., 15:46", or "7.10." for a day only
  image: { src: str, alt: str, credit: str } | null # og:image, hotlinked, https only
  importance: 1 | 2 | 3 # 3 = big, 1 = small
  tags: [str]
  followups: [{ date: str, href: str, headline: str }] # earlier coverage, href like "2026-10-03.html#2026-10-03-openai-02"
  update_note: str | null # required when followups is not empty: only what is new since that coverage
  section: str # optional, lead only: the section id the lead came from
  entities: [str] # optional, memory only: people, organisations, places, products the story is about
  key_facts: [str] # optional, memory only: the two to four facts a later edition must not restate
```

## Rules validate.py enforces

- Every required field is present with the type above; `weather`, `dek`,
  `image` and `update_note` may be null.
- Story ids are unique across the lead and all sections, match
  `YYYY-MM-DD-<slug>-NN` and start with the edition's date.
- `previous` is null or `YYYY-MM-DD.html`; a follow-up `href` is
  `YYYY-MM-DD.html#<story id>`. Both are relative, because editions sit flat in
  one folder.
- A story with followups carries an `update_note`.
- `image.src` is https. A brief's `section` names a section, and no brief
  repeats a story's URL.
- With `--memory`: every follow-up names a story memory holds, and no story
  reuses the URL of an earlier story unless it is a follow-up.
- A summary outside its importance's range (3: 90 to 150 words, 2: 50 to 90,
  1: 25 to 45) is a warning, not an error.
- A section's `local`, when present, is true or false.

## Changes from the first draft

- Added `recent_feedback` (footer "You asked for...") and `design_overrides`
  (design.yaml `overrides:`), both filled by `render.py` when missing.
- Added optional `section` on the lead, and `entities` and `key_facts` on every
  story, so memory can find the same event under a new URL.
- Added `published_display` and `generated_display`, Berlin time computed by
  `render.py`, because Jinja has no time zones and designs printed UTC.
- Added optional `local` on sections, so a design can frame the home section
  without assuming it comes first.
- Summary length now follows importance instead of one 60 to 180 word range,
  to keep the page short enough to read over breakfast.

## Page constraints (kasten HTML pane sandbox)

One self-contained HTML file, inline CSS and JS only. External resources only
over https (Google Fonts are fine, images are hotlinked). No fetch or XHR
(`connect-src 'none'`), so the page cannot write feedback anywhere. Works at
phone width (16px gutter, no horizontal scroll), light and dark through
`prefers-color-scheme`. A story without an image must still look intended.
German and English stories sit side by side.
