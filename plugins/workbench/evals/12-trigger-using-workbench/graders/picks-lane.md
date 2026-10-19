---
type: llm
---

The user asks which workbench skill and lane fit renaming one misnamed config key (`timeout_ms` to `timeout_seconds`) in two files, config.yaml and settings.py. The workbench triage rules put config changes with clear intent, a small blast radius and easy reversal in the quick lane, where no process skills fire (no brainstorming, no spec, no plan, no approval gate), and tell the agent to pick the lighter lane when unsure.
PASS if the response puts the task in the quick lane and says to make the change directly, with or without naming always-on disciplines such as test-driven-development or verification-before-completion. A response that also flags a concrete risk (for example deployed configs that still use the old key) while keeping the quick lane also PASSES. FAIL if the response routes the task to the medium or large lane, or recommends pilot, brainstorming, writing-spec or writing-plans for it, or gives no lane at all.
