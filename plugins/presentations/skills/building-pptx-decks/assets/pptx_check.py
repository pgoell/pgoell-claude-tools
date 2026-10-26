#!/usr/bin/env python3
"""Structure and content checks for a .pptx file or unpacked directory. Standard library only.

Usage: python3 pptx_check.py <deck.pptx|dir> [--floor-pt 12]

Catches what a LibreOffice render does not: parts or links that point nowhere,
parts without a content type, repeated slide or shape ids, colors that are not
six hex digits, negative shadow offsets, chart axes PowerPoint cannot resolve,
and stacked charts with outside-end labels. Warns on text under the floor and
on leftover placeholder text. Exit 1 on any error.
"""
import argparse
import re
import sys
from xml.etree import ElementTree as ET

from pptx_tool import NS, Package, rels, root_rels, shape_texts, slide_order

LEFTOVER = re.compile(r"lorem|ipsum|\bx{3,}\b|\bTODO\b|\[insert|click to (add|edit)", re.I)


def cmd_check(a):
    pkg = Package(a.deck)
    errors, warnings = [], []
    parsed = {}
    for n in pkg.names():
        if n.endswith((".xml", ".rels")):
            try:
                parsed[n] = pkg.xml(n)
            except ET.ParseError as e:
                errors.append(f"{n}: not well-formed XML ({e})")
    ct = parsed.get("[Content_Types].xml")
    if ct is None:
        errors.append("[Content_Types].xml missing or broken")
    else:
        defaults = {d.get("Extension").lower() for d in ct.findall("ct:Default", NS)}
        overrides = {o.get("PartName").lstrip("/") for o in ct.findall("ct:Override", NS)}
        for o in sorted(overrides):
            if not pkg.has(o):
                warnings.append(f"[Content_Types].xml names missing {o} (harmless)")
        for n in pkg.names():
            if n != "[Content_Types].xml" and n not in overrides and n.rsplit(".", 1)[-1].lower() not in defaults:
                errors.append(f"{n} has no content type")
    for n in pkg.names():
        if n.endswith(".rels") and n in parsed:
            src = n.replace("_rels/", "").removesuffix(".rels")
            for rid, _, target, external in rels(pkg, src) if src else root_rels(pkg):
                if not external and not pkg.has(target):
                    errors.append(f"{n} {rid} points at missing {target}")
    ids = [i for i, _, _ in slide_order(pkg)]
    if len(ids) != len(set(ids)):
        errors.append("presentation.xml repeats a slide id")
    sizes = {}
    for i, (_, _, part) in enumerate(slide_order(pkg), 1):
        if part is None or part not in parsed:
            errors.append(f"slide {i} has no part")
            continue
        root = parsed[part]
        shape_ids = [el.get("id") for el in root.iter() if el.tag.endswith("}cNvPr")]
        if len(shape_ids) != len(set(shape_ids)):
            errors.append(f"{part}: two shapes share an id (PowerPoint repairs the file)")
        for el in root.iter(f"{{{NS['a']}}}srgbClr"):
            if not re.fullmatch(r"[0-9A-Fa-f]{6}", el.get("val", "")):
                errors.append(f"{part}: color {el.get('val')!r} is not six hex digits")
        for el in root.iter():
            if el.tag.endswith(("}outerShdw", "}innerShdw")) and any(int(el.get(k, "0")) < 0 for k in ("dist", "blurRad")):
                errors.append(f"{part}: negative shadow distance or blur")
            if el.tag.endswith("}rPr") or el.tag.endswith("}defRPr") or el.tag.endswith("}endParaRPr"):
                if el.get("sz"):
                    sizes.setdefault(int(el.get("sz")), set()).add(i)
        for kind, lines in shape_texts(root):
            for line in lines:
                if LEFTOVER.search(line):
                    warnings.append(f"slide {i}: leftover placeholder text {line[:60]!r}")
        for _, kind, target, _ in rels(pkg, part):
            if kind == "chart" and target in parsed:
                check_chart(target, parsed[target], errors)
    floor = int(a.floor_pt * 100)
    for sz in sorted(sizes):
        if sz < floor:
            warnings.append(f"text at {sz / 100:g} pt on slides {sorted(sizes[sz])}, under the {a.floor_pt:g} pt floor")
    print(f"{len(ids)} slides; text sizes (pt): " + ", ".join(f"{s / 100:g}" for s in sorted(sizes)))
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    print("check passed" if not errors else f"check failed: {len(errors)} errors")
    sys.exit(1 if errors else 0)


def check_chart(name, root, errors):
    declared = {el.find("c:axId", NS).get("val") for tag in ("valAx", "catAx", "dateAx", "serAx") for el in root.iter(f"{{{NS['c']}}}{tag}")}
    plot = root.find("c:chart/c:plotArea", NS)
    for group in plot if plot is not None else []:
        if group.tag.endswith("Chart"):
            # The first two ids are the category and value axes; a third (series
            # axis) may legitimately stay undeclared.
            for ax in group.findall("c:axId", NS)[:2]:
                if ax.get("val") not in declared:
                    errors.append(f"{name}: series axis {ax.get('val')} is never declared (PowerPoint drops the chart)")
            grouping = group.find("c:grouping", NS)
            if grouping is not None and grouping.get("val") in ("stacked", "percentStacked"):
                for pos in group.iter(f"{{{NS['c']}}}dLblPos"):
                    if pos.get("val") == "outEnd":
                        errors.append(f"{name}: stacked chart with labels outside the end (PowerPoint refuses it)")


def main():
    ap = argparse.ArgumentParser(description="Structure and content checks for a .pptx")
    ap.add_argument("deck")
    ap.add_argument("--floor-pt", type=float, default=12)
    cmd_check(ap.parse_args())


if __name__ == "__main__":
    main()
