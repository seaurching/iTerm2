# -*- coding: utf-8 -*-
# Bracket balance check + key extraction + 8-locale Triggers.strings generation.
#
# Sources:
#   21 ObjC files in sources/Triggers/   (NSLocalizedStringFromTableInBundle, table "Triggers")
#   17 Swift files in sources/Triggers/   (NSLocalizedString, tableName: "Triggers")
# Table: Triggers
import os
import re
import sys

OBJC_SRCS = [
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
SWIFT_SRCS = [
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
LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
TABLE = 'Triggers'
SRCDIR = 'sources/Triggers'

# ----------------------------------------------------------------------------
# 1. Bracket balance check
# ----------------------------------------------------------------------------
def check_balance_objc(s):
    stack = []
    state = 'code'
    i = 0
    n = len(s)
    line = 1
    opens = {'(': ')', '[': ']', '{': '}'}
    closes = set(opens.values())
    while i < n:
        c = s[i]
        nxt = s[i+1] if i+1 < n else ''
        if c == '\n':
            line += 1
            if state == 'line_comment':
                state = 'code'
            i += 1; continue
        if state == 'code':
            if c == '/' and nxt == '/':
                state = 'line_comment'; i += 2; continue
            if c == '/' and nxt == '*':
                state = 'block_comment'; i += 2; continue
            if c == '"':
                state = 'string'; i += 1; continue
            if c == "'":
                state = 'char'; i += 1; continue
            if c in opens:
                stack.append((c, line)); i += 1; continue
            if c in closes:
                if not stack:
                    return f'extra closing {c!r} at line {line}'
                op, ol = stack.pop()
                if opens[op] != c:
                    return f'mismatch: opened {op!r} at line {ol}, closed {c!r} at line {line}'
                i += 1; continue
            i += 1; continue
        if state == 'block_comment':
            if c == '*' and nxt == '/':
                state = 'code'; i += 2; continue
            i += 1; continue
        if state == 'string':
            if c == '\\':
                i += 2; continue
            if c == '"':
                state = 'code'; i += 1; continue
            i += 1; continue
        if state == 'char':
            if c == '\\':
                i += 2; continue
            if c == "'":
                state = 'code'; i += 1; continue
            i += 1; continue
        i += 1
    if state in ('string', 'char', 'block_comment'):
        return f'unterminated {state} at line {line}'
    if stack:
        op, ol = stack[-1]
        return f'unclosed {op!r} opened at line {ol}'
    return None

def check_balance_swift(s):
    # Like ObjC but handles triple-quoted """ strings and \(...) interpolation.
    stack = []
    state = 'code'
    i = 0
    n = len(s)
    line = 1
    opens = {'(': ')', '[': ']', '{': '}'}
    closes = set(opens.values())
    while i < n:
        c = s[i]
        nxt = s[i+1] if i+1 < n else ''
        if c == '\n':
            line += 1
            if state == 'line_comment':
                state = 'code'
            i += 1; continue
        if state == 'code':
            if c == '/' and nxt == '/':
                state = 'line_comment'; i += 2; continue
            if c == '/' and nxt == '*':
                state = 'block_comment'; i += 2; continue
            if c == '"' and i+2 < n and s[i+1] == '"' and s[i+2] == '"':
                state = 'triple_string'; i += 3; continue
            if c == '"':
                state = 'string'; i += 1; continue
            if c in opens:
                stack.append((c, line)); i += 1; continue
            if c in closes:
                if not stack:
                    return f'extra closing {c!r} at line {line}'
                op, ol = stack.pop()
                if opens[op] != c:
                    return f'mismatch: opened {op!r} at line {ol}, closed {c!r} at line {line}'
                i += 1; continue
            i += 1; continue
        if state == 'block_comment':
            if c == '*' and nxt == '/':
                state = 'code'; i += 2; continue
            i += 1; continue
        if state == 'triple_string':
            if c == '"' and i+2 < n and s[i+1] == '"' and s[i+2] == '"':
                state = 'code'; i += 3; continue
            i += 1; continue
        if state == 'string':
            if c == '\\':
                i += 2; continue
            if c == '"':
                state = 'code'; i += 1; continue
            i += 1; continue
        i += 1
    if state in ('string', 'triple_string', 'block_comment'):
        return f'unterminated {state} at line {line}'
    if stack:
        op, ol = stack[-1]
        return f'unclosed {op!r} opened at line {ol}'
    return None

for src in OBJC_SRCS:
    s = open(src, encoding='utf-8').read()
    r = check_balance_objc(s)
    if r:
        print(f'{src}: FAIL - {r}')
        sys.exit(1)
    print(f'{src}: bracket balance OK')
for src in SWIFT_SRCS:
    s = open(src, encoding='utf-8').read()
    r = check_balance_swift(s)
    if r:
        print(f'{src}: FAIL - {r}')
        sys.exit(1)
    print(f'{src}: bracket balance OK')

# ----------------------------------------------------------------------------
# 2. Extract keys
# ----------------------------------------------------------------------------
def decode(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            c = s[i+1]
            if c == 'n': out.append('\n')
            elif c == 't': out.append('\t')
            elif c == 'r': out.append('\r')
            elif c == '\\': out.append('\\')
            elif c == '"': out.append('"')
            elif c == "'": out.append("'")
            elif c == '0': out.append('\0')
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

objc_pat = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"Triggers"')
swift_pat = re.compile(r'NSLocalizedString\("((?:[^"\\]|\\.)*)", tableName: "Triggers"')

objc_seen = set()
swift_seen = set()
code_keys = []
for src in OBJC_SRCS:
    s = open(src, encoding='utf-8').read()
    for m in objc_pat.finditer(s):
        k = decode(m.group(1))
        if k not in objc_seen:
            objc_seen.add(k)
            code_keys.append(k)
for src in SWIFT_SRCS:
    s = open(src, encoding='utf-8').read()
    for m in swift_pat.finditer(s):
        k = decode(m.group(1))
        if k not in swift_seen:
            swift_seen.add(k)
            if k not in objc_seen:
                code_keys.append(k)

all_seen = objc_seen | swift_seen
print(f'ObjC: {len(objc_seen)} keys, Swift: {len(swift_seen)} keys, total unique: {len(all_seen)}')

# ----------------------------------------------------------------------------
# 3. Translations: key -> (simplified, traditional)
#    Curly quotes use “/” (ASCII-safe in source); traditional uses 「/」.
# ----------------------------------------------------------------------------
T = {
    # === Trigger.m ===
    "The following parameter for a “%@” trigger could not be evaluated:\n\n%@\n\nThe error was:\n\n%@": ("无法求值 “%@” 触发器的以下参数：\n\n%@\n\n错误为：\n\n%@", "無法求值「%@」觸發器的以下參數：\n\n%@\n\n錯誤為：\n\n%@"),
    "OK": ("确定", "確定"),
    "Error in Trigger Parameter": ("触发器参数错误", "觸發器參數錯誤"),
    "Job: %@": ("作业：%@", "作業：%@"),
    "Content: ": ("内容： ", "內容： "),
    " URL: ": (" URL： ", " URL： "),
    "exit code 0": ("退出码 0", "退出碼 0"),
    "non-zero exit code": ("非零退出码", "非零退出碼"),
    "exit code %@": ("退出码 %@", "退出碼 %@"),
    "after %@ seconds": ("%@ 秒后", "%@ 秒後"),
    "id: %@": ("ID：%@", "ID：%@"),
    "matching /%@/": ("匹配 /%@/", "匹配 /%@/"),
    "command /%@/": ("命令 /%@/", "命令 /%@/"),
    "appeared": ("出现", "出現"),
    "disappeared": ("消失", "消失"),

    # === HighlightTrigger.m ===
    "Highlight Text…": ("高亮文本…", "高亮文字…"),
    "Highlight text %@ over %@": ("高亮文本 %@，底色 %@", "高亮文字 %@，底色 %@"),
    "Text: ": ("文本： ", "文字： "),
    " Background: ": (" 背景： ", " 背景： "),
    "(no color)": ("（无颜色）", "（無顏色）"),

    # === iTermHighlightLineTrigger.m ===
    "Highlight Line…": ("高亮行…", "高亮行…"),
    "Highlight Line with %@ over %@": ("高亮行 %@，底色 %@", "高亮行 %@，底色 %@"),

    # === AlertTrigger.m ===
    "Show Alert…": ("显示警告…", "顯示警告…"),
    "Enter text to show in alert": ("输入要在警告中显示的文本", "輸入要在警告中顯示的文字"),
    "Show alert “%@”": ("显示警告 “%@”", "顯示警告「%@」"),

    # === BellTrigger.m ===
    "Ring Bell": ("响铃", "響鈴"),

    # === BounceTrigger.m ===
    "Bounce Dock Icon": ("跳动 Dock 图标", "跳動 Dock 圖示"),
    "Bounce dock icon %@": ("跳动 Dock 图标 %@", "跳動 Dock 圖示 %@"),
    "until focused": ("直到获焦", "直到獲焦"),
    "once": ("一次", "一次"),
    "Bounce Until Activated": ("跳动直到激活", "跳動直到啟動"),
    "Bounce Once": ("跳动一次", "跳動一次"),

    # === CaptureTrigger.m ===
    "Capture Output": ("捕获输出", "擷取輸出"),
    "Capture output, running “%@” on double-click": ("捕获输出，双击时运行 “%@”", "擷取輸出，雙擊時執行「%@」"),
    "Coprocess to run on activation": ("激活时运行的协进程", "啟動時執行的協同程序"),

    # === CoprocessTrigger.m ===
    "Run Coprocess…": ("运行协进程…", "執行協同程序…"),
    "Run Coprocess “%@”": ("运行协进程 “%@”", "執行協同程序「%@」"),
    "Enter coprocess command to run": ("输入要运行的协进程命令", "輸入要執行的協同程序命令"),
    "Run Silent Coprocess…": ("运行静默协进程…", "執行靜默協同程序…"),

    # === MarkTrigger.m ===
    "Set Mark": ("设置标记", "設定標記"),
    "Set Mark and %@ scrolling": ("设置标记并 %@ 滚动", "設定標記並 %@ 捲動"),
    "stop": ("停止", "停止"),
    "continue": ("继续", "繼續"),
    "Keep Scrolling": ("继续滚动", "繼續捲動"),
    "Stop Scrolling": ("停止滚动", "停止捲動"),
    "and stop scrolling": ("并停止滚动", "並停止捲動"),

    # === PasswordTrigger.m ===
    "Open Password Manager to Unlock": ("打开密码管理器以解锁", "打開密碼管理器以解鎖"),
    "Open Password Manager…": ("打开密码管理器…", "打開密碼管理器…"),
    "Open Password Manager to “%@”": ("打开密码管理器到 “%@”", "打開密碼管理器到「%@」"),
    "Open Password Manager": ("打开密码管理器", "打開密碼管理器"),

    # === ScriptTrigger.m ===
    "Run Command…": ("运行命令…", "執行命令…"),
    "Run Command “%@”": ("运行命令 “%@”", "執行命令「%@」"),
    "Enter command to run": ("输入要运行的命令", "輸入要執行的命令"),

    # === SendTextTrigger.m ===
    "Send Text…": ("发送文本…", "傳送文字…"),
    "Send text “%@”": ("发送文本 “%@”", "傳送文字「%@」"),
    "Enter text to send": ("输入要发送的文本", "輸入要傳送的文字"),

    # === SetDirectoryTrigger.m ===
    "Report Directory": ("报告目录", "回報目錄"),
    "Report Directory as “%@”": ("将目录报告为 “%@”", "將目錄回報為「%@」"),
    "Directory": ("目录", "目錄"),

    # === SetHostnameTrigger.m ===
    "Report User & Host": ("报告用户与主机", "回報使用者與主機"),
    "Report User & Host as “%@”": ("将用户与主机报告为 “%@”", "將使用者與主機回報為「%@」"),
    "username@hostname": ("用户名@主机名", "使用者名稱@主機名稱"),

    # === StopTrigger.m ===
    "Stop Processing Triggers": ("停止处理触发器", "停止處理觸發器"),

    # === iTermHyperlinkTrigger.m (shared with HyperlinkBrowserTrigger.swift) ===
    "Make Hyperlink…": ("创建超链接…", "建立超連結…"),
    "Make Hyperlink with URL “%@”": ("创建超链接，URL 为 “%@”", "建立超連結，URL 為「%@」"),

    # === iTermRPCTrigger.m ===
    "Invoke Script Function": ("调用脚本函数", "呼叫腳本函式"),
    "Invoke Script Function “%@”": ("调用脚本函数 “%@”", "呼叫腳本函式「%@」"),
    "Function call": ("函数调用", "函式呼叫"),

    # === iTermSetTitleTrigger.m ===
    "Set Title…": ("设置标题…", "設定標題…"),
    "Set Title to “%@”": ("将标题设为 “%@”", "將標題設為「%@」"),
    "Enter new title": ("输入新标题", "輸入新標題"),

    # === iTermShellPromptTrigger.m (shared with Swift) ===
    "Prompt Detected": ("检测到提示", "偵測到提示"),

    # === iTermUserNotificationTrigger.m ===
    "Post Notification…": ("发送通知…", "發送通知…"),
    "Post Notification “%@”": ("发送通知 “%@”", "發送通知「%@」"),
    "Enter Message": ("输入消息", "輸入訊息"),

    # === PTYTriggerEvaluator.m ===
    "Trigger “%@” with regex “%@”": ("触发器 “%@”，正则 “%@”", "觸發器「%@」，正規表示式「%@」"),

    # === HighlightTrigger.m color menu items (36) ===
    "Yellow on Black": ("黄字黑底", "黃字黑底"),
    "Black on Yellow": ("黑字黄底", "黑字黃底"),
    "White on Red": ("白字红底", "白字紅底"),
    "Red on White": ("红字白底", "紅字白底"),
    "Black on Orange": ("黑字橙底", "黑字橙底"),
    "Orange on Black": ("橙字黑底", "橙字黑底"),
    "Purple on Black": ("紫字黑底", "紫字黑底"),
    "Black on Purple": ("黑字紫底", "黑字紫底"),
    "Black Foreground": ("黑色前景", "黑色前景"),
    "Blue Foreground": ("蓝色前景", "藍色前景"),
    "Brown Foreground": ("棕色前景", "棕色前景"),
    "Cyan Foreground": ("青色前景", "青色前景"),
    "Dark Gray Foreground": ("深灰前景", "深灰前景"),
    "Gray Foreground": ("灰色前景", "灰色前景"),
    "Green Foreground": ("绿色前景", "綠色前景"),
    "Light Gray Foreground": ("浅灰前景", "淺灰前景"),
    "Magenta Foreground": ("洋红前景", "洋紅前景"),
    "Orange Foreground": ("橙色前景", "橙色前景"),
    "Purple Foreground": ("紫色前景", "紫色前景"),
    "Red Foreground": ("红色前景", "紅色前景"),
    "White Foreground": ("白色前景", "白色前景"),
    "Yellow Foreground": ("黄色前景", "黃色前景"),
    "Black Background": ("黑色背景", "黑色背景"),
    "Blue Background": ("蓝色背景", "藍色背景"),
    "Brown Background": ("棕色背景", "棕色背景"),
    "Cyan Background": ("青色背景", "青色背景"),
    "Dark Gray Background": ("深灰背景", "深灰背景"),
    "Gray Background": ("灰色背景", "灰色背景"),
    "Green Background": ("绿色背景", "綠色背景"),
    "Light Gray Background": ("浅灰背景", "淺灰背景"),
    "Magenta Background": ("洋红背景", "洋紅背景"),
    "Orange Background": ("橙色背景", "橙色背景"),
    "Purple Background": ("紫色背景", "紫色背景"),
    "Red Background": ("红色背景", "紅色背景"),
    "White Background": ("白色背景", "白色背景"),
    "Yellow Background": ("黄色背景", "黃色背景"),

    # === BufferInputTrigger.swift ===
    "Buffer Input": ("缓冲输入", "緩衝輸入"),
    "Stop Buffering Input": ("停止缓冲输入", "停止緩衝輸入"),
    "Buffer Input…": ("缓冲输入…", "緩衝輸入…"),
    "Start Buffering Input": ("开始缓冲输入", "開始緩衝輸入"),
    "Start buffering": ("开始缓冲", "開始緩衝"),
    "Stop buffering": ("停止缓冲", "停止緩衝"),

    # === EnterWorkgroupBrowser/EnterWorkgroupTrigger.swift ===
    "Enter Workgroup…": ("进入工作组…", "進入工作群組…"),
    "Enter Workgroup “%@”": ("进入工作组 “%@”", "進入工作群組「%@」"),
    "(unset)": ("（未设置）", "（未設定）"),
    "Untitled": ("无标题", "無標題"),
    "(missing)": ("（缺失）", "（缺失）"),

    # === ExitWorkgroupBrowser/ExitWorkgroupTrigger.swift ===
    "Exit Workgroup": ("退出工作组", "退出工作群組"),

    # === FoldTrigger.swift ===
    "Fold to %@": ("折叠到 %@", "折疊到 %@"),
    "Fold to Named Mark": ("折叠到命名标记", "折疊到命名標記"),
    "Name of Mark": ("标记名称", "標記名稱"),

    # === HighlightBrowserTrigger.swift ===
    "Highlight Text": ("高亮文本", "高亮文字"),

    # === HyperlinkBrowserTrigger.swift ===
    "(nil)": ("（无）", "（無）"),

    # === InjectJavascriptTrigger.swift ===
    "Inject Javascript (URL Regex)": ("注入 JavaScript（URL 正则）", "注入 JavaScript（URL 正規表示式）"),
    "Inject Javascript (Content Regex)": ("注入 JavaScript（内容正则）", "注入 JavaScript（內容正規表示式）"),
    "Javascript": ("JavaScript", "JavaScript"),

    # === InjectTrigger.swift ===
    "Inject Data “%@”": ("注入数据 “%@”", "注入資料「%@」"),
    "Inject Data…": ("注入数据…", "注入資料…"),
    "Use \\e for esc, \\a for ^G.": ("用 \\e 表示 esc，\\a 表示 ^G。", "以 \\e 表示 esc，\\a 表示 ^G。"),

    # === ReaderModeBrowserTrigger.swift ===
    "Enter Reader Mode": ("进入阅读模式", "進入閱讀模式"),

    # === ReloadBrowserTrigger.swift ===
    "Reload After Delay": ("延迟后重新加载", "延遲後重新載入"),
    "Delay in seconds": ("延迟秒数", "延遲秒數"),

    # === SetNamedMarkTrigger.swift ===
    "Set Named Mark to %@": ("将命名标记设为 %@", "將命名標記設為 %@"),
    "Set Named Mark": ("设置命名标记", "設定命名標記"),
    "Name for this mark": ("此标记的名称", "此標記的名稱"),

    # === SetTabStatusTrigger.swift ===
    "Set Tab Status…": ("设置标签页状态…", "設定分頁狀態…"),
    "Working": ("工作中", "工作中"),
    "Waiting": ("等待中", "等待中"),
    "Idle": ("空闲", "閒置"),
    "(no status)": ("（无状态）", "（無狀態）"),
    "  Dot: ": ("  圆点： ", "  圓點： "),
    "  Text: ": ("  文本： ", "  文字： "),

    # === SetUserVariableTrigger.swift ===
    "Set User Variable “%@” to “%@”": ("将用户变量 “%@” 设为 “%@”", "將使用者變數「%@」設為「%@」"),
    "Set User Variable “%@”": ("设置用户变量 “%@”", "設定使用者變數「%@」"),
    "Set User Variable…": ("设置用户变量…", "設定使用者變數…"),
    "Value for variable": ("变量值", "變數值"),
    "%@ = %@": ("%@ = %@", "%@ = %@"),

    # === SGRTrigger.swift ===
    "Change Style “%@”": ("更改样式 “%@”", "變更樣式「%@」"),
    "Change Style…": ("更改样式…", "變更樣式…"),
    "Enter SGR codes. See help button for details.": ("输入 SGR 代码。详情见帮助按钮。", "輸入 SGR 代碼。詳情見說明按鈕。"),

    # === iTermEventTriggerParameterView.swift: createRow labels ===
    "Exit Code:": ("退出码：", "退出碼："),
    "Job:": ("作业：", "作業："),
    "Variable:": ("变量：", "變數："),
    "Value:": ("值：", "值："),
    "Directory:": ("目录：", "目錄："),
    "Timeout:": ("超时：", "逾時："),
    "Sequence ID:": ("序列 ID：", "序列 ID："),
    "Message:": ("消息：", "訊息："),
    "Host:": ("主机：", "主機："),
    "User:": ("用户：", "使用者："),
    "Threshold:": ("阈值：", "閾值："),
    "Command:": ("命令：", "命令："),
    "Fire When:": ("触发时机：", "觸發時機："),

    # === exit-code popup ===
    "Any": ("任意", "任意"),
    "Zero (Success)": ("零（成功）", "零（成功）"),
    "Non-Zero (Failure)": ("非零（失败）", "非零（失敗）"),
    "Specific Value…": ("特定值…", "特定值…"),
    "Exit code": ("退出码", "退出碼"),

    # === helpLabel texts ===
    "Process name to match in the foreground-job ancestry chain (case-insensitive)": ("要在前台作业祖链中匹配的进程名（不区分大小写）", "要在前台作業祖鏈中匹配的行程名（不區分大小寫）"),
    "Name of the session variable to watch": ("要监视的会话变量名", "要監視的工作階段變數名稱"),
    "Regular expression the new value must match (leave blank to match any change)": ("新值须匹配的正则表达式（留空则匹配任意更改）", "新值須匹配的正規表示式（留空則匹配任意變更）"),
    "Regular expression to match the directory path": ("匹配目录路径的正则表达式", "匹配目錄路徑的正規表示式"),
    "Regular expression to match the sequence identifier": ("匹配序列标识符的正则表达式", "匹配序列識別碼的正規表示式"),
    "Regular expression to match the notification message": ("匹配通知消息的正则表达式", "匹配通知訊息的正規表示式"),
    "Regular expression to match the hostname": ("匹配主机名的正则表达式", "匹配主機名稱的正規表示式"),
    "Regular expression to match the username": ("匹配用户名的正则表达式", "匹配使用者名稱的正規表示式"),
    "Regular expression to match the command line": ("匹配命令行的正则表达式", "匹配命令列的正規表示式"),

    # === seconds / progress-bar popup / no-params ===
    "seconds": ("秒", "秒"),
    "Appears or Disappears": ("出现或消失", "出現或消失"),
    "Appears": ("出现", "出現"),
    "Disappears": ("消失", "消失"),
    "No additional parameters required.": ("无需额外参数。", "無需額外參數。"),

    # === displayName: event names ===
    "Command Finished": ("命令完成", "命令完成"),
    "Directory Changed": ("目录已更改", "目錄已變更"),
    "Host Changed": ("主机已更改", "主機已變更"),
    "User Changed": ("用户已更改", "使用者已變更"),
    "Idle (Silence)": ("空闲（静默）", "閒置（靜默）"),
    "Activity After Idle": ("空闲后活动", "閒置後活動"),
    "Session Ended": ("会话已结束", "工作階段已結束"),
    "Bell Received": ("收到响铃", "收到響鈴"),
    "Long-Running Command": ("长时间运行的命令", "長時間執行的命令"),
    "Custom Escape Sequence": ("自定义转义序列", "自訂跳脫序列"),
    "Notification Posted": ("已发送通知", "已發送通知"),
    "Progress Bar Changed": ("进度条已更改", "進度列已變更"),
    "Job Started": ("作业已开始", "作業已開始"),
    "Job Ended": ("作业已结束", "作業已結束"),
    "Variable Changed": ("变量已更改", "變數已變更"),
    "Unknown Event": ("未知事件", "未知事件"),

    # === helpText: event descriptions ===
    "Fires when shell integration detects a new prompt.": ("Shell 集成检测到新提示时触发。", "Shell 整合偵測到新提示時觸發。"),
    "Fires when a command exits. Requires shell integration.": ("命令退出时触发。需要 Shell 集成。", "命令結束時觸發。需要 Shell 整合。"),
    "Fires when the working directory changes.": ("工作目录更改时触发。", "工作目錄變更時觸發。"),
    "Fires when connecting to a different host via SSH.": ("通过 SSH 连接到不同主机时触发。", "透過 SSH 連線到不同主機時觸發。"),
    "Fires when the current user changes (su/sudo).": ("当前用户更改时触发（su/sudo）。", "目前使用者變更時觸發（su/sudo）。"),
    "Fires when no output is received for the specified duration.": ("指定时长内未收到输出时触发。", "指定時長內未收到輸出時觸發。"),
    "Fires when output resumes after being idle.": ("空闲后恢复输出时触发。", "閒置後恢復輸出時觸發。"),
    "Fires when the session terminates.": ("会话终止时触发。", "工作階段終止時觸發。"),
    "Fires when a terminal bell (\\a) is received.": ("收到终端响铃（\\a）时触发。", "收到終端響鈴（\\a）時觸發。"),
    "Fires when a command runs longer than the threshold.": ("命令运行时间超过阈值时触发。", "命令執行時間超過閾值時觸發。"),
    "Fires when a specific OSC escape sequence is received.": ("收到特定 OSC 转义序列时触发。", "收到特定 OSC 跳脫序列時觸發。"),
    "Fires when a notification is posted by a control sequence (OSC 9).": ("控制序列（OSC 9）发送通知时触发。", "控制序列（OSC 9）發送通知時觸發。"),
    "Fires when a progress bar appears or disappears.": ("进度条出现或消失时触发。", "進度列出現或消失時觸發。"),
    "Fires when a process matching the job filter enters the foreground-job ancestry chain.": ("匹配作业过滤器的进程进入前台作业祖链时触发。", "匹配作業過濾器的行程進入前台作業祖鏈時觸發。"),
    "Fires when a process matching the job filter leaves the foreground-job ancestry chain.": ("匹配作业过滤器的进程离开前台作业祖链时触发。", "匹配作業過濾器的行程離開前台作業祖鏈時觸發。"),
    "Fires when a session variable changes to a value matching the regex.": ("会话变量更改为匹配正则的值时触发。", "工作階段變數變更為匹配正規表示式的值時觸發。"),
}

missing = [k for k in all_seen if k not in T]
extra = [k for k in T if k not in all_seen]
if missing:
    print('MISSING translations:')
    for k in missing: print(f'  {k!r}')
if extra:
    print('EXTRA translations:')
    for k in extra: print(f'  {k!r}')
if missing or extra:
    sys.exit(1)
print(f'Cross-check OK: {len(all_seen)} keys matched in T ({len(T)} entries)')

# ----------------------------------------------------------------------------
# 4. Generate 8-locale .strings files
# ----------------------------------------------------------------------------
def esc(s):
    return (s.replace('\\', '\\\\')
             .replace('"', '\\"')
             .replace('\n', '\\n')
             .replace('\t', '\\t'))

def value_for(key, loc):
    if loc in ('Base', 'en'):
        return key
    simp, trad = T[key]
    return simp if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN') else trad

for loc in LOCALES:
    ldir = f'{SRCDIR}/{loc}.lproj'
    os.makedirs(ldir, exist_ok=True)
    lines = [f'/* Triggers.strings - {loc} */']
    for key in code_keys:
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    content = '\n'.join(lines) + '\n'
    path = f'{ldir}/{TABLE}.strings'
    open(path, 'w', encoding='utf-8').write(content)
    print(f'  {path}: {len(code_keys)} keys')

print(f'All {TABLE}.strings files generated')
