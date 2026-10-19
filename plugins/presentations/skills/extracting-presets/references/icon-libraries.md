# Icon libraries

Step numbers refer to the workflow in `../SKILL.md`.

A PPTX icon library extracts into the preset's `icons/` member (shape and index format in the contract). The workflow differs enough from slide extraction to have its own recipe:

- Vector art hides in two storages, so inventory both before writing any code: embedded SVG media (`asvg:svgBlip` relationship references resolving to `ppt/media/*.svg`, copy the files directly) and native freeform shapes (`a:custGeom` paths that need conversion). A grep count of `svgBlip` versus `custGeom` per slide sizes the work in seconds.
- Before building a custGeom converter, scan the whole file for the drawing features actually used: path command types, preset geometries, line properties, and where fills come from. Icon suites are typically simple (`moveTo`, `lnTo`, `cubicBezTo`, `close`, with circles exported as beziers, so no arc math), fills resolve through the shape's own `solidFill`, then the inherited group fill, then the theme scheme in `theme1.xml`, and paths render with `fill-rule="evenodd"` so ring shapes stay donuts. Scaling the converter to the observed feature set keeps it small.
- Expect generic shape names ("Graphic 4"); searchable metadata must be assembled instead: slide titles become categories, keyword text boxes tag icons by spatial association, and per-icon names are assigned by visual inspection of rendered contact sheets (fan out vision subagents at scale, have them write JSON to disk rather than chat, and validate full id coverage before merging).
- Normalize an icon to `currentColor` only when it is provably monochrome, and check `stroke` as well as `fill`; keep genuinely multicolor icons as found and record their fixed colors in the index.
- QA gates before the library lands: XML-parse every output (official files carry corruption, such as stray trailing bytes), rasterize thumbnails and eyeball sample sheets, flag bounding-box aspect-ratio outliers (they expose mis-grouped shapes and sliver artifacts), and dedupe visually identical icons with a perceptual hash, keeping the merged duplicates' tags as aliases.
- Record in the manifest: that names are extraction-assigned search aids rather than official nomenclature, any source-file artifacts found, and any referenced sets that stay portal-only.
