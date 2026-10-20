---
name: crafting-presentations
description: Deprecated, superseded by presentations:creating-presentations. Formerly used to build a multi-slide HTML presentation with slide-type templates, a deck-stage engine, and an optional two-window presenter view. Prefer the presentations plugin for all new decks.
---

# Crafting Presentations

> **Deprecated.** Superseded by `presentations:creating-presentations`, which bundles the same deck-stage engine plus a preset architecture and an integrated review loop. This copy is archived and no longer maintained; its bundled example deck was removed (the surviving layout gallery lives in the presentations plugin's `presets/default/slides/`).

Multi-slide HTML decks with deck-stage navigation, slide-type composition, and a two-window presenter mode.

## When to use this skill

Reach for `crafting-presentations` when the deck is more than two or three slides, when speaker notes will be presented live, or when the user wants a presenter-view sidecar window during a Teams, Zoom, or Meet share. For a quick one-off single-file slide deck without presenter mode, use `deprecated:crafting-html` and its `references/09-slide-deck.html` template. For theming a deck to a brand, layer `deprecated:crafting-design-systems` on top of this skill.

If you have not yet designed the deck's _content_ (audience analysis, message structure, slide-by-slide storyboard, speaker notes), invoke `deprecated:presentations` first. It produces a `deck.md` you can pass to this skill as the source brief, then `crafting-presentations` handles the HTML rendering.

## The stage

Every slide is a `<section>` inside a `<deck-stage>` custom element. The authored canvas is 1920 x 1080 (16:9). `deck-stage.js` fits the canvas to the viewport via CSS transform scaling, so the deck looks the same in a 4K display and in a Zoom share. Slides are addressed by index (1-based on the URL hash, e.g. `#3`) and by `data-screen-label` for the agenda strip.

Layout grammar:

- Outer padding 80 to 120 pixels. The empty space is part of the brand.
- 12-column grid with 32-pixel gutters as a soft guide.
- One idea per slide. If you need three, make three slides.
- Footer band on every non-title slide, with a brand wordmark left and slide number right.

## Slide-type catalog

| Type              | When to reach for it                                                                                       |
| ----------------- | ---------------------------------------------------------------------------------------------------------- |
| Title             | Cover / hero, opens the deck. Contains the deck title, subtitle, and a meta row (audience, date, version). |
| SectionDivider    | Major chapter break inside a long deck. Dark variant by default for visual rhythm.                         |
| AgendaSlide       | Multi-item list with an optional "current" highlight as the deck progresses.                               |
| ContentSlide      | Two-column layout, a lede on top and supporting points below. The workhorse content slide.                 |
| StatSlide         | One or more hero numbers with captions. Use when the number IS the message.                                |
| CapabilitiesSlide | Three or four feature cards with icon, headline, body.                                                     |
| ComparisonSlide   | Side-by-side "before / after" or "us / them" two-column compare.                                           |
| QuoteSlide        | Pull quote with attribution; clean dark background.                                                        |
| TimelineSlide     | Linear sequence with phase labels and milestones.                                                          |
| ClosingSlide      | Call to action, contact, next steps; mirrors the title slide visually.                                     |

## Composing the deck

The example slides for these types formerly bundled here now live in the presentations plugin (`presets/default/slides/`). Compose all slides in one HTML file with `<deck-stage>` wrapping them; do not move slides between the `<deck-stage>` and the page body, the deck-stage element drives scaling and navigation.

## Speaker notes

Speaker notes live in a JSON island inside the deck HTML:

```html
<script type="application/json" id="speaker-notes">
{
  "1": "Open with the value prop. Twenty seconds.",
  "2": "Set up the section: what we are about to cover."
}
</script>
```

Keys match the 1-based slide index. `presenter.js` reads this block and sends it to the presenter window over the sync channel. A slide without a notes entry shows "No notes for this slide" in presenter view. The displayed notes render a small markdown subset (headings, bold, italics, inline code, bullet and numbered lists).

Notes are editable live from the presenter window: `E` (or the Edit button) turns the notes panel into a raw-markdown textarea for the current slide. Edits autosave to localStorage per deck, survive reloads of either window, and the "Save to deck" button writes the updated JSON island back into the deck HTML file via the File System Access API (Chromium only; the picker prompts once per session, validates the chosen file contains `<deck-stage>`, and warns when the filename does not match the deck).

## Presenter mode

Open the deck in Edge, Chrome, or Arc. Keys (from the deck window):

- `P` opens the presenter window. Allow the popup once.
- `B` blacks out the audience screen. Press again to resume.
- Arrow keys, Space, Home, End, click move both windows.

Keys (from the presenter window):

- `B` blacks out the audience screen.
- `T` resets the timer.
- `E` edits the current slide's notes; `Esc` finishes editing.
- `.` or `K` blacks out the presenter view itself.

While the presenter window is open, the deck window hides its thumbnail rail and nav overlay so the shared window shows clean slides; both return when the presenter closes.

Sync uses `BroadcastChannel`, no server required. It works across `file://` pages in Chromium (they share one storage origin), which is the normal way these decks are presented. Preview iframes and presenting state are driven over `postMessage` because `file://` documents are opaque origins to each other (`contentDocument` and `window.opener.document` are null); never reach into a frame's DOM from sibling deck windows.

Sharing in Teams, Zoom, or Meet: open the deck, press `P`, then pick **Share to Window** and select the deck window only. Never **Share screen**, or the presenter notes leak. The presenter window is invisible to the audience even though it is on the same machine.

## Single-file vs multi-file output

Multi-file is the default. Keep the upstream layout: `slides/index.html` plus `slides/slides.css` plus `slides/deck-stage.js` plus `slides/presenter.js` plus `slides/presenter.html` plus `assets/*.svg`. This is the right shape for a deck that lives in a repo and benefits from editability.

Single-file is the right call when the deck must travel as one attachment (email, Teams DM, archive). Inline `slides.css`, `deck-stage.js`, `presenter.js` into the head of a single HTML file. Replace `<img src="../assets/...">` with `<svg>` markup inline (the SVGs are small text). The presenter window needs the `presenter.html` sidecar next to the deck file, so a strictly single-file deck has no presenter mode; if presenter mode matters for a deck that travels, ship the pair (deck plus `presenter.html`). No HTTP server is needed either way: `BroadcastChannel` works across `file://` pages in Chromium.

## Applying a design system

Before emitting HTML, check for an active design system and inline its overrides into the deck's style:

1. Resolve the design-system name: per-prompt override (e.g., "render with the `brand-2026` design system"), then `.workbench/config.md` `## Design system` `Name:`, then no override.
2. Locate the directory: `.workbench/design-systems/<name>/` (project scope), then `~/.claude/workbench/design-systems/<name>/` (user scope). If a name resolves but no directory is found at either scope, report the missing path to the user and emit with the bundled defaults; do not fabricate a substitute.
3. Inline `colors.css` (and `typography.css` if present) into the deck's `<head>` as a `<style>` block AFTER the bundled `colors_and_type.css` link or inline. This makes the design system's values win the cascade.
4. For any referenced component, paste `components/<name>.html` markup and scoped style into the deck slide where it belongs.
5. For any referenced image, base64-encode (`base64 -w 0 <file>`) and inline as `data:image/<type>;base64,<payload>`. SVG is text and can be inlined directly. Use relative paths only when the deck and the design system co-exist in the same git tree and the deck will not travel.

To create or edit a design system, see `deprecated:crafting-design-systems`.

## CSS variable surface

The formerly bundled token sheet and deck stylesheet declared the `:root` variables the deck reads; the surviving token sheet is the presentations plugin's `presets/default/colors.css`. Override any subset via your design system's `colors.css` and `typography.css`.

## Cross-references

- `deprecated:crafting-html` is the catch-all for non-presentation HTML artifacts and ships a simpler single-file `09-slide-deck.html` for quick one-off decks.
- `deprecated:exporting-decks-to-pptx` converts a finished deck (single-file or multi-file) into a native, editable PowerPoint file.
- `deprecated:crafting-design-systems` is the theming layer. It supplies the CSS variable overrides this skill consumes.
- `deprecated:writing-spec`, `deprecated:writing-plans`, `deprecated:brainstorming`, `deprecated:systematic-debugging`, and `research:research` are the other HTML producers in the wider plugin family, each with their own artifact shape.

## Caveats

- Decks that load icon or font CDNs (Lucide via unpkg, DM Sans via Google Fonts) break offline. Vendor those assets into the slides directory for production decks.
