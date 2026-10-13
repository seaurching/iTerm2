# -*- coding: utf-8 -*-
"""Wrap UI strings in TerminalView directory.
"""
import sys, warnings
warnings.filterwarnings('ignore')

SRCS = [
    'sources/TerminalView/PseudoTerminal.m',
    'sources/TerminalView/PTYTextView.m',
]

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# ============================================================================
# TerminalView directory edits
# ============================================================================
EDITS = [
    # PseudoTerminal.m L8040: menu item
    ('@"Select"',
     W('Select', 'TerminalView', '选择菜单项')),
    # PseudoTerminal.m L8048: menu item
    ('@"New Tab to the Right"',
     W('New Tab to the Right', 'TerminalView', '右侧新建标签页菜单项')),
    # PseudoTerminal.m L8054: menu item
    ('@"Edit Session…"',
     W('Edit Session…', 'TerminalView', '编辑会话菜单项')),
    # PseudoTerminal.m L8060: menu item
    ('@"Close Tab"',
     W('Close Tab', 'TerminalView', '关闭标签页菜单项')),
    # PseudoTerminal.m L8070: menu item
    ('@"Duplicate Tab"',
     W('Duplicate Tab', 'TerminalView', '复制标签页菜单项')),
    # PseudoTerminal.m L8077: menu item
    ('@"Save Tab as Window Arrangement"',
     W('Save Tab as Window Arrangement', 'TerminalView', '保存标签页为窗口排列菜单项')),
    # PseudoTerminal.m L8084: menu item
    ('@"Move to New Window"',
     W('Move to New Window', 'TerminalView', '移动到新窗口菜单项')),
    # PseudoTerminal.m L8110: menu item
    ('@"Close Other Tabs"',
     W('Close Other Tabs', 'TerminalView', '关闭其他标签页菜单项')),
    # PseudoTerminal.m L8152: menu item
    ('@"Tab Color"',
     W('Tab Color', 'TerminalView', '标签页颜色菜单项')),
    # PseudoTerminal.m L8564: menu item
    ('@"New Group…"',
     W('New Group…', 'TerminalView', '新建分组菜单项')),
    # PseudoTerminal.m L8587: menu item
    ('@"Add Tab to Group"',
     W('Add Tab to Group', 'TerminalView', '添加标签页到分组菜单项')),
    # PseudoTerminal.m L8594: menu item
    ('@"Rename Group…"',
     W('Rename Group…', 'TerminalView', '重命名分组菜单项')),
    # PseudoTerminal.m L8601: menu item
    ('@"Remove Tab from Group"',
     W('Remove Tab from Group', 'TerminalView', '从分组移除标签页菜单项')),
    # PseudoTerminal.m L9138: menu item
    ('@"Group Color"',
     W('Group Color', 'TerminalView', '分组颜色菜单项')),
    # PseudoTerminal.m L13712: menu item
    ('@"Enable GPU Frame Capture"',
     W('Enable GPU Frame Capture', 'TerminalView', '启用GPU帧捕获菜单项')),
    # PseudoTerminal.m L13714: menu item
    ('@"Capture GPU Frame"',
     W('Capture GPU Frame', 'TerminalView', '捕获GPU帧菜单项')),
    # PTYTextView.m L6859: menu item
    ('@"Disable Command Selection"',
     W('Disable Command Selection', 'TerminalView', '禁用命令选择菜单项')),
    # PTYTextView.m L6863: menu item
    ('@"Help"',
     W('Help', 'TerminalView', '帮助菜单项')),
    # PTYTextView.m L6889: menu item
    ('@"Copy Command"',
     W('Copy Command', 'TerminalView', '复制命令菜单项')),
    # PTYTextView.m L6896: menu item
    ('@"Copy Output"',
     W('Copy Output', 'TerminalView', '复制输出菜单项')),
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

print(f'TerminalView wrap done: {total} edits total')
