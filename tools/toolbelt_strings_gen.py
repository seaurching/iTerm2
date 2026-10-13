# -*- coding: utf-8 -*-
# Generate 8-locale Toolbelt.strings files for the Toolbelt directory.
#
# Locales:
#   Base, en                 -> English (value = key)
#   zh_CN, zh-Hans, zh-Hans-CN -> Simplified Chinese
#   zh_TW, zh-Hant, zh-Hant-TW -> Traditional Chinese
#
# Table name: Toolbelt  ->  sources/Toolbelt/<locale>.lproj/Toolbelt.strings
#
# Extracts keys from both ObjC (NSLocalizedStringFromTableInBundle) and Swift
# (NSLocalizedString, including multi-line triple-quoted and String(format:) forms),
# cross-checks against the translation table, then writes 8 .strings files.
import os
import re
import sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
TABLE = 'Toolbelt'
SRCDIR = 'sources/Toolbelt'

OBJC_FILES = [
    'iTermToolActions.m',
    'iTermToolbeltView.m',
    'iTermToolSnippets.m',
    'ToolProfiles.m',
    'ToolPasteHistory.m',
    'ToolCommandHistoryView.m',
    'ToolDirectoriesView.m',
    'ToolNotes.m',
]
SWIFT_FILES = [
    'ToolCodecierge.swift',
    'ToolStatus.swift',
    'StatusPrioritySettings.swift',
    'ToolNamedMarks.swift',
    'ToolStatusCellView.swift',
]

def decode_objc(s):
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
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

def decode_swift_single(s):
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
            elif c == 'u' and i+2 < len(s) and s[i+2] == '{':
                end = s.find('}', i+3)
                out.append(chr(int(s[i+3:end], 16))); i = end + 1; continue
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

def decode_swift_multi(raw, closing_indent):
    # Strip first newline after opening """
    if raw.startswith('\n'):
        raw = raw[1:]
    # Remove trailing closing-indent line (newline before closing delim not in string)
    idx = raw.rfind('\n' + closing_indent)
    if idx != -1 and raw[idx+1:] == closing_indent:
        raw = raw[:idx]
    # Strip closing_indent from each line
    lines = raw.split('\n')
    out_lines = []
    for line in lines:
        if line.startswith(closing_indent):
            out_lines.append(line[len(closing_indent):])
        else:
            out_lines.append(line)
    content = '\n'.join(out_lines)
    # Single-pass escape + line-continuation decoding
    result = []
    i = 0
    n = len(content)
    while i < n:
        c = content[i]
        if c == '\\' and i+1 < n:
            nxt = content[i+1]
            if nxt == '\n':
                i += 2; continue
            elif nxt == 'n': result.append('\n'); i += 2; continue
            elif nxt == 't': result.append('\t'); i += 2; continue
            elif nxt == 'r': result.append('\r'); i += 2; continue
            elif nxt == '\\': result.append('\\'); i += 2; continue
            elif nxt == '"': result.append('"'); i += 2; continue
            elif nxt == "'": result.append("'"); i += 2; continue
            elif nxt == '0': result.append('\0'); i += 2; continue
            elif nxt == 'u' and i+2 < n and content[i+2] == '{':
                end = content.find('}', i+3)
                result.append(chr(int(content[i+3:end], 16))); i = end + 1; continue
            else:
                result.append(nxt); i += 2; continue
        else:
            result.append(c); i += 1
    return ''.join(result)

def esc(s):
    return (s.replace('\\', '\\\\')
             .replace('"', '\\"')
             .replace('\n', '\\n')
             .replace('\t', '\\t'))

# ============================================================================
# Translations: decoded_key -> (simplified, traditional)
# ============================================================================
T = {}

# --- iTermToolActions.m ---
T['Apply'] = ('应用', '套用')
T['Add'] = ('添加', '新增')
T['Remove'] = ('移除', '移除')
T['Edit'] = ('编辑', '編輯')
T['Untitled'] = ('未命名', '未命名')

# --- iTermToolbeltView.m ---
T['No Tools enabled. Select them from the menu above.'] = (
    '未启用任何工具。请从上方菜单中选择。',
    '未啟用任何工具。請從上方選單中選擇。')
T['Contextual Menu'] = ('上下文菜单', '上下文選單')

# --- iTermToolSnippets.m ---
T['Snippet icon'] = ('代码片段图标', '程式碼片段圖示')
T['Folder icon'] = ('文件夹图标', '資料夾圖示')
T['Send'] = ('发送', '傳送')
T['Open in Advanced Paste'] = ('在高级粘贴中打开', '在進階貼上中開啟')
T['Send Snippet'] = ('发送代码片段', '傳送程式碼片段')

# --- ToolProfiles.m ---
T['Open Profile'] = ('打开配置文件', '開啟設定檔')
T['Open'] = ('打开', '開啟')
T['New Tab'] = ('新建标签页', '新建分頁')
T['New Window'] = ('新建窗口', '新建視窗')
T['New Horizontal Split'] = ('新建水平分屏', '新建水平分割窗格')
T['New Vertical Split'] = ('新建垂直分屏', '新建垂直分割窗格')

# --- ToolPasteHistory.m ---
T['Delete All'] = ('全部删除', '全部刪除')
T['Clear All'] = ('全部清除', '全部清除')
T['⚠️ Secure keyboard entry disables paste history.'] = (
    '⚠️ 安全键盘输入会禁用粘贴历史。',
    '⚠️ 安全鍵盤輸入會停用貼上歷史。')
T['Copy'] = ('复制', '複製')
T['Erase Paste History'] = ('抹掉粘贴历史', '抹除貼上歷史')
T['Paste history will be erased. Continue?'] = (
    '粘贴历史将被抹掉。是否继续？',
    '貼上歷史將被抹除。是否繼續？')
T['OK'] = ('好', '好')
T['Cancel'] = ('取消', '取消')

# --- ToolCommandHistoryView.m ---
T['Clear'] = ('清除', '清除')
T['Erase Command History'] = ('抹掉命令历史', '抹除指令歷史')
T['Command history for all hosts will be erased. Continue?'] = (
    '所有主机的命令历史将被抹掉。是否继续？',
    '所有主機的指令歷史將被抹除。是否繼續？')

# --- ToolDirectoriesView.m ---
T['Toggle Star'] = ('切换星标', '切換星標')
T['Erase Saved Directories?'] = ('抹掉已保存的目录？', '抹除已儲存的目錄？')

# --- ToolNotes.m ---
T['Global'] = ('全局', '全域')
T['Session'] = ('会话', '工作階段')

# --- ToolCodecierge.swift ---
T['Your codecierge session has been going on for a long time. Are you still using it? If not, stop it to save money and privacy.'] = (
    '您的 codecierge 会话已持续了较长时间。您仍在使用它吗？如果不是，请停止它以节省费用并保护隐私。',
    '您的 codecierge 工作階段已持續了較長時間。您仍在使用它嗎？如果不是，請停止它以節省費用並保護隱私。')
T['Keep Going'] = ('继续', '繼續')
T['Stop Codecierge'] = ('停止 Codecierge', '停止 Codecierge')
T['Codecierge Usage Warning'] = ('Codecierge 使用警告', 'Codecierge 使用警告')
T['There was an error: %@'] = ('出现错误：%@', '發生錯誤：%@')
T['Thinking…'] = ('思考中…', '思考中…')
T['Codecierge uses AI to help you in your terminal.'] = (
    'Codecierge 使用 AI 在终端中为您提供帮助。',
    'Codecierge 使用 AI 在終端機中為您提供協助。')
T['Get Started'] = ('开始使用', '開始使用')
T['Reveal Setting'] = ('显示设置', '顯示設定')
T['Generative AI has been disabled by the system administrator.'] = (
    '系统管理员已禁用生成式 AI。',
    '系統管理員已停用生成式 AI。')
T['You must enable AI features to use Codecierge.'] = (
    '您必须启用 AI 功能才能使用 Codecierge。',
    '您必須啟用 AI 功能才能使用 Codecierge。')
T["What are you trying to do? I'll suggest commands and explain their output."] = (
    '您想做什么？我会建议命令并解释其输出。',
    '您想做什麼？我會建議指令並解釋其輸出。')
T['I want to…'] = ('我想…', '我想…')
T['Run commands automatically'] = ('自动运行命令', '自動執行指令')
T['Start'] = ('开始', '開始')
T['This lets an AI completely control your computer. It could delete your files, do something stupid or dangerous, or lead to the downfall of humanity. Proceed with caution.'] = (
    '这会让 AI 完全控制您的电脑。它可能删除您的文件、做些愚蠢或危险的事，甚至导致人类的覆灭。请谨慎操作。',
    '這會讓 AI 完全控制您的電腦。它可能刪除您的檔案、做些愚蠢或危險的事，甚至導致人類的覆滅。請謹慎操作。')
T['Danger!'] = ('危险！', '危險！')
T["Everything that happens in your terminal while Codecierge is running will be sent to your AI provider. Don't send them confidential information!"] = (
    '在 Codecierge 运行期间，终端中发生的所有操作都会发送给您的 AI 提供商。请勿向其发送机密信息！',
    '在 Codecierge 執行期間，終端機中發生的所有操作都會傳送給您的 AI 提供商。請勿向其傳送機密資訊！')
T['Privacy Warning'] = ('隐私警告', '隱私警告')
T['Goal: '] = ('目标：', '目標：')
T['End Task'] = ('结束任务', '結束任務')
T['Response'] = ('回复', '回覆')
T['Send reply'] = ('发送回复', '傳送回覆')

# --- ToolStatus.swift ---
T['Settings'] = ('设置', '設定')
T['Notify on status change'] = ('状态变更时通知', '狀態變更時通知')
T['Watching the selected session for a status change. An alert will appear on the next change, then turn this off.'] = (
    '正在监视所选会话的状态变更。下次变更时将出现提醒，然后关闭此功能。',
    '正在監視所選工作階段的狀態變更。下次變更時將出現提醒，然後關閉此功能。')
T['Watching this window for a session status change. An alert will appear on the next change, then turn this off.'] = (
    '正在监视此窗口的会话状态变更。下次变更时将出现提醒，然后关闭此功能。',
    '正在監視此視窗的工作階段狀態變更。下次變更時將出現提醒，然後關閉此功能。')
T['Notify with an alert when the selected session’s status changes.'] = (
    '所选会话状态变更时通过提醒通知。',
    '所選工作階段狀態變更時透過提醒通知。')
T['Notify with an alert when any session in this window changes status.'] = (
    '此窗口中任何会话状态变更时通过提醒通知。',
    '此視窗中任何工作階段狀態變更時透過提醒通知。')
T['Pane %ld'] = ('分屏面板 %ld', '分割窗格 %ld')
T['Tab %ld'] = ('标签页 %ld', '分頁 %ld')
T['Snooze'] = ('忽略', '靜音')

# --- ToolStatus.swift helpMarkdown (decoded multi-line key) ---
_HELP_KEY = (
    '## Session Status\n\n'
    'The **Session Status** tool shows the status of sessions across all tabs. Each entry displays the '
    'session name, a colored indicator dot, status text, and a keyboard shortcut to jump to that session.\n\n'
    '### Setting Status\n\n'
    '**Triggers:** Add a **Set Tab Status** trigger in **Prefs > Profiles > Advanced > Triggers**. '
    'It lets you set the status text, dot color, and text color when a regex matches terminal output.\n\n'
    '**Control Sequence (OSC 21337):** Programs can set tab status directly:\n\n'
    '`printf \'\\e]21337;status=Working;indicator=#ffa500\\a\'`\n\n'
    'Supported keys (separated by `;`):\n\n'
    '* `status=TEXT` — Sets the status text (e.g., “Working”, “Waiting”).\n'
    '* `indicator=COLOR` — Sets the dot color.\n'
    '* `status-color=COLOR` — Sets the status text color.\n'
    '* `detail=TEXT` — Sets optional detail text shown below the status (wraps up to 3 lines).\n\n'
    'Colors use xterm format: `rgb:RR/GG/BB` (hex, 1–4 digits per component) or `#RRGGBB`.\n\n'
    'Set a key to empty to clear it: `status=` clears the status text.\n\n'
    '**Clear all status:** `printf \'\\e]21337;status=;indicator=\\a\'`\n\n'
    '### Priority Sorting\n\n'
    'Sessions are sorted by priority. Click the ⚙ button to configure which status '
    'keywords have the highest priority. The default order is: waiting, working, idle.\n\n'
    '### Snoozing\n\n'
    'Right-click a row and choose **Snooze** to move it to the bottom of the list and '
    'dim it. A snoozed entry automatically un-snoozes the next time its status changes.'
)
_HELP_SIMP = (
    '## 会话状态\n\n'
    '**会话状态**工具显示所有标签页中会话的状态。每个条目显示会话名称、彩色指示圆点、状态文本以及跳转到该会话的键盘快捷键。\n\n'
    '### 设置状态\n\n'
    '**触发器：**在 **偏好设置 > 配置文件 > 高级 > 触发器**中添加一个 **设置标签页状态** 触发器。'
    '它允许您在正则表达式匹配终端输出时设置状态文本、圆点颜色和文本颜色。\n\n'
    '**控制序列 (OSC 21337)：**程序可以直接设置标签页状态：\n\n'
    '`printf \'\\e]21337;status=Working;indicator=#ffa500\\a\'`\n\n'
    '支持的键（以 `;` 分隔）：\n\n'
    '* `status=TEXT` — 设置状态文本（例如 “Working”、“Waiting”）。\n'
    '* `indicator=COLOR` — 设置圆点颜色。\n'
    '* `status-color=COLOR` — 设置状态文本颜色。\n'
    '* `detail=TEXT` — 设置显示在状态下方的可选详情文本（最多换行 3 行）。\n\n'
    '颜色使用 xterm 格式：`rgb:RR/GG/BB`（十六进制，每个分量 1–4 位）或 `#RRGGBB`。\n\n'
    '将键设为空以清除：`status=` 清除状态文本。\n\n'
    '**清除所有状态：**`printf \'\\e]21337;status=;indicator=\\a\'`\n\n'
    '### 优先级排序\n\n'
    '会话按优先级排序。点击 ⚙ 按钮配置哪些状态关键字具有最高优先级。默认顺序为：waiting、working、idle。\n\n'
    '### 忽略\n\n'
    '右键点击某行并选择 **忽略**，将其移至列表底部并变暗显示。被忽略的条目在其状态下次变更时会自动取消忽略。'
)
_HELP_TRAD = (
    '## 工作階段狀態\n\n'
    '**工作階段狀態**工具顯示所有分頁中工作階段的狀態。每個項目顯示工作階段名稱、彩色指示圓點、狀態文字以及跳轉到該工作階段的鍵盤快捷鍵。\n\n'
    '### 設定狀態\n\n'
    '**觸發器：**在 **偏好設定 > 設定檔 > 進階 > 觸發器**中新增一個 **設定分頁狀態** 觸發器。'
    '它允許您在正規表示式匹配終端機輸出時設定狀態文字、圓點顏色和文字顏色。\n\n'
    '**控制序列 (OSC 21337)：**程式可以直接設定分頁狀態：\n\n'
    '`printf \'\\e]21337;status=Working;indicator=#ffa500\\a\'`\n\n'
    '支援的鍵（以 `;` 分隔）：\n\n'
    '* `status=TEXT` — 設定狀態文字（例如「Working」、「Waiting」）。\n'
    '* `indicator=COLOR` — 設定圓點顏色。\n'
    '* `status-color=COLOR` — 設定狀態文字顏色。\n'
    '* `detail=TEXT` — 設定顯示在狀態下方的可選詳情文字（最多換行 3 行）。\n\n'
    '顏色使用 xterm 格式：`rgb:RR/GG/BB`（十六進位，每個分量 1–4 位）或 `#RRGGBB`。\n\n'
    '將鍵設為空以清除：`status=` 清除狀態文字。\n\n'
    '**清除所有狀態：**`printf \'\\e]21337;status=;indicator=\\a\'`\n\n'
    '### 優先順序排序\n\n'
    '工作階段按優先順序排序。點擊 ⚙ 按鈕設定哪些狀態關鍵字具有最高優先順序。預設順序為：waiting、working、idle。\n\n'
    '### 靜音\n\n'
    '右鍵點擊某列並選擇 **靜音**，將其移至列表底部並變暗顯示。被靜音的項目在其狀態下次變更時會自動取消靜音。'
)
T[_HELP_KEY] = (_HELP_SIMP, _HELP_TRAD)

# --- StatusPrioritySettings.swift ---
T['New Priority Pattern'] = ('新建优先级模式', '新建優先順序模式')
T['Enter a substring to match against status text (case-insensitive).'] = (
    '输入要与状态文本匹配的子字符串（不区分大小写）。',
    '輸入要與狀態文字比對的子字串（不區分大小寫）。')
T['Statuses are sorted by priority. Items near the top have higher priority. Drag to reorder. Click to edit.'] = (
    '状态按优先级排序。靠近顶部的项目优先级更高。拖动以重新排序。点击以编辑。',
    '狀態按優先順序排序。靠近頂部的項目優先順序較高。拖曳以重新排序。點擊以編輯。')
T['Show status in tab subtitle'] = ('在标签页副标题中显示状态', '在分頁副標題中顯示狀態')
T['Merge workgroup statuses'] = ('合并工作组状态', '合併工作群組狀態')
T['When enabled, only the most recent status from each workgroup is shown.'] = (
    '启用后，仅显示每个工作组的最新状态。',
    '啟用後，僅顯示每個工作群組的最新狀態。')
T['Pattern'] = ('模式', '模式')
T['Notify'] = ('通知', '通知')

# --- ToolNamedMarks.swift ---
T['(Unnamed)'] = ('(未命名)', '(未命名)')

# --- ToolStatusCellView.swift ---
T['Notify on status change armed'] = ('已启用状态变更通知', '已啟用狀態變更通知')
T['Snoozed'] = ('已忽略', '已靜音')

# ============================================================================
# Extract keys from source and cross-check
# ============================================================================
code_keys = []
seen = set()

# ObjC
pat_objc = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"Toolbelt"')
for fn in OBJC_FILES:
    s = open(f'{SRCDIR}/{fn}', encoding='utf-8').read()
    for m in pat_objc.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k); code_keys.append(k)

# Swift
pat_swift = re.compile(r'NSLocalizedString\("((?:[^"\\]|\\.)*)", tableName: "Toolbelt"')
pat_swift_multi = re.compile(r'NSLocalizedString\("""(.*?)""", tableName: "Toolbelt"', re.DOTALL)
for fn in SWIFT_FILES:
    s = open(f'{SRCDIR}/{fn}', encoding='utf-8').read()
    multiline_spans = []
    for m in pat_swift_multi.finditer(s):
        # closing indent = whitespace after last newline in captured raw
        raw = m.group(1)
        last_nl = raw.rfind('\n')
        closing_indent = raw[last_nl+1:] if last_nl != -1 else ''
        k = decode_swift_multi(raw, closing_indent)
        if k not in seen:
            seen.add(k); code_keys.append(k)
        multiline_spans.append(m.span())
    # mask multi-line regions for single-line pattern
    masked = list(s)
    for a, b in multiline_spans:
        for j in range(a, b):
            if masked[j] != '\n':
                masked[j] = ' '
    s_masked = ''.join(masked)
    for m in pat_swift.finditer(s_masked):
        k = decode_swift_single(m.group(1))
        if k not in seen:
            seen.add(k); code_keys.append(k)

missing = [k for k in code_keys if k not in T]
extra = [k for k in T if k not in seen]
if missing:
    print('MISSING translations:')
    for k in missing: print(f'  {k!r}')
if extra:
    print('EXTRA translations (not in code):')
    for k in extra: print(f'  {k!r}')
if missing or extra:
    sys.exit(1)
print(f'Cross-check OK: {len(code_keys)} keys matched')

# ============================================================================
# Generate .strings files
# ============================================================================
def value_for(key, loc):
    if loc in ('Base', 'en'):
        return key
    simp, trad = T[key]
    return simp if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN') else trad

def q(loc):
    return f'"{loc}"' if '-' in loc else loc

for loc in LOCALES:
    ldir = f'{SRCDIR}/{loc}.lproj'
    os.makedirs(ldir, exist_ok=True)
    lines = [f'/* Toolbelt.strings - {loc} */']
    for key in code_keys:
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    content = '\n'.join(lines) + '\n'
    path = f'{ldir}/{TABLE}.strings'
    open(path, 'w', encoding='utf-8').write(content)
    print(f'  {path}: {len(code_keys)} keys')

print('All Toolbelt.strings files generated')
