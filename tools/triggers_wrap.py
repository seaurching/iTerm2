# -*- coding: utf-8 -*-
# Wrap user-visible strings in Triggers ObjC sources with
# NSLocalizedStringFromTableInBundle(@"key", @"Triggers", [NSBundle bundleForClass:[self class]], @"comment").
#
# Table: Triggers
# Sources: 21 ObjC files in sources/Triggers/
#
# Note on expected counts:
#   Most edits appear once per file (expected=1). Some appear twice because the
#   same string is used in both +title and -description, or in both
#   menuItemsForPoupupButton and groupedMenuItemsForPopupButton. Color menu
#   items use "label + enum tag" as the anchor so each (label, enum) pair is
#   counted independently.
import re
import sys

SRCS = [
    'sources/Triggers/Trigger.m',
    'sources/Triggers/HighlightTrigger.m',
    'sources/Triggers/iTermHighlightLineTrigger.m',
    'sources/Triggers/AlertTrigger.m',
    'sources/Triggers/BellTrigger.m',
    'sources/Triggers/BounceTrigger.m',
    'sources/Triggers/CaptureTrigger.m',
    'sources/Triggers/CoprocessTrigger.m',
    'sources/Triggers/MarkTrigger.m',
    'sources/Triggers/PasswordTrigger.m',
    'sources/Triggers/ScriptTrigger.m',
    'sources/Triggers/SendTextTrigger.m',
    'sources/Triggers/SetDirectoryTrigger.m',
    'sources/Triggers/SetHostnameTrigger.m',
    'sources/Triggers/StopTrigger.m',
    'sources/Triggers/iTermHyperlinkTrigger.m',
    'sources/Triggers/iTermRPCTrigger.m',
    'sources/Triggers/iTermSetTitleTrigger.m',
    'sources/Triggers/iTermShellPromptTrigger.m',
    'sources/Triggers/iTermUserNotificationTrigger.m',
    'sources/Triggers/PTYTriggerEvaluator.m',
]

def W(key, comment):
    return (f'NSLocalizedStringFromTableInBundle(@"{key}", @"Triggers", '
            f'[NSBundle bundleForClass:[self class]], @"{comment}")')

edits = [
    # === Trigger.m ===
    # L474: evaluation error title (format string with \n escapes)
    ('[NSString stringWithFormat:@"The following parameter for a “%@” trigger could not be evaluated:\\n\\n%@\\n\\nThe error was:\\n\\n%@",',
     '[NSString stringWithFormat:' + W('The following parameter for a “%@” trigger could not be evaluated:\\n\\n%@\\n\\nThe error was:\\n\\n%@', '错误：触发器参数求值失败标题') + ','),
    # L479: OK button
    ('actions:@[ @"OK" ]',
     'actions:@[ ' + W('OK', '按钮：确定') + ' ]'),
    # L483: warning heading
    ('heading:@"Error in Trigger Parameter"',
     'heading:' + W('Error in Trigger Parameter', '警告标题：触发器参数错误')),
    # L587: job label (format string)
    ('[NSString stringWithFormat:@"Job: %@", self.job]',
     '[NSString stringWithFormat:' + W('Job: %@', '触发器列表：作业名') + ', self.job]'),
    # L645: content label
    ('initWithString:@"Content: " attributes: plainAttributes',
     'initWithString:' + W('Content: ', '正则信息：内容标签') + ' attributes: plainAttributes'),
    # L647: URL label
    ('initWithString:@" URL: " attributes: plainAttributes',
     'initWithString:' + W(' URL: ', '正则信息：URL 标签') + ' attributes: plainAttributes'),
    # L668: exit code 0
    ('[parts addObject:@"exit code 0"];',
     '[parts addObject:' + W('exit code 0', '事件参数：退出码 0') + '];'),
    # L670: non-zero exit code
    ('[parts addObject:@"non-zero exit code"];',
     '[parts addObject:' + W('non-zero exit code', '事件参数：非零退出码') + '];'),
    # L672: exit code (format string)
    ('[NSString stringWithFormat:@"exit code %@", exitCodeFilter]',
     '[NSString stringWithFormat:' + W('exit code %@', '事件参数：退出码') + ', exitCodeFilter]'),
    # L679: after N seconds (timeout)
    ('[NSString stringWithFormat:@"after %@ seconds", timeout]',
     '[NSString stringWithFormat:' + W('after %@ seconds', '事件参数：N 秒后') + ', timeout]'),
    # L685: after N seconds (threshold)
    ('[NSString stringWithFormat:@"after %@ seconds", threshold]',
     '[NSString stringWithFormat:' + W('after %@ seconds', '事件参数：N 秒后') + ', threshold]'),
    # L691: id (format string)
    ('[NSString stringWithFormat:@"id: %@", sequenceId]',
     '[NSString stringWithFormat:' + W('id: %@', '事件参数：序列 ID') + ', sequenceId]'),
    # L697: matching directory regex
    ('[NSString stringWithFormat:@"matching /%@/", directoryRegex]',
     '[NSString stringWithFormat:' + W('matching /%@/', '事件参数：匹配目录正则') + ', directoryRegex]'),
    # L703: matching host regex
    ('[NSString stringWithFormat:@"matching /%@/", hostRegex]',
     '[NSString stringWithFormat:' + W('matching /%@/', '事件参数：匹配主机正则') + ', hostRegex]'),
    # L709: matching user regex
    ('[NSString stringWithFormat:@"matching /%@/", userRegex]',
     '[NSString stringWithFormat:' + W('matching /%@/', '事件参数：匹配用户正则') + ', userRegex]'),
    # L715: command regex
    ('[NSString stringWithFormat:@"command /%@/", commandRegex]',
     '[NSString stringWithFormat:' + W('command /%@/', '事件参数：命令正则') + ', commandRegex]'),
    # L725: matching variable value regex
    ('[NSString stringWithFormat:@"matching /%@/", variableValueRegex]',
     '[NSString stringWithFormat:' + W('matching /%@/', '事件参数：匹配变量值正则') + ', variableValueRegex]'),
    # L732: appeared
    ('[parts addObject:@"appeared"];',
     '[parts addObject:' + W('appeared', '事件参数：进度条出现') + '];'),
    # L734: disappeared
    ('[parts addObject:@"disappeared"];',
     '[parts addObject:' + W('disappeared', '事件参数：进度条消失') + '];'),

    # === HighlightTrigger.m ===
    # L67: title
    ('return @"Highlight Text…";',
     'return ' + W('Highlight Text…', '高亮文本触发器标题') + ';'),
    # L71: description (format string + two "(no color)" fallbacks; 2nd has typo extra ')')
    ('return [NSString stringWithFormat:@"Highlight text %@ over %@", self.textColor.humanReadableDescription ?: @"(no color)", self.backgroundColor.humanReadableDescription ?: @"(no color))"];',
     'return [NSString stringWithFormat:' + W('Highlight text %@ over %@', '高亮触发器描述') + ', self.textColor.humanReadableDescription ?: ' + W('(no color)', '颜色：无颜色') + ', self.backgroundColor.humanReadableDescription ?: ' + W('(no color)', '颜色：无颜色') + '];'),
    # L511: Text label (shared with iTermHighlightLineTrigger.m L177)
    ('[[NSAttributedString alloc] initWithString:@"Text: "]',
     '[[NSAttributedString alloc] initWithString:' + W('Text: ', '参数标签：文本') + ']'),
    # L521: Background label (shared with iTermHighlightLineTrigger.m L187)
    ('[[NSAttributedString alloc] initWithString:@" Background: "]',
     '[[NSAttributedString alloc] initWithString:' + W(' Background: ', '参数标签：背景') + ']'),

    # === iTermHighlightLineTrigger.m ===
    # L20: title
    ('return @"Highlight Line…";',
     'return ' + W('Highlight Line…', '高亮行触发器标题') + ';'),
    # L24: description (format string + two "(no color)" fallbacks, no typo)
    ('return [NSString stringWithFormat:@"Highlight Line with %@ over %@", self.textColor.humanReadableDescription ?: @"(no color)", self.backgroundColor.humanReadableDescription ?: @"(no color)"];',
     'return [NSString stringWithFormat:' + W('Highlight Line with %@ over %@', '高亮行触发器描述') + ', self.textColor.humanReadableDescription ?: ' + W('(no color)', '颜色：无颜色') + ', self.backgroundColor.humanReadableDescription ?: ' + W('(no color)', '颜色：无颜色') + '];'),

    # === AlertTrigger.m ===
    ('return @"Show Alert…";',
     'return ' + W('Show Alert…', '警告触发器标题') + ';'),
    ('return @"Enter text to show in alert";',
     'return ' + W('Enter text to show in alert', '占位符：输入警告文本') + ';'),
    ('[NSString stringWithFormat:@"Show alert “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Show alert “%@”', '警告触发器描述') + ', self.param]'),

    # === BellTrigger.m ===
    # L17 (description) + L22 (title): same key, appears twice
    ('return @"Ring Bell";',
     'return ' + W('Ring Bell', '响铃触发器') + ';', 2),

    # === BounceTrigger.m ===
    ('return @"Bounce Dock Icon";',
     'return ' + W('Bounce Dock Icon', '跳动 Dock 触发器标题') + ';'),
    ('return [NSString stringWithFormat:@"Bounce dock icon %@", self.bounceType == NSCriticalRequest ? @"until focused" : @"once"];',
     'return [NSString stringWithFormat:' + W('Bounce dock icon %@', '跳动触发器描述') + ', self.bounceType == NSCriticalRequest ? ' + W('until focused', '跳动：直到获焦') + ' : ' + W('once', '跳动：一次') + '];'),
    # L79 + L83: same key, appears twice
    ('return @"Bounce Until Activated";',
     'return ' + W('Bounce Until Activated', '跳动：直到激活') + ';', 2),
    ('return @"Bounce Once";',
     'return ' + W('Bounce Once', '跳动：一次') + ';'),

    # === CaptureTrigger.m ===
    # L23 (title) + L30 (description else): same key, appears twice
    ('return @"Capture Output";',
     'return ' + W('Capture Output', '捕获输出触发器') + ';', 2),
    ('[NSString stringWithFormat:@"Capture output, running “%@” on double-click", self.param]',
     '[NSString stringWithFormat:' + W('Capture output, running “%@” on double-click', '捕获触发器描述') + ', self.param]'),
    ('return @"Coprocess to run on activation";',
     'return ' + W('Coprocess to run on activation', '占位符：激活时运行的协进程') + ';'),

    # === CoprocessTrigger.m ===
    ('return @"Run Coprocess…";',
     'return ' + W('Run Coprocess…', '运行协进程触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Run Coprocess “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Run Coprocess “%@”', '运行协进程触发器描述') + ', self.param]'),
    # L31 (CoprocessTrigger) + L82 (MuteCoprocessTrigger): same key, appears twice
    ('return @"Enter coprocess command to run";',
     'return ' + W('Enter coprocess command to run', '占位符：输入协进程命令') + ';', 2),
    ('return @"Run Silent Coprocess…";',
     'return ' + W('Run Silent Coprocess…', '运行静默协进程触发器标题') + ';'),

    # === MarkTrigger.m ===
    ('return @"Set Mark";',
     'return ' + W('Set Mark', '设置标记触发器标题') + ';'),
    ('return [NSString stringWithFormat:@"Set Mark and %@ scrolling", [self shouldStopScrolling] ? @"stop" : @"continue"];',
     'return [NSString stringWithFormat:' + W('Set Mark and %@ scrolling', '标记触发器描述') + ', [self shouldStopScrolling] ? ' + W('stop', '滚动：停止') + ' : ' + W('continue', '滚动：继续') + '];'),
    ('@(kMarkTriggerParamTagKeepScrolling): @"Keep Scrolling",',
     '@(kMarkTriggerParamTagKeepScrolling): ' + W('Keep Scrolling', '标记：继续滚动') + ','),
    ('@(kMarkTriggerParamTagStopScrolling): @"Stop Scrolling" };',
     '@(kMarkTriggerParamTagStopScrolling): ' + W('Stop Scrolling', '标记：停止滚动') + ' };'),
    ('? @"and stop scrolling" : @""',
     '? ' + W('and stop scrolling', '标记：并停止滚动') + ' : @""'),

    # === PasswordTrigger.m ===
    # L14: static placeholder string (wrap only declaration; references use same value)
    ('static NSString *PasswordTriggerPlaceholderString = @"Open Password Manager to Unlock";',
     'static NSString *PasswordTriggerPlaceholderString = ' + W('Open Password Manager to Unlock', '密码触发器占位符：打开密码管理器以解锁') + ';'),
    ('return @"Open Password Manager…";',
     'return ' + W('Open Password Manager…', '密码管理器触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Open Password Manager to “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Open Password Manager to “%@”', '密码管理器触发器描述') + ', self.param]'),
    ('return @"Open Password Manager";',
     'return ' + W('Open Password Manager', '密码管理器触发器：无参数描述') + ';'),

    # === ScriptTrigger.m ===
    ('return @"Run Command…";',
     'return ' + W('Run Command…', '运行命令触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Run Command “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Run Command “%@”', '运行命令触发器描述') + ', self.param]'),
    ('return @"Enter command to run";',
     'return ' + W('Enter command to run', '占位符：输入要运行的命令') + ';'),

    # === SendTextTrigger.m ===
    ('return @"Send Text…";',
     'return ' + W('Send Text…', '发送文本触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Send text “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Send text “%@”', '发送文本触发器描述') + ', self.param]'),
    ('return @"Enter text to send";',
     'return ' + W('Enter text to send', '占位符：输入要发送的文本') + ';'),

    # === SetDirectoryTrigger.m ===
    ('return @"Report Directory";',
     'return ' + W('Report Directory', '报告目录触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Report Directory as “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Report Directory as “%@”', '报告目录触发器描述') + ', self.param]'),
    ('return @"Directory";',
     'return ' + W('Directory', '占位符：目录') + ';'),

    # === SetHostnameTrigger.m ===
    ('return @"Report User & Host";',
     'return ' + W('Report User & Host', '报告用户与主机触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Report User & Host as “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Report User & Host as “%@”', '报告用户与主机触发器描述') + ', self.param]'),
    ('return @"username@hostname";',
     'return ' + W('username@hostname', '占位符：用户名@主机名') + ';'),

    # === StopTrigger.m ===
    ('return @"Stop Processing Triggers";',
     'return ' + W('Stop Processing Triggers', '停止处理触发器标题') + ';'),

    # === iTermHyperlinkTrigger.m ===
    ('return @"Make Hyperlink…";',
     'return ' + W('Make Hyperlink…', '创建超链接触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Make Hyperlink with URL “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Make Hyperlink with URL “%@”', '创建超链接触发器描述') + ', self.param]'),

    # === iTermRPCTrigger.m ===
    ('return @"Invoke Script Function";',
     'return ' + W('Invoke Script Function', '调用脚本函数触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Invoke Script Function “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Invoke Script Function “%@”', '调用脚本函数触发器描述') + ', self.param]'),
    ('return @"Function call";',
     'return ' + W('Function call', '占位符：函数调用') + ';'),

    # === iTermSetTitleTrigger.m ===
    ('return @"Set Title…";',
     'return ' + W('Set Title…', '设置标题触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Set Title to “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Set Title to “%@”', '设置标题触发器描述') + ', self.param]'),
    ('return @"Enter new title";',
     'return ' + W('Enter new title', '占位符：输入新标题') + ';'),

    # === iTermShellPromptTrigger.m ===
    ('return @"Prompt Detected";',
     'return ' + W('Prompt Detected', '检测到提示触发器标题') + ';'),

    # === iTermUserNotificationTrigger.m ===
    ('return @"Post Notification…";',
     'return ' + W('Post Notification…', '发送通知触发器标题') + ';'),
    ('[NSString stringWithFormat:@"Post Notification “%@”", self.param]',
     '[NSString stringWithFormat:' + W('Post Notification “%@”', '发送通知触发器描述') + ', self.param]'),
    ('return @"Enter Message";',
     'return ' + W('Enter Message', '占位符：输入消息') + ';'),

    # === PTYTriggerEvaluator.m ===
    # L89: stats label (format string); only this fragment is unique in file
    ('[NSString stringWithFormat:@"Trigger “%@” with regex “%@”",',
     '[NSString stringWithFormat:' + W('Trigger “%@” with regex “%@”', '统计：触发器名称与正则') + ','),
]

# ============================================================================
# HighlightTrigger.m color menu items
# Each item uses "label + enum tag" as anchor. Most appear in both
# menuItemsForPoupupButton and groupedMenuItemsForPopupButton (expected=2).
# Exceptions in Background group due to a pre-existing typo at L188 where
# "Gray Background" is paired with kDarkGrayBackgroundHighlight.
# ============================================================================
COLORS = [
    # (label, enum, expected, comment)
    # fgbg (8 items, all x2)
    ('Yellow on Black', 'kYellowOnBlackHighlight', 2, '颜色：黄字黑底'),
    ('Black on Yellow', 'kBlackOnYellowHighlight', 2, '颜色：黑字黄底'),
    ('White on Red', 'kWhiteOnRedHighlight', 2, '颜色：白字红底'),
    ('Red on White', 'kRedOnWhiteHighlight', 2, '颜色：红字白底'),
    ('Black on Orange', 'kBlackOnOrangeHighlight', 2, '颜色：黑字橙底'),
    ('Orange on Black', 'kOrangeOnBlackHighlight', 2, '颜色：橙字黑底'),
    ('Purple on Black', 'kPurpleOnBlackHighlight', 2, '颜色：紫字黑底'),
    ('Black on Purple', 'kBlackOnPurpleHighlight', 2, '颜色：黑字紫底'),
    # fg (14 items, all x2)
    ('Black Foreground', 'kBlackHighlight', 2, '前景色：黑色'),
    ('Blue Foreground', 'kBlueHighlight', 2, '前景色：蓝色'),
    ('Brown Foreground', 'kBrownHighlight', 2, '前景色：棕色'),
    ('Cyan Foreground', 'kCyanHighlight', 2, '前景色：青色'),
    ('Dark Gray Foreground', 'kDarkGrayHighlight', 2, '前景色：深灰'),
    ('Gray Foreground', 'kGrayHighlight', 2, '前景色：灰色'),
    ('Green Foreground', 'kGreenHighlight', 2, '前景色：绿色'),
    ('Light Gray Foreground', 'kLightGrayHighlight', 2, '前景色：浅灰'),
    ('Magenta Foreground', 'kMagentaHighlight', 2, '前景色：洋红'),
    ('Orange Foreground', 'kOrangeHighlight', 2, '前景色：橙色'),
    ('Purple Foreground', 'kPurpleHighlight', 2, '前景色：紫色'),
    ('Red Foreground', 'kRedHighlight', 2, '前景色：红色'),
    ('White Foreground', 'kWhiteHighlight', 2, '前景色：白色'),
    ('Yellow Foreground', 'kYellowHighlight', 2, '前景色：黄色'),
    # bg (14 enum values, 15 edits due to typo split)
    ('Black Background', 'kBlackBackgroundHighlight', 2, '背景色：黑色'),
    ('Blue Background', 'kBlueBackgroundHighlight', 2, '背景色：蓝色'),
    ('Brown Background', 'kBrownBackgroundHighlight', 2, '背景色：棕色'),
    ('Cyan Background', 'kCyanBackgroundHighlight', 2, '背景色：青色'),
    ('Dark Gray Background', 'kDarkGrayBackgroundHighlight', 1, '背景色：深灰'),
    ('Gray Background', 'kDarkGrayBackgroundHighlight', 1, '背景色：灰色（原 typo 行）'),
    ('Gray Background', 'kGrayBackgroundHighlight', 2, '背景色：灰色'),
    ('Green Background', 'kGreenBackgroundHighlight', 2, '背景色：绿色'),
    ('Light Gray Background', 'kLightGrayBackgroundHighlight', 2, '背景色：浅灰'),
    ('Magenta Background', 'kMagentaBackgroundHighlight', 2, '背景色：洋红'),
    ('Orange Background', 'kOrangeBackgroundHighlight', 2, '背景色：橙色'),
    ('Purple Background', 'kPurpleBackgroundHighlight', 2, '背景色：紫色'),
    ('Red Background', 'kRedBackgroundHighlight', 2, '背景色：红色'),
    ('White Background', 'kWhiteBackgroundHighlight', 2, '背景色：白色'),
    ('Yellow Background', 'kYellowBackgroundHighlight', 2, '背景色：黄色'),
]

# Regex-based color edits: source spacing is inconsistent (1/2/4 spaces after
# the comma), so match flexible whitespace. Only unwrapped items match (wrapped
# items already start with NSLocalizedStringFromTableInBundle, not @").
regex_edits = []
for label, enum, exp, comment in COLORS:
    pat = re.compile(r'@"' + re.escape(label) + r'",\s+\[NSNumber numberWithInt:\(int\)' + enum + r'\],')
    new = f'{W(label, comment)}, [NSNumber numberWithInt:(int){enum}],'
    regex_edits.append((pat, new, exp))

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
    for pat, new, exp in regex_edits:
        s2, c = pat.subn(new, s)
        if c == 0:
            continue
        if c != exp:
            print(f'ERROR: {src}: expected {exp}, got {c} for: {pat.pattern[:90]!r}')
            sys.exit(1)
        s = s2
        n += c
    open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {n} edits OK')
    total += n

print(f'Triggers wrap done: {total} edits total')
