# -*- coding: utf-8 -*-
# Wrap user-visible strings in sources/TryingTooHard/ with localization macros.
#
# Files:
#   iTermPrintGuard.m      (ObjC)  -> NSLocalizedStringFromTableInBundle
#   iTermTouchIDHelper.swift (Swift) -> NSLocalizedString
#
# Table: TryingTooHard
# ObjC bundle: [NSBundle bundleForClass:[self class]]
# identifier:@"NoSyncAllowPrinting" is an internal identifier — NOT wrapped.
import sys

OBJC_SRC = 'sources/TryingTooHard/iTermPrintGuard.m'
SWIFT_SRC = 'sources/TryingTooHard/iTermTouchIDHelper.swift'

def W(key, comment):
    return (f'NSLocalizedStringFromTableInBundle(@"{key}", @"TryingTooHard", '
            f'[NSBundle bundleForClass:[self class]], @"{comment}")')

def WS(key, comment):
    return f'NSLocalizedString("{key}", tableName: "TryingTooHard", comment: "{comment}")'

# --- ObjC edits (iTermPrintGuard.m) ---
objc_edits = [
    (f'[iTermWarning showWarningWithTitle:@"There\'s a lot of printing going on. Want to keep allowing it?"',
     f'[iTermWarning showWarningWithTitle:{W("There\'s a lot of printing going on. Want to keep allowing it?", "大量打印警告标题")}'),
    (f'actions:@[ @"Allow", @"Disable Temporarily", @"Disable Permanently" ]',
     f'actions:@[ {W("Allow", "允许打印按钮")}, {W("Disable Temporarily", "暂时禁用打印按钮")}, {W("Disable Permanently", "永久禁用打印按钮")} ]'),
    (f'heading:@"Allow Printing?"',
     f'heading:{W("Allow Printing?", "允许打印警告标题")}'),
]

s = open(OBJC_SRC, encoding='utf-8').read()
n = 0
for old, new in objc_edits:
    c = s.count(old)
    if c != 1:
        print(f'ERROR [{OBJC_SRC}]: expected 1, got {c} for: {old!r}')
        sys.exit(1)
    s = s.replace(old, new)
    n += 1
open(OBJC_SRC, 'w', encoding='utf-8').write(s)
print(f'{OBJC_SRC}: {n} edits OK')

# --- Swift edits (iTermTouchIDHelper.swift) ---
swift_edits = [
    ('withTitle: "The Touch ID install script is missing from the iTerm2 application bundle."',
     f'withTitle: {WS("The Touch ID install script is missing from the iTerm2 application bundle.", "Touch ID 安装脚本缺失警告标题")}'),
    ('actions: ["OK"]',
     f'actions: [{WS("OK", "确定按钮")}]'),
    ('heading: "Cannot Enable Touch ID for Sudo"',
     f'heading: {WS("Cannot Enable Touch ID for Sudo", "无法为 Sudo 启用 Touch ID 警告标题")}'),
]

s = open(SWIFT_SRC, encoding='utf-8').read()
n = 0
for old, new in swift_edits:
    c = s.count(old)
    if c != 1:
        print(f'ERROR [{SWIFT_SRC}]: expected 1, got {c} for: {old!r}')
        sys.exit(1)
    s = s.replace(old, new)
    n += 1
open(SWIFT_SRC, 'w', encoding='utf-8').write(s)
print(f'{SWIFT_SRC}: {n} edits OK')
print('TryingTooHard wrap done')
