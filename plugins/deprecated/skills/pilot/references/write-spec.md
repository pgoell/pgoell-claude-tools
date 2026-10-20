# Pilot Step 3: Write the spec (large lane)

Then, following the guidance of `deprecated:writing-spec` (or the profile's replacement):

- Use the design converged on in step 2 (the human-driven brainstorm, or, without the `design` gate, the decision doc).
- Path and format: as writing-spec resolves them, by `config-schema.md` `## Resolution order` (`don't commit` included).
- The skill runs its self-review subagent and its user approval gate. **With the `design` gate active,** this is a real human gate: present the spec and WAIT for the user's approval; do not answer it yourself. If the user requests changes, apply them and re-run the self-review before proceeding. **Without the `design` gate,** self-answer the approval gate using the decision doc as the basis.
- Commit: `docs: add <topic> design spec`, unless `<paths.specs>` is `don't commit`.

If `Hooks.post_spec` is defined in the profile, run it now with `{{spec_path}}` substituted to the spec path.

With the `design` gate active, once the user approves the spec, proceed autonomously through the remaining steps.
