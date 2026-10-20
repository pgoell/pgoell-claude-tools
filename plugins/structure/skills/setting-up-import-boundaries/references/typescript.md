# TypeScript: dependency-cruiser

[dependency-cruiser](https://github.com/sverweij/dependency-cruiser) checks imports against `forbidden` rules in a config file. It finds `.dependency-cruiser.js` by default; `.cjs`, `.mjs`, `.ts` and `.json` work too. Its exit code is the number of `error` violations, so `0` means pass.

## Install

```bash
npm install --save-dev dependency-cruiser
npx dependency-cruiser --init    # optional: writes a starter config to compare with
```

## Rules

Each rule has a `name`, a `comment` and a `severity`. Write the reason and the fix in `comment`: the `err-long` output prints it for each violation, and an agent reads it as its instruction. Paths are regular expressions on the file path from the repo root.

```js
// .dependency-cruiser.cjs
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      comment: "Circular import. Move the shared part into a module both can import.",
      severity: "error",
      from: {},
      to: { circular: true },
    },
    {
      name: "layers-no-upward",
      comment: "store must not import service or api. Pass what it needs in as an argument.",
      severity: "error",
      from: { path: "^src/store/" },
      to: { path: "^src/(service|api)/" },
    },
    {
      name: "features-independent",
      comment: "A feature must not import another feature. Move shared code to src/service/.",
      severity: "error",
      from: { path: "^src/features/([^/]+)/" },
      to: {
        path: "^src/features/([^/]+)/",
        pathNot: "^src/features/$1/",
      },
    },
    {
      name: "no-internals",
      comment: "Import a module through its index.ts, not its files.",
      severity: "error",
      from: { pathNot: "^src/store/" },
      to: { path: "^src/store/.+", pathNot: "^src/store/index\\.ts$" },
    },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsConfig: { fileName: "tsconfig.json" },
    tsPreCompilationDeps: true,
  },
};
```

Notes:

- `$1` in `to.pathNot` is the folder that `from.path` captured, so `features-independent` lets a feature import itself and nothing beside it.
- `tsConfig` lets it resolve the path aliases in `tsconfig.json`; without it, aliased imports go unseen.
- `tsPreCompilationDeps: true` also counts type-only imports.
- **Today's breaks.** Narrow the rule with a `pathNot` for the file and a comment line above it saying why, to fix later. Keep the list short.

## Wire it

Run it on the source folder with the `err-long` output:

```bash
npx dependency-cruiser src --config .dependency-cruiser.cjs --output-type err-long
```

Add that line to the lint task (a `lint` script in `package.json`, or the `run` list of `[tasks.lint]` in `mise.toml`), so pre-push and CI run it wherever they already run lint. If CI does not run the lint task, add it as a step after the checkout and `npm ci`.
