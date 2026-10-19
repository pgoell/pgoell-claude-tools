"""The deck's source text as the editor sees it. Standard library only.

Scan finds the source offsets of every element. splice runs one edit op as
splices on the text, so the bytes outside the edited span stay as they were,
and says where every slide element moved to.
"""
import html
import re
from html.parser import HTMLParser

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}


class Scan(HTMLParser):
    """Source offsets of every element: start, open_end, close, end.

    An element whose end tag is missing keeps end=None and is not editable.
    """

    def __init__(self, text):
        super().__init__(convert_charrefs=False)
        self.text, self.els, self.stack, self.foreign = text, [], [], 0
        self.lines = [0] + [m.end() for m in re.finditer("\n", text)]
        self.feed(text)
        self.close()
        self.by_pos = {el["start"]: el for el in self.els}  # for display
        self.closed = {el["start"]: el for el in self.els if el["end"]}  # for edits

    def at(self):
        line, col = self.getpos()
        return self.lines[line - 1] + col

    def handle_starttag(self, tag, attrs, closed=False):
        start = self.at()
        el = {"tag": tag, "attrs": dict(attrs), "start": start, "open_end": start + len(self.get_starttag_text()), "close": None, "end": None}
        self.els.append(el)
        if tag in VOID or (closed and self.foreign):
            el["close"] = el["end"] = el["open_end"]
            return
        self.foreign += tag in ("svg", "math")
        self.stack.append(el)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs, True)

    def handle_endtag(self, tag):
        if not any(el["tag"] == tag for el in self.stack):
            return
        start = self.at()
        while True:
            el = self.stack.pop()
            self.foreign -= el["tag"] in ("svg", "math")
            if el["tag"] == tag:
                el["close"], el["end"] = start, self.text.index(">", start) + 1
                return

    def line(self, offset):
        lo, hi = 0, len(self.lines)
        while hi - lo > 1:
            mid = (lo + hi) // 2
            lo, hi = (mid, hi) if self.lines[mid] <= offset else (lo, mid)
        return lo + 1

    def in_stage(self):
        stage = next((el for el in self.els if el["tag"] == "deck-stage" and el["end"]), None)
        return [el for el in self.els if stage and stage["start"] < el["start"] < stage["end"]]


def cut_start(text, el):
    """Start of an element including the line break and indent before it, so a move leaves no hole."""
    return re.search(r"(\r?\n)?[ \t]*\Z", text[:el["start"]]).start()


def op_text(scan, text, body):
    """Replace an element's content. Characters the source wrote as entities go back to that spelling."""
    el = scan.closed[body["pos"]]
    old, new = text[el["open_end"]:el["close"]], body["html"]
    for entity in set(re.findall(r"&#?\w+;", old)):
        char = html.unescape(entity)
        if char not in "&<>\"'" and char != entity:
            new = new.replace(char, entity)
    return [(el["open_end"], len(old), new)], None


def op_move(scan, text, body):
    """Move an element before or after a sibling."""
    el, ref = scan.closed[body["pos"]], scan.closed[body["ref"]]
    start = cut_start(text, el)
    at = ref["end"] if body["after"] else cut_start(text, ref)
    chunk = text[start:el["end"]]
    return [(start, len(chunk), ""), (at, 0, chunk)], (start, len(chunk), at)


def set_attr(text, el, name, value):
    """Splice that sets one attribute in an element's start tag, leaving the others as written."""
    quoted = '"' + value.replace("&", "&amp;").replace('"', "&quot;") + '"'
    tag = text[el["start"]:el["open_end"]]
    for m in re.finditer(r"""\s([^\s"'<>/=]+)(?:\s*=\s*("[^"]*"|'[^']*'|[^\s"'=<>`]+))?""", tag[1 + len(el["tag"]):]):
        if m.group(1).lower() == name and m.group(2):
            return (el["start"] + 1 + len(el["tag"]) + m.start(2), len(m.group(2)), quoted)
    end = el["open_end"] - (2 if tag.endswith("/>") else 1)
    return (end, 0, f" {name}={quoted}")


def declare(css, props):
    """A declaration list with props set: earlier values of the same properties go, the rest stays."""
    for prop in props:
        css = re.sub(rf"(?:^|(?<=;))\s*{re.escape(prop)}\s*:[^;]*;?", "", css)
    return "; ".join([css.strip().rstrip(";")] * bool(css.strip()) + [f"{k}: {v}" for k, v in props.items()])


def op_style(scan, text, body):
    """Set inline style properties on one element."""
    el = scan.closed[body["pos"]]
    return [set_attr(text, el, "style", declare(html.unescape(el["attrs"].get("style") or ""), body["props"]))], None


def op_attr(scan, text, body):
    return [set_attr(text, scan.closed[body["pos"]], body["name"], body["value"])], None


def op_rule(scan, text, body):
    """Set properties in one rule of <style id="deck-edits">, the block that holds slide-scoped edits."""
    block = next((el for el in scan.els if el["tag"] == "style" and el["attrs"].get("id") == "deck-edits"), None)
    selector = body["selector"]
    if not block:
        head = next((el for el in scan.els if el["tag"] == "head" and el["end"]), None)
        at = head["close"] if head else next(el for el in scan.els if el["tag"] == "deck-stage")["start"]
        return [(at, 0, f'<style id="deck-edits">\n{selector} {{ {declare("", body["props"])}; }}\n</style>\n')], None
    old = text[block["open_end"]:block["close"]]
    lines, prefix = old.split("\n"), selector + " {"
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            lines[i] = f'{prefix} {declare(line[len(prefix):].rstrip().rstrip("}"), body["props"])}; }}'
            break
    else:
        lines.insert(len(lines) - 1, f'{prefix} {declare("", body["props"])}; }}')
    return [(block["open_end"], len(old), "\n".join(lines))], None


OPS = {"text": op_text, "move": op_move, "style": op_style, "attr": op_attr, "rule": op_rule}


def splice(text, body):
    """Run one edit op on the text. Returns the new text and where every slide element moved to, or None."""
    scan = Scan(text)
    try:
        splices, moved = OPS[body["op"]](scan, text, body)
    except (KeyError, TypeError, StopIteration):  # unknown element, or one without an end tag
        return None
    new = text
    for at, removed, inserted in sorted(splices, reverse=True):
        new = new[:at] + inserted + new[at + removed:]
    moves = {}
    for el in scan.in_stage():
        p = el["start"]
        if moved and moved[0] <= p < moved[0] + moved[1]:
            moves[p] = moved[2] - (moved[1] if moved[0] < moved[2] else 0) + p - moved[0]
        elif not any(at <= p < at + removed for at, removed, _ in splices):
            moves[p] = p + sum(len(inserted) - removed for at, removed, inserted in splices if at + removed <= p)
    # Every element must still sit where the map says, or the page reloads instead of trusting it.
    if any(new[at:at + 1 + len(scan.by_pos[old]["tag"])].lower() != "<" + scan.by_pos[old]["tag"] for old, at in moves.items()):
        return None
    return new, moves
