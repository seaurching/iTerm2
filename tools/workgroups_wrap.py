# -*- coding: utf-8 -*-
"""Wrap user-visible English strings in Workgroups Swift files with
NSLocalizedString("key", tableName: "Workgroups", comment: "...").
All files are Swift — no ObjC wrappers needed.
"""
import sys, warnings
warnings.filterwarnings('ignore')

SRCS = [
    'sources/Workgroups/CodeReviewPromptManagerWindowController.swift',
    'sources/Workgroups/CodeReviewPromptView.swift',
    'sources/Workgroups/DiffWaitingPromptView.swift',
    'sources/Workgroups/SessionView+DiffWaitingPromptOverlay.swift',
    'sources/Workgroups/iTermWorkgroup.swift',
    'sources/Workgroups/iTermWorkgroupDetailViewController.swift',
    'sources/Workgroups/iTermWorkgroupInstance.swift',
    'sources/Workgroups/iTermWorkgroupsEditingViewController.swift',
    'sources/Workgroups/iTermWorkgroupPeerPort.swift',
    'sources/Workgroups/iTermWorkgroupSessionDetailViewController.swift',
    'sources/Workgroups/iTermWorkgroupToolbarItemRegistry.swift',
    'sources/Workgroups/WorkgroupAutoRequestReviewToolbarItem.swift',
    'sources/Workgroups/WorkgroupAutoSendClippingsToolbarItem.swift',
    'sources/Workgroups/WorkgroupMenu.swift',
    'sources/Workgroups/WorkgroupModeSwitcherItem.swift',
    'sources/Workgroups/WorkgroupNavigationToolbarItem.swift',
    'sources/Workgroups/WorkgroupPresets.swift',
    'sources/Workgroups/WorkgroupVisualView.swift',
]

def W(key, comment):
    return f'NSLocalizedString("{key}", tableName: "Workgroups", comment: "{comment}")'

def F(key, comment, *args):
    fmt = W(key, comment)
    return f'String(format: {fmt}, {", ".join(args)})'

edits = []

# ============================================================================
# CodeReviewPromptManagerWindowController.swift
# ============================================================================
edits += [
    # L55: window title
    ('        window.title = "Code Review Prompts"',
     '        window.title = ' + W('Code Review Prompts', '代码评审提示窗口标题')),
    # L138: column title
    ('        nameColumn.title = "Name"',
     '        nameColumn.title = ' + W('Name', '名称列标题')),
    # L149: accessibility
    ('                     accessibilityDescription: "Add")!,',
     '                     accessibilityDescription: ' + W('Add', '添加按钮无障碍描述') + ')!,'),
    # L151: accessibility
    ('                     accessibilityDescription: "Remove")!',
     '                     accessibilityDescription: ' + W('Remove', '移除按钮无障碍描述') + ')!'),
    # L163: label
    ('        let nameLabel = NSTextField(labelWithString: "Name:")',
     '        let nameLabel = NSTextField(labelWithString: ' + W('Name:', '名称标签') + ')'),
    # L178: placeholder
    ('        nameInput.placeholderString = "Untitled"',
     '        nameInput.placeholderString = ' + W('Untitled', '未命名占位符')),
    # L184: label
    ('        let bodyLabel = NSTextField(labelWithString: "Prompt:")',
     '        let bodyLabel = NSTextField(labelWithString: ' + W('Prompt:', '提示标签') + ')'),
    # L224: label (wrappingLabelWithString)
    ('            "Select a prompt on the left to edit it, or click + to add a new prompt.")',
     '            ' + W('Select a prompt on the left to edit it, or click + to add a new prompt.', '空提示选择引导标签') + ')'),
    # L432: default prompt name
    ('        let name = uniqueName(basedOn: "New Prompt")',
     '        let name = uniqueName(basedOn: ' + W('New Prompt', '新提示默认名称') + ')'),
    # L457: unique name with interpolation
    ('        return "\\(base) \\(i)"',
     '        return ' + F('%@ %d', '唯一提示名称格式', 'base', 'i')),
]

# ============================================================================
# CodeReviewPromptView.swift
# ============================================================================
edits += [
    # L67: label
    ('        titleLabel = NSTextField(labelWithString: "Code review prompt:")',
     '        titleLabel = NSTextField(labelWithString: ' + W('Code review prompt:', '代码评审提示标签') + ')'),
    # L102: button title
    ('        startButton.title = "Start"',
     '        startButton.title = ' + W('Start', '开始按钮标题')),
    # L265: menu header
    ('        menu.addItem(withTitle: "Prompts", action: nil, keyEquivalent: "")',
     '        menu.addItem(withTitle: ' + W('Prompts', '提示菜单标题') + ', action: nil, keyEquivalent: "")'),
    # L280: menu item
    ('        let saveItem = NSMenuItem(title: "Save Current as New…",',
     '        let saveItem = NSMenuItem(title: ' + W('Save Current as New…', '保存为新提示菜单项') + ','),
    # L287: menu item
    ('        let manageItem = NSMenuItem(title: "Manage Prompts…",',
     '        let manageItem = NSMenuItem(title: ' + W('Manage Prompts…', '管理提示菜单项') + ','),
    # L312: alert messageText
    ('        alert.messageText = "Name this prompt"',
     '        alert.messageText = ' + W('Name this prompt', '命名提示弹窗标题')),
    # L313-314: alert informativeText
    ('        alert.informativeText =\n            "Saved prompts can be re-loaded from the Prompts pulldown."',
     '        alert.informativeText =\n            ' + W('Saved prompts can be re-loaded from the Prompts pulldown.', '保存提示可从提示下拉菜单重新加载')),
    # L315: alert button
    ('        alert.addButton(withTitle: "Save")',
     '        alert.addButton(withTitle: ' + W('Save', '保存按钮标题') + ')'),
    # L316: alert button
    ('        alert.addButton(withTitle: "Cancel")',
     '        alert.addButton(withTitle: ' + W('Cancel', '取消按钮标题') + ')'),
    # L319: placeholder
    ('        field.placeholderString = "Prompt name"',
     '        field.placeholderString = ' + W('Prompt name', '提示名称占位符')),
]

# ============================================================================
# DiffWaitingPromptView.swift
# ============================================================================
edits += [
    # L89: button title
    ('        runAnywayButton.title = "Run Anyway"',
     '        runAnywayButton.title = ' + W('Run Anyway', '仍然运行按钮标题')),
    # L96: button title
    ('        cancelButton.title = "Cancel"',
     '        cancelButton.title = ' + W('Cancel', '取消按钮标题')),
]

# ============================================================================
# SessionView+DiffWaitingPromptOverlay.swift
# ============================================================================
edits += [
    # L22: title (multi-line string concat)
    ('                title: "Diff session is waiting for changes.",',
     '                title: ' + W('Diff session is waiting for changes.', 'Diff会话等待变更标题') + ','),
    # L23-28: body (multi-line string concat)
    ('                body: "This session is set to Diff mode and only starts its "\n'
     '                    + "command when git reports staged or unstaged changes. "\n'
     '                    + "The working tree is currently clean, or iTerm2 hasn\'t "\n'
     '                    + "finished its first check yet. Edit a file (or stage one) "\n'
     '                    + "and the command will start on its own. To run it now "\n'
     '                    + "anyway, click below.",',
     '                body: ' + W('This session is set to Diff mode and only starts its command when git reports staged or unstaged changes. The working tree is currently clean, or iTerm2 hasn\'t finished its first check yet. Edit a file (or stage one) and the command will start on its own. To run it now anyway, click below.', 'Diff会话等待变更正文') + ','),
    # L47: title
    ('                title: "Reload queued. Waiting for changes.",',
     '                title: ' + W('Reload queued. Waiting for changes.', '重载排队等待变更标题') + ','),
    # L48-52: body
    ('                body: "This session is set to Diff mode, so Reload will "\n'
     '                    + "re-run the command only after git reports staged or "\n'
     '                    + "unstaged changes. The previous output is still on "\n'
     '                    + "screen behind this panel. Cancel to keep that output "\n'
     '                    + "and abandon the reload, or run the command now anyway.",',
     '                body: ' + W('This session is set to Diff mode, so Reload will re-run the command only after git reports staged or unstaged changes. The previous output is still on screen behind this panel. Cancel to keep that output and abandon the reload, or run the command now anyway.', '重载排队等待变更正文') + ','),
]

# ============================================================================
# iTermWorkgroup.swift
# ============================================================================
edits += [
    # L36: displayName
    ('            displayName: "Main")',
     '            displayName: ' + W('Main', '主会话默认显示名称') + ')'),
]

# ============================================================================
# iTermWorkgroupDetailViewController.swift
# ============================================================================
edits += [
    # L47-48: label
    ('        emptyLabel = NSTextField(labelWithString:\n            "Select a workgroup on the left or click + to create one.")',
     '        emptyLabel = NSTextField(labelWithString:\n            ' + W('Select a workgroup on the left or click + to create one.', '空工作组选择引导标签') + ')'),
    # L53: button title
    ('        whatIsButton = NSButton(title: "What is a Workgroup?",',
     '        whatIsButton = NSButton(title: ' + W('What is a Workgroup?', '什么是工作组按钮标题') + ','),
    # L62: placeholder
    ('        nameField.placeholderString = "Workgroup name"',
     '        nameField.placeholderString = ' + W('Workgroup name', '工作组名称占位符')),
    # L322: menu item
    ('        let peer = menu.addItem(withTitle: "Add Peer",',
     '        let peer = menu.addItem(withTitle: ' + W('Add Peer', '添加对等体菜单项') + ','),
    # L326: menu item
    ('        let split = menu.addItem(withTitle: "Add Split",',
     '        let split = menu.addItem(withTitle: ' + W('Add Split', '添加分屏菜单项') + ','),
    # L333: menu item
    ('        let tab = menu.addItem(withTitle: "Add Tab",',
     '        let tab = menu.addItem(withTitle: ' + W('Add Tab', '添加标签页菜单项') + ','),
    # L420: undo action name
    ('        parentEditor?.replaceSelectedWorkgroup(wg, actionName: "Add Session")',
     '        parentEditor?.replaceSelectedWorkgroup(wg, actionName: ' + W('Add Session', '添加会话撤销操作名称') + ')'),
    # L447: undo action name
    ('        parentEditor?.replaceSelectedWorkgroup(wg, actionName: "Remove Session")',
     '        parentEditor?.replaceSelectedWorkgroup(wg, actionName: ' + W('Remove Session', '移除会话撤销操作名称') + ')'),
    # L512: undo action name
    ('        parentEditor?.replaceSelectedWorkgroup(wg, actionName: "Rename Workgroup")',
     '        parentEditor?.replaceSelectedWorkgroup(wg, actionName: ' + W('Rename Workgroup', '重命名工作组撤销操作名称') + ')'),
    # L576: label
    ('            return "Main session"',
     '            return ' + W('Main session', '主会话标签')),
    # L578: label with interpolation
    ('            return "Peer: \\(session.displayName)"',
     '            return ' + F('Peer: %@', '对等体标签', 'session.displayName')),
    # L580: label
    ('            let dir = s.orientation == .vertical ? "Vertical" : "Horizontal"',
     '            let dir = s.orientation == .vertical ? ' + W('Vertical', '垂直方向标签') + ' : ' + W('Horizontal', '水平方向标签')),
    # L582: label with interpolation
    ('            return "Split: \\(dir) \\(pct)%"',
     '            return ' + F('Split: %@ %d%%', '分屏标签', 'dir', 'pct')),
    # L584: label
    ('            return "Tab"',
     '            return ' + W('Tab', '标签页标签')),
    # L622: undo action name
    ('                                               actionName: "Change Split Location")',
     '                                               actionName: ' + W('Change Split Location', '更改分屏位置撤销操作名称') + ')'),
]

# ============================================================================
# iTermWorkgroupInstance.swift
# ============================================================================
edits += [
    # L131: default name
    ('        return workgroup.name.isEmpty ? "Untitled" : workgroup.name',
     '        return workgroup.name.isEmpty ? ' + W('Untitled', '未命名工作组') + ' : workgroup.name'),
    # L191: singular/plural
    ('        let sessionWord = extraCount == 1 ? "session" : "sessions"',
     '        let sessionWord = extraCount == 1 ? ' + W('session', '单个会话') + ' : ' + W('sessions', '多个会话')),
    # L193: confirmation message (with curly quotes — use plain string)
    ('            return "This will also exit the workgroup “\\(names[0])” and close \\(extraCount) other \\(sessionWord)."',
     '            return ' + F('This will also exit the workgroup “%@” and close %d other %@.', '退出工作组确认消息', 'names[0]', 'extraCount', 'sessionWord')),
    # L195: confirmation message
    ('        return "This will also exit \\(names.count) workgroups and close \\(extraCount) other \\(sessionWord)."',
     '        return ' + F('This will also exit %d workgroups and close %d other %@.', '退出多个工作组确认消息', 'names.count', 'extraCount', 'sessionWord')),
]

# ============================================================================
# iTermWorkgroupsEditingViewController.swift
# ============================================================================
edits += [
    # L56: column title
    ('        column.title = "Name"',
     '        column.title = ' + W('Name', '名称列标题')),
    # L81: menu item
    ('        let titleItem = NSMenuItem(title: "Add Preset",',
     '        let titleItem = NSMenuItem(title: ' + W('Add Preset', '添加预设菜单项') + ','),
]

# ============================================================================
# iTermWorkgroupPeerPort.swift
# ============================================================================
edits += [
    # L94: default peer label
    ('             label: cfg.displayName.isEmpty ? "Peer" : cfg.displayName,',
     '             label: cfg.displayName.isEmpty ? ' + W('Peer', '对等体默认标签') + ' : cfg.displayName,'),
]

# ============================================================================
# iTermWorkgroupSessionDetailViewController.swift
# ============================================================================
edits += [
    # L100: label
    ('        emptyLabel = NSTextField(labelWithString: "No session selected.")',
     '        emptyLabel = NSTextField(labelWithString: ' + W('No session selected.', '未选择会话标签') + ')'),
    # L225: label
    ('        let splitLabel = NSTextField(labelWithString: "Split:")',
     '        let splitLabel = NSTextField(labelWithString: ' + W('Split:', '分屏标签') + ')'),
    # L232: accessibility
    ('                                       accessibilityDescription: "Vertical"),',
     '                                       accessibilityDescription: ' + W('Vertical', '垂直方向无障碍描述') + '),'),
    # L234: accessibility
    ('                                         accessibilityDescription: "Horizontal") {',
     '                                         accessibilityDescription: ' + W('Horizontal', '水平方向无障碍描述') + ') {'),
    # L260: label
    ('        let locationLabel = NSTextField(labelWithString: "Location:")',
     '        let locationLabel = NSTextField(labelWithString: ' + W('Location:', '位置标签') + ')'),
    # L283: label
    ('        toolbarHeaderLabel = NSTextField(labelWithString: "Toolbar Items:")',
     '        toolbarHeaderLabel = NSTextField(labelWithString: ' + W('Toolbar Items:', '工具栏项目标签') + ')'),
    # L335: label
    ('        let minLabel = NSTextField(labelWithString: "Min width:")',
     '        let minLabel = NSTextField(labelWithString: ' + W('Min width:', '最小宽度标签') + ')'),
    # L345: label
    ('        let maxLabel = NSTextField(labelWithString: "Max width:")',
     '        let maxLabel = NSTextField(labelWithString: ' + W('Max width:', '最大宽度标签') + ')'),
    # L366: label
    ('        backShortcutLabel = NSTextField(labelWithString: "Back:")',
     '        backShortcutLabel = NSTextField(labelWithString: ' + W('Back:', '后退标签') + ')'),
    # L374: label
    ('        forwardShortcutLabel = NSTextField(labelWithString: "Forward:")',
     '        forwardShortcutLabel = NSTextField(labelWithString: ' + W('Forward:', '前进标签') + ')'),
    # L382: label
    ('        reloadShortcutLabel = NSTextField(labelWithString: "Reload:")',
     '        reloadShortcutLabel = NSTextField(labelWithString: ' + W('Reload:', '重载标签') + ')'),
    # L774: undo action name
    ('        commitUpdate(s, actionName: "Change Profile") { [weak self] in',
     '        commitUpdate(s, actionName: ' + W('Change Profile', '更改配置撤销操作名称') + ') { [weak self] in'),
    # L785: undo action name
    ('        commitUpdate(s, actionName: "Change Mode")',
     '        commitUpdate(s, actionName: ' + W('Change Mode', '更改模式撤销操作名称') + ')'),
    # L794: undo action name
    ('        commitUpdate(s, actionName: "Change Orientation")',
     '        commitUpdate(s, actionName: ' + W('Change Orientation', '更改方向撤销操作名称') + ')'),
    # L802: undo action name
    ('        commitUpdate(s, actionName: "Change Side")',
     '        commitUpdate(s, actionName: ' + W('Change Side', '更改侧边撤销操作名称') + ')'),
    # L812: undo action name (no trailing closure)
    ('        commitUpdate(s, actionName: "Change Split Location")\n    }',
     '        commitUpdate(s, actionName: ' + W('Change Split Location', '更改分屏位置撤销操作名称') + ')\n    }'),
    # L996: undo action name
    ('        commitUpdate(s, actionName: "Add Toolbar Item") { [weak self] in',
     '        commitUpdate(s, actionName: ' + W('Add Toolbar Item', '添加工具栏项撤销操作名称') + ') { [weak self] in'),
    # L1015: undo action name
    ('        commitUpdate(s, actionName: "Remove Toolbar Item") { [weak self] in',
     '        commitUpdate(s, actionName: ' + W('Remove Toolbar Item', '移除工具栏项撤销操作名称') + ') { [weak self] in'),
    # L1109: undo action name (appears 3 times: L1109, L1151, L1159)
    ('                commitUpdate(s, actionName: "Rename Peer")',
     '                commitUpdate(s, actionName: ' + W('Rename Peer', '重命名对等体撤销操作名称') + ')', 3),
    # L1114: undo action name
    ('                commitUpdate(s, actionName: "Change Command")',
     '                commitUpdate(s, actionName: ' + W('Change Command', '更改命令撤销操作名称') + ')'),
    # L1119: undo action name
    ('                commitUpdate(s, actionName: "Change Per-File Command")',
     '                commitUpdate(s, actionName: ' + W('Change Per-File Command', '更改每文件命令撤销操作名称') + ')'),
    # L1124: undo action name
    ('                commitUpdate(s, actionName: "Change URL")',
     '                commitUpdate(s, actionName: ' + W('Change URL', '更改URL撤销操作名称') + ')'),
    # L1198: undo action name
    ('        commitUpdate(s, actionName: "Change Spacer Width") { [weak self] in',
     '        commitUpdate(s, actionName: ' + W('Change Spacer Width', '更改间隔宽度撤销操作名称') + ') { [weak self] in'),
    # L1271: undo action name
    ('        commitUpdate(s, actionName: "Reorder Toolbar Item") { [weak self] in',
     '        commitUpdate(s, actionName: ' + W('Reorder Toolbar Item', '重排工具栏项撤销操作名称') + ') { [weak self] in'),
    # L1325: spacer description with interpolation
    ('            return "\\(base) (\\(formatWidth(minWidth))\\u2013\\(formatWidth(maxWidth)) pt)"',
     '            return ' + F('%@ (%@–%@ pt)', '间隔描述格式', 'base', 'formatWidth(minWidth)', 'formatWidth(maxWidth)')),
    # L1355: undo action name
    ('            commitUpdate(s, actionName: "Change Peer Shortcut")',
     '            commitUpdate(s, actionName: ' + W('Change Peer Shortcut', '更改对等体快捷键撤销操作名称') + ')'),
    # L1372: undo action name (first)
    ('            commitUpdate(s, actionName: "Change Shortcut")',
     '            commitUpdate(s, actionName: ' + W('Change Shortcut', '更改快捷键撤销操作名称') + ')', 2),  # appears twice (L1372, L1375)
]

# ============================================================================
# WorkgroupAutoRequestReviewToolbarItem.swift
# ============================================================================
edits += [
    # L63: accessibility
    ('                               accessibilityDescription: "Auto-request review when idle")',
     '                               accessibilityDescription: ' + W('Auto-request review when idle', '自动请求审查无障碍描述') + ')'),
    # L66: tooltip
    ('            button.toolTip = "Auto-request a review when idle (needs exactly one code review session)"',
     '            button.toolTip = ' + W('Auto-request a review when idle (needs exactly one code review session)', '自动请求审查提示（需要恰好一个代码评审会话）')),
    # L71: tooltip on
    ('            ? "Auto-request a review from the code review session when idle: on"',
     '            ? ' + W('Auto-request a review from the code review session when idle: on', '自动请求审查提示（开）')),
    # L72: tooltip off
    ('            : "Auto-request a review from the code review session when idle: off"',
     '            : ' + W('Auto-request a review from the code review session when idle: off', '自动请求审查提示（关）')),
]

# ============================================================================
# WorkgroupAutoSendClippingsToolbarItem.swift
# ============================================================================
edits += [
    # L51: accessibility
    ('                               accessibilityDescription: "Auto-send clippings when idle")',
     '                               accessibilityDescription: ' + W('Auto-send clippings when idle', '自动发送剪辑无障碍描述') + ')'),
    # L55: tooltip on
    ('            ? "Auto-send clippings to the main session when idle: on"',
     '            ? ' + W('Auto-send clippings to the main session when idle: on', '自动发送剪辑提示（开）')),
    # L56: tooltip off
    ('            : "Auto-send clippings to the main session when idle: off"',
     '            : ' + W('Auto-send clippings to the main session when idle: off', '自动发送剪辑提示（关）')),
]

# ============================================================================
# WorkgroupMenu.swift
# ============================================================================
edits += [
    # L50: default name
    ('        let title = wg.name.isEmpty ? "Untitled" : wg.name',
     '        let title = wg.name.isEmpty ? ' + W('Untitled', '未命名工作组') + ' : wg.name'),
]

# ============================================================================
# WorkgroupNavigationToolbarItem.swift
# ============================================================================
edits += [
    # L48: tooltip action
    ('        backButton.toolTip = Self.tooltip(action: "Previous file",',
     '        backButton.toolTip = Self.tooltip(action: ' + W('Previous file', '上一个文件工具提示') + ','),
    # L50: tooltip action
    ('        forwardButton.toolTip = Self.tooltip(action: "Next file",',
     '        forwardButton.toolTip = Self.tooltip(action: ' + W('Next file', '下一个文件工具提示') + ','),
    # L52: tooltip action
    ('        reloadButton.toolTip = Self.tooltip(action: "Reload",',
     '        reloadButton.toolTip = Self.tooltip(action: ' + W('Reload', '重载工具提示') + ','),
    # L204: tooltip format
    ('        return "\\(action) (\\(keys))"',
     '        return ' + F('%@ (%@)', '工具提示格式', 'action', 'keys')),
]

# ============================================================================
# WorkgroupPresets.swift
# ============================================================================
edits += [
    # L24: preset display name
    ('            displayName: "Coding Agent + Diff",',
     '            displayName: ' + W('Coding Agent + Diff', '预设：编码代理+Diff') + ','),
    # L28: preset display name
    ('            displayName: "Coding Agent + Diff + Code Review",',
     '            displayName: ' + W('Coding Agent + Diff + Code Review', '预设：编码代理+Diff+代码评审') + ','),
]

# ============================================================================
# WorkgroupVisualView.swift
# ============================================================================
edits += [
    # L176: label
    ('        let text = "No workgroup" as NSString',
     '        let text = ' + W('No workgroup', '无工作组标签') + ' as NSString'),
    # L210: tab label
    ('        case .root: return "Main"',
     '        case .root: return ' + W('Main', '主标签页标签'), 3),  # appears 3 times (L210, L297, L413)
    # L211: tab label (appears 3 times: L211, L299, L416)
    ('        case .tab: return "Tab"',
     '        case .tab: return ' + W('Tab', '标签页标签'), 3),
    # L212: default label
    ('        default: return "?"',
     '        default: return ' + W('?', '未知标签')),
    # L298: peer label
    ('        case .peer: return "Peer"',
     '        case .peer: return ' + W('Peer', '对等体标签'), 2),  # appears 2 times (L298, L414)
    # L300: split label
    ('        case .split: return "Split"',
     '        case .split: return ' + W('Split', '分屏标签'), 2),  # appears 2 times (L300, L415)
    # L416: tab label (3rd occurrence)
    ('        case .tab: return "Tab"',
     '        case .tab: return ' + W('Tab', '标签页标签'), 2),
]

# ============================================================================
# iTermWorkgroupToolbarItemRegistry.swift
# ============================================================================
edits += [
    # L28: displayName
    ('              displayName: "Git Status",',
     '              displayName: ' + W('Git Status', 'Git状态工具栏项名称') + ','),
    # L32: displayName
    ('              displayName: "Changed File Selector",',
     '              displayName: ' + W('Changed File Selector', '已更改文件选择器工具栏项名称') + ','),
    # L36: displayName
    ('              displayName: "Peer Mode Switcher",',
     '              displayName: ' + W('Peer Mode Switcher', '对等体模式切换器工具栏项名称') + ','),
    # L40: displayName
    ('              displayName: "Navigation Buttons",',
     '              displayName: ' + W('Navigation Buttons', '导航按钮工具栏项名称') + ','),
    # L44: displayName
    ('              displayName: "Reload",',
     '              displayName: ' + W('Reload', '重载工具栏项名称') + ','),
    # L48: displayName
    ('              displayName: "Git Base Selector",',
     '              displayName: ' + W('Git Base Selector', 'Git基准选择器工具栏项名称') + ','),
    # L52: displayName
    ('              displayName: "Auto-Send Clippings When Idle",',
     '              displayName: ' + W('Auto-Send Clippings When Idle', '空闲时自动发送剪辑工具栏项名称') + ','),
    # L56: displayName
    ('              displayName: "Auto-Request Review When Idle",',
     '              displayName: ' + W('Auto-Request Review When Idle', '空闲时自动请求审查工具栏项名称') + ','),
    # L60: displayName
    ('              displayName: "Spacer",',
     '              displayName: ' + W('Spacer', '间隔工具栏项名称') + ','),
]

# ============================================================================
# WorkgroupPresets.swift (additional)
# ============================================================================
edits += [
    # L63: displayName (appears 2 times: L63, L106)
    ('            displayName: "Diff",',
     '            displayName: ' + W('Diff', 'Diff预设显示名称') + ',', 2),
    # L69: workgroup name
    ('            name: "Coding Agent + Diff",',
     '            name: ' + W('Coding Agent + Diff', '编码代理+Diff工作组名称') + ','),
    # L83: default parameter
    ('        name: String = "Coding Agent + Diff + Code Review"',
     '        name: String = ' + W('Coding Agent + Diff + Code Review', '编码代理+Diff+代码评审工作组名称')),
    # L93: displayName
    ('            displayName: "Chat")',
     '            displayName: ' + W('Chat', 'Chat预设显示名称') + ')'),
    # L106: displayName
    ('            displayName: "Diff",',
     '            displayName: ' + W('Diff', 'Diff预设显示名称') + ','),
    # L125: displayName
    ('            displayName: "Code Review",',
     '            displayName: ' + W('Code Review', '代码评审预设显示名称') + ','),
]

# ============================================================================
# iTermWorkgroupSessionDetailViewController.swift (additional)
# ============================================================================
edits += [
    # L742: profile popup
    ('        profilePopup.addItem(withTitle: "Default")',
     '        profilePopup.addItem(withTitle: ' + W('Default', '默认配置文件菜单项') + ')'),
    # L105: label
    ('        profileRow = makeLabeledRow(labelText: "Profile:",',
     '        profileRow = makeLabeledRow(labelText: ' + W('Profile:', '配置文件标签') + ','),
    # L107: label
    ('        modeRow = makeLabeledRow(labelText: "Mode:",',
     '        modeRow = makeLabeledRow(labelText: ' + W('Mode:', '模式标签') + ','),
    # L109: label
    ('        commandRow = makeLabeledRow(labelText: "Command:",',
     '        commandRow = makeLabeledRow(labelText: ' + W('Command:', '命令标签') + ','),
    # L112: label
    ('            labelText: "File command:",',
     '            labelText: ' + W('File command:', '文件命令标签') + ','),
    # L114: label
    ('        urlRow = makeLabeledRow(labelText: "URL:", control: makeURLField())',
     '        urlRow = makeLabeledRow(labelText: ' + W('URL:', 'URL标签') + ', control: makeURLField())'),
    # L115: label
    ('        peerRow = makeLabeledRow(labelText: "Name:",',
     '        peerRow = makeLabeledRow(labelText: ' + W('Name:', '名称标签') + ','),
    # L117: label
    ('        peerShortcutRow = makeLabeledRow(labelText: "Shortcut:",',
     '        peerShortcutRow = makeLabeledRow(labelText: ' + W('Shortcut:', '快捷键标签') + ','),
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
    for item in edits:
        if len(item) == 4:
            old, new, expected = item[0], item[1], item[3]
        elif len(item) == 3:
            old, new, expected = item[0], item[1], item[2]
        else:
            old, new = item[0], item[1]
            expected = 1
        if old not in s:
            continue
        n = s.count(old)
        if n == 0:
            continue
        if n != expected:
            print(f'{src}: expected {expected} replacements for old={old!r}, found {n}')
            sys.exit(1)
        s = s.replace(old, new)
        count += n

    if count > 0:
        open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {count} edits OK')
    total += count

print(f'Workgroups Swift wrap done: {total} edits total')
