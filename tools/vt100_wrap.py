# -*- coding: utf-8 -*-
# Wrap user-visible strings in sources/VT100/iTermNotifyOnStatusChangeController.swift
# with NSLocalizedString("key", tableName: "VT100", comment: "...").
#
# Table: VT100
# The informativeText uses string interpolation; convert to String(format:) with %@.
import sys

SRC = 'sources/VT100/iTermNotifyOnStatusChangeController.swift'

def WS(key, comment):
    return f'NSLocalizedString("{key}", tableName: "VT100", comment: "{comment}")'

edits = [
    # L236: fallback session name
    ('let name = sessionName ?? "A session"',
     f'let name = sessionName ?? {WS("A session", "状态变更提示：会话名缺失时的占位")}'),
    # L237: fallback "from" status
    ('from ?? "none"',
     f'from ?? {WS("none", "状态变更提示：原状态缺失占位")}'),
    # L238: fallback "to" status
    ('to ?? "none"',
     f'to ?? {WS("none", "状态变更提示：新状态缺失占位")}'),
    # L244: alert messageText
    ('alert.messageText = "Session status changed"',
     f'alert.messageText = {WS("Session status changed", "状态变更提示：警告标题")}'),
    # L245: alert informativeText (interpolation -> format string)
    ('alert.informativeText = "\\(name) changed from “\\(fromText)” to “\\(toText)”."',
     f'alert.informativeText = String(format: {WS("%@ changed from “%@” to “%@”.", "状态变更提示：会话从原状态变为新状态")}, name, fromText, toText)'),
    # L246: OK button
    ('alert.addButton(withTitle: "OK")',
     f'alert.addButton(withTitle: {WS("OK", "状态变更提示：确定按钮")})'),
    # L253: Reveal button
    ('alert.addButton(withTitle: "Reveal")',
     f'alert.addButton(withTitle: {WS("Reveal", "状态变更提示：显示按钮")})'),
]

s = open(SRC, encoding='utf-8').read()
n = 0
for old, new in edits:
    c = s.count(old)
    if c != 1:
        print(f'ERROR: expected 1, got {c} for: {old!r}')
        sys.exit(1)
    s = s.replace(old, new)
    n += 1
open(SRC, 'w', encoding='utf-8').write(s)
print(f'{SRC}: {n} edits OK')
print('VT100 wrap done')
