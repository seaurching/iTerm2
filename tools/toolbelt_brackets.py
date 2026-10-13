# -*- coding: utf-8 -*-
"""Bracket balance check for wrapped Toolbelt source files.

Handles both ObjC (.m) and Swift (.swift). Swift multi-line strings
delimited by \"\"\" are tracked separately so their content does not
corrupt the paren/brace count.

Tracks string/comment state at character level and verifies
() [] {} are balanced. Reports imbalance per file.
"""
import sys

OBJC_FILES = [
    'sources/Toolbelt/iTermToolActions.m',
    'sources/Toolbelt/iTermToolbeltView.m',
    'sources/Toolbelt/iTermToolSnippets.m',
    'sources/Toolbelt/ToolProfiles.m',
    'sources/Toolbelt/ToolPasteHistory.m',
    'sources/Toolbelt/ToolCommandHistoryView.m',
    'sources/Toolbelt/ToolDirectoriesView.m',
    'sources/Toolbelt/ToolNotes.m',
]

SWIFT_FILES = [
    'sources/Toolbelt/ToolCodecierge.swift',
    'sources/Toolbelt/ToolStatus.swift',
    'sources/Toolbelt/StatusPrioritySettings.swift',
    'sources/Toolbelt/ToolNamedMarks.swift',
    'sources/Toolbelt/ToolStatusCellView.swift',
]

def check_balance(s, swift=False):
    # state: 'code', 'line_comment', 'block_comment', 'string', 'char', 'ml_string'
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
        tri = s[i:i+3]
        if c == '\n':
            line += 1
            if state == 'line_comment':
                state = 'code'
            i += 1
            continue
        if state == 'code':
            if swift and tri == '"""':
                state = 'ml_string'; i += 3; continue
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
        if state == 'ml_string':
            # skip escaped chars
            if c == '\\':
                i += 2; continue
            if tri == '"""':
                state = 'code'; i += 3; continue
            i += 1; continue
        if state == 'char':
            if c == '\\':
                i += 2; continue
            if c == "'":
                state = 'code'; i += 1; continue
            i += 1; continue
        i += 1
    if state in ('string', 'char', 'block_comment', 'ml_string'):
        return f'unterminated {state} at line {line}'
    if stack:
        op, ol = stack[-1]
        return f'unclosed {op!r} opened at line {ol}'
    return None

errs = 0
for f in OBJC_FILES:
    s = open(f, encoding='utf-8').read()
    r = check_balance(s, swift=False)
    if r:
        print(f'{f}: FAIL — {r}')
        errs += 1
    else:
        print(f'{f}: OK')
for f in SWIFT_FILES:
    s = open(f, encoding='utf-8').read()
    r = check_balance(s, swift=True)
    if r:
        print(f'{f}: FAIL — {r}')
        errs += 1
    else:
        print(f'{f}: OK')
sys.exit(1 if errs else 0)
