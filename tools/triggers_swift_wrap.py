# -*- coding: utf-8 -*-
# Wrap user-visible strings in Triggers Swift sources with
# NSLocalizedString("key", tableName: "Triggers", comment: "...").
#
# Table: Triggers
# Sources: 17 Swift files in sources/Triggers/
# (BrowserTrigger.swift and iTermEventTriggerEvaluator.swift are skipped:
#  the former has only protocol/enum/extension defs, the latter is all
#  RLog/DLog logging and internal logic — no user-visible strings.)
#
# Interpolated strings become:
#   String(format: NSLocalizedString("template %@", tableName: "Triggers",
#                                     comment: "..."), arg)
# For Any-typed params (self.param ?? ""), the arg is wrapped in
# String(describing:) since Any does not conform to CVarArg.
import re
import sys

SRCS = [
    'sources/Triggers/BufferInputTrigger.swift',
    'sources/Triggers/EnterWorkgroupBrowserTrigger.swift',
    'sources/Triggers/EnterWorkgroupTrigger.swift',
    'sources/Triggers/ExitWorkgroupBrowserTrigger.swift',
    'sources/Triggers/ExitWorkgroupTrigger.swift',
    'sources/Triggers/FoldTrigger.swift',
    'sources/Triggers/HighlightBrowserTrigger.swift',
    'sources/Triggers/HyperlinkBrowserTrigger.swift',
    'sources/Triggers/InjectJavascriptTrigger.swift',
    'sources/Triggers/InjectTrigger.swift',
    'sources/Triggers/ReaderModeBrowserTrigger.swift',
    'sources/Triggers/ReloadBrowserTrigger.swift',
    'sources/Triggers/SetNamedMarkTrigger.swift',
    'sources/Triggers/SetTabStatusTrigger.swift',
    'sources/Triggers/SetUserVariableTrigger.swift',
    'sources/Triggers/SGRTrigger.swift',
    'sources/Triggers/iTermEventTriggerParameterView.swift',
]

def W(key, comment):
    return f'NSLocalizedString("{key}", tableName: "Triggers", comment: "{comment}")'

def F(key, comment, *args):
    fmt = W(key, comment)
    return f'String(format: {fmt}, {", ".join(args)})'

edits = [
    # === BufferInputTrigger.swift ===
    ('            return "Buffer Input"',
     '            return ' + W('Buffer Input', '缓冲输入触发器描述：开始')),
    ('            return "Stop Buffering Input"',
     '            return ' + W('Stop Buffering Input', '缓冲输入触发器描述：停止')),
    ('        return "Buffer Input…"',
     '        return ' + W('Buffer Input…', '缓冲输入触发器标题')),
    ('        [ NSNumber(value: Tag.start.rawValue): "Start Buffering Input",',
     '        [ NSNumber(value: Tag.start.rawValue): ' + W('Start Buffering Input', '弹出菜单：开始缓冲输入') + ','),
    ('          NSNumber(value: Tag.stop.rawValue): "Stop Buffering Input" ]',
     '          NSNumber(value: Tag.stop.rawValue): ' + W('Stop Buffering Input', '弹出菜单：停止缓冲输入') + ' ]'),
    ('        NSAttributedString(string: shouldBuffer ? "Start buffering" : "Stop buffering",',
     '        NSAttributedString(string: shouldBuffer ? ' + W('Start buffering', '参数：开始缓冲') + ' : ' + W('Stop buffering', '参数：停止缓冲') + ','),

    # === EnterWorkgroupBrowserTrigger.swift / EnterWorkgroupTrigger.swift (shared keys) ===
    ('        return "Enter Workgroup…"',
     '        return ' + W('Enter Workgroup…', '进入工作组触发器标题')),
    ('        return "Enter Workgroup “\\(displayLabel(forID: effectiveID))”"',
     '        return ' + F('Enter Workgroup “%@”', '进入工作组触发器描述', 'displayLabel(forID: effectiveID)')),
    ('        guard let id, !id.isEmpty else { return "(unset)" }',
     '        guard let id, !id.isEmpty else { return ' + W('(unset)', '工作组：未设置') + ' }'),
    ('wg.name.isEmpty ? "Untitled" : wg.name',
     'wg.name.isEmpty ? ' + W('Untitled', '工作组：无标题') + ' : wg.name', 2),
    ('        return "(missing)"',
     '        return ' + W('(missing)', '工作组：缺失')),

    # === ExitWorkgroupBrowserTrigger.swift / ExitWorkgroupTrigger.swift (shared key) ===
    ('        return "Exit Workgroup"',
     '        return ' + W('Exit Workgroup', '退出工作组触发器'), 2),

    # === FoldTrigger.swift ===
    (r'        return "Fold to \(self.param ?? "")"',
     '        return ' + F('Fold to %@', '折叠触发器描述', 'String(describing: self.param ?? "")')),
    ('        return "Fold to Named Mark"',
     '        return ' + W('Fold to Named Mark', '折叠触发器标题')),
    ('        return "Name of Mark"',
     '        return ' + W('Name of Mark', '占位符：标记名称')),

    # === HighlightBrowserTrigger.swift ===
    ('        "Highlight Text"',
     '        ' + W('Highlight Text', '高亮文本触发器'), 2),
    ('        result.append(NSAttributedString(string:"Text: "))',
     '        result.append(NSAttributedString(string:' + W('Text: ', '参数标签：文本') + '))'),
    ('        result.append(NSAttributedString(string: " Background: "))',
     '        result.append(NSAttributedString(string: ' + W(' Background: ', '参数标签：背景') + '))'),

    # === HyperlinkBrowserTrigger.swift ===
    ('        "Make Hyperlink with URL “\(param as? String ?? "(nil)")”"',
     '        ' + F('Make Hyperlink with URL “%@”', '创建超链接触发器描述',
            'param as? String ?? NSLocalizedString("(nil)", tableName: "Triggers", comment: "超链接：无URL值")')),
    ('        "Make Hyperlink…"',
     '        ' + W('Make Hyperlink…', '创建超链接触发器标题')),
    # === InjectJavascriptTrigger.swift ===
    # L11 (description) + L15 (title): same key, appears twice
    ('        return "Inject Javascript (URL Regex)"',
     '        return ' + W('Inject Javascript (URL Regex)', '注入 JavaScript 触发器：URL 正则'), 2),
    # L67 (description) + L71 (title): same key, appears twice
    ('        return "Inject Javascript (Content Regex)"',
     '        return ' + W('Inject Javascript (Content Regex)', '注入 JavaScript 触发器：内容正则'), 2),
    # L25 (URL class) + L81 (Content class): same key, appears twice
    ('        return "Javascript"',
     '        return ' + W('Javascript', '占位符：JavaScript'), 2),

    # === InjectTrigger.swift ===
    ('        return "Inject Data “\(self.param ?? "")”"',
     '        return ' + F('Inject Data “%@”', '注入数据触发器描述', 'String(describing: self.param ?? "")')),
    ('        return "Inject Data…"',
     '        return ' + W('Inject Data…', '注入数据触发器标题')),
    # Placeholder contains literal backslash escapes (\\e, \\a); key keeps
    # the source-literal form with double backslashes.
    (r'        return "Use \\e for esc, \\a for ^G."',
     '        return ' + W(r'Use \\e for esc, \\a for ^G.', '占位符：使用转义说明')),

    # === ReaderModeBrowserTrigger.swift ===
    # L11 (description) + L15 (title): same key, appears twice
    ('        return "Enter Reader Mode"',
     '        return ' + W('Enter Reader Mode', '进入阅读模式触发器'), 2),

    # === ReloadBrowserTrigger.swift ===
    # L11 (description) has a typo: extra ')' before closing quote. The key
    # drops the stray ')' so description and title share one key.
    ('        return "Reload After Delay)"',
     '        return ' + W('Reload After Delay', '重新加载触发器描述')),
    ('        return "Reload After Delay"',
     '        return ' + W('Reload After Delay', '重新加载触发器标题')),
    ('        return "Delay in seconds"',
     '        return ' + W('Delay in seconds', '占位符：延迟秒数')),

    # === SetNamedMarkTrigger.swift ===
    (r'        return "Set Named Mark to \(self.param ?? "")"',
     '        return ' + F('Set Named Mark to %@', '设置命名标记触发器描述', 'String(describing: self.param ?? "")')),
    ('        return "Set Named Mark"',
     '        return ' + W('Set Named Mark', '设置命名标记触发器标题')),
    ('        return "Name for this mark"',
     '        return ' + W('Name for this mark', '占位符：标记名称')),

    # === SetTabStatusTrigger.swift ===
    # L59: expression-body title (no return keyword)
    ('    override static var title: String { "Set Tab Status…" }',
     '    override static var title: String { ' + W('Set Tab Status…', '设置标签页状态触发器标题') + ' }'),
    # L70: comboBoxItems — three independent strings
    ('        ["Working", "Waiting", "Idle"]',
     '        [' + W('Working', '标签页状态：工作中') + ', ' + W('Waiting', '标签页状态：等待中') + ', ' + W('Idle', '标签页状态：空闲') + ']'),
    # L104: no-status fallback
    ('        let text = statusText.isEmpty ? "(no status)" : statusText',
     '        let text = statusText.isEmpty ? ' + W('(no status)', '标签页状态：无状态') + ' : statusText'),
    # L108 / L112: paramAttributedString labels
    ('            result.append(NSAttributedString(string: "  Dot: ", attributes: regularAttributes()))',
     '            result.append(NSAttributedString(string: ' + W('  Dot: ', '参数标签：圆点') + ', attributes: regularAttributes()))'),
    ('            result.append(NSAttributedString(string: "  Text: ", attributes: regularAttributes()))',
     '            result.append(NSAttributedString(string: ' + W('  Text: ', '参数标签：文本') + ', attributes: regularAttributes()))'),

    # === SetUserVariableTrigger.swift ===
    # L62: double interpolation (name, value are String)
    ('            return "Set User Variable “\\(name)” to “\\(value)”"',
     '            return ' + F('Set User Variable “%@” to “%@”', '设置用户变量触发器描述', 'name', 'value')),
    # L64: single interpolation (param is Any?, needs String(describing:))
    ('            return "Set User Variable “\\(param ?? "")”"',
     '            return ' + F('Set User Variable “%@”', '设置用户变量触发器描述：仅参数', 'String(describing: param ?? "")')),
    ('        return "Set User Variable…"',
     '        return ' + W('Set User Variable…', '设置用户变量触发器标题')),
    ('        return "Value for variable"',
     '        return ' + W('Value for variable', '占位符：变量值')),
    # L116: paramAttributedString (name, value are String)
    (r'            return NSAttributedString(string: "\(name) = \(value)", attributes: regularAttributes())',
     '            return NSAttributedString(string: ' + F('%@ = %@', '参数显示：用户变量', 'name', 'value') + ', attributes: regularAttributes())'),

    # === SGRTrigger.swift ===
    ('        return "Change Style “\\(self.param ?? "")”"',
     '        return ' + F('Change Style “%@”', '更改样式触发器描述', 'String(describing: self.param ?? "")')),
    ('        return "Change Style…"',
     '        return ' + W('Change Style…', '更改样式触发器标题')),
    ('        return "Enter SGR codes. See help button for details."',
     '        return ' + W('Enter SGR codes. See help button for details.', '占位符：输入 SGR 代码')),
    # helpText (L29-112) is a technical SGR code reference table — skipped.
    # === iTermEventTriggerParameterView.swift ===
    # --- createRow labels (13) ---
    ('        let row = createRow(label: "Exit Code:")',
     '        let row = createRow(label: ' + W('Exit Code:', '行标签：退出码') + ')'),
    ('        let row = createRow(label: "Job:")',
     '        let row = createRow(label: ' + W('Job:', '行标签：作业') + ')'),
    ('        let nameRow = createRow(label: "Variable:")',
     '        let nameRow = createRow(label: ' + W('Variable:', '行标签：变量') + ')'),
    ('        let valueRow = createRow(label: "Value:")',
     '        let valueRow = createRow(label: ' + W('Value:', '行标签：值') + ')'),
    ('        let row = createRow(label: "Directory:")',
     '        let row = createRow(label: ' + W('Directory:', '行标签：目录') + ')'),
    ('        let row = createRow(label: "Timeout:")',
     '        let row = createRow(label: ' + W('Timeout:', '行标签：超时') + ')'),
    ('        let row = createRow(label: "Sequence ID:")',
     '        let row = createRow(label: ' + W('Sequence ID:', '行标签：序列 ID') + ')'),
    ('        let row = createRow(label: "Message:")',
     '        let row = createRow(label: ' + W('Message:', '行标签：消息') + ')'),
    ('        let row = createRow(label: "Host:")',
     '        let row = createRow(label: ' + W('Host:', '行标签：主机') + ')'),
    ('        let row = createRow(label: "User:")',
     '        let row = createRow(label: ' + W('User:', '行标签：用户') + ')'),
    ('        let thresholdRow = createRow(label: "Threshold:")',
     '        let thresholdRow = createRow(label: ' + W('Threshold:', '行标签：阈值') + ')'),
    ('        let commandRow = createRow(label: "Command:")',
     '        let commandRow = createRow(label: ' + W('Command:', '行标签：命令') + ')'),
    ('        let row = createRow(label: "Fire When:")',
     '        let row = createRow(label: ' + W('Fire When:', '行标签：触发时机') + ')'),

    # --- exit-code popup items (L165, 4 strings) ---
    ('        popup.addItems(withTitles: ["Any", "Zero (Success)", "Non-Zero (Failure)", "Specific Value…"])',
     '        popup.addItems(withTitles: [' + W('Any', '退出码过滤：任意') + ', '
     + W('Zero (Success)', '退出码过滤：零（成功）') + ', '
     + W('Non-Zero (Failure)', '退出码过滤：非零（失败）') + ', '
     + W('Specific Value…', '退出码过滤：特定值…') + '])'),

    # --- placeholderString (only "Exit code" adapted; ".*"/"30"/"60"/"claude"/"user.myVar" skipped) ---
    ('        textField.placeholderString = "Exit code"',
     '        textField.placeholderString = ' + W('Exit code', '占位符：退出码')),

    # --- helpLabel texts (9) ---
    ('        let helpLabel = NSTextField(labelWithString: "Process name to match in the foreground-job ancestry chain (case-insensitive)")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Process name to match in the foreground-job ancestry chain (case-insensitive)', '帮助：匹配的前台作业进程名') + ')'),
    ('        let nameHelp = NSTextField(labelWithString: "Name of the session variable to watch")',
     '        let nameHelp = NSTextField(labelWithString: ' + W('Name of the session variable to watch', '帮助：要监视的会话变量名') + ')'),
    ('        let valueHelp = NSTextField(labelWithString: "Regular expression the new value must match (leave blank to match any change)")',
     '        let valueHelp = NSTextField(labelWithString: ' + W('Regular expression the new value must match (leave blank to match any change)', '帮助：新值须匹配的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the directory path")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the directory path', '帮助：匹配目录路径的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the sequence identifier")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the sequence identifier', '帮助：匹配序列标识符的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the notification message")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the notification message', '帮助：匹配通知消息的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the hostname")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the hostname', '帮助：匹配主机名的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the username")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the username', '帮助：匹配用户名的正则') + ')'),
    ('        let helpLabel = NSTextField(labelWithString: "Regular expression to match the command line")',
     '        let helpLabel = NSTextField(labelWithString: ' + W('Regular expression to match the command line', '帮助：匹配命令行的正则') + ')'),

    # --- "seconds" units label (L275 + L375, expected=2) ---
    ('        let unitsLabel = NSTextField(labelWithString: "seconds")',
     '        let unitsLabel = NSTextField(labelWithString: ' + W('seconds', '单位：秒') + ')', 2),

    # --- progress-bar popup items (L407, 3 strings) ---
    ('        popup.addItems(withTitles: ["Appears or Disappears", "Appears", "Disappears"])',
     '        popup.addItems(withTitles: [' + W('Appears or Disappears', '进度条过滤：出现或消失') + ', '
     + W('Appears', '进度条过滤：出现') + ', '
     + W('Disappears', '进度条过滤：消失') + '])'),

    # --- no-parameters label (L417) ---
    ('        let label = NSTextField(labelWithString: "No additional parameters required.")',
     '        let label = NSTextField(labelWithString: ' + W('No additional parameters required.', '无参数提示') + ')'),

    # --- displayName: 17 event names (L721-757) ---
    ('            return "Prompt Detected"',
     '            return ' + W('Prompt Detected', '事件名：检测到提示')),
    ('            return "Command Finished"',
     '            return ' + W('Command Finished', '事件名：命令完成')),
    ('            return "Directory Changed"',
     '            return ' + W('Directory Changed', '事件名：目录已更改')),
    ('            return "Host Changed"',
     '            return ' + W('Host Changed', '事件名：主机已更改')),
    ('            return "User Changed"',
     '            return ' + W('User Changed', '事件名：用户已更改')),
    ('            return "Idle (Silence)"',
     '            return ' + W('Idle (Silence)', '事件名：空闲（静默）')),
    ('            return "Activity After Idle"',
     '            return ' + W('Activity After Idle', '事件名：空闲后活动')),
    ('            return "Session Ended"',
     '            return ' + W('Session Ended', '事件名：会话已结束')),
    ('            return "Bell Received"',
     '            return ' + W('Bell Received', '事件名：收到响铃')),
    ('            return "Long-Running Command"',
     '            return ' + W('Long-Running Command', '事件名：长时间运行的命令')),
    ('            return "Custom Escape Sequence"',
     '            return ' + W('Custom Escape Sequence', '事件名：自定义转义序列')),
    ('            return "Notification Posted"',
     '            return ' + W('Notification Posted', '事件名：已发送通知')),
    ('            return "Progress Bar Changed"',
     '            return ' + W('Progress Bar Changed', '事件名：进度条已更改')),
    ('            return "Job Started"',
     '            return ' + W('Job Started', '事件名：作业已开始')),
    ('            return "Job Ended"',
     '            return ' + W('Job Ended', '事件名：作业已结束')),
    ('            return "Variable Changed"',
     '            return ' + W('Variable Changed', '事件名：变量已更改')),
    ('            return "Unknown Event"',
     '            return ' + W('Unknown Event', '事件名：未知事件')),

    # --- helpText: 16 event descriptions (L761-797; default returns "" skipped) ---
    ('            return "Fires when shell integration detects a new prompt."',
     '            return ' + W('Fires when shell integration detects a new prompt.', '帮助：检测到新提示时触发')),
    ('            return "Fires when a command exits. Requires shell integration."',
     '            return ' + W('Fires when a command exits. Requires shell integration.', '帮助：命令退出时触发')),
    ('            return "Fires when the working directory changes."',
     '            return ' + W('Fires when the working directory changes.', '帮助：工作目录更改时触发')),
    ('            return "Fires when connecting to a different host via SSH."',
     '            return ' + W('Fires when connecting to a different host via SSH.', '帮助：SSH 连接到不同主机时触发')),
    ('            return "Fires when the current user changes (su/sudo)."',
     '            return ' + W('Fires when the current user changes (su/sudo).', '帮助：当前用户更改时触发')),
    ('            return "Fires when no output is received for the specified duration."',
     '            return ' + W('Fires when no output is received for the specified duration.', '帮助：指定时长无输出时触发')),
    ('            return "Fires when output resumes after being idle."',
     '            return ' + W('Fires when output resumes after being idle.', '帮助：空闲后恢复输出时触发')),
    ('            return "Fires when the session terminates."',
     '            return ' + W('Fires when the session terminates.', '帮助：会话终止时触发')),
    # L780: contains literal \\a backslash escape; key keeps source-literal form.
    (r'            return "Fires when a terminal bell (\\a) is received."',
     '            return ' + W(r'Fires when a terminal bell (\\a) is received.', '帮助：收到终端响铃时触发')),
    ('            return "Fires when a command runs longer than the threshold."',
     '            return ' + W('Fires when a command runs longer than the threshold.', '帮助：命令运行超阈值时触发')),
    ('            return "Fires when a specific OSC escape sequence is received."',
     '            return ' + W('Fires when a specific OSC escape sequence is received.', '帮助：收到特定 OSC 转义序列时触发')),
    ('            return "Fires when a notification is posted by a control sequence (OSC 9)."',
     '            return ' + W('Fires when a notification is posted by a control sequence (OSC 9).', '帮助：控制序列发送通知时触发')),
    ('            return "Fires when a progress bar appears or disappears."',
     '            return ' + W('Fires when a progress bar appears or disappears.', '帮助：进度条出现或消失时触发')),
    ('            return "Fires when a process matching the job filter enters the foreground-job ancestry chain."',
     '            return ' + W('Fires when a process matching the job filter enters the foreground-job ancestry chain.', '帮助：进程进入前台作业祖链时触发')),
    ('            return "Fires when a process matching the job filter leaves the foreground-job ancestry chain."',
     '            return ' + W('Fires when a process matching the job filter leaves the foreground-job ancestry chain.', '帮助：进程离开前台作业祖链时触发')),
    ('            return "Fires when a session variable changes to a value matching the regex."',
     '            return ' + W('Fires when a session variable changes to a value matching the regex.', '帮助：会话变量更改为匹配正则的值时触发')),
]

# ============================================================================
# Apply edits
# ============================================================================
total = 0
for src in SRCS:
    s = open(src, encoding='utf-8').read()
    n = 0
    for edit in edits:
        old, new = edit[0], edit[1]
        expected = edit[2] if len(edit) > 2 else 1
        c = s.count(old)
        if c == 0:
            continue
        if c != expected:
            print(f'ERROR: {src}: expected {expected}, got {c} for: {old[:90]!r}')
            sys.exit(1)
        s = s.replace(old, new)
        n += c
    open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {n} edits OK')
    total += n

print(f'Triggers Swift wrap done: {total} edits total')
