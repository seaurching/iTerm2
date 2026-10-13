# -*- coding: utf-8 -*-
# Bracket balance check + key extraction + 8-locale TryingTooHard.strings generation.
#
# Sources:
#   sources/TryingTooHard/iTermPrintGuard.m        (ObjC)
#   sources/TryingTooHard/iTermTouchIDHelper.swift  (Swift)
# Table: TryingTooHard
import json
import os
import re
import sys

OBJC_SRC = 'sources/TryingTooHard/iTermPrintGuard.m'
SWIFT_SRC = 'sources/TryingTooHard/iTermTouchIDHelper.swift'
LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
TABLE = 'TryingTooHard'
SRCDIR = 'sources/TryingTooHard'

# ----------------------------------------------------------------------------
# 1. Bracket balance check (ObjC, string/comment aware)
# ----------------------------------------------------------------------------
def check_balance(s):
    stack = []
    state = 'code'
    i = 0
    n = len(s)
    line = 1
    opens = {'(': ')', '[': ']', '{': '}'}
    closes = set(opens.values())
    while i < n:
        c = s[i]
        nxt = s[i+1] if i+1 < n else ''
        if c == '\n':
            line += 1
            if state == 'line_comment':
                state = 'code'
            i += 1; continue
        if state == 'code':
            if c == '/' and nxt == '/':
                state = 'line_comment'; i += 2; continue
            if c == '/' and nxt == '*':
                state = 'block_comment'; i += 2; continue
            if c == '"':
                state = 'string'; i += 1; continue
            if c == "'":
                state = 'char'; i += 1; continue
            if c in opens:
                stack.append((c, line)); i += 1; continue
            if c in closes:
                if not stack:
                    return f'extra closing {c!r} at line {line}'
                op, ol = stack.pop()
                if opens[op] != c:
                    return f'mismatch: opened {op!r} at line {ol}, closed {c!r} at line {line}'
                i += 1; continue
            i += 1; continue
        if state == 'block_comment':
            if c == '*' and nxt == '/':
                state = 'code'; i += 2; continue
            i += 1; continue
        if state == 'string':
            if c == '\\':
                i += 2; continue
            if c == '"':
                state = 'code'; i += 1; continue
            i += 1; continue
        if state == 'char':
            if c == '\\':
                i += 2; continue
            if c == "'":
                state = 'code'; i += 1; continue
            i += 1; continue
        i += 1
    if state in ('string', 'char', 'block_comment'):
        return f'unterminated {state} at line {line}'
    if stack:
        op, ol = stack[-1]
        return f'unclosed {op!r} opened at line {ol}'
    return None

for src in (OBJC_SRC, SWIFT_SRC):
    s = open(src, encoding='utf-8').read()
    r = check_balance(s)
    if r:
        print(f'{src}: FAIL — {r}')
        sys.exit(1)
    print(f'{src}: bracket balance OK')

# ----------------------------------------------------------------------------
# 2. Extract keys
# ----------------------------------------------------------------------------
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

objc_pat = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"TryingTooHard"')
swift_pat = re.compile(r'NSLocalizedString\("((?:[^"\\]|\\.)*)", tableName: "TryingTooHard"')
code_keys = []
seen = set()
for src, pat in [(OBJC_SRC, objc_pat), (SWIFT_SRC, swift_pat)]:
    s = open(src, encoding='utf-8').read()
    for m in pat.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k); code_keys.append(k)
print(f'Extracted {len(code_keys)} unique keys')

# ----------------------------------------------------------------------------
# 3. Translations: key -> (simplified, traditional)
# ----------------------------------------------------------------------------
T = {
    "There's a lot of printing going on. Want to keep allowing it?": ("正在大量打印内容。要继续允许吗？", "正在大量列印內容。要繼續允許嗎？"),
    "Allow": ("允许", "允許"),
    "Disable Temporarily": ("暂时禁用", "暫時停用"),
    "Disable Permanently": ("永久禁用", "永久停用"),
    "Allow Printing?": ("允许打印？", "允許列印？"),
    "The Touch ID install script is missing from the iTerm2 application bundle.": ("iTerm2 应用程序包中缺少 Touch ID 安装脚本。", "iTerm2 應用程式套件中缺少 Touch ID 安裝腳本。"),
    "OK": ("确定", "確定"),
    "Cannot Enable Touch ID for Sudo": ("无法为 Sudo 启用 Touch ID", "無法為 Sudo 啟用 Touch ID"),
}

missing = [k for k in code_keys if k not in T]
extra = [k for k in T if k not in seen]
if missing:
    print('MISSING translations:'); [print(f'  {k!r}') for k in missing]
if extra:
    print('EXTRA translations:'); [print(f'  {k!r}') for k in extra]
if missing or extra:
    sys.exit(1)
print(f'Cross-check OK: {len(code_keys)} keys matched')

# ----------------------------------------------------------------------------
# 4. Generate 8-locale .strings files
# ----------------------------------------------------------------------------
def esc(s):
    return (s.replace('\\', '\\\\')
             .replace('"', '\\"')
             .replace('\n', '\\n')
             .replace('\t', '\\t'))

def value_for(key, loc):
    if loc in ('Base', 'en'):
        return key
    simp, trad = T[key]
    return simp if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN') else trad

for loc in LOCALES:
    ldir = f'{SRCDIR}/{loc}.lproj'
    os.makedirs(ldir, exist_ok=True)
    lines = [f'/* TryingTooHard.strings - {loc} */']
    for key in code_keys:
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    content = '\n'.join(lines) + '\n'
    path = f'{ldir}/{TABLE}.strings'
    open(path, 'w', encoding='utf-8').write(content)
    print(f'  {path}: {len(code_keys)} keys')

print('All TryingTooHard.strings files generated')
