# spycner-tools

A personal Claude Code plugin marketplace.

## Plugins

### atlassian

Jira and Confluence skills for the Atlassian suite — search, create, update, and manage work items and pages.

**Skills:**
- `/spycner-tools:jira` — Search issues, create/update tickets, transition status, add comments, manage sprints
- `/spycner-tools:confluence` — Search pages, read documentation, create/update pages, browse spaces

### google-workspace

Gmail and Calendar skills for Google Workspace — powered by the `gws` CLI.

**Skills:**
- `/spycner-tools:gmail` — Search, read, send, and manage Gmail messages, drafts, labels, and filters
- `/spycner-tools:calendar` — View agenda, create and manage events, check availability, manage calendars

### research

Comprehensive web research with multi-perspective analysis, or optimized prompt generation for external AI tools.

**Skills:**
- `/spycner-tools:research` — Research intake, refinement, and routing. Orchestrates a multi-agent pipeline (planner, researcher, writer) with independent review gates for quality assurance, or generates optimized prompts for external AI tools (OpenAI, Gemini, Perplexity).

## Installation

```
/plugin marketplace add Spycner/spycner-tools
/plugin install atlassian@spycner-tools
/plugin install google-workspace@spycner-tools
/plugin install research@spycner-tools
```

## Setup

### Atlassian

The plugin supports two authentication paths:

**Option 1 — Atlassian CLI (recommended):**
```bash
brew install atlassian/tap/acli
acli auth login
```

**Option 2 — API token (for curl fallback):**

Generate a token at https://id.atlassian.com/manage/api-tokens, then set:

```bash
export ATLASSIAN_DOMAIN="your-domain"    # e.g. mycompany (for mycompany.atlassian.net)
export ATLASSIAN_EMAIL="you@company.com"
export ATLASSIAN_API_TOKEN="your-token"
```

### Google Workspace

Install and authenticate the `gws` CLI:

```bash
npm i -g @anthropic-ai/gws
gws auth login -s gmail,calendar
```

For full setup instructions, see: https://github.com/googleworkspace/cli

### Research Plugin

No authentication required. The research plugin uses WebSearch and WebFetch which work out of the box.
