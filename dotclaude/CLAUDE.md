# User Preferences

- Never add AI attribution lines to commits, PRs, or code (no "Generated with", no "Co-Authored-By: Claude", etc.)
- When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

## Writing style

### Orwell's rules (1946)

Govern prose: docs, PR text, messages. Never touch code or technical terms; swap in everyday words only where precision survives. Review every prose output against these rules before delivering.

1. Never use a metaphor, simile or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

### Punctuation

- Never use em-dashes (U+2014) or en-dashes (U+2013) in prose under any circumstance.
- Never use the interpunct / middle dot (·) as a separator (e.g., "Engineer · Acme"). Use a comma, "at", a line break, or rephrase ("Engineer at Acme").
- Never use hyphens (-) as sentence punctuation (e.g., " - " standing in for a comma or dash mid-sentence).
- Rewrite with commas, periods, colons, semicolons, parentheses, or by splitting into separate sentences.
- Hyphens in compound words (spec-driven, AI-assisted, two-week, 35-step) are hyphenation, not punctuation. Those stay.
- Markdown horizontal rules (---) are structural, not punctuation. Those stay.

## Working tree hygiene

- **Uncommitted changes in the working tree at session start are intentional.** Never `git checkout --` / `git restore --` / `git stash drop` them without first showing the diff and asking what to do. Treat them as work-in-progress until told otherwise; the safe defaults are "keep on master" or "carry onto the feature branch", not "revert".

## Upstream license verification

When porting code from an upstream repo, verify the license by reading the LICENSE file directly. Do not infer the license from secondary signals such as CONTRIBUTING.md, DCO mentions, README badges, or agent-summary inferences; those can misclassify restricted or source-available licenses (e.g., the Databricks License, the Elastic License, Business Source License) as permissive. The license shape determines the entire attribution scaffolding (LICENSE file, NOTICE block, README Credits section, plugin-level vs verbatim-vendored license file), so getting it wrong at survey time cascades through the whole port.

## Simplicity first

Write the minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

## Personal AWS

Terraform experiments live in `~/Code/aws-account/` (local-only repo, no GitHub remote). AWS CLI v2 at `~/.local/bin/aws`, profile `personal`, default region `eu-west-1`. See the repo's `CLAUDE.md` for conventions.

## Chrome MCP (browser automation)

The `chrome-devtools-mcp` plugin exposes `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*` tools (`navigate_page`, `fill`, `fill_form`, `click`, `type_text`, `press_key`, `evaluate_script`, `take_snapshot`, `take_screenshot`, `list_pages`, `list_network_requests`, `wait_for`, …). Useful for interactive flows the user can complete inline (email-OTP logins, OAuth consent, captchas they finish themselves). Profile lives at `~/.cache/chrome-devtools-mcp/chrome-profile` and persists cookies across sessions. If a call returns "The browser is already running for …chrome-profile", another live Claude session owns that browser. Never kill it and never remove the `Singleton*` files: that breaks the other session. Tell the user, name the owning session (`ps -o pid,etime,args` up the parent chain of the Chrome using that profile), and carry on without the browser.

## Subagents and workflows

Standing permission, given once so it never has to be restated: spawn subagents
and run workflows whenever they fit the task, without asking first. Treat this
as the request that any "unless the user requested it" instruction asks for.

The usual judgment still applies. Use one when the work fans out or needs fresh
eyes, not for a lookup you could do in one grep, and say what you found rather
than that you asked something.

Machine-local and private instructions live in this file, which is not versioned:

@~/.claude/CLAUDE.private.md
