# Excludes and the fan-out baseline

All three files sit at the repo root. The scripts find them from any subdirectory and read the working-tree copy. In each, a line that starts with `#` is a comment and blank lines are skipped.

In both excludes files a line over 512 bytes, counted as written, is skipped: a longer one could cost seconds or minutes. What it would have excluded still gets reported. For a path that long, write a glob such as `deep/**`.

## `.file-size-excludes`

`check-file-size` already skips lockfiles, images, fonts, PDFs and license texts. This file adds to those defaults:

- one git glob per line, anchored at the repo root;
- `*` stays inside one folder, `**/` crosses folders;
- `[...]` is a class, as in git: write `\\[` for a plain `[`;
- the rest of a line is taken as is: no leading `/` (write `dir/**`, not `/dir/**`) and no trailing `# comment`;
- no file means the defaults only.

```text
# generated
**/generated-*.ts
# vendored
third_party/**
```

A new exclude line counts at once; a split counts for a bare run only once committed.

## `.fan-out-excludes`

Folders `check-fan-out` skips. Same glob rules except that `*`, `**` and `?` are the only special characters (`[` and `^` are plain), matched against the folder's path: `docs/log` skips that folder, `vendor/**` every folder below `vendor`, `**/fixtures` any folder named `fixtures`. Write a comment line above each glob that says why the folder is a list by design; a reviewer reads it in the diff.

```text
# one file per docs change, by design
docs/log
# vendored, not ours to group
vendor/**
```

## `.fan-out-baseline`

One line per folder over the limit: the folder's path, a space, its count. A folder fails when its count passes both the limit (7) and its line; a folder with no line fails as soon as it passes the limit.

```text
src/handlers 12
docs/how-to 9
```

`scripts/check-fan-out --update-baseline` maintains it:

- no file: writes one line for each folder over the limit today, with a header comment;
- a file exists: lowers a line to today's count, drops a line once the folder is at or under the limit (or gone, or excluded), keeps comments, and never raises or adds a line.

To accept a bigger folder, a person edits the number by hand, and the diff shows it. An agent never does that to make the check pass.

## Odd names

Both checks keep one line per name, and a line reader would lose some names. So each report, `.fan-out-baseline` and both excludes files write:

| In the name                | Written          |
| -------------------------- | ---------------- |
| backslash                  | `\\`             |
| newline, tab, CR           | `\n`, `\t`, `\r` |
| `#` that starts the path   | `\#`             |
| space that starts the path | `\s`             |

Copy the name as the report shows it. In `.fan-out-excludes`, `?` stands for one character of the name, escaped or not, and a raw tab or CR inside a name also works. In `.file-size-excludes` a shown name is still a glob, so a `*`, `?` or `[` in it needs a `\` before it. A space that ends a name is the one case a shown name does not cover, since a line loses it: write `?` for it in `.fan-out-excludes`, `\s` in `.file-size-excludes`.

An exclude written before this scheme may change meaning: in `.file-size-excludes` a glob with `\n`, `\t`, `\r` or `\s` now means those characters, and in `.fan-out-excludes` a `[...]` no longer is a class. A line that stops matching shows up in the next report.
