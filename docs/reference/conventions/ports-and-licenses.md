---
type: Reference
title: Ports and licenses
description: The files a port ships for each upstream license shape, and the dash substitution rules for verbatim ports.
tags: [conventions, ports, licenses, attribution]
status: stable
---

# Ports and licenses

Read this before you port code or text from an upstream repo. Reasons and history: [ports-and-licenses](/explanation/ports-and-licenses.md).

Read the upstream `LICENSE` file itself before any port. Never infer the license from CONTRIBUTING.md, DCO mentions, README badges, or summaries.

- **Upstream-port attribution.** A port from a non-MIT upstream (Apache-2.0, as in `playground`) ships `LICENSE` (this repo's MIT), `NOTICE` (per-file upstream attribution, original license, upstream commit SHA), and a plugin `README.md` with a Credits section linking the source. Drop upstream-only frontmatter such as `license:`. Fetch upstream with `gh api ...?ref=<commit-sha>` so the bytes match the SHA in `NOTICE`. Manifest `license:` says MIT (it covers the plugin's own additions; the Apache files stay Apache per `NOTICE`). Model: `plugins/playground/`.
- **Upstream-port attribution, vendored-LICENSE variant.** Or vendor the Apache-2.0 LICENSE verbatim at `plugins/<plugin>/LICENSE` and declare `"license": "Apache-2.0"` in the manifest (`terminal`). `NOTICE` still maps each file, README still has Credits, and `NOTICE` says which shape was chosen.
- **Upstream with no declared license.** Neither relicense nor refuse: vendor verbatim and state in `NOTICE` that there is no license, with the commit SHA, the author's publishing intent, and that all rights stay with the author. No live example.
- **Upstream with restricted-license upstream (use-scope restriction).** For a license that limits use (the Databricks License: "in connection with Databricks Services"), vendor it verbatim at `plugins/<plugin>/LICENSE-upstream` and ship MIT at `plugins/<plugin>/LICENSE`. `NOTICE` holds the commit SHA, the license name and its limit in one plain sentence, the dash substitution rules applied, the per-file mapping (upstream path to local path), and which files are original MIT work. README Credits names the limit. Remove cross-references to upstream skills that were not ported. Both manifests still say `"license": "MIT"`. Model: `plugins/databricks/` (commit `bf6d932`).
- **Idea adaptation ("steal like an artist") is distinct from a verbatim port.** Rewriting an upstream idea in your own words, copying no text, is original MIT work: ship MIT `LICENSE` and a README `## Inspiration` (or Credits) section naming the source and author, and no `NOTICE` or `LICENSE-upstream` (`learning`). Pasting upstream text makes it a port.
- **Verbatim ports must substitute em-dashes/en-dashes inline at port time.** Rules: (1) sentence pause `<space>U+2014<space>` becomes comma plus space; (2) labelled bullet `**name** U+2014 description` becomes colon plus space; (3) number range `<digit>U+2013<digit>` becomes a hyphen; (4) heading `## Title U+2014 Subtitle` becomes colon plus space; (5) code-block comment `# Label U+2014 Description` becomes colon plus space. Periods, semicolons, parentheses, or a split sentence also work. Record the rules applied in the plugin's `NOTICE` (see `plugins/playground/NOTICE`, `plugins/databricks/NOTICE`). The right arrow (U+2192) stays.
