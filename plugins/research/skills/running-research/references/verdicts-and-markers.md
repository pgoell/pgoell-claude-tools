# Verdicts and markers

The orchestrator of `research:running-research` reads this file to parse reviewer verdicts, researcher markers and claim checker results.

## Verdict Parsing

Both reviewers return verdicts in this format:

```
VERDICT: PASS | ISSUES
ISSUES:
  - id: <stable-id>
    severity: critical | minor
    category: <category>
    description: <one line>
    location: <pointer>
SUMMARY: <text>
```

A verdict of PASS with critical issues is malformed; re-dispatch the reviewer once with a format reminder. Stable ids enable stall detection: same id set in consecutive reviews means surface to user.

Only the synthesis reviewer writes a `REFETCH:` block, after SUMMARY in `synthesis-review-{N}.md`. Its response stays the verdict line plus the issue id list.

```
REFETCH:
  - url: <URL>
    claim: <claim as synthesis.md states it>
    mark: confirmed | rejected | unresolved
    quote: "<short quote from the page>" (unresolved: the reason instead)
```

## Verification Markers

These words are fixed. Every prompt that writes or reads them uses these spellings and no others.

- `ARTIFACT-VERIFIED <sha256>`: last line of a researcher's response; the file is complete.
- `ARTIFACT-MISSING <reason>`: last line of a researcher's response; the file is absent or partial.
- `REFETCH:`: the block in `synthesis-review-{N}.md` that lists refetched URLs.
- `CLAIM-CHECK: REFUTED | UPHELD | UNCLEAR`: last line of a claim checker's response, after its `quote:` and `url:` lines. Two or more `REFUTED` make the claim a critical `source-quality` issue, id `claim-check-<claim-slug>`.
- `SPLIT`, `SKIPPED-CONFIRMED`, `NOT-CHECKED`: outcomes in `claim-checks.md` beside those three words; `references/claim-check.md` defines them.
- `confirmed`, `rejected`, `unresolved`: the mark per refetched URL. A `rejected` claim is a critical `source-quality` issue; an `unresolved` one is minor.
