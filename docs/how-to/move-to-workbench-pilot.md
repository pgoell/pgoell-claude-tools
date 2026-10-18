---
type: How-to Guide
title: Move from autopilot or copilot to workbench pilot
description: Rename the old project profile and set the Gates row so workbench 1.0.0 and later keep the behavior you had.
tags: [workbench, pilot, migration]
status: stable
---

# Move from autopilot or copilot to workbench pilot

Workbench 1.0.0 merged `autopilot` and `copilot` into one skill, `/workbench:pilot`. The old skills now sit in the `deprecated` plugin. Pilot reads its profile from `.workbench/pilot.md` and stops when that file is missing, so a project with only `.workbench/autopilot.md` needs two changes.

1. Rename the profile, at the repository root:

   ```bash
   git mv .workbench/autopilot.md .workbench/pilot.md
   ```

   If git does not track the file, use `mv`.
2. Add a `## Gates` section that matches the skill you used:

   ```markdown
   ## Gates

   Gates: none
   ```

   | You used    | Write            | Pilot then                                                                                                      |
   | ----------- | ---------------- | --------------------------------------------------------------------------------------------------------------- |
   | `autopilot` | `Gates: none`    | runs the whole flow on its own                                                                                  |
   | `copilot`   | `Gates: design`  | pauses for you to lead the brainstorm and approve the spec                                                      |
   | either      | omit the section | uses the new default, `design, slices`: pauses for the design, then after each slice for you to review its diff |

For one run, a phrase in the prompt overrides the profile: "auto mode" or "no gates" means `none`, "co mode" means `design`.

## Check it worked

Run `/workbench:pilot` with a small task. It finds `.workbench/pilot.md` and pauses only where your `Gates:` row says.

The full profile format is in [profile-schema.md](../../plugins/workbench/skills/pilot/references/profile-schema.md). See [the workbench reference page](/reference/plugins/workbench.md).
