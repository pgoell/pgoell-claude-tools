# What runs next

"What runs next" in `SKILL.md` holds the rule: bugs first, or the queue only grows. This page holds the order to pick the next task by, and how the brief learns.

## The order

1. A gap or fault the last task shipped, and regressions. They go first and "must hold".
2. What the last task left of its own issues.
3. Open bugs, in batches of about five related ones per PR. Group by file area so subagents can run side by side.
4. Then one feature. Then the bugs that feature filed, before the next feature.
5. Then wishes and every other open issue, whoever filed it. Only the "not now" label never runs; do not ask the user for a go on queue items.

After a task that rebuilt a data path (how the product saves, loads or moves stored data), plan one task that reviews the whole path, not the diff. On the example project the two batches after such a rebuild found five regressions in it.

## When you learn something

When you learn something, change the brief: a fault you saw twice becomes a clause in the next task line, and a fault that will come again becomes a rule in `rules.md`. Tell the user when you add a rule.
