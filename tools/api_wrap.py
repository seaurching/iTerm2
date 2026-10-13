# -*- coding: utf-8 -*-
"""Wrap UI strings in API directory.
"""
import sys, warnings
warnings.filterwarnings('ignore')

SRCS = [
    'sources/API/iTermScriptChooser.m',
    'sources/API/iTermScriptsMenuController.m',
]

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# ============================================================================
# API directory edits
# ============================================================================
EDITS = [
    # iTermScriptChooser.m L49: button title
    ('@"Code-sign exported script using identity: "',
     W('Code-sign exported script using identity: ', 'API', '代码签名按钮标题')),
    # iTermScriptChooser.m L77: button title
    ('@"Offer to launch automatically during installation"',
     W('Offer to launch automatically during installation', 'API', '自动启动按钮标题')),
    # iTermScriptsMenuController.m L1457: alert messageText
    ('@"Spaces Not Allowed"',
     W('Spaces Not Allowed', 'API', '不允许空格警告标题')),
    # iTermScriptsMenuController.m L1458: alert informativeText
    ('@"Scripts can\'t have space characters in their filenames."',
     W("Scripts can't have space characters in their filenames.", 'API', '不允许空格警告内容')),
    # iTermScriptsMenuController.m L1459: alert button
    ('@"Use _ Instead of Space"',
     W('Use _ Instead of Space', 'API', '使用下划线按钮标题')),
    # iTermScriptsMenuController.m L1460: alert button
    ('@"Change Name"',
     W('Change Name', 'API', '更改名称按钮标题')),
]

# ============================================================================
# Main loop
# ============================================================================
total = 0
for src in SRCS:
    try:
        s = open(src, encoding='utf-8').read()
    except FileNotFoundError:
        print(f'{src}: FILE NOT FOUND')
        sys.exit(1)

    count = 0
    for old, new in EDITS:
        if old not in s:
            continue
        n = s.count(old)
        if n == 0:
            continue
        s = s.replace(old, new)
        count += n

    if count > 0:
        open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {count} edits OK')
    total += count

print(f'API wrap done: {total} edits total')
