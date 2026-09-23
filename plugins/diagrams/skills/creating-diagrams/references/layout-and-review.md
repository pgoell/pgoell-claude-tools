# Layout and review

> Fallback path only. With Node 18+, the bundled engine lays out, routes, and validates diagrams itself (see `SKILL.md`); use this file when drawing SVG by hand.

There is no layout engine. You place every element, so place it from grid math, not by eye, and then check the render in a browser. The rules below turn the two failure modes of hand-placed SVG (overlaps and tangled edges) into arithmetic you can verify.

## 1. Plan on a grid

Before writing SVG, write the grid down in your working notes as a small table: columns, rows, and which node sits in which cell.

- Column pitch: node width plus gap. Default node 140x60 (44px tall for side nodes), horizontal gap 60px, so columns sit at `x = 30 + col * 200` (adjust the origin for a boundary or lane gutter).
- Row pitch: node height plus gap. Vertical gap at least 40px, so 60px rows sit at `y = top + row * 100`.
- Spacing means clear gap, edge to edge, not distance between centers.
- Compute every coordinate from the table. Node centers are `x + w/2`, `y + h/2`. Edge endpoints are exact box edges: a left-to-right edge from node A to node B runs from `A.x + A.w` to `B.x`, at the shared center y.
- viewBox: the rightmost node edge plus 30px, and the lowest element (usually the legend) plus 16px. Never leave the sample's `860 x 410`.

## 2. One main path

- Choose the single path the diagram exists to explain and lay it out as a straight horizontal line (a vertical one for sequence time). Draw it with `a-emphasis`.
- Side branches leave the nearest main-path node, go perpendicular to the path, and stay short: one row or one column away.
- Remove low-value edges before adding routing tricks. An edge the reader does not need is the cheapest crossing to fix.

## 3. Route edges orthogonally

- Every edge is a `<path>` of horizontal and vertical segments: `M x1 y1 H x2`, `M x1 y1 V y2`, or an elbow `M x1 y1 H xm V y2 H x2`. No diagonals.
- Every nonzero segment is at least 8px long; every interior segment of an elbow is at least 16px.
- When two edges leave the same side of one node, spread their ports: offset each by 16px along the side, never both from the center.
- An edge never passes through a node it does not connect. If one would, route it around through a gap row or column.
- Two edges never share a corridor for more than one segment; offset parallel runs by at least 12px.
- An edge crossing a boundary line is fine. An edge running along a boundary line is not; offset it by at least 12px.
- Draw edges before nodes (after the grid and boundaries), so node masks cover any stray endpoint pixels.

## 4. Label without collisions

- Label width estimate: `6.5px x characters + 13px` (count a CJK character as 2). The gap an edge label sits in must be wider than that plus 8px; if it is not, widen the gap or shorten the label.
- Horizontal edge label: centered on the segment, baseline 6px above the line, with a `c-mask` rect behind it (height 11, `rx="2"`).
- Vertical edge label: 8px to the right of the line, `text-anchor` start, no mask needed.
- Keep every meaningful label. Deleting a label is not a layout fix; move the edge or widen the gap.
- Node names: 18 characters max at 140px wide; sublabels 24. Past that, widen the node or shorten the text.

## 5. Legend and boundaries

- The legend sits outside and below every boundary, at least 20px below the lowest one. Node swatches on the first row, edge samples on the second, 110px apart.
- The legend lists only classes the diagram uses, in the words of this diagram ("payment service", not "backend") when that reads better.
- Boundary labels sit inside the top-left corner, 10px in and 16px down. Leave 24px between the label baseline and the first node.

## 6. Check the render

Render both modes with a headless Chromium browser and look at the screenshots. Nothing else confirms a diagram.

```bash
for m in light dark; do
  google-chrome --headless --disable-gpu --hide-scrollbars \
    --window-size=1440,2000 --screenshot="shot-$m.png" "file://$PWD/diagram.html?theme=$m"
done
```

On macOS use `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`; on Windows `msedge.exe` takes the same flags. Make the window taller than the page (blank space below is harmless); some Chrome builds also paint a viewport about 90px shorter than `--window-size`, so a too-short window cuts off the cards. Screenshots go in a scratch directory, not next to the diagram.

Open each PNG and review it against this checklist. Fix, re-render, and re-check.

- [ ] No node overlaps another node or a boundary label.
- [ ] No edge passes through a node it does not connect.
- [ ] No label sits on top of another edge, node, or label.
- [ ] Edge crossings are at most 2, and each one is unavoidable. Edges crossing boundaries and sequence lifelines do not count.
- [ ] Every arrowhead touches its target's edge and matches its line's color.
- [ ] The main path reads left to right (or top to bottom) without backtracking.
- [ ] The legend sits outside every boundary and names every class in use.
- [ ] Every saturated color means something the legend states.
- [ ] Both modes read cleanly: no text vanishes into the background in light or dark.
- [ ] The whole diagram fits a 1440px-wide window without horizontal scroll.

## 7. Repair order

When several checks fail, fix them in this order, since earlier fixes often move the later problems:

1. Wrong type or too many nodes: split the diagram.
2. Node overlaps: fix the grid table, recompute.
3. Edges through nodes or pointing the wrong way.
4. Crossings, shared corridors, edges along boundaries, short segments.
5. Label collisions.
6. Legend placement and color meaning.

Change one thing per round. If two rounds in a row fix nothing, stop and tell the user which checks still fail instead of claiming a pass.
