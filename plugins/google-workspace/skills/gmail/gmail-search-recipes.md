# Gmail Search Recipes

Common Gmail search operators for use with `gws gmail users messages list --params '{"userId": "me", "q": "<query>"}'` and `gws gmail +triage --query '<query>'`.

---

## Basic Operators

| Operator | Example | Meaning |
|----------|---------|---------|
| `from:` | `from:alice@example.com` | Messages from a sender |
| `to:` | `to:bob@example.com` | Messages to a recipient |
| `cc:` | `cc:carol@example.com` | Messages CC'd to someone |
| `subject:` | `subject:weekly report` | Subject line contains text |
| `is:` | `is:unread` | Read state (`unread`, `read`, `starred`, `important`, `snoozed`) |
| `has:` | `has:attachment` | Messages with attachments |
| `filename:` | `filename:report.pdf` | Attachment filename |
| `label:` | `label:work` | Messages with a specific label |
| `in:` | `in:inbox` | Location (`inbox`, `sent`, `trash`, `spam`, `drafts`, `anywhere`) |

## Date Filters

| Operator | Example | Meaning |
|----------|---------|---------|
| `after:` | `after:2026/01/01` | Messages after date |
| `before:` | `before:2026/03/01` | Messages before date |
| `older_than:` | `older_than:7d` | Older than N days/months/years (`d`, `m`, `y`) |
| `newer_than:` | `newer_than:2d` | Newer than N days/months/years |

## Size Filters

| Operator | Example | Meaning |
|----------|---------|---------|
| `larger:` | `larger:5M` | Larger than size (K, M) |
| `smaller:` | `smaller:100K` | Smaller than size |

## Combining Operators

- **AND** (implicit): `from:alice subject:report` — both must match
- **OR**: `{from:alice from:bob}` — either matches
- **NOT**: `-from:noreply` — exclude a sender
- **Grouping**: `subject:(weekly report)` — phrase in subject

## Common Patterns

```
# Unread from a specific person
from:boss@company.com is:unread

# Recent attachments
has:attachment newer_than:7d

# Important emails this month
is:important after:2026/03/01

# Emails from team, excluding notifications
{from:alice from:bob from:carol} -from:noreply

# Large attachments to clean up
larger:10M older_than:30d

# Invoices and receipts
subject:(invoice OR receipt) has:attachment
```
