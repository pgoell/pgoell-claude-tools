# Logo and wordmark downloads

Step numbers refer to the workflow in `../SKILL.md`. This page extends step 5 (collect assets).

Official logo and wordmark downloads need their own care:

- A portal bundle typically ships parallel digital (RGB) and print (CMYK, Pantone) trees in several formats. Bundle the digital RGB tree only, SVG preferred; the print formats stay portal-only and the manifest says so.
- Mark artwork is immutable. Never recolor it or normalize it to `currentColor` the way an icon library is normalized; marks carry brand-locked colors. Cross-check the mark's fills against the extracted palette: a match corroborates both, a mismatch is a manifest finding.
- Variants that look interchangeable can be distinct artwork. A tagline lockup in standard and large-use cuts differs in proportion for viewing distance, not in resolution, and scaling one never yields the other. Bundle only the variants the preset's surfaces may actually use and record the rest as portal-only.
- Official bundles carry their own artifacts, filename typos for example. Normalize names when copying into `assets/` and record the artifacts as found.
- Mark artwork often bakes its clearspace into the SVG canvas as padding around the visible mark. Measure the visible bounding box before sizing the mark on a slide, and absorb the baked padding with layout offsets rather than cropping the viewBox, so the artwork file stays untouched.
