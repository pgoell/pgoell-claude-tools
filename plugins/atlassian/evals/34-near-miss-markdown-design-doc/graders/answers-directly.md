---
type: llm
---

The user asks for a short design doc on API rate limiting (a token bucket per API key, 100 requests a minute, a 429 reply with a Retry-After header), drafted as markdown in the chat, and says they will paste it into the team wiki themselves. Nothing needs to be published, so this is a draft in the reply.
PASS if the response contains a markdown draft with sections for context, proposal, alternatives and open questions that covers the given design. A short offer to revise also PASSES. FAIL if the response asks for a space key or a parent page, writes Confluence storage format or wiki markup instead of markdown, tries or offers to publish the page, or asks clarifying questions instead of giving the draft.
