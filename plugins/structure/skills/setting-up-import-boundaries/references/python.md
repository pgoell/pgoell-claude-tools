# Python: import-linter

[import-linter](https://import-linter.readthedocs.io/en/stable/) reads contracts from `pyproject.toml` and checks the imports of the root package. The command is `lint-imports`; it exits non-zero when a contract breaks and prints each broken contract by name with the imports that break it.

## Install

Add it to the dev dependencies, then run it through the project's environment:

```bash
uv add --dev import-linter    # or: pip install import-linter
uv run lint-imports
```

## Contracts

Put the reason and the fix in each contract's `name`: the failure output shows it, and an agent reads it as its instruction. A module path is the import path (`mypackage.api`), and a contract covers a module's descendants too.

```toml
[tool.importlinter]
root_package = "mypackage"

[[tool.importlinter.contracts]]
name = "Layers: api calls service calls store, never upwards. Move shared code down a layer."
type = "layers"
layers = [
  "mypackage.api",
  "mypackage.service",
  "mypackage.store",
]

[[tool.importlinter.contracts]]
name = "Features stay independent. Move shared code to mypackage.service."
type = "independence"
modules = [
  "mypackage.billing",
  "mypackage.search",
]

[[tool.importlinter.contracts]]
name = "Only mypackage.store talks to the database driver. Call a store function instead."
type = "forbidden"
source_modules = [
  "mypackage.api",
  "mypackage.service",
]
forbidden_modules = [
  "psycopg",
]
```

Notes:

- **Layers.** List from highest to lowest. Siblings that may not import each other share one line, split by `|` (`"mypackage.billing | mypackage.search"`); siblings that may, by `:`. Never mix the two on one line. `containers = ["mypackage"]` with short names (`"api"`) applies the same layers inside each listed package.
- **Forbidden on an outside package** (`psycopg` above) needs `include_external_packages = true` under `[tool.importlinter]`.
- **Internals.** To keep other modules out of a package's inside, forbid its submodules from the rest: `forbidden_modules = ["mypackage.store.*"]` with every other top module as a source. Callers then use what `mypackage/store/__init__.py` exports.
- **Today's breaks.** List them under the contract with a reason, to fix later, and keep the list short:

```toml
ignore_imports = [
  # TODO(#42): move the retry helper into service
  "mypackage.store.retry -> mypackage.api.errors",
]
```

- `allow_indirect_imports = true` on a forbidden contract checks direct imports only. Leave it off unless the user asks.

## Wire it

Append to the lint task in `mise.toml`, so pre-push and CI run it wherever they already run `mise run lint`:

```toml
[tasks.lint]
run = [
  # ...existing steps stay...
  "uv run lint-imports",
]
```

If CI does not run the lint task, add a step after the checkout and tool setup: `- run: uv run lint-imports`.
