# -*- coding: utf-8 -*-
"""Generate Workgroups.strings for 8 locales from translated keys.

Scans all Swift files in sources/Workgroups/ for
NSLocalizedString("key", tableName: "Workgroups", ...) calls, then
generates .strings files for Base/en/zh_CN/zh_TW/zh-Hans/zh-Hans-CN/
zh-Hant/zh-Hant-TW.
"""
import os, re, sys

SRCDIR = 'sources/Workgroups'
TABLE = 'Workgroups'
LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# --- Translation table: key -> (simplified, traditional) ---
T = {
    '%@ %d': ('%@ %d', '%@ %d'),
    '%@ (%@)': ('%@（%@）', '%@（%@）'),
    '?': ('？', '？'),
    'Add': ('添加', '加入'),
    'Add Peer': ('添加对等体', '加入對等體'),
    'Add Preset': ('添加预设', '加入預設'),
    'Add Session': ('添加会话', '加入工作階段'),
    'Add Split': ('添加分屏', '加入分割'),
    'Add Tab': ('添加标签页', '加入分頁'),
    'Add Toolbar Item': ('添加工具栏项', '加入工具列項目'),
    'Auto-request a review from the code review session when idle: off': ('空闲时从代码评审会话自动请求审查：关', '閒置時從程式碼審查工作階段自動請求審查：關'),
    'Auto-request a review from the code review session when idle: on': ('空闲时从代码评审会话自动请求审查：开', '閒置時從程式碼審查工作階段自動請求審查：開'),
    'Auto-request a review when idle (needs exactly one code review session)': ('空闲时自动请求审查（需要恰好一个代码评审会话）', '閒置時自動請求審查（需要恰好一個程式碼審查工作階段）'),
    'Auto-request review when idle': ('空闲时自动请求审查', '閒置時自動請求審查'),
    'Auto-send clippings to the main session when idle: off': ('空闲时自动发送剪辑到主会话：关', '閒置時自動傳送剪輯到主工作階段：關'),
    'Auto-send clippings to the main session when idle: on': ('空闲时自动发送剪辑到主会话：开', '閒置時自動傳送剪輯到主工作階段：開'),
    'Auto-send clippings when idle': ('空闲时自动发送剪辑', '閒置時自動傳送剪輯'),
    'Back:': ('后退：', '返回：'),
    'Cancel': ('取消', '取消'),
    'Change Command': ('更改命令', '變更命令'),
    'Change Mode': ('更改模式', '變更模式'),
    'Change Orientation': ('更改方向', '變更方向'),
    'Change Peer Shortcut': ('更改对等体快捷键', '變更對等體快速鍵'),
    'Change Per-File Command': ('更改每文件命令', '變更每檔案命令'),
    'Change Profile': ('更改配置', '變更設定檔'),
    'Change Shortcut': ('更改快捷键', '變更快速鍵'),
    'Change Side': ('更改侧边', '變更側邊'),
    'Change Spacer Width': ('更改间隔宽度', '變更間隔寬度'),
    'Change Split Location': ('更改分屏位置', '變更分割位置'),
    'Change URL': ('更改URL', '變更URL'),
    'Code Review Prompts': ('代码评审提示', '程式碼審查提示'),
    'Code review prompt:': ('代码评审提示：', '程式碼審查提示：'),
    'Coding Agent + Diff': ('编码代理 + Diff', '編碼代理 + Diff'),
    'Coding Agent + Diff + Code Review': ('编码代理 + Diff + 代码评审', '編碼代理 + Diff + 程式碼審查'),
    'Diff session is waiting for changes.': ('Diff 会话正在等待变更。', 'Diff 工作階段正在等待變更。'),
    'Forward:': ('前进：', '前進：'),
    'Horizontal': ('水平', '水平'),
    'Location:': ('位置：', '位置：'),
    'Main': ('主', '主'),
    'Main session': ('主会话', '主工作階段'),
    'Manage Prompts…': ('管理提示…', '管理提示…'),
    'Max width:': ('最大宽度：', '最大寬度：'),
    'Min width:': ('最小宽度：', '最小寬度：'),
    'Name': ('名称', '名稱'),
    'Name this prompt': ('为此提示命名', '為此提示命名'),
    'Name:': ('名称：', '名稱：'),
    'New Prompt': ('新提示', '新提示'),
    'Next file': ('下一个文件', '下一個檔案'),
    'No session selected.': ('未选择会话。', '未選擇工作階段。'),
    'No workgroup': ('无工作组', '無工作組'),
    'Peer': ('对等体', '對等體'),
    'Peer: %@': ('对等体：%@', '對等體：%@'),
    'Previous file': ('上一个文件', '上一個檔案'),
    'Prompt name': ('提示名称', '提示名稱'),
    'Prompt:': ('提示：', '提示：'),
    'Prompts': ('提示', '提示'),
    'Reload': ('重载', '重新載入'),
    'Reload queued. Waiting for changes.': ('重载已排队。正在等待变更。', '重新載入已排隊。正在等待變更。'),
    'Reload:': ('重载：', '重新載入：'),
    'Remove': ('移除', '移除'),
    'Remove Session': ('移除会话', '移除工作階段'),
    'Remove Toolbar Item': ('移除工具栏项', '移除工具列項目'),
    'Rename Peer': ('重命名对等体', '重新命名對等體'),
    'Rename Workgroup': ('重命名工作组', '重新命名工作組'),
    'Reorder Toolbar Item': ('重排工具栏项', '重新排列工具列項目'),
    'Run Anyway': ('仍然运行', '仍然執行'),
    'Save': ('保存', '儲存'),
    'Save Current as New…': ('保存当前为新提示…', '儲存目前為新提示…'),
    'Saved prompts can be re-loaded from the Prompts pulldown.': ('已保存的提示可从"提示"下拉菜单重新加载。', '已儲存的提示可從「提示」下拉選單重新載入。'),
    'Select a prompt on the left to edit it, or click + to add a new prompt.': ('选择左侧的提示进行编辑，或点击 + 添加新提示。', '選擇左側的提示進行編輯，或點擊 + 新增提示。'),
    'Select a workgroup on the left or click + to create one.': ('选择左侧的工作组，或点击 + 创建一个。', '選擇左側的工作組，或點擊 + 建立一個。'),
    'Split': ('分屏', '分割'),
    'Split:': ('分屏：', '分割：'),
    'Split: %@ %d%%': ('分屏：%@ %d%%', '分割：%@ %d%%'),
    'Start': ('开始', '開始'),
    'Tab': ('标签页', '分頁'),
    'This session is set to Diff mode, so Reload will re-run the command only after git reports staged or unstaged changes. The previous output is still on screen behind this panel. Cancel to keep that output and abandon the reload, or run the command now anyway.': ('此会话设置为 Diff 模式，因此重载仅在 git 报告暂存或未暂存的更改后才会重新运行命令。之前的输出仍在此面板后面的屏幕上。取消可保留该输出并放弃重载，或立即运行命令。', '此工作階段設定為 Diff 模式，因此重新載入僅在 git 報告暫存或未暫存的變更後才會重新執行命令。之前的輸出仍在此面板後面的螢幕上。取消可保留該輸出並放棄重新載入，或立即執行命令。'),
    'This will also exit %d workgroups and close %d other %@.': ('这还将退出 %d 个工作组并关闭其他 %d 个%@。', '這還將退出 %d 個工作組並關閉其他 %d 個%@。'),
    'This will also exit the workgroup “%@” and close %d other %@.': ('这还将退出工作组“%@”并关闭其他 %d 个%@。', '這還將退出工作組「%@」並關閉其他 %d 個%@。'),
    'Toolbar Items:': ('工具栏项目：', '工具列項目：'),
    'Untitled': ('未命名', '未命名'),
    'Vertical': ('垂直', '垂直'),
    'What is a Workgroup?': ('什么是工作组？', '什麼是工作組？'),
    'Workgroup name': ('工作组名称', '工作組名稱'),
    'session': ('个会话', '個工作階段'),
    'sessions': ('个会话', '個工作階段'),
    # --- iTermWorkgroupToolbarItemRegistry.swift ---
    'Git Status': ('Git 状态', 'Git 狀態'),
    'Changed File Selector': ('已更改文件选择器', '已變更檔案選擇器'),
    'Peer Mode Switcher': ('对等体模式切换器', '對等體模式切換器'),
    'Navigation Buttons': ('导航按钮', '導航按鈕'),
    'Git Base Selector': ('Git 基准选择器', 'Git 基準選擇器'),
    'Auto-Send Clippings When Idle': ('空闲时自动发送剪辑', '閒置時自動傳送剪輯'),
    'Auto-Request Review When Idle': ('空闲时自动请求审查', '閒置時自動請求審查'),
    'Spacer': ('间隔', '間隔'),
    # --- WorkgroupPresets.swift ---
    'Diff': ('Diff', 'Diff'),
    'Chat': ('Chat', 'Chat'),
    'Code Review': ('代码评审', '程式碼審查'),
    # --- iTermWorkgroupSessionDetailViewController.swift ---
    'Default': ('默认', '預設'),
    'Profile:': ('配置文件：', '設定檔：'),
    'Mode:': ('模式：', '模式：'),
    'Command:': ('命令：', '命令：'),
    'File command:': ('文件命令：', '檔案命令：'),
    'URL:': ('URL：', 'URL：'),
    'Shortcut:': ('快捷键：', '快速鍵：'),
}

def q(loc):
    return f'"{loc}"' if '-' in loc else loc

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def value_for(key, loc):
    if loc in ('Base', 'en'):
        return key
    if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN'):
        return T[key][0]
    return T[key][1]  # zh_TW, zh-Hant, zh-Hant-TW

# --- Extract keys from source ---
pat = re.compile(r'NSLocalizedString\("((?:[^"\\\\]|\\\\.)*)",\s*tableName:\s*"Workgroups"')
keys = set()
for f in os.listdir(SRCDIR):
    if not f.endswith('.swift'):
        continue
    s = open(os.path.join(SRCDIR, f), encoding='utf-8').read()
    for m in pat.finditer(s):
        keys.add(m.group(1))

print(f'Extracted {len(keys)} keys from Workgroups Swift files')

# --- Cross-check ---
missing = keys - set(T.keys())
extra = set(T.keys()) - keys
if missing:
    print(f'MISSING from T ({len(missing)}):')
    for k in sorted(missing):
        print(f'  {k!r}')
    sys.exit(1)
if extra:
    print(f'EXTRA in T ({len(extra)}):')
    for k in sorted(extra):
        print(f'  {k!r}')
    sys.exit(1)
print(f'Cross-check OK: {len(keys)} keys matched in T ({len(T)} entries)')

# --- Generate .strings files ---
for loc in LOCALES:
    d = os.path.join(SRCDIR, f'{loc}.lproj')
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, f'{TABLE}.strings')
    lines = [f'/* {TABLE}.strings - {loc} */']
    for key in sorted(keys):
        val = value_for(key, loc)
        lines.append(f'"{esc(key)}" = "{esc(val)}";')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'  {path}: {len(keys)} keys')

print(f'All {TABLE}.strings files generated')
