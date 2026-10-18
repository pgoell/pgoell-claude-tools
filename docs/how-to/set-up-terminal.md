---
type: How-to Guide
title: Set up the terminal plugin
description: Install tmux so the tmux skill can drive interactive programs.
tags: [terminal, tmux, setup]
status: stable
---

# Set up the terminal plugin

`/terminal:tmux` runs interactive programs (REPLs, debuggers, other agents) inside tmux sessions. It needs `tmux` on Linux, macOS or WSL. Native Windows terminals are not supported; on Windows, install tmux inside WSL.

1. Install tmux:

   ```bash
   sudo apt install tmux    # Debian, Ubuntu, WSL
   brew install tmux        # macOS
   ```

## Check it worked

```bash
tmux -V
```

Then ask the agent to "start a Python REPL in tmux and evaluate 2 + 2".

See [the terminal reference page](/reference/plugins/terminal.md).
