# -*- coding: utf-8 -*-
"""Wrap UI strings in Clippings and Companion directories.
"""
import sys, warnings
warnings.filterwarnings('ignore')

def W(key, table, comment):
    return f'NSLocalizedString("{key}", tableName: "{table}", comment: "{comment}")'

# ============================================================================
# Clippings edits (6 strings)
# ============================================================================
CLIPPINGS_EDITS = [
    # ClippingsView.swift L184: toolTip
    ('closeButton.toolTip = "Hide clippings"',
     'closeButton.toolTip = ' + W('Hide clippings', 'Clippings', '隐藏剪辑工具提示')),
    # ClippingsView.swift L281: toolTip (with interpolation)
    ('historyStatusLabel.toolTip = "Viewing archived clippings (\\(historyIndex + 1) of \\(total))"',
     'historyStatusLabel.toolTip = String(format: ' + W('Viewing archived clippings (%d of %d)', 'Clippings', '查看归档剪辑工具提示') + ', historyIndex + 1, total)'),
    # ClippingsView.swift L618: toolTip
    ('previewButton.toolTip = "Preview (Space)"',
     'previewButton.toolTip = ' + W('Preview (Space)', 'Clippings', '预览工具提示')),
    # AddClippingPanel.swift L28: panel title
    ('panel.title = "New Clipping"',
     'panel.title = ' + W('New Clipping', 'Clippings', '新建剪辑面板标题')),
    # AddClippingPanel.swift L64: button title
    ('let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))',
     'let cancel = NSButton(title: ' + W('Cancel', 'Clippings', '取消按钮标题') + ', target: self, action: #selector(cancelClicked))'),
    # AddClippingPanel.swift L76: button title
    ('let add = NSButton(title: "Add", target: self, action: #selector(addClicked))',
     'let add = NSButton(title: ' + W('Add', 'Clippings', '添加按钮标题') + ', target: self, action: #selector(addClicked))'),
]

# ============================================================================
# Companion edits (18 strings)
# ============================================================================
COMPANION_EDITS = [
    # CompanionPairingController.swift L112: alert messageText
    ('alert.messageText = "Companion Device Needs an Update"',
     'alert.messageText = ' + W('Companion Device Needs an Update', 'Companion', '伴侣设备需要更新警告标题')),
    # L113: alert informativeText
    ('alert.informativeText = "The iTerm2 Buddy app on your phone is too old to connect to "',
     'alert.informativeText = ' + W('The iTerm2 Buddy app on your phone is too old to connect to ', 'Companion', '伴侣设备需要更新警告内容')),
    # L116: alert messageText
    ('alert.messageText = "iTerm2 Needs an Update"',
     'alert.messageText = ' + W('iTerm2 Needs an Update', 'Companion', 'iTerm2需要更新警告标题')),
    # L117: alert informativeText
    ('alert.informativeText = "This version of iTerm2 is too old to connect to the iTerm2 "',
     'alert.informativeText = ' + W('This version of iTerm2 is too old to connect to the iTerm2 ', 'Companion', 'iTerm2需要更新警告内容')),
    # L122: alert button
    ('alert.addButton(withTitle: "OK")',
     'alert.addButton(withTitle: ' + W('OK', 'Companion', '确定按钮标题') + ')'),
    # L178: alert messageText
    ('alert.messageText = "Re-pair Your Companion Device"',
     'alert.messageText = ' + W('Re-pair Your Companion Device', 'Companion', '重新配对警告标题')),
    # L184: alert button
    ('alert.addButton(withTitle: "Re-pair…")',
     'alert.addButton(withTitle: ' + W('Re-pair…', 'Companion', '重新配对按钮标题') + ')'),
    # L185: alert button
    ('alert.addButton(withTitle: "Later")',
     'alert.addButton(withTitle: ' + W('Later', 'Companion', '稍后按钮标题') + ')'),
    # CompanionPresenceController.swift L131: menu item
    ('NSMenuItem(title: "Companion Device Settings…",',
     'NSMenuItem(title: ' + W('Companion Device Settings…', 'Companion', '伴侣设备设置菜单项') + ','),
    # CompanionPairingWindowController.swift L27: button title
    ('NSButton(title: "Install Companion App on your iPhone", target: nil, action: nil)',
     'NSButton(title: ' + W('Install Companion App on your iPhone', 'Companion', '安装伴侣应用按钮标题') + ', target: nil, action: nil)'),
    # L42: button title
    ('NSButton(title: "Unpair", target: nil, action: nil)',
     'NSButton(title: ' + W('Unpair', 'Companion', '取消配对按钮标题') + ', target: nil, action: nil)'),
    # L55: button title
    ('NSButton(title: "Verify", target: nil, action: nil)',
     'NSButton(title: ' + W('Verify', 'Companion', '验证按钮标题') + ', target: nil, action: nil)'),
    # L56: button title
    ('NSButton(title: "Cancel Pairing", target: nil, action: nil)',
     'NSButton(title: ' + W('Cancel Pairing', 'Companion', '取消配对按钮标题') + ', target: nil, action: nil)'),
    # L97: panel title
    ('panel.title = "Companion Device Settings"',
     'panel.title = ' + W('Companion Device Settings', 'Companion', '伴侣设备设置面板标题')),
    # CompanionWizardWindowController.swift L71: panel title
    ('panel.title = "Set Up a Companion Device"',
     'panel.title = ' + W('Set Up a Companion Device', 'Companion', '设置伴侣设备面板标题')),
    # L398: alert messageText
    ('alert.messageText = "Setup Could Not Be Completed"',
     'alert.messageText = ' + W('Setup Could Not Be Completed', 'Companion', '设置未完成警告标题')),
    # L401: alert button
    ('alert.addButton(withTitle: "OK")',
     'alert.addButton(withTitle: ' + W('OK', 'Companion', '确定按钮标题') + ')'),
    # L473: button title
    ('NSButton(title: "Show Pairing Code", target: self, action: #selector(showPairingCodePressed))',
     'NSButton(title: ' + W('Show Pairing Code', 'Companion', '显示配对码按钮标题') + ', target: self, action: #selector(showPairingCodePressed))'),
]

# ============================================================================
# Main loop
# ============================================================================
DIRS = [
    ('sources/Clippings/ClippingsView.swift', 'Clippings', CLIPPINGS_EDITS[:3]),
    ('sources/Clippings/AddClippingPanel.swift', 'Clippings', CLIPPINGS_EDITS[3:]),
    ('sources/Companion/CompanionPairingController.swift', 'Companion', COMPANION_EDITS[:9]),
    ('sources/Companion/CompanionPresenceController.swift', 'Companion', COMPANION_EDITS[9:10]),
    ('sources/Companion/CompanionPairingWindowController.swift', 'Companion', COMPANION_EDITS[10:15]),
    ('sources/Companion/CompanionWizardWindowController.swift', 'Companion', COMPANION_EDITS[15:]),
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

print(f'Clippings/Companion wrap done: {total} edits total')
