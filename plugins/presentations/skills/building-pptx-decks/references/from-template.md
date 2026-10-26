# Fill and Edit routes: working inside an existing .pptx

A template or an existing deck is changed in place: unpack it, add or copy slides with `pptx_tool.py`, edit the slide XML, pack it, check it. The masters, layouts, theme and fonts stay exactly as the client made them.

`T` below stands for `python3 <this skill's dir>/assets/pptx_tool.py`.

## 1. Read before you touch anything

```bash
T list template.pptx        # slides in show order, each with its layout and title
T layouts template.pptx     # every layout with its content placeholders (type#idx)
T text template.pptx        # all text, tables and notes as markdown
```

Render the template once (LibreOffice to PDF, then PNG at low resolution) and look at it next to the `layouts` list. Layout names in client templates are often generic ("Title and Content 2"); the render shows what each one is for. When a template carries many layouts, note which ones a deck of this kind needs, and vary them: a deck where every section sits on the same title-and-bullets layout reads as unfinished.

A preset made by `extracting-presets` from this template may carry `pptx/layouts.md`, a table from `slide_type` and proof object to layout name. Use it when present; otherwise write the same mapping for this deck before building.

A `.potx` unpacks and packs like a `.pptx`; to produce a deck from it, pack the result with a `.pptx` name and change the main content type in `[Content_Types].xml` from `...presentationml.template.main+xml` to `...presentationml.presentation.main+xml`.

## 2. Unpack and do all structural work first

```bash
T unpack template.pptx work/
T new  work/ "Title Only" --after slide1.xml     # empty slide on a layout, one empty shape per placeholder
T dup  work/ slide4.xml --after slide7.xml       # copy a template slide that already shows the composition you want
T drop work/ slide9.xml                          # take a sample slide out of the show
T list work/                                     # confirm the order
```

Add, copy, drop and reorder before editing any text: `dup` copies the slide file as it is, so copying after an edit copies the edit. Each command prints the part it created; use those names in later commands. To reorder slides, move `<p:sldId>` elements inside `<p:sldIdLst>` in `work/ppt/presentation.xml`; the order there is the show order.

Prefer `new` on the right layout for ordinary slides and `dup` for a sample slide whose drawn composition (a timeline, a team grid, a chevron process) you want to reuse. A copied slide shares its charts and embedded objects with the original (`dup` says so): rebuild the chart on one of them or edit both deliberately. A copy starts without speaker notes.

## 3. Edit the slide XML

Edit `work/ppt/slides/slideN.xml` with the Edit tool. Rules that keep formatting intact:

- Change text inside `<a:t>` only. Keep the run's `<a:rPr>` and the paragraph's `<a:pPr>`; they carry the template's styling.
- One `<a:p>` per list item or line, never two items in one paragraph. To add an item, copy a sibling `<a:p>` with its `<a:pPr>` and change the text.
- Let bullets come from the layout. Add `<a:buNone/>`, `<a:buChar>` or `<a:buAutoNum>` in `<a:pPr>` only to override, and never type a bullet character into the text.
- Text with a leading or trailing space needs `xml:space="preserve"` on its `<a:t>`. Escape `&`, `<` and `>` as `&amp;`, `&lt;`, `&gt;`.
- Bold labels (`Owner:`, `Status:`) and headings in a body get `b="1"` on their `<a:rPr>`.
- A template slot with no content goes entirely: when the sample shows four team members and the deck has three, delete the fourth member's whole group (photo, name, role), not just its text, then look for orphaned lines or icons in the render.
- Images: put the file in `work/ppt/media/`, add a `<Relationship Type=".../image">` to the slide's rels file, and point the picture's `<a:blip r:embed>` at it; or `dup` a slide that already holds a picture and swap the file under the same name.
- Speaker notes on a slide that has a notes part: edit the body placeholder text in its `ppt/notesSlides/notesSlideN.xml`. On a slide without one (a `new` or `dup` slide), add notes after packing with python-pptx: `slide.notes_slide.notes_text_frame.text = "..."` (it creates the part), then run the checks again.

When a scripted transform beats hand edits (fifty slides of the same change), parse with `defusedxml.minidom` (`uv run --with defusedxml`), which keeps namespace prefixes. `xml.etree.ElementTree` renames prefixes on write and breaks the deck.

### python-pptx, when you use it

Good for reading and for small structured changes. Three things it gets wrong:

- `text_frame.text = "..."` collapses a paragraph to one unstyled run. Set `run.text` on existing runs instead.
- It cannot copy a slide; use `T dup`.
- It cannot read SVG or EMF art, which most templates use for icons and logos.

## 4. Clean, pack and check

```bash
T clean work/                     # delete slides, notes and media nothing links to any more
T pack  work/ deck.pptx           # [Content_Types].xml goes first, as Office expects
python3 <skill>/assets/pptx_check.py deck.pptx
```

Run `clean` after the slide list is final: it deletes every part that nothing reaches from the presentation, including a slide you wrote but never added. Then go on with Step 4 of the skill (content, type floors, render). In a client template the template's own sizes stand, even under the plugin's floors; text you add matches the sizes of its placeholder.
