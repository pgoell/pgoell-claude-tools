# Heimatblatt

The local paper from the Kinzig valley, grown up. Warm newsprint, a line-drawn
vignette of the Kaiserpfalz arcade and the Marienkirche towers, and a framed
"Aus der Region" block that reads as the heart of the paper. World, tech and
business sections stay plain and serious; ornament appears three times at most.

## Fonts

- Head: Zilla Slab (400 to 700, italic 500/600), a friendly slab.
- Body: Literata (optical sizes), a humanist book serif that holds up at 15 to 18px.
- Story ids: system monospace.

## Palette tokens (light / dark)

| token       | light   | dark    | use                              |
| ----------- | ------- | ------- | -------------------------------- |
| --paper     | #f5efe3 | #1c1916 | page                             |
| --paper-2   | #ede4d2 | #25211c | image placeholder                |
| --ink       | #2b2520 | #ece3d2 | text, double rules               |
| --ink-soft  | #4a4038 | #d3c7b3 | deks, source names               |
| --muted     | #7a6e62 | #9d907f | meta, credits, ids               |
| --rule      | #cfc2ab | #40382f | hairlines, column rules          |
| --accent    | #9c3b24 | #e08a68 | brick red: drop caps, links, Neu |
| --local     | #3f5a3c | #a9c39b | valley green: the regional block |
| --local-bg  | #ebe6d3 | #212219 | regional block ground            |
| --update-bg | #f3e1d2 | #33241c | "Neu:" box                       |

Also --font-head, --font-body, --grain-opacity and --photo (the CSS filter
that warms photos).

## Layout

- Lead: photo beside headline; summary under the photo, "Neu:" and earlier
  coverage beside it. Without a photo it becomes one centred 760px column.
- The section marked `local: true` is "Aus der Region": framed, green, square thumbnails,
  and the briefs for that section shown inside it as "Außerdem aus der Region".
- Other sections: feature story (photo left, text right; with no photo, the
  headline takes the left column and the text gets a drop cap) and a row of
  equal columns with hairline rules.
- A photo that fails to load removes itself and the story falls back to the
  text-only layout (tiny inline handler). Times are `published_display`,
  already in Berlin time.

## What I would tune

- Long summaries make the small columns tall; a line clamp or a "weiterlesen"
  disclosure would tighten the page, at the cost of the full-text feel.
- The emblem is drawn at 160x72; at footer size the arches nearly close up.
  A simpler mark for small sizes would help.
- The mobile ears (weather, issue) stack above the title and take space; a
  single line under the dateline might read better.
