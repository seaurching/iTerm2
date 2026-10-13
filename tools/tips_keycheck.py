# -*- coding: utf-8 -*-
"""Cross-check: decode ObjC source keys and .strings keys to runtime
values, then compare sets. Handles escape sequences correctly."""
import re

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

objc_files = [
    "iTermTip.m",
    "iTermTipCardViewController.m",
    "iTermTipController.m",
    "iTermTipWindowController.m",
    "iTermTipData.m",
]

code_keys = set()
for fn in objc_files:
    s = open(f"sources/Tips/{fn}", encoding="utf-8").read()
    for m in re.finditer(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"Tips"', s):
        code_keys.add(decode_objc(m.group(1)))

str_keys = set()
ss = open("sources/Tips/Base.lproj/Tips.strings", encoding="utf-8").read()
for m in re.finditer(r'^"((?:[^"\\]|\\.)*)" = ', ss, re.M):
    str_keys.add(decode_objc(m.group(1)))

print(f"Code runtime keys: {len(code_keys)}")
print(f"Strings runtime keys: {len(str_keys)}")
missing = code_keys - str_keys
extra = str_keys - code_keys
if missing:
    print(f"MISSING in strings ({len(missing)}):")
    for k in sorted(missing): print(f"  {k!r}")
else:
    print("OK: all code keys present in strings")
if extra:
    print(f"EXTRA in strings ({len(extra)}):")
    for k in sorted(extra): print(f"  {k!r}")
else:
    print("OK: no extra keys in strings")
