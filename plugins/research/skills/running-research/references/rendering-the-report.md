# Rendering the report as HTML

Step 10 sends you here when the resolved format is html. You, the orchestrator, render `{OUTPUT_PATH}/report.html` from `{OUTPUT_PATH}/report.md`. Never hand this to a subagent: Claude Code refuses `report*.md` files from subagents, and the reviews passed `report.md`, so only a faithful copy of it may ship. `report.md` stays as the reviewed source; `report.html` is the deliverable.

## 1. Read the inputs

- `{OUTPUT_PATH}/report.md`, in full.
- `references/research-report-template.html` in this skill's folder, in full.
- If a design system is set, the SKILL.md section "Applying a design system" says what to read and how it changes the template's styles. Apply it now; it never changes the content rules below.

If you cannot read the template, stop here and go to section 5.

## 2. Keep the template's frame

Keep these parts of the template as they are:

- The whole `<head>`: charset, viewport and the `<style>` block (changed only by a design system).
- The page frame: `div.page`, `nav.toc` with its `div.label`, `main`, `header.report-header` with `div.eyebrow` ("Research report") and `div.meta`.
- The section pattern: `<section id="X" aria-labelledby="X-h">` with `<h2 id="X-h">`.
- The class names the styles need: `#executive-summary`, `#methodology`, `ol.sources`, `li.source-entry`, `.source-body`, `.title`, `.ref`.

Replace everything else. The template's text is sample text about rate limiting; none of it may stay, including its notes under headings (such as the line about superscript citations under Sources). Where report.md lacks a part the template shows (a date line, a methodology section, reference details beyond the link), drop that part; never fill it in. The executive summary is the first `##` section other than a Table of Contents, whatever its heading says.

## 3. Map report.md into the frame

Keep every heading, in the same order and with the same words. Add no claim, number, source or sentence that report.md does not hold, and drop none.

- **Title.** The `#` H1 of report.md goes into both `<title>` and `<h1>`.
- **Meta line.** `Date:` takes the `_Date: YYYY-MM-DD_` line of report.md. `Sources:` takes the number of entries in the references section. Delete the `Version:` span. Delete the date paragraph from the body, since the meta line now shows it.
- **Table of contents.** `nav.toc` holds one `<a href="#X">` per `##` heading of report.md, in order, with the heading's words. A `## Table of Contents` section in report.md becomes this nav and gets no section of its own.
- **Sections.** Each `##` heading opens a `<section>`. Its id `X` is the heading in lower case, with every run of other characters than a to z and 0 to 9 turned into one hyphen. Three headings get fixed ids so the template's styles apply: the executive summary gets `executive-summary`, methodology gets `methodology`, and references (or sources) gets `sources`.
- **Lower headings.** `###` becomes `<h3>` with an id built the same way; `####` becomes `<h4>`.
- **Text.** A paragraph becomes `<p>`. `**x**` becomes `<strong>`, `_x_` or `*x*` becomes `<em>`, a backticked span becomes `<code>`. A `-` or `1.` list becomes `<ul>` or `<ol>` with `<li>`, nested lists nested. A `>` quote becomes `<blockquote>`. A pipe table becomes `<table>` with its header row in `<thead>` and the rest in `<tbody>`. A fenced code block becomes `<pre><code>`. Escape `&`, `<` and `>` in text as `&amp;`, `&lt;`, `&gt;`.
- **Links and citations.** Each `[text](url)` becomes `<a href="url" rel="noopener">text</a>`, in the same place and with the same text. Keep inline citations inline; do not turn them into the template's `sup.cite` footnotes. Tags in brackets with no URL (`[author estimate]`, `[original analysis]`, `[vendor]`, `[consulting]`) stay as plain text.
- **References.** Each entry of the references list becomes `<li class="source-entry" id="src-N">` inside `ol.sources`, N counting from 1. Inside it, a `div.source-body` with `div.title` holding the entry's link and `div.ref` holding the rest of the entry (publisher, date, access date, credibility tag). Add a `<details>` quote only when report.md gives a quote for that entry.
- **Diagrams.** Delete the template's Diagrams section, its SVG and its nav link. report.md holds no diagram, and you must not invent one.
- **Dashes.** Never write U+2014 or U+2013. Where report.md has one, write `&mdash;` or `&ndash;` instead.

## 4. Write and check

Write the page to `{OUTPUT_PATH}/report.html.part`, never straight to `report.html`. Then run each check:

```bash
md=$(grep -o '](http' {OUTPUT_PATH}/report.md | wc -l)
html=$(grep -o 'href="http' {OUTPUT_PATH}/report.html.part | wc -l)
echo "$md $html"
```

`html` must be at least `md`. Fewer means a link or citation went missing.

```bash
grep -nE 'Research report template|Topic of the research report|This template demonstrates|Replace this (paragraph|section)|example\.com/[a-e]|Example [A-E]: |Version:</b>|Finding [1-3]<|Numbered entries match|Token-bucket|If the report consumed|Each finding is an' {OUTPUT_PATH}/report.html.part
```

Must print nothing. A line means template sample text is left.

```bash
grep -nP '[\x{2014}\x{2013}]' {OUTPUT_PATH}/report.html.part
```

Must print nothing.

````bash
awk '/^```/{f=!f} !f && /^## / && !/^## Table of Contents/{n++} END{print n+0}' {OUTPUT_PATH}/report.md
grep -c '<h2' {OUTPUT_PATH}/report.html.part
````

The two counts must match. The first counts the `##` headings of report.md outside code fences, without a Table of Contents heading.

When a check fails, fix the page and run every check again. When all pass, `mv {OUTPUT_PATH}/report.html.part {OUTPUT_PATH}/report.html`.

## 5. When it fails

If you cannot read the template, or a check still fails after one fix, remove the partial page with `rm -f {OUTPUT_PATH}/report.html.part`, leave no `report.html`, and keep `report.md`. Tell the user the HTML render failed, which check failed (or that the template was unreadable), and that `report.md` is the finished report.
