---
name: setting-up-import-boundaries
description: Use when the user wants to enforce which module may import which in a repo, add layer rules, keep sibling modules independent, forbid imports of internals, or set up import-linter (Python) or dependency-cruiser (TypeScript). Surveys the repo's modules, writes per-repo contracts with the user, and wires them into mise lint and CI with failure messages that say what to do.
---

# Setting Up Import Boundaries

A deep module hides its inside behind a small interface (John Ousterhout, "A Philosophy of Software Design"). Imports that reach past the interface, or run the wrong way between layers, undo that. This skill writes rules that fail lint when code breaks a boundary: import-linter contracts for Python, dependency-cruiser rules for TypeScript.

Rules belong to one repo. Write them from what this repo's modules are, with the user; never copy them from another repo or a shared config.

**Platforms.** Shell and file tools only, so it runs the same in Claude Code, Codex and Cursor.

## When NOT to invoke

- The user wants file size or folder fan-out checks: use `setting-up-the-checks`.
- The repo has one module, or no imports between its folders yet: there is no boundary to guard. Say so and stop.

## Step 1: Survey the modules

Find the language and the top modules: `pyproject.toml` and the packages under `src/` or the root for Python; `package.json`, `tsconfig.json` and the folders under `src/` for TypeScript. For each top module, note what it is for and what it imports from the others (`grep -rn '^from \|^import ' src/` or `grep -rn "from '\.\.\?/" src/`). Draw the graph for the user as a short list, `a -> b`.

## Step 2: Propose the rules

From the graph, propose one rule per boundary, each with a one-line reason the user can check:

- **Layers:** higher modules may import lower ones, never the other way (`api -> service -> store`).
- **Independence:** sibling modules never import each other (`billing` and `search`); shared code moves to a lower layer.
- **Forbidden:** one module never imports another, or no module outside a package imports its internals.

Show the imports that already break a proposed rule. For each, the user picks: fix it now, or list it as an ignored import with a comment saying why, to fix later. Write only the rules the user agrees to.

## Step 3: Write the config and wire it

- Python: [references/python.md](references/python.md) (`[tool.importlinter]` in `pyproject.toml`, run with `lint-imports`).
- TypeScript: [references/typescript.md](references/typescript.md) (`.dependency-cruiser.cjs`, run with `dependency-cruiser`).

Add the run to the lint task (`mise run lint` or the repo's equivalent) and to the CI lint job, as the reference shows. If the repo has no lint task or CI, add a `lint` task to `mise.toml` and tell the user the one command to add to CI later.

## Step 4: Check it works

Run the lint task and expect it to pass. Then break one rule on purpose (add an import a contract forbids), run it again, expect a failure that names the rule and its reason, and revert the import. Leave the changes for the user to review and commit, unless they asked you to commit.

## Self-Healing

- **`lint-imports` cannot find the package.** The root package must be importable: run it through the project's environment (`uv run lint-imports`), and check `root_package` matches the import name, not the distribution name.
- **dependency-cruiser reports nothing on a TypeScript repo.** It needs `tsConfig` in `options` to resolve path aliases; see the reference.
- **Too many failures at once.** Start with one contract, ignore today's breaks with reasons, and tighten later.
