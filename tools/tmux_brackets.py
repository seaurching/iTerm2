# -*- coding: utf-8 -*-
"""Bracket balance check for wrapped tmux source files.

Tracks ObjC string/comment state at character level and verifies
() [] {} are balanced. Reports imbalance per file.
"""
import sys

files = [
    'sources/tmux/TmuxGateway.m',
    'sources/tmux/TmuxWindowOpener.m',
    'sources/tmux/TmuxWindowsTable.m',
    'sources/tmux/TmuxSessionsTable.m',
    'sources/tmux/TmuxController.m',
]

def check_balance(s):
    # state: 'code', 'line_comment', 'block_comment', 'string', 'char'
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
            i += 1
            continue
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

errs = 0
for f in files:
    s = open(f, encoding='utf-8').read()
    r = check_balance(s)
    if r:
        print(f'{f}: FAIL — {r}')
        errs += 1
    else:
        print(f'{f}: OK')
sys.exit(1 if errs else 0)
