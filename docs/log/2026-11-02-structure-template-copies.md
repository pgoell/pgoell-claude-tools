# 2026-11-02: Fix

structure 0.2.15, no issue. The `pgoell/project-template` Copier template holds byte-identical copies of `check-file-size`, `check-fan-out` and `structure-hook` in its `template/scripts`, but the docs named only the last two. They now name all three. The plugin README also says that `check-file-size`, unlike the other two, does not start with the canonical-copy comment. Pages changed: `reference/plugins/structure.md`.
