# -*- coding: utf-8 -*-
"""Extract all tmux-table keys from the 5 wrapped source files (deduplicated)."""
import re

files = [
    'sources/tmux/TmuxGateway.m',
    'sources/tmux/TmuxWindowOpener.m',
    'sources/tmux/TmuxWindowsTable.m',
    'sources/tmux/TmuxSessionsTable.m',
    'sources/tmux/TmuxController.m',
]

def decode_objc(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            c = s[i+1]
            if c == 'n': out.append('\n')
            elif c == 't': out.append('\t')
            elif c == 'r': out.append('\r')
            elif c == '\\': out.append('\\')
            elif c == '"': out.append('"')
            elif c == "'": out.append("'")
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

keys = []
seen = set()
pat = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"tmux"')
for f in files:
    s = open(f, encoding='utf-8').read()
    for m in pat.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k)
            keys.append(k)

print(f'Total unique keys: {len(keys)}')
for k in keys:
    print(repr(k))
