# Colors

Step numbers refer to the workflow in `../SKILL.md`.

## Reading colors off the source (step 1)

When an example figure is the only source of a color (chart series colors, typically), extract the embedded image and read values from its large flat fills with an exact-color histogram; solid chart areas survive compression intact while small legend swatches and thin strokes bleed. Match the sampled values against the palette already extracted, and record near misses as found instead of snapping them silently: an example figure that predates the current palette is itself a finding for the manifest.

Brand color guides print each value several ways at once, usually hex, RGB, CMYK, and Pantone. Hex is canonical for digital work; keep Pantone and print notes as comments beside the variables. Cross-check the printed hex against the printed RGB, guides carry typos, and record any mismatch in the manifest as found instead of silently correcting it.

## Contrast and chart tokens (step 2)

Check accent contrast in both directions before mapping. A brand accent often works as a graphic on white yet fails as text (a bright brand green on white can land around 2.2:1); map a darker ramp step as `--accent-ink` for accent-colored text and keep the bright value in `--accent` for graphics. Hold every text tier and the text accent at 4.5:1 or better on `--bg`, `--bg-elev`, and `--bg-subtle` in every scope.

Map the brand's chart colors onto the chart token group the contract defines (`--chart-highlight`, `--chart-context`, `--chart-grid`, `--chart-1` onward, optional `--chart-seq-*` and `--chart-div-*`), in the order the brand's charts use them. `--chart-highlight` is the story series and must clear 3:1 on the background; when the accent is lighter, point it at `--accent-ink`. Run the categorical set through a color-vision-deficiency simulation and record any pair that merges, or any color under 3:1, in the manifest.

## A color guide with no deck (steps 3 and 4)

When the source is a color guide with no deck to mine, steps 3 and 4 collapse to a single palette specimen: a real slide layout that shows the palette groups and exercises the semantic mapping in every encoded variant. It validates the mapping in a browser and gives the gallery its first entry; the structural slide set follows once real deck material exists. Record the missing pieces (typography, wordmark, slide set) as manifest gaps.
