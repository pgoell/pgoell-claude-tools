---
type: How-to Guide
title: Set up the vercel plugin
description: Install the external vercel plugin and add what its guideline and deploy skills need.
tags: [vercel, external, setup]
status: stable
---

# Set up the vercel plugin

`vercel` is an external plugin: this marketplace points at [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) and follows its `main` branch. Claude Code only. Most of its skills need nothing beyond install.

1. Install it:

   ```
   /plugin install vercel@pgoell-claude-tools
   ```

2. Let the host reach `raw.githubusercontent.com`. `/vercel:web-design-guidelines` and `/vercel:writing-guidelines` fetch the current guideline text from there each time they run.
3. For the deploy skills, `/vercel:deploy-to-vercel` and `/vercel:vercel-cli-with-tokens`, install the Vercel CLI and log in with your Vercel account:

   ```bash
   npm install -g vercel
   vercel login
   ```

## Check it worked

```bash
vercel whoami
```

Then ask for a review, such as "check this component against the web design guidelines".

See [the vercel reference page](/reference/plugins/vercel.md).
