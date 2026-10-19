# Plain git hooks, without lefthook

Git runs hooks from the repo top, so `scripts/check-file-size` resolves there. The templates:

- `assets/pre-commit` sizes the staged files: `git diff --cached --name-only -z --diff-filter=d | xargs -0 -r scripts/check-file-size`.
- `assets/pre-push` runs the bare check on every tracked file at HEAD.

Find your case from step 1, and handle each hook (`pre-commit`, `pre-push`) on its own.

## Case A: `core.hooksPath` is already set

Another tool owns the hooks (Husky, for example). Do not change the config. In the folder it names:

- If `<folder>/<hook>` exists, append the call line (below).
- If not, copy the template there: `cp "${CLAUDE_SKILL_DIR}/assets/<hook>" <folder>/<hook>` and `chmod 755 <folder>/<hook>`.

**Husky v9 sets the path to `.husky/_`.** That folder is gitignored and Husky writes it anew, and its stubs run the versioned hooks in `.husky/`. So never edit anything inside `.husky/_`. Append the call line to `.husky/<hook>` instead; if that file is missing, create it with just the call line and `chmod 755 .husky/<hook>`. Husky runs it with `sh -e`, so no shebang is needed.

## Case B: no `core.hooksPath`, but a real `.git/hooks/<hook>`

A real hook is one that does not end in `.sample`. Setting `core.hooksPath` turns off every hook in `.git/hooks`, so move the old hook into the versioned folder first, then append:

```bash
mkdir -p .githooks
cp .git/hooks/pre-commit .githooks/pre-commit
chmod 755 .githooks/pre-commit
```

Append the call line to `.githooks/pre-commit`, and do the same for `pre-push` if it exists. A hook with no old copy gets the template, as in case C. Then run `git config core.hooksPath .githooks`. Tell the user the old hook now lives in `.githooks/`, versioned.

## Case C: no hooks at all

```bash
mkdir -p .githooks
cp "${CLAUDE_SKILL_DIR}/assets/pre-commit" .githooks/pre-commit
cp "${CLAUDE_SKILL_DIR}/assets/pre-push" .githooks/pre-push
chmod 755 .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks
```

If `.githooks/<hook>` already exists, append the call line instead of copying over it.

## The call lines

When you append to a hook, add the line before any final `exit`, and keep `|| exit 1`: a hook without `set -e` would otherwise ignore the failure and let the commit through.

pre-commit:

```sh
git diff --cached --name-only -z --diff-filter=d | xargs -0 -r scripts/check-file-size || exit 1
```

pre-push:

```sh
scripts/check-file-size || exit 1
```

## Each clone

`core.hooksPath` lives in `.git/config`, which git does not version. Every clone must run this once:

```bash
git config core.hooksPath .githooks
```

Add that line to the repo's setup script, or to the README's setup section. If the repo has neither, add a short section to the README (create `README.md` if there is none):

````markdown
## Setup

After you clone, turn on the repo's git hooks once:

```bash
git config core.hooksPath .githooks
```
````

Tell the user where you put it. Case A needs no such line: the other tool already sets the path.
