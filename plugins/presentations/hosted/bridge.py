#!/usr/bin/env python3
"""Hand one deck feedback issue to a Claude session in herdr. Standard library only.

Run by the deck-feedback workflow on the machine that holds the worktrees, with
ISSUE_NUMBER, ISSUE_URL, ISSUE_BODY and DECK_REPO_PATH in the environment. A
Claude session already running in the issue's worktree gets the prompt;
otherwise herdr opens a workspace on the worktree and starts one. Claude must
already trust the worktree's folder, or the new session stops at that question.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path


HERDR = shutil.which("herdr") or str(Path.home() / ".local/bin/herdr")  # a runner unit has a short PATH


def herdr(*args):
    for _ in range(20):  # a new pane's shell takes a moment before it can start an agent
        reply = json.loads(subprocess.run([HERDR, *args], capture_output=True, text=True).stdout)
        if reply.get("error", {}).get("code") != "agent_pane_busy":
            break
        time.sleep(1)
    if "error" in reply:
        sys.exit(f"herdr {' '.join(args[:2])}: {reply['error']['message']}")
    return reply["result"]


number, body = os.environ["ISSUE_NUMBER"], os.environ["ISSUE_BODY"]
repo = Path(os.environ["DECK_REPO_PATH"]).resolve()
field = lambda name: re.search(rf"^{name}: `([^`\n]+)`\r?$", body, re.M).group(1)
tree, deck = Path(field("Worktree")).resolve(), field("Deck")
if not tree.is_relative_to(repo) or not (tree / ".git").exists():
    sys.exit(f"{tree} is not a worktree of {repo}")

pane = next((a["pane_id"] for a in herdr("agent", "list")["agents"] if a["agent"] == "claude" and Path(a["cwd"]) == tree), None)
if not pane:
    pane = herdr("workspace", "create", "--cwd", str(tree), "--label", f"deck: {tree.name}", "--no-focus")["root_pane"]["pane_id"]
    herdr("agent", "start", f"deck-feedback-{number}", "--kind", "claude", "--pane", pane)

herdr("agent", "prompt", pane,
      f"Deck feedback arrived as GitHub issue #{number} ({os.environ['ISSUE_URL']}) for `{deck}` in this worktree. "
      f"Read it with `gh issue view {number}`: it is a deck editor feedback prompt. Follow the "
      "presentations:editing-presentations skill: read every screenshot the issue names, then apply the comments in "
      "order. Commit, push this branch, comment on the issue with what you applied and what you left, and close it.")
print(f"issue #{number} sent to pane {pane}")
