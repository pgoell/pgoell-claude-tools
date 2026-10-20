---
name: visualizing-options
description: "Deprecated and retired without replacement. Formerly used when a design discussion needs visual options shown in a browser: mockups, layout comparisons, wireframes, or architecture diagrams that the user can click to choose between. Spawns a local server and renders content fragments."
---

# Visualizing Design Options

> **Deprecated.** Retired without replacement. This copy is archived and no longer maintained.

Browser-based visual companion for showing mockups, layouts, wireframes, and diagrams during a design discussion. The user opens a local URL; you write HTML content fragments to a session directory; clicks are recorded back as JSON events.

## When to Use

Decide per question, not per session. The test: would the user understand this better by seeing it than reading it?

Use the browser when the content itself is visual:

- UI mockups: wireframes, layouts, navigation structures, component designs.
- Architecture diagrams: system components, data flow, relationship maps.
- Side-by-side visual comparisons: two layouts, two color schemes.
- Design polish: look and feel, spacing, visual hierarchy.

Use the terminal otherwise: requirements, scope, conceptual A/B/C choices, tradeoff lists, technical decisions.

A question about a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual. "Which of these wizard layouts feels right?" is visual.

## Divergent Directions

When the user cannot describe what they want in words (signals: "make it look nice", "I have no visual taste", "I'll know it when I see it", repeated "I don't know" on visual questions), stop asking and show. Render 3-4 deliberately divergent directions on one screen. Each option commits to a different aesthetic pole (for example minimal, illustrated, playful, editorial); never show variations of one theme that differ only in accent color or spacing. Label each direction and state its intent in one line, so the user reacts to real spread instead of imagining alternatives.

After the user reacts, converge: take the chosen direction (or the elements they liked across directions) and iterate within-direction variations on the next screen.

## Quick Start

```bash
scripts/start-server.sh --project-dir /path/to/project
```

The script returns startup JSON with `url`, `screen_dir`, and `state_dir`. Save those values for the loop.

If you launched the server in the background and did not capture stdout, read `$STATE_DIR/server-info` to recover them.

Pass `--project-dir` so mockups persist in `.workbench/brainstorm/`. Without it, files go to `/tmp` and get cleaned up on stop. Add `.workbench/` to `.gitignore` if not already.

## The Loop

1. Check the server is alive (`$STATE_DIR/server-info` exists, `$STATE_DIR/server-stopped` does not). Restart with `start-server.sh` if it has shut down.
2. Write a new HTML file to `screen_dir` using the `Write` tool. Use semantic filenames (`platform.html`, `layout.html`); never reuse names.
3. Tell the user what is on screen and remind them of the URL. End your turn.
4. On your next turn, read `$STATE_DIR/events` for click events. Merge with the user's terminal text.
5. Iterate (write a new file with a version suffix) or advance.
6. When returning to the terminal for non-visual questions, push a waiting screen (`<p class="subtitle">Continuing in terminal...</p>`) so the browser does not show stale content.

## Cleanup

```bash
scripts/stop-server.sh $SESSION_DIR
```

Project-dir sessions persist in `.workbench/brainstorm/` for reference. Sessions writing to `/tmp` get deleted on stop.

## Reference

For the deep guide (CSS classes, content fragments vs full documents, platform-specific server start, design tips, file naming, browser events format), see `visual-companion.md` in this skill's directory.
