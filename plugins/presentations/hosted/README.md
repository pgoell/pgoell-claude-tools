# Hosted deck editor

The deck editor from the `editing-presentations` skill as a container behind a
reverse proxy, for reviewing decks from any browser. "Send" files the feedback
as a GitHub issue; a workflow on a self-hosted runner hands that issue to a
Claude session in herdr, in the worktree the deck lives in.

```
browser → proxy with sign-in → deck-editor container → files in the worktree
                                      │ Send
                                      ▼
                         GitHub issue, label deck-feedback
                                      │ workflow, self-hosted runner
                                      ▼
                    bridge.py → herdr → Claude session in the worktree
                                      │ edits the deck
                                      ▼
                         the open browser page reloads
```

The container and the Claude session work on the same files, so nothing syncs:
the session's edits reload the page, and the screenshots the issue names are
files the session reads from disk.

## Parts

| File                               | Role                                                                                                                                                                                                                                   |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `picker.py`                        | Lists the branches of the repo, local and on origin, and the decks of the one picked, at `/__decks/`. A click opens that deck in the editor; a branch with no worktree gets one under `.worktrees/` first. One deck is open at a time. |
| `Dockerfile`, `docker-compose.yml` | Python, Chromium for the screenshots, git for the branch name. No published port.                                                                                                                                                      |
| `bridge.py`                        | Reads worktree and deck from the issue and prompts a Claude session through herdr.                                                                                                                                                     |
| `deck-feedback.yml`                | The workflow that runs `bridge.py`.                                                                                                                                                                                                    |

## Set up

1. Copy `.env.example` to `.env` and fill in a fine-grained GitHub token for the deck repo with "Issues: read and write" and "Contents: read". Create the label `deck-feedback` in that repo.
2. `docker compose -f hosted/docker-compose.yml up -d --build`, from `plugins/presentations`.
3. Point the proxy at the container. `/__decks/*` goes to port 8001, the rest to port 8000, all of it behind the sign-in. Leave `/__editor/events` uncompressed: it is an event stream, and a proxy that compresses it holds it back whole. For Caddy:

   ```
   decks.example.com {
       @compressible not path /__editor/events
       encode @compressible gzip

       handle /oauth2/* {
           reverse_proxy oauth2-proxy:4180
       }
       handle /__decks/* {
           import oauth2_auth
           reverse_proxy deck-editor:8001
       }
       @root path /
       handle @root {
           route {
               import oauth2_auth
               redir * /__decks/
           }
       }
       handle {
           import oauth2_auth
           reverse_proxy deck-editor:8000
       }
   }
   ```

4. Add a self-hosted runner to the deck repo on the machine that runs herdr, and copy `deck-feedback.yml` to `.github/workflows/` on the default branch.

## Limits

- The editor has no sign-in of its own. Whoever passes the proxy can rewrite every deck in the mounted repo.
- The picker makes a worktree for a branch on first open and never removes one. Remove it by hand when the branch is merged (`git worktree remove .worktrees/<name>`). Ignore `.worktrees/` in the deck repo.
- "Fetch origin" runs `git fetch --prune` with the token, so branches deleted on origin leave the list. Without "Contents: read" the fetch fails and the list shows origin as the checkout last saw it.
- A worktree is not updated when its branch moves on origin. Pull in it by hand.
- A branch checked out in a worktree outside the repo folder is listed and cannot be opened: the container mounts the repo folder only.
- The container renders screenshots with the fonts it has. A deck that relies on a font installed on the host shows a fallback there.
- `bridge.py` starts Claude with no flags, so the session runs in your default permission mode.
- A new session in a folder Claude does not trust yet stops at the trust question, and the prompt is lost. Trust the repo folder once by hand.
