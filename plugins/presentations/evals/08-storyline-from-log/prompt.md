---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

I need a 15-minute deck for our CFO and the head of data about our warehouse bill. Below is the investigation log my team kept, in the order we worked. Save it as `source.md` in the current directory first. Work out the storyline and the slide content and write it to `deck.md`. Don't render any slides yet.

# Warehouse cost investigation log

**Week 1.** Pulled 12 months of warehouse invoices. Spend rose from €38k in October 2025 to €96k in September 2026, €742k over the 12 months. Finance flagged it in the Q2 review.

**Week 2.** Checked storage. Storage is €6k a month and flat. Not the driver.

**Week 3.** Tagged compute by team. Marketing analytics is 21% of compute, finance reporting 14%, data science 9%. 56% has no owner tag.

**Week 4.** Traced the untagged compute to scheduled jobs. 214 scheduled jobs run every 15 minutes. Most were set up in 2025 during the dashboard migration.

**Week 5.** Matched jobs to dashboards. 147 of the 214 jobs refresh 3 dashboards: "Sales pulse", "Ops live", and "Exec overview v1". Those 3 dashboards had 0 views in the last 90 days. They were replaced by "Exec overview v2" in March 2026.

**Week 6.** Ran the numbers. The 147 jobs cost €34k a month, €410k a year at the current rate. Switched them off in the staging copy for a week: no alerts, no user complaints, and v2 still loads in 2 seconds.

**Open points.** We need sign-off from the head of data to delete the jobs in production, because the dashboard owners have left the company. Finance wants a monthly owner-tag report so this does not happen again. Tagging all jobs takes one engineer about 3 weeks.
