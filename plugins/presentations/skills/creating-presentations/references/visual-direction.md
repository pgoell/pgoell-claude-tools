# Visual Direction

Choose the look of a deck before composing it. Without a concrete direction, a model draws the most probable look, and the most probable look is the one every AI deck shares. The fix is to propose several concrete directions drawn from the subject, see each one rendered, pick one, and lock it as tokens. Geometry (the canvas, type scale, gallery layouts, gates) stays fixed; only the look changes per deck.

## When to run it

- **New deck on the `default` preset:** run the full step. The five bundled voice presets (`analytical`, `keynote`, `product`, `editorial`, `workshop`) are ready-made directions: when one fits the subject, render it as a candidate next to the ones you draw from the subject, and when it wins, switch the deck to that preset instead of writing `direction.css`.
- **Client or voice preset active** (any preset other than `default`): colors and type belong to the preset. Skip palette and type; propose only the motif and the layout concept (two or three options), render them in the preset's own tokens, and pick the same way.
- **Skip entirely** when the user already fixed the look (named colors, a reference deck, "keep it plain"), when a `direction.md` already sits next to the deck, or when the task is only to review an existing deck.

## 1. Propose three or four directions

Read the subject first: the audience's industry, the materials and objects of the work, the words and documents the audience handles every day (a freight audience reads manifests and route maps; a hospital board reads ward charts and rosters). Draw each direction from that material, not from general taste.

Write each direction as a short spec:

| Field          | What to write                                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Name           | Two or three words that say where it comes from ("Route map", "Ledger", "Ward chart")                                           |
| Background     | One hex, plus the dark scope hex for structure slides                                                                           |
| Accent         | One hex and its job: the one thing it marks ("the recommended option", "our numbers in every chart")                            |
| Type pairing   | Heading and body families (or one family for both), with a reason tied to the subject; families that can be vendored            |
| Motif          | One recurring device from the subject (a grid of ledger rules, a route line, a stamp), used sparingly                           |
| Layout concept | How space is used across the deck ("claims in a wide left column, evidence right"; "full-bleed evidence, text in a lower band") |
| Avoids         | Which default look this direction steers away from                                                                              |

Always include the **quiet** direction as one of the options: the `default` preset as it ships (near-white canvas, ink text, grays, one green accent for the focus, deep blue-green structure slides). Some audiences want calm and predictable, and a consulting deck often does better restrained than striking. Its spec and what it avoids are in `presets/default/manifest.md` at the plugin root (`../../presets/default/manifest.md` from this skill).

Then run two checks on every direction except the quiet one:

- **Palette-swap test.** Imagine these colors, type, and motif on a deck about a completely different subject. If they would work just as well there, the choice is not specific enough; rewrite it from the subject.
- **Default check.** Read the spec back against the looks listed under "What this direction avoids" in the default preset manifest. A direction that lands on one of them is replaced, not tweaked.

Also check each accent hex against the background: an accent under 4.5:1 is for graphics only (bars, rules, markers), never for text, as in the default preset.

## 2. Render one sample slide each

Pick the deck's most important content slide (the one carrying the governing idea, or the first content slide) and render it once per direction with the real copy, into `.deck-review/directions/<name>.html`, each with its direction's tokens inlined after the preset's variables. Same content, same gallery layout (adjusted only by the layout concept), so the look is the only thing that differs. Screenshot each at 1920x1080 and build a side-by-side sheet (`.deck-review/directions/index.html`, the screenshots in a grid with each direction's name and one-line spec under it).

## 3. Choose

- **Interactive:** show the sheet and the specs, and let the user pick (or mix: "Ledger colors with the Route map layout").
- **Autonomous:** compare two at a time with the pairwise prompt in `review-loop.md` (fresh subagent, two calls with the order swapped). Start with the quiet direction as the incumbent; a challenger replaces it only when both calls pick the challenger. A tie keeps the incumbent. Criteria: fits the subject and audience in the deck brief, passes the palette-swap test, reads well at a glance (S8, S10), and the accent does one job (V2). Report which direction won and why.

## 4. Lock the tokens

Write the winner as two files next to the deck:

- `direction.md`: the spec table for the chosen direction, including the accent's job. Judges cite it through V2 and V3, and later edits to the deck keep to it.
- `direction.css`: `:root` overrides of the preset's semantic variables only (in the default preset `--bg`, `--bg-inverse`, `--fg`, `--fg-muted`, `--fg-subtle`, `--accent`, `--accent-ink`, `--border`, the chart tokens `--chart-highlight` and `--chart-context`, and the font stacks `--font-sans` and `--font-display`), plus any motif as a CSS class. A new accent needs a `--chart-highlight` of at least 3:1 on the background. Inline it into the deck head after the preset's `colors.css` and `typography.css`, so it wins the cascade.

Never override the type scale, spacing, or canvas tokens: the H7 floors and the gallery layouts depend on them. Vendor any webfont the direction uses (see the Caveats in `SKILL.md`), or pick families that ship with the system. After locking, every slide reads its colors and fonts from these variables; no hex values in slide markup.
