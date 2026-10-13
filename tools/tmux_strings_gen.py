# -*- coding: utf-8 -*-
"""Generate 8-locale tmux.strings files for the tmux directory.

Locales:
  Base, en                 -> English (value = key)
  zh_CN, zh-Hans, zh-Hans-CN -> Simplified Chinese
  zh_TW, zh-Hant, zh-Hant-TW -> Traditional Chinese

Table name: tmux  ->  sources/tmux/<locale>.lproj/tmux.strings

Includes a built-in cross-check that every key wrapped in the source files
has a translation defined, and vice versa.
"""
import os
import re
import sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
TABLE = 'tmux'
SRCDIR = 'sources/tmux'

SRC_FILES = [
    'TmuxGateway.m',
    'TmuxWindowOpener.m',
    'TmuxWindowsTable.m',
    'TmuxSessionsTable.m',
    'TmuxController.m',
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

def esc(s):
    return (s.replace('\\', '\\\\')
             .replace('"', '\\"')
             .replace('\n', '\\n')
             .replace('\t', '\\t'))

# ============================================================================
# Translations: decoded_key -> (simplified, traditional)
# ============================================================================
T = {}

# --- TmuxGateway.m ---
T['tmux Reported a Problem'] = ('tmux 报告了一个问题', 'tmux 報告了一個問題')
T['OK'] = ('好', '好')
T['Malformed command (expected %%num data): "%s"'] = (
    '格式错误的命令（预期 %%num data）：“%s”',
    '格式錯誤的命令（預期 %%num data）：“%s”')
T['Malformed command (expected %%layout-change <window> <layout> [<window_visible_layout> <window_flags>]): "%@"'] = (
    '格式错误的命令（预期 %%layout-change <window> <layout> [<window_visible_layout> <window_flags>]）：“%@”',
    '格式錯誤的命令（預期 %%layout-change <window> <layout> [<window_visible_layout> <window_flags>]）：“%@”')
T['Malformed command (expected %%window-add id): "%@"'] = (
    '格式错误的命令（预期 %%window-add id）：“%@”',
    '格式錯誤的命令（預期 %%window-add id）：“%@”')
T['Malformed command (expected %%window-close id): "%@"'] = (
    '格式错误的命令（预期 %%window-close id）：“%@”',
    '格式錯誤的命令（預期 %%window-close id）：“%@”')
T['Malformed command (expected %%window-renamed id new_name): "%@"'] = (
    '格式错误的命令（预期 %%window-renamed id new_name）：“%@”',
    '格式錯誤的命令（預期 %%window-renamed id new_name）：“%@”')
T['Malformed command (expected %%session-renamed id name): "%@"'] = (
    '格式错误的命令（预期 %%session-renamed id name）：“%@”',
    '格式錯誤的命令（預期 %%session-renamed id name）：“%@”')
T['Malformed command (expected %%session-changed id name): "%@"'] = (
    '格式错误的命令（预期 %%session-changed id name）：“%@”',
    '格式錯誤的命令（預期 %%session-changed id name）：“%@”')
T['Malformed command (expected %%sessions-changed): "%@"'] = (
    '格式错误的命令（预期 %%sessions-changed）：“%@”',
    '格式錯誤的命令（預期 %%sessions-changed）：“%@”')
T['Malformed command (expected %%window-pane-changed @window-id %%pane-id): "%@"'] = (
    '格式错误的命令（预期 %%window-pane-changed @window-id %%pane-id）：“%@”',
    '格式錯誤的命令（預期 %%window-pane-changed @window-id %%pane-id）：“%@”')
T['Malformed command (expected %%session-window-changed $session-id @window-id): "%@"'] = (
    '格式错误的命令（预期 %%session-window-changed $session-id @window-id）：“%@”',
    '格式錯誤的命令（預期 %%session-window-changed $session-id @window-id）：“%@”')
T['Malformed command (expected %%pause %%wp): "%@"'] = (
    '格式错误的命令（预期 %%pause %%wp）：“%@”',
    '格式錯誤的命令（預期 %%pause %%wp）：“%@”')
T['Malformed command (expected %%subscription-changed sid [...] : value): "%@"'] = (
    '格式错误的命令（预期 %%subscription-changed sid [...] : value）：“%@”',
    '格式錯誤的命令（預期 %%subscription-changed sid [...] : value）：“%@”')
T['Error: %@.\n\nTmux 2.1 and earlier will refuse to create a new window pane with a nonexistent initial working directory.\n\nInfo:\n%@'] = (
    '错误：%@。\n\nTmux 2.1 及更早版本会拒绝使用不存在的初始工作目录创建新窗口面板。\n\n信息：\n%@',
    '錯誤：%@。\n\nTmux 2.1 及更早版本會拒絕使用不存在的初始工作目錄建立新視窗面板。\n\n資訊：\n%@')
T['Error: %@.\n\nInfo:\n%@'] = (
    '错误：%@。\n\n信息：\n%@',
    '錯誤：%@。\n\n資訊：\n%@')
T['%begin without %end'] = ('%begin 缺少 %end', '%begin 缺少 %end')
T['Malformed command (expected %%begin command_id [flags]): "%@"'] = (
    '格式错误的命令（预期 %%begin command_id [flags]）：“%@”',
    '格式錯誤的命令（預期 %%begin command_id [flags]）：“%@”')
T['%begin with empty command queue'] = ('%begin 时命令队列为空', '%begin 時命令佇列為空')

# --- TmuxWindowOpener.m ---
T["Can't open window: missing layout"] = ('无法打开窗口：缺少布局', '無法開啟視窗：缺少佈局')
T['Error parsing layout %@'] = ('解析布局出错 %@', '解析佈局時發生錯誤 %@')
T['Error: malformed history line from tmux.'] = ('错误：来自 tmux 的历史行格式错误。', '錯誤：來自 tmux 的歷史行格式錯誤。')
T['See Console.app for details'] = ('详情请查看 Console.app', '詳情請查看 Console.app')

# --- TmuxWindowsTable.m ---
T['Open in Window'] = ('在窗口中打开', '在視窗中開啟')
T['Open in Windows'] = ('在多个窗口中打开', '在多個視窗中開啟')

# --- TmuxSessionsTable.m ---
T['New Session'] = ('新建会话', '新建工作階段')
T['New Session %d'] = ('新建会话 %d', '新建工作階段 %d')

# --- TmuxController.m ---
T['Bad response for initial list windows request: %@'] = (
    '初始列出窗口请求的响应无效：%@',
    '初始列出視窗請求的回應無效：%@')
T['Too many tmux windows!'] = ('tmux 窗口过多！', 'tmux 視窗過多！')
T['Use the tmux dashboard to select which to open.'] = (
    '请使用 tmux 控制面板选择要打开的窗口。',
    '請使用 tmux 控制面板選擇要開啟的視窗。')
T['Some tmux windows were hidden.'] = ('部分 tmux 窗口已隐藏。', '部分 tmux 視窗已隱藏。')
T['tmux is not in UTF-8 mode. Please pass the -u command line argument to tmux or change your LANG environment variable to end with “.UTF-8”.'] = (
    'tmux 未处于 UTF-8 模式。请向 tmux 传递 -u 命令行参数，或将您的 LANG 环境变量改为以“.UTF-8”结尾。',
    'tmux 未處於 UTF-8 模式。請向 tmux 傳遞 -u 命令列參數，或將您的 LANG 環境變數改為以「.UTF-8」結尾。')
T['UTF-8 Mode Not Detected'] = ('未检测到 UTF-8 模式', '未偵測到 UTF-8 模式')
T['The "%@" option is turned on in tmux. It is not compatible with the iTerm2-tmux integration. Please disable it and try again.'] = (
    'tmux 中已开启“%@”选项。该选项与 iTerm2-tmux 集成不兼容。请将其关闭后重试。',
    'tmux 中已開啟「%@」選項。該選項與 iTerm2-tmux 整合不相容。請將其關閉後重試。')
T['Unsupported tmux option'] = ('不支持的 tmux 选项', '不支援的 tmux 選項')
T['While attaching to tmux, some tabs were found whose color is pure red. This may be due to a bug in early versions of iTerm2 3.6.x. Would you like to reset those tabs’ colors?'] = (
    '在附加到 tmux 时，发现部分标签页的颜色为纯红色。这可能是由于 iTerm2 3.6.x 早期版本中的一个 bug 导致。是否要重置这些标签页的颜色？',
    '在附加到 tmux 時，發現部分分頁的顏色為純紅色。這可能是由於 iTerm2 3.6.x 早期版本中的一個 bug 所致。是否要重設這些分頁的顏色？')
T['Reset'] = ('重置', '重設')
T['Keep Red'] = ('保持红色', '保持紅色')
T['Fix corrupted tab colors?'] = ('修复损坏的标签页颜色？', '修復損壞的分頁顏色？')
T['Bad response for list windows request: %@'] = (
    '列出窗口请求的响应无效：%@',
    '列出視窗請求的回應無效：%@')
T['Error opening tmux tab'] = ('打开 tmux 标签页时出错', '開啟 tmux 分頁時發生錯誤')
T['A tmux pane terminated immediately after creation'] = (
    'tmux 面板在创建后立即终止',
    'tmux 面板在建立後立即終止')

# ============================================================================
# Extract keys from source and cross-check
# ============================================================================
pat = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"tmux"')
code_keys = []
seen = set()
for fn in SRC_FILES:
    s = open(f'{SRCDIR}/{fn}', encoding='utf-8').read()
    for m in pat.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k)
            code_keys.append(k)

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
    lines = [f'/* tmux.strings - {loc} */']
    for key in code_keys:
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    content = '\n'.join(lines) + '\n'
    path = f'{ldir}/{TABLE}.strings'
    open(path, 'w', encoding='utf-8').write(content)
    print(f'  {path}: {len(code_keys)} keys')

print('All tmux.strings files generated')
