# -*- coding: utf-8 -*-
# Verify Python Swift multi-line string decoder against Swift's runtime output.
import re

SRC = 'sources/Toolbelt/ToolStatus.swift'
s = open(SRC, encoding='utf-8').read()

# Extract raw content between NSLocalizedString(""" and """, tableName:
pat = re.compile(r'NSLocalizedString\("""(.*?)""", tableName: "Toolbelt"', re.DOTALL)
m = pat.search(s)
assert m, 'no helpMarkdown match'
raw = m.group(1)

# Determine closing delimiter indentation: the line containing the closing """
# Look at the characters between the last newline in raw and end of raw.
# raw ends with: ...\n<closing_indent>
last_nl = raw.rfind('\n')
closing_indent = raw[last_nl+1:]   # everything after last newline = closing indent
assert all(c in ' \t' for c in closing_indent), f'closing indent not whitespace: {closing_indent!r}'

def decode_swift_multi(raw, closing_indent):
    # 1. Strip first newline after opening """
    if raw.startswith('\n'):
        raw = raw[1:]
    # 2. Remove trailing closing-indent (the part after the last newline — that's
    #    the closing delimiter's own line, not string content). The newline before
    #    the closing delimiter is also not part of the string.
    idx = raw.rfind('\n' + closing_indent)
    if idx != -1 and raw[idx+1:] == closing_indent:
        raw = raw[:idx]
    # 3. Split into lines and strip closing_indent from each
    lines = raw.split('\n')
    out_lines = []
    for line in lines:
        if line.startswith(closing_indent):
            out_lines.append(line[len(closing_indent):])
        else:
            out_lines.append(line)
    content = '\n'.join(out_lines)
    # 4. Single-pass escape + line-continuation decoding
    result = []
    i = 0
    n = len(content)
    while i < n:
        c = content[i]
        if c == '\\' and i+1 < n:
            nxt = content[i+1]
            if nxt == '\n':
                # line continuation: skip backslash + newline
                i += 2; continue
            elif nxt == 'n': result.append('\n'); i += 2; continue
            elif nxt == 't': result.append('\t'); i += 2; continue
            elif nxt == 'r': result.append('\r'); i += 2; continue
            elif nxt == '\\': result.append('\\'); i += 2; continue
            elif nxt == '"': result.append('"'); i += 2; continue
            elif nxt == "'": result.append("'"); i += 2; continue
            elif nxt == '0': result.append('\0'); i += 2; continue
            elif nxt == 'u' and i+2 < n and content[i+2] == '{':
                end = content.find('}', i+3)
                assert end != -1, f'unterminated \\u{{ at {i}'
                hexval = content[i+3:end]
                result.append(chr(int(hexval, 16)))
                i = end + 1; continue
            else:
                # unknown escape: keep next char literally
                result.append(nxt); i += 2; continue
        else:
            result.append(c); i += 1
    return ''.join(result)

decoded = decode_swift_multi(raw, closing_indent)
expected = open('/tmp/swift_ml_dump.txt', encoding='utf-8').read()

print(f'closing_indent={closing_indent!r} (len {len(closing_indent)})')
print(f'decoded len={len(decoded)}, expected len={len(expected)}')
print(f'MATCH={decoded == expected}')
if decoded != expected:
    # find first diff
    for k in range(min(len(decoded), len(expected))):
        if decoded[k] != expected[k]:
            print(f'first diff at {k}: decoded={decoded[k]!r} expected={expected[k]!r}')
            print(f'  decoded ctx: ...{decoded[max(0,k-20):k+20]!r}')
            print(f'  expected ctx: ...{expected[max(0,k-20):k+20]!r}')
            break
    if len(decoded) != len(expected):
        print(f'length diff: decoded={len(decoded)} expected={len(expected)}')
