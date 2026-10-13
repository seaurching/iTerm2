# -*- coding: utf-8 -*-
"""Wrap UI strings in Settings directory.
"""
import sys, warnings
warnings.filterwarnings('ignore')

SRCS = [
    'sources/Settings/ProfilesColorsPreferencesViewController.m',
    'sources/Settings/iTermEditKeyActionWindowController.m',
    'sources/Settings/GeneralPreferencesViewController.m',
]

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# ============================================================================
# Settings directory edits
# ============================================================================
EDITS = [
    # ProfilesColorsPreferencesViewController.m L687: alert button
    ('@"OK"',
     W('OK', 'Settings', '确定按钮标题')),
    # ProfilesColorsPreferencesViewController.m L688: alert button
    ('@"Cancel"',
     W('Cancel', 'Settings', '取消按钮标题')),
    # ProfilesColorsPreferencesViewController.m L719: alert messageText
    ('@"No deletable color presets."',
     W('No deletable color presets.', 'Settings', '无可删除颜色预设警告标题')),
    # ProfilesColorsPreferencesViewController.m L720: alert informativeText
    ('@"You cannot erase the built-in presets and no custom presets have been imported."',
     W('You cannot erase the built-in presets and no custom presets have been imported.', 'Settings', '无可删除颜色预设警告内容')),
    # ProfilesColorsPreferencesViewController.m L727: alert messageText
    ('@"Select a preset to delete:"',
     W('Select a preset to delete:', 'Settings', '选择要删除的预设标题')),
    # ProfilesColorsPreferencesViewController.m L772: alert messageText
    ('@"Save Failed."',
     W('Save Failed.', 'Settings', '保存失败警告标题')),
    # iTermEditKeyActionWindowController.m L551: menu item
    ('@"Apply to current session"',
     W('Apply to current session', 'Settings', '应用到当前会话')),
    # iTermEditKeyActionWindowController.m L553: menu item
    ('@"Apply to all sessions"',
     W('Apply to all sessions', 'Settings', '应用到所有会话')),
    # iTermEditKeyActionWindowController.m L555: menu item
    ('@"Apply to all sessions except current"',
     W('Apply to all sessions except current', 'Settings', '应用到除当前外所有会话')),
    # iTermEditKeyActionWindowController.m L557: menu item
    ('@"Apply to all sessions in window"',
     W('Apply to all sessions in window', 'Settings', '应用到窗口中所有会话')),
    # iTermEditKeyActionWindowController.m L559: menu item
    ('@"Apply to all sessions in tab"',
     W('Apply to all sessions in tab', 'Settings', '应用到标签页中所有会话')),
    # iTermEditKeyActionWindowController.m L561: menu item
    ('@"Apply to broadcasted-to sessions"',
     W('Apply to broadcasted-to sessions', 'Settings', '应用到广播目标会话')),
    # GeneralPreferencesViewController.m L2396: button title
    ('@"Install…"',
     W('Install…', 'Settings', '安装按钮标题')),
    # GeneralPreferencesViewController.m L2407: button title
    ('@"Reveal in Finder"',
     W('Reveal in Finder', 'Settings', '在Finder中显示按钮标题')),
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

print(f'Settings wrap done: {total} edits total')
