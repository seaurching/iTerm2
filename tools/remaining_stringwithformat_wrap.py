# -*- coding: utf-8 -*-
"""Wrap remaining stringWithFormat/initWithTitle UI strings.
"""
import sys, warnings
warnings.filterwarnings('ignore')

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

def F(key, table, comment):
    return f'[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

EDITS = [
    # === AppKit/iTermApplicationDelegate.m ===
    # L545: menu title parts
    ('NSString *countPart = (n == 1) ? @"1 Alert Suppressed" : [NSString stringWithFormat:@"%@ Alerts Suppressed", @(n)];',
     'NSString *countPart = (n == 1) ? ' + W('1 Alert Suppressed', 'AppKit', '已抑制1个警告') + ' : [NSString stringWithFormat:' + W('%@ Alerts Suppressed', 'AppKit', '已抑制多个警告') + ', @(n)];'),
    # L549: menu title format
    ('menuItem.title = [NSString stringWithFormat:@"%@ (%@ ago)…", countPart, rel];',
     'menuItem.title = ' + F('%@ (%@ ago)…', 'AppKit', '已抑制警告菜单标题格式') + ', countPart, rel];'),
    # L551: menu title format
    ('menuItem.title = [NSString stringWithFormat:@"%@…", countPart];',
     'menuItem.title = ' + F('%@…', 'AppKit', '已抑制警告菜单标题') + ', countPart];'),
    # L1750: menu item
    ('initWithTitle:@"Toggle Key Recording" action:@selector(toggleKeyRecording:)',
     'initWithTitle:' + W('Toggle Key Recording', 'AppKit', '切换按键录制菜单项') + ' action:@selector(toggleKeyRecording:)'),
    # L1753: menu item
    ('initWithTitle:@"Replay Recorded Keys" action:@selector(replayRecordedKeys:)',
     'initWithTitle:' + W('Replay Recorded Keys', 'AppKit', '回放录制的按键菜单项') + ' action:@selector(replayRecordedKeys:)'),
    # L3200: alert informativeText
    ('alert.informativeText = [NSString stringWithFormat:@"Failed to save retrospective debug logs: %@", error.localizedDescription];',
     'alert.informativeText = ' + F('Failed to save retrospective debug logs: %@', 'AppKit', '保存调试日志失败警告内容') + ', error.localizedDescription];'),
    # L3294: alert informativeText
    ('alert.informativeText = [NSString stringWithFormat:@"Could not install the Python runtime: %@",\n                                     error.localizedDescription ?: @"unknown error"];',
     'alert.informativeText = ' + F('Could not install the Python runtime: %@', 'AppKit', '安装Python运行时失败警告内容') + ',\n                                     error.localizedDescription ?: @"unknown error"];'),
    # L3387: alert informativeText
    ('alert.informativeText = [NSString stringWithFormat:@"Could not prepare the Python environment for the REPL: %@",\n                                     error.localizedDescription];',
     'alert.informativeText = ' + F('Could not prepare the Python environment for the REPL: %@', 'AppKit', '准备REPL Python环境失败警告内容') + ',\n                                     error.localizedDescription];'),
    # L3539: alert informativeText
    ('alert.informativeText = [NSString stringWithFormat:@"GPU rendering is off in the current session because %@", reason];',
     'alert.informativeText = ' + F('GPU rendering is off in the current session because %@', 'AppKit', 'GPU渲染关闭警告内容') + ', reason];'),
    
    # === Settings/ProfilesColorsPreferencesViewController.m ===
    # L773: alert informativeText
    ('alert.informativeText = [NSString stringWithFormat:@"Could not save to %@", item.displayName];',
     'alert.informativeText = ' + F('Could not save to %@', 'Settings', '无法保存警告内容') + ', item.displayName];'),
    
    # === API/iTermScriptsMenuController.m ===
    # L1246: warning title
    ('warning.title = [NSString stringWithFormat:@"Open new script in %@?", app];',
     'warning.title = ' + F('Open new script in %@?', 'API', '在新脚本中打开警告标题') + ', app];'),
    
    # === API/iTermAPIScriptLauncher.m ===
    # L522: base string
    ('NSString *base = [NSString stringWithFormat:@"“%@” uses an Intel-only Python environment, which cannot run on this version of macOS because Rosetta is not available.", name];',
     'NSString *base = ' + F('“%@” uses an Intel-only Python environment, which cannot run on this version of macOS because Rosetta is not available.', 'API', 'Intel专用Python环境警告') + ', name];'),
    
    # === ProcessInfo/iTermJobTreeViewController.m ===
    # L145: tooltip
    ('[self setToolTip:[NSString stringWithFormat:@"SIG%@ (%d)", signalNames[i], i]];',
     '[self setToolTip:' + F('SIG%@ (%d)', 'ProcessInfo', '信号工具提示') + ', signalNames[i], i]];',
     2),  # appears 2 times? let me check
    
    # === TerminalView/PseudoTerminal.m ===
    # L2862: window title format
    ('return [NSString stringWithFormat:@"%@ — %@", self.window.title, @(number_ + 1)];',
     'return ' + F('%@ — %@', 'TerminalView', '窗口标题格式') + ', self.window.title, @(number_ + 1)];'),
    # L2867: window title format
    ('return [NSString stringWithFormat:@"%@ — %@", _contentView.windowTitle, formattedShortcut];',
     'return ' + F('%@ — %@', 'TerminalView', '窗口标题格式2') + ', _contentView.windowTitle, formattedShortcut];'),
]

# ============================================================================
# Main loop
# ============================================================================
SRCS = [
    'sources/AppKit/iTermApplicationDelegate.m',
    'sources/Settings/ProfilesColorsPreferencesViewController.m',
    'sources/API/iTermScriptsMenuController.m',
    'sources/API/iTermAPIScriptLauncher.m',
    'sources/ProcessInfo/iTermJobTreeViewController.m',
    'sources/TerminalView/PseudoTerminal.m',
]

total = 0
for src in SRCS:
    try:
        s = open(src, encoding='utf-8').read()
    except FileNotFoundError:
        print(f'{src}: FILE NOT FOUND')
        sys.exit(1)

    count = 0
    for item in EDITS:
        if len(item) == 4:
            old, new, expected = item[0], item[1], item[3]
        else:
            old, new = item[0], item[1]
            expected = 1
        if old not in s:
            continue
        n = s.count(old)
        if n == 0:
            continue
        if n != expected:
            print(f'{src}: expected {expected} but found {n} for {old[:60]!r}')
            continue
        s = s.replace(old, new)
        count += n

    if count > 0:
        open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {count} edits OK')
    total += count

print(f'Remaining stringWithFormat wrap done: {total} edits total')
