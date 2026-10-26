#!/usr/bin/env python3
"""Package bookkeeping for editing an existing .pptx by hand. Standard library only.

Adding, copying or removing a slide touches four places at once (the slide
part, its rels, the presentation's slide list and rels, [Content_Types].xml).
This tool does that bookkeeping; the agent edits slide content only.
Checks live in pptx_check.py beside it.

Usage (python3 pptx_tool.py <command> ...):
  unpack  <deck.pptx> <dir>               extract the package
  pack    <dir> <out.pptx>                zip it back, [Content_Types].xml first
  list    <deck.pptx|dir>                 slides in show order, with layout and title
  layouts <deck.pptx|dir>                 every slide layout, with its placeholders
  text    <deck.pptx|dir>                 every slide's text, tables and notes as markdown
  dup     <dir> <slideN.xml> [--after slideM.xml]   copy a slide, notes left out
  new     <dir> <layout name> [--after slideM.xml]  empty slide on a layout
  drop    <dir> <slideN.xml>              take a slide out of the show; run clean after
  clean   <dir>                           delete parts nothing links to any more
  theme   <deck.pptx|dir> <theme.json>    write theme colors, fonts and name in place
          theme.json: {"name": "...", "head": "Font", "body": "Font",
                       "colors": {"dk1": "0B1F33", "lt1": "FFFFFF", ... "folHlink": "..."}}

Mutating commands edit XML as text, never through a parser round trip, so
untouched parts stay byte for byte.
"""
import argparse
import posixpath
import re
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

NS = {
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "c": "http://schemas.openxmlformats.org/drawingml/2006/chart",
    "rel": "http://schemas.openxmlformats.org/package/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
}
REL_BASE = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/"
SLIDE_CT = "application/vnd.openxmlformats-officedocument.presentationml.slide+xml"
# Placeholder types a new slide leaves to the layout (date, footer, slide number).
CHROME_PH = {"dt", "ftr", "sldNum", "hdr"}


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(2)


class Package:
    """Read access to a .pptx file or an unpacked directory, by part name."""

    def __init__(self, path):
        self.path = Path(path)
        self.is_dir = self.path.is_dir()
        if self.is_dir:
            self._names = sorted(
                str(p.relative_to(self.path)).replace("\\", "/")
                for p in self.path.rglob("*")
                if p.is_file()
            )
        elif zipfile.is_zipfile(self.path):
            self._zip = zipfile.ZipFile(self.path)
            self._names = [n for n in self._zip.namelist() if not n.endswith("/")]
        else:
            die(f"{path} is neither a directory nor a .pptx")

    def names(self):
        return list(self._names)

    def has(self, name):
        return name in self._names

    def read(self, name):
        if self.is_dir:
            return (self.path / name).read_bytes()
        return self._zip.read(name)

    def text(self, name):
        return self.read(name).decode("utf-8")

    def write(self, name, data):
        if not self.is_dir:
            die("this command needs an unpacked directory (run unpack first)")
        target = self.path / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(data, encoding="utf-8") if isinstance(data, str) else target.write_bytes(data)
        if name not in self._names:
            self._names.append(name)

    def delete(self, name):
        (self.path / name).unlink()
        self._names.remove(name)

    def xml(self, name):
        return ET.fromstring(self.read(name))


def rels_name(part):
    d, f = posixpath.split(part)
    return posixpath.join(d, "_rels", f + ".rels")


def rels(pkg, part):
    """Relationships of a part: list of (id, type suffix, resolved target, external)."""
    name = rels_name(part)
    if not pkg.has(name):
        return []
    out = []
    base = posixpath.dirname(part)
    for el in pkg.xml(name).findall("rel:Relationship", NS):
        external = el.get("TargetMode") == "External"
        target = el.get("Target")
        if not external:
            target = target.lstrip("/") if target.startswith("/") else posixpath.normpath(posixpath.join(base, target))
        out.append((el.get("Id"), el.get("Type").rsplit("/", 1)[-1], target, external))
    return out


def slide_order(pkg):
    """Slides in show order: list of (sldId element text, rId, part name)."""
    pres = "ppt/presentation.xml"
    by_id = {rid: target for rid, _, target, _ in rels(pkg, pres)}
    out = []
    for el in pkg.xml(pres).findall("p:sldIdLst/p:sldId", NS):
        rid = el.get(f"{{{NS['r']}}}id")
        out.append((el.get("id"), rid, by_id.get(rid)))
    return out


def layout_name(pkg, part):
    try:
        cs = pkg.xml(part).find("p:cSld", NS)
        return cs.get("name", "") if cs is not None else ""
    except (KeyError, FileNotFoundError):
        return "?"


def slide_layout(pkg, slide):
    for _, kind, target, _ in rels(pkg, slide):
        if kind == "slideLayout":
            return target
    return None


def para_text(p):
    return "".join(t.text or "" for t in p.iter(f"{{{NS['a']}}}t"))


def shape_texts(root):
    """Yield (kind, text) for every text body and table in a slide tree."""
    for sp in root.iter():
        tag = sp.tag.rsplit("}", 1)[-1]
        if tag == "txBody":
            lines = [para_text(p) for p in sp.findall("a:p", NS)]
            lines = [line for line in lines if line.strip()]
            if lines:
                yield "text", lines
        elif tag == "tbl":
            rows = []
            for tr in sp.findall("a:tr", NS):
                cells = [" ".join(para_text(p) for p in tc.iter(f"{{{NS['a']}}}p")).strip() for tc in tr.findall("a:tc", NS)]
                rows.append("| " + " | ".join(cells) + " |")
            yield "table", rows


def title_of(root):
    for sp in root.iter(f"{{{NS['p']}}}sp"):
        ph = sp.find("p:nvSpPr/p:nvPr/p:ph", NS)
        if ph is not None and ph.get("type") in ("title", "ctrTitle"):
            return " ".join(para_text(p) for p in sp.iter(f"{{{NS['a']}}}p")).strip()
    return ""


def cmd_unpack(a):
    out = Path(a.dir)
    if out.exists() and any(out.iterdir()):
        die(f"{out} is not empty")
    with zipfile.ZipFile(a.deck) as z:
        z.extractall(out)
    print(f"unpacked {a.deck} into {out}")


def cmd_pack(a):
    src = Path(a.dir)
    files = sorted(p for p in src.rglob("*") if p.is_file() and p.name != ".DS_Store")
    first = [p for p in files if p.name == "[Content_Types].xml"]
    if not first:
        die("no [Content_Types].xml in the directory")
    with zipfile.ZipFile(a.out, "w", zipfile.ZIP_DEFLATED) as z:
        for p in first + [p for p in files if p not in first]:
            z.write(p, str(p.relative_to(src)).replace("\\", "/"))
    print(f"wrote {a.out}")


def cmd_list(a):
    pkg = Package(a.deck)
    for i, (_, _, part) in enumerate(slide_order(pkg), 1):
        lay = slide_layout(pkg, part)
        print(f"{i:>3}  {posixpath.basename(part):<14} layout={layout_name(pkg, lay) if lay else '-':<28} {title_of(pkg.xml(part))}")


def cmd_layouts(a):
    pkg = Package(a.deck)
    for name in sorted(n for n in pkg.names() if re.fullmatch(r"ppt/slideLayouts/slideLayout\d+\.xml", n)):
        root = pkg.xml(name)
        phs = []
        for ph in root.iter(f"{{{NS['p']}}}ph"):
            kind = ph.get("type", "body")
            if kind not in CHROME_PH:
                phs.append(f"{kind}#{ph.get('idx', '0')}")
        print(f"{posixpath.basename(name):<20} {layout_name(pkg, name):<32} {' '.join(phs)}")


def cmd_text(a):
    pkg = Package(a.deck)
    for i, (_, _, part) in enumerate(slide_order(pkg), 1):
        lay = slide_layout(pkg, part)
        print(f"## Slide {i} ({posixpath.basename(part)}, layout: {layout_name(pkg, lay) if lay else '-'})\n")
        for kind, lines in shape_texts(pkg.xml(part)):
            print("\n".join(lines) if kind == "table" else "\n".join(f"- {line}" for line in lines))
            print()
        for _, rkind, target, _ in rels(pkg, part):
            if rkind == "notesSlide" and pkg.has(target):
                notes = [
                    line
                    for sp in pkg.xml(target).iter(f"{{{NS['p']}}}sp")
                    if (ph := sp.find("p:nvSpPr/p:nvPr/p:ph", NS)) is not None and ph.get("type") == "body"
                    for kind, lines in shape_texts(sp)
                    for line in lines
                ]
                if notes:
                    print("Notes: " + " ".join(notes) + "\n")


def next_rid(rels_xml):
    nums = [int(n) for n in re.findall(r'Id="rId(\d+)"', rels_xml)]
    return f"rId{max(nums, default=0) + 1}"


def add_relationship(pkg, part, kind, target):
    name = rels_name(part)
    xml = pkg.text(name)
    rid = next_rid(xml)
    xml = xml.replace("</Relationships>", f'<Relationship Id="{rid}" Type="{REL_BASE}{kind}" Target="{target}"/></Relationships>')
    pkg.write(name, xml)
    return rid


def add_override(pkg, part, content_type):
    xml = pkg.text("[Content_Types].xml")
    if f'PartName="/{part}"' not in xml:
        xml = xml.replace("</Types>", f'<Override PartName="/{part}" ContentType="{content_type}"/></Types>')
        pkg.write("[Content_Types].xml", xml)


def insert_slide(pkg, part, after):
    """Register a new slide part in the presentation, after another slide or at the end."""
    pres = "ppt/presentation.xml"
    rid = add_relationship(pkg, pres, "slide", posixpath.relpath(part, "ppt"))
    xml = pkg.text(pres)
    pfx = re.search(r"<(\w+:)?sldIdLst", xml).group(1) or ""
    ids = [int(i) for i in re.findall(rf"<{pfx}sldId\b[^>]*\bid=\"(\d+)\"", xml)]
    rpfx = re.search(r'xmlns:(\w+)="' + re.escape(NS["r"]) + '"', xml).group(1)
    new_el = f'<{pfx}sldId id="{max(ids, default=255) + 1}" {rpfx}:id="{rid}"/>'
    anchor = None
    if after:
        after_part = posixpath.join("ppt/slides", posixpath.basename(after))
        for _, arid, apart in slide_order(pkg):
            if apart == after_part:
                anchor = re.search(rf"<{pfx}sldId\b[^>]*{rpfx}:id=\"{arid}\"[^>]*/>", xml)
        if anchor is None:
            die(f"{after} is not in the slide list")
    if anchor:
        xml = xml[: anchor.end()] + new_el + xml[anchor.end() :]
    else:
        xml = xml.replace(f"</{pfx}sldIdLst>", new_el + f"</{pfx}sldIdLst>")
    pkg.write(pres, xml)
    add_override(pkg, part, SLIDE_CT)


def next_slide_part(pkg):
    nums = [int(m.group(1)) for n in pkg.names() if (m := re.fullmatch(r"ppt/slides/slide(\d+)\.xml", n))]
    return f"ppt/slides/slide{max(nums, default=0) + 1}.xml"


def cmd_dup(a):
    pkg = Package(a.dir)
    src = posixpath.join("ppt/slides", posixpath.basename(a.slide))
    if not pkg.has(src):
        die(f"{src} not found")
    new = next_slide_part(pkg)
    pkg.write(new, pkg.read(src))
    rels_xml = pkg.text(rels_name(src)) if pkg.has(rels_name(src)) else None
    shared = []
    if rels_xml:
        # A notes slide belongs to exactly one slide: the copy starts without notes.
        rels_xml = re.sub(r'<Relationship\b[^>]*Type="[^"]*/notesSlide"[^>]*/>', "", rels_xml)
        shared = re.findall(r'Type="[^"]*/(chart|diagramData|oleObject|package)"', rels_xml)
        pkg.write(rels_name(new), rels_xml)
    insert_slide(pkg, new, a.after or posixpath.basename(src))
    print(f"created {new} from {src}")
    if shared:
        print(f"note: the copy shares {', '.join(sorted(set(shared)))} parts with {src}; editing one edits both")


def cmd_new(a):
    pkg = Package(a.dir)
    layouts = {layout_name(pkg, n): n for n in pkg.names() if re.fullmatch(r"ppt/slideLayouts/slideLayout\d+\.xml", n)}
    if a.layout not in layouts:
        die(f"no layout named {a.layout!r}; layouts: {', '.join(sorted(layouts))}")
    lay = layouts[a.layout]
    shapes, sid = [], 1
    for sp in pkg.xml(lay).iter(f"{{{NS['p']}}}sp"):
        ph = sp.find("p:nvSpPr/p:nvPr/p:ph", NS)
        if ph is None or ph.get("type", "body") in CHROME_PH:
            continue
        sid += 1
        attrs = " ".join(f'{k}="{v}"' for k, v in ph.attrib.items())
        name = sp.find("p:nvSpPr/p:cNvPr", NS).get("name", f"Placeholder {sid}")
        shapes.append(
            f'<p:sp><p:nvSpPr><p:cNvPr id="{sid}" name="{name}"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>'
            f"<p:nvPr><p:ph {attrs}/></p:nvPr></p:nvSpPr><p:spPr/>"
            f'<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></p:txBody></p:sp>'
        )
    xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<p:sld xmlns:a="{NS["a"]}" xmlns:r="{NS["r"]}" xmlns:p="{NS["p"]}">'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
        '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
        + "".join(shapes)
        + '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>'
    )
    new = next_slide_part(pkg)
    pkg.write(new, xml)
    pkg.write(
        rels_name(new),
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        f'<Relationships xmlns="{NS["rel"]}"><Relationship Id="rId1" Type="{REL_BASE}slideLayout" '
        f'Target="../slideLayouts/{posixpath.basename(lay)}"/></Relationships>',
    )
    insert_slide(pkg, new, a.after)
    print(f"created {new} on layout {a.layout!r} ({len(shapes)} placeholders)")


def cmd_drop(a):
    pkg = Package(a.dir)
    part = posixpath.join("ppt/slides", posixpath.basename(a.slide))
    pres = "ppt/presentation.xml"
    hit = [rid for _, rid, p in slide_order(pkg) if p == part]
    if not hit:
        die(f"{part} is not in the slide list")
    xml = pkg.text(pres)
    xml = re.sub(rf'<(\w+:)?sldId\b[^>]*:id="{hit[0]}"[^>]*/>', "", xml)
    pkg.write(pres, xml)
    rx = pkg.text(rels_name(pres))
    pkg.write(rels_name(pres), re.sub(rf'<Relationship\b[^>]*Id="{hit[0]}"[^>]*/>', "", rx))
    print(f"dropped {part} from the show; run clean to delete its parts")


def reachable(pkg):
    seen, todo = set(), [""]
    while todo:
        part = todo.pop()
        name = "_rels/.rels" if part == "" else rels_name(part)
        if name in seen:
            continue
        seen.add(name)
        if part:
            seen.add(part)
        for _, _, target, external in rels(pkg, part) if part else root_rels(pkg):
            if not external and pkg.has(target) and target not in seen:
                todo.append(target)
    return seen


def root_rels(pkg):
    out = []
    for el in pkg.xml("_rels/.rels").findall("rel:Relationship", NS):
        out.append((el.get("Id"), el.get("Type"), el.get("Target").lstrip("/"), el.get("TargetMode") == "External"))
    return out


def cmd_clean(a):
    pkg = Package(a.dir)
    keep = reachable(pkg) | {"[Content_Types].xml"}
    gone = [n for n in pkg.names() if n not in keep]
    for n in gone:
        pkg.delete(n)
    ct = pkg.text("[Content_Types].xml")
    for n in gone:
        ct = re.sub(rf'<Override\b[^>]*PartName="/{re.escape(n)}"[^>]*/>', "", ct)
    pkg.write("[Content_Types].xml", ct)
    print(f"removed {len(gone)} parts" + (": " + ", ".join(gone) if gone else ""))


SLOTS = ("dk1", "lt1", "dk2", "lt2", "accent1", "accent2", "accent3", "accent4", "accent5", "accent6", "hlink", "folHlink")


def patch_theme(xml, spec):
    for slot, hexval in spec.get("colors", {}).items():
        if slot not in SLOTS or not re.fullmatch(r"[0-9A-Fa-f]{6}", hexval):
            die(f"theme color {slot}={hexval!r}: slot must be one of {', '.join(SLOTS)}, value six hex digits")
        xml = re.sub(rf"(<a:{slot}>).*?(</a:{slot}>)", rf'\g<1><a:srgbClr val="{hexval.upper()}"/>\g<2>', xml, count=1, flags=re.S)
    for key, block in (("head", "majorFont"), ("body", "minorFont")):
        if spec.get(key):
            face = spec[key].replace("&", "&amp;").replace('"', "&quot;")
            xml = re.sub(rf'(<a:{block}>\s*<a:latin typeface=")[^"]*', rf"\g<1>{face}", xml, count=1)
    if spec.get("name"):
        name = spec["name"].replace("&", "&amp;").replace('"', "&quot;")
        xml = re.sub(r'(<a:theme\b[^>]*\bname=")[^"]*', rf"\g<1>{name}", xml, count=1)
        xml = re.sub(r'(<a:clrScheme\b[^>]*\bname=")[^"]*', rf"\g<1>{name}", xml, count=1)
    return xml


def cmd_theme(a):
    import json

    spec = json.loads(Path(a.spec).read_text(encoding="utf-8"))
    pkg = Package(a.deck)
    themes = [n for n in pkg.names() if re.fullmatch(r"ppt/theme/theme\d+\.xml", n)]
    # Every master's theme takes the brand; notes and handout themes ride along harmlessly.
    patched = {n: patch_theme(pkg.text(n), spec) for n in themes}
    if pkg.is_dir:
        for n, xml in patched.items():
            pkg.write(n, xml)
    else:
        data = {n: pkg.read(n) for n in pkg.names()}
        pkg._zip.close()
        with zipfile.ZipFile(a.deck, "w", zipfile.ZIP_DEFLATED) as z:
            for n in sorted(data, key=lambda n: n != "[Content_Types].xml"):
                z.writestr(n, patched[n].encode("utf-8") if n in patched else data[n])
    print(f"themed {len(themes)} theme parts in {a.deck}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("unpack"); s.add_argument("deck"); s.add_argument("dir"); s.set_defaults(fn=cmd_unpack)
    s = sub.add_parser("pack"); s.add_argument("dir"); s.add_argument("out"); s.set_defaults(fn=cmd_pack)
    for name, fn in (("list", cmd_list), ("layouts", cmd_layouts), ("text", cmd_text)):
        s = sub.add_parser(name); s.add_argument("deck"); s.set_defaults(fn=fn)
    s = sub.add_parser("dup"); s.add_argument("dir"); s.add_argument("slide"); s.add_argument("--after"); s.set_defaults(fn=cmd_dup)
    s = sub.add_parser("new"); s.add_argument("dir"); s.add_argument("layout"); s.add_argument("--after"); s.set_defaults(fn=cmd_new)
    s = sub.add_parser("drop"); s.add_argument("dir"); s.add_argument("slide"); s.set_defaults(fn=cmd_drop)
    s = sub.add_parser("clean"); s.add_argument("dir"); s.set_defaults(fn=cmd_clean)
    s = sub.add_parser("theme"); s.add_argument("deck"); s.add_argument("spec"); s.set_defaults(fn=cmd_theme)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
