# Presenter Mode

How the presenter runs a finished deck live. Tell the user these keys and the sharing rule when they are about to present.

Open the deck in a Chromium browser (Edge, Chrome, Arc). From the deck window, `P` opens the presenter window (allow the popup once), `B` blacks out the audience screen. From the presenter window: `B` blackout, `T` resets the timer, `E` edits the current slide's notes (`Esc` finishes), `.` or `K` blacks out the presenter view itself. Arrow keys, Space, Home, End, and clicks move both windows.

Notes are editable live from the presenter: edits autosave to localStorage per deck and survive reloads, and "Save to deck" writes the updated JSON island back into the deck HTML via the File System Access API (Chromium only). While the presenter window is open, the deck window hides its thumbnail rail and overlay so the shared window shows clean slides.

Sync uses `BroadcastChannel`, no server required, and works across `file://` pages in Chromium (they share one storage origin). Never reach into a sibling window's DOM: `file://` documents are opaque origins to each other, which is why notes and state travel over the channel and `postMessage`.

Sharing in Teams, Zoom, or Meet: open the deck, press `P`, then pick **Share to Window** and select the deck window only. Never **Share screen**, or the presenter notes leak.
