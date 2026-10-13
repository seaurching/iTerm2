# -*- coding: utf-8 -*-
# Bracket balance check + key extraction + 8-locale VT100Screen.strings generation.
#
# Sources:
#   sources/VT100Screen/VT100ScreenMutableState.m                           (ObjC)
#   sources/VT100Screen/VT100ScreenMutableState+TerminalDelegate.m         (ObjC)
# Table: VT100Screen
import os
import re
import sys

OBJC_SRCS = [
    'sources/VT100Screen/VT100ScreenMutableState.m',
    'sources/VT100Screen/VT100ScreenMutableState+TerminalDelegate.m',
]
LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
TABLE = 'VT100Screen'
SRCDIR = 'sources/VT100Screen'

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

for src in OBJC_SRCS:
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

objc_pat = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"VT100Screen"')
code_keys = []
seen = set()
for src in OBJC_SRCS:
    s = open(src, encoding='utf-8').read()
    for m in objc_pat.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k); code_keys.append(k)
print(f'Extracted {len(code_keys)} unique keys')

# ----------------------------------------------------------------------------
# 3. Translations: key -> (simplified, traditional)
# ----------------------------------------------------------------------------
T = {
    "Archive Restored": ("归档已恢复", "封存已恢復"),
    "Session Contents Restored on %@": ("会话内容已于 %@ 恢复", "工作階段內容已於 %@ 恢復"),
    "ssh exited": ("ssh 已退出", "ssh 已退出"),
    "%@ ssh sessions ended.": ("%@ 个 ssh 会话已结束。", "%@ 個 ssh 工作階段已結束。"),
    "%@ — now at %@.": ("%@ — 现位于 %@。", "%@ — 現位於 %@。"),
    "%@.": ("%@。", "%@。"),
    "%@ trigger": ("%@ 触发器", "%@ 觸發器"),
    "Out-of-date version of it2ssh detected. Please upgrade it2ssh.": ("检测到过时版本的 it2ssh。请升级 it2ssh。", "偵測到過時版本的 it2ssh。請升級 it2ssh。"),
    "Future version of it2ssh detected. Please upgrade iTerm2.": ("检测到未来版本的 it2ssh。请升级 iTerm2。", "偵測到未來版本的 it2ssh。請升級 iTerm2。"),
    "Recovering ssh connection…": ("正在恢复 ssh 连接…", "正在恢復 ssh 連線…"),
    "ssh connection recovered!": ("ssh 连接已恢复！", "ssh 連線已恢復！"),
    "   Started %@": ("   已启动 %@", "   已啟動 %@"),
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
    lines = [f'/* VT100Screen.strings - {loc} */']
    for key in code_keys:
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    content = '\n'.join(lines) + '\n'
    path = f'{ldir}/{TABLE}.strings'
    open(path, 'w', encoding='utf-8').write(content)
    print(f'  {path}: {len(code_keys)} keys')

print('All VT100Screen.strings files generated')
