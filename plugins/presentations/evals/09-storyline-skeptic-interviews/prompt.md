---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Write, Edit, Bash]
runs: 3
---

I'm presenting churn research to our VP of Sales next week, 20 minutes. She is convinced we lose customers on price and wants a 15% discount program. Below are my interview notes in the order I did the interviews. Save them as `source.md` in the current directory first. Work out the storyline and the slide content and write it to `deck.md`. Don't render any slides yet.

# Churn interviews, August 2026

We interviewed 8 customers who cancelled in Q2 2026. Q2 churn was 31 accounts, €1.2M in annual contract value.

**Interview 1, logistics firm, 40 seats.** Said the price went up at renewal. Later said their admin left in month 2 and nobody else knew how to set up the workflows. Used 6 of 40 seats at cancellation.

**Interview 2, retailer, 120 seats.** Moved to a competitor that was 10% cheaper. Also said "we never got the integrations running".

**Interview 3, law firm, 25 seats.** Onboarding call was scheduled 5 weeks after signing. By then the project lead had moved on. Price was "fine".

**Interview 4, insurer, 300 seats.** Cancelled because a parent company mandated another vendor. Nothing we could change.

**Interview 5, agency, 15 seats.** "Nobody showed us how to build templates." Price not mentioned.

**Interview 6, manufacturer, 60 seats.** Price was the stated reason. Usage data: 4 active users in the last 30 days.

**Interview 7, school network, 80 seats.** Onboarding took 11 weeks. Said a cheaper tool "would have had the same problem".

**Interview 8, bank, 200 seats.** Never finished the security review, so no user ever logged in. Price not mentioned.

**Usage data across all 31 Q2 churned accounts.** 24 of 31 never reached 30% seat activation in their first 90 days. Accounts that reached 30% activation in 90 days churned at 4% in the same period; accounts below it churned at 27%.

**Cost of a fix.** Two onboarding specialists cost €180k a year. Target: every new account gets its kickoff within 5 days and 30% activation within 60 days.
