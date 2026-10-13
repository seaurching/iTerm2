# -*- coding: utf-8 -*-
"""Wrap UI strings in AppKit directory.
"""
import sys, warnings
warnings.filterwarnings('ignore')

SRCS = [
    'sources/AppKit/iTermApplicationDelegate.m',
]

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# ============================================================================
# AppKit directory edits
# ============================================================================
EDITS = [
    # L457: menu item title
    ('@"Undo Close Session"',
     W('Undo Close Session', 'AppKit', '撤销关闭会话菜单项')),
    # L542: menu item title
    ('@"Suppressed Alerts…"',
     W('Suppressed Alerts…', 'AppKit', '已抑制警告菜单项')),
    # L716: menu title
    ('@"Downloads"',
     W('Downloads', 'AppKit', '下载菜单标题')),
    # L720: menu title
    ('@"Downloads"',
     W('Downloads', 'AppKit', '下载菜单标题')),
    # L722: menu item title
    ('@"Clear All"',
     W('Clear All', 'AppKit', '清除所有菜单项')),
    # L732: menu title
    ('@"Uploads"',
     W('Uploads', 'AppKit', '上传菜单标题')),
    # L736: menu title
    ('@"Uploads"',
     W('Uploads', 'AppKit', '上传菜单标题')),
    # L738: menu item title
    ('@"Clear All"',
     W('Clear All', 'AppKit', '清除所有菜单项')),
    # L792: alert messageText
    ('@"Colors Scheme Imported"',
     W('Colors Scheme Imported', 'AppKit', '配色方案已导入警告标题')),
    # L793: alert informativeText
    ('@"The color scheme was imported and added to presets. You can find it under Settings > Profiles > Colors > Load Presets…."',
     W('The color scheme was imported and added to presets. You can find it under Settings > Profiles > Colors > Load Presets….', 'AppKit', '配色方案已导入警告内容')),
    # L1036: alert messageText
    ('@"Quit iTerm2?"',
     W('Quit iTerm2?', 'AppKit', '退出确认警告标题')),
    # L1038: alert button
    ('@"OK"',
     W('OK', 'AppKit', '确定按钮标题')),
    # L1039: alert button
    ('@"Cancel"',
     W('Cancel', 'AppKit', '取消按钮标题')),
    # L1151: menu item title
    ('@"New Window (Default Profile)"',
     W('New Window (Default Profile)', 'AppKit', '新建窗口菜单项')),
    # L1767: panel title
    ('@"Choose a JSON File"',
     W('Choose a JSON File', 'AppKit', '选择JSON文件面板标题')),
    # L1799: menu item title
    ('@"Settings"',
     W('Settings', 'AppKit', '设置菜单项')),
    # L1804: menu item title
    ('@"Bring All Windows to Front"',
     W('Bring All Windows to Front', 'AppKit', '置前所有窗口菜单项')),
    # L1812: menu item title
    ('@"Buried Sessions"',
     W('Buried Sessions', 'AppKit', '埋藏会话菜单项')),
    # L1817: menu item title
    ('@"Check For Updates"',
     W('Check For Updates', 'AppKit', '检查更新菜单项')),
    # L1822: menu item title
    ('@"Main Menu"',
     W('Main Menu', 'AppKit', '主菜单菜单项')),
    # L1826: menu item title
    ('@"Quit iTerm2"',
     W('Quit iTerm2', 'AppKit', '退出菜单项')),
    # L2627: menu item title
    ('@"Restore Arrangement"',
     W('Restore Arrangement', 'AppKit', '恢复窗口排列菜单项')),
    # L3181: alert messageText
    ('@"No Retrospective Logs"',
     W('No Retrospective Logs', 'AppKit', '无调试日志警告标题')),
    # L3182: alert informativeText
    ('@"No retrospective debug logs have been recorded yet."',
     W('No retrospective debug logs have been recorded yet.', 'AppKit', '无调试日志警告内容')),
    # L3183: alert button
    ('@"OK"',
     W('OK', 'AppKit', '确定按钮标题')),
    # L3192: panel title
    ('@"Save Retrospective Debug Logs"',
     W('Save Retrospective Debug Logs', 'AppKit', '保存调试日志面板标题')),
    # L3199: alert messageText
    ('@"Could Not Save"',
     W('Could Not Save', 'AppKit', '保存失败警告标题')),
    # L3201: alert button
    ('@"OK"',
     W('OK', 'AppKit', '确定按钮标题')),
    # L3293: alert messageText
    ('@"Installation Failed"',
     W('Installation Failed', 'AppKit', '安装失败警告标题')),
    # L3386: alert messageText
    ('@"Python Environment Unavailable"',
     W('Python Environment Unavailable', 'AppKit', 'Python环境不可用警告标题')),
    # L3533: alert messageText
    ('@"GPU Renderer Availability"',
     W('GPU Renderer Availability', 'AppKit', 'GPU渲染器可用性警告标题')),
    # L3541: alert informativeText
    ('@"GPU rendering is enabled for the current session."',
     W('GPU rendering is enabled for the current session.', 'AppKit', 'GPU渲染启用警告内容')),
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

print(f'AppKit wrap done: {total} edits total')
