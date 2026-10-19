#!/usr/bin/env python3
"""Check every JSON body in markdown files: ```json fences and curl -d/--data '...' args.
Shell bodies are expanded the way bash would: '...' is literal, and '"'"$VAR"'"' splices
become 0, so a numeric splice parses. A body of only ... (an elision) is skipped. Exit 1 if any body fails json.loads."""
import json, re, shlex, sys

FENCE = re.compile(r"^```(\w*)\s*$")
DATA = re.compile(r"(?:-d|--data(?:-raw|-binary)?)\s+(?=['\"])")


def bodies(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    i = 0
    while i < len(lines):
        m = FENCE.match(lines[i])
        if not m or not m.group(1):
            i += 1
            continue
        lang, start, j = m.group(1), i + 1, i + 1
        while j < len(lines) and not lines[j].startswith("```"):
            j += 1
        block = "\n".join(lines[start:j])
        if lang == "json":
            yield start + 1, "json-fence", block
        elif lang in ("bash", "sh", "shell"):
            for d in DATA.finditer(block):
                line = start + 1 + block[: d.end()].count("\n")
                rest = block[d.end():].replace("\\\n", " ")
                lex = shlex.shlex(rest, posix=True)
                lex.whitespace_split = True
                lex.commenters = ""
                try:
                    tok = lex.get_token()
                except ValueError as e:
                    yield line, "curl -d", f"<<shell parse error: {e}>>"
                    continue
                if tok == "...":
                    continue  # elided body in a pattern line, not an example
                # $VAR survives shlex as text; bash would expand it
                yield line, "curl -d", re.sub(r"\$\{?\w+\}?", "0", tok)
        i = j + 1


def main(paths):
    total = bad = 0
    for p in paths:
        for line, kind, body in bodies(p):
            total += 1
            try:
                json.loads(body)
                print(f"PASS {p}:{line} [{kind}]")
            except json.JSONDecodeError as e:
                bad += 1
                ctx = body.split("\n")[e.lineno - 1].strip()[:70]
                print(f"FAIL {p}:{line} [{kind}] {e.msg} at body line {e.lineno}: {ctx}")
    print(f"{total} bodies, {bad} failed")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
