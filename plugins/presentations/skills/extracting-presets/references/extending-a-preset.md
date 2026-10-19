# Extending an existing preset

New slide material enters the workflow at step 3, into the existing preset directory. When a deck built with the `creating-presentations` skill produced a new slide worth keeping, this skill folds it back into the preset.

A new guidance source with no slides to mine (another portal page, an updated brand guide) re-enters at step 2 instead: merge its rules into the existing `colors.css`, `typography.css`, and `guidelines.md`, then update the manifest's sources, coverage, and gaps. Reconcile every new rule against what earlier pages already settled, and record cross-page divergences in the manifest as found, with a resolution when one page is more specific. One follow-on is easy to miss: extending a bundled preset is still a plugin change that needs the version bump from step 8 (local `.pgoell` presets need no repo change).
