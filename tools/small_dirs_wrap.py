# -*- coding: utf-8 -*-
"""Wrap UI strings in small directories: Toolbelt, StatusBar, PasswordManager, PTYSession, ContextMenu.
"""
import sys, warnings
warnings.filterwarnings('ignore')

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# ============================================================================
# Toolbelt (1 string)
# ============================================================================
TOOLBELT_EDITS = [
    # L123: menu item title
    ('@"Toggle Checkmark"',
     W('Toggle Checkmark', 'Toolbelt', '切换复选标记菜单项')),
]

# ============================================================================
# StatusBar (1 string)
# ============================================================================
STATUSBAR_EDITS = [
    # L300: menu title
    ('@"Contextual Menu"',
     W('Contextual Menu', 'StatusBar', '右键菜单标题')),
]

# ============================================================================
# PasswordManager (1 string)
# ============================================================================
PASSWORD_EDITS = [
    # L308: menu item title (only in DEBUG builds)
    ('@"Test Adapter (Dev)"',
     W('Test Adapter (Dev)', 'PasswordManager', '测试适配器菜单项')),
]

# ============================================================================
# PTYSession (2 strings)
# ============================================================================
PTYSESSION_EDITS = [
    # L14460: menu item title
    ('@"Unpause tmux Pane"',
     W('Unpause tmux Pane', 'PTYSession', '恢复tmux面板菜单项')),
    # L14463: menu item title
    ('@"Pause tmux Pane"',
     W('Pause tmux Pane', 'PTYSession', '暂停tmux面板菜单项')),
]

# ============================================================================
# ContextMenu (3 strings)
# ============================================================================
CONTEXTMENU_EDITS = [
    # L140, L385, L964: menu title (appears 3 times)
    ('@"Contextual Menu"',
     W('Contextual Menu', 'ContextMenu', '右键菜单标题')),
]

# ============================================================================
# Main loop
# ============================================================================
DIRS = [
    ('sources/Toolbelt/CapturedOutput/ToolCapturedOutputView.m', 'Toolbelt', TOOLBELT_EDITS),
    ('sources/StatusBar/Core/iTermStatusBarContainerView.m', 'StatusBar', STATUSBAR_EDITS),
    ('sources/PasswordManager/iTermPasswordManagerWindowController.m', 'PasswordManager', PASSWORD_EDITS),
    ('sources/PTYSession/PTYSession.m', 'PTYSession', PTYSESSION_EDITS),
    ('sources/ContextMenu/iTermTextViewContextMenuHelper.m', 'ContextMenu', CONTEXTMENU_EDITS),
]

total = 0
for src, table, edits in DIRS:
    try:
        s = open(src, encoding='utf-8').read()
    except FileNotFoundError:
        print(f'{src}: FILE NOT FOUND')
        sys.exit(1)

    count = 0
    for old, new in edits:
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

print(f'Small dirs wrap done: {total} edits total')
