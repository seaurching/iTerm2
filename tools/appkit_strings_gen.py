# -*- coding: utf-8 -*-
"""Add new keys to AppKit.strings for all locales.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# New keys to add
NEW_KEYS = {
    'Undo Close Session': ('撤销关闭会话', '撤銷關閉工作階段'),
    'Suppressed Alerts…': ('已抑制的警告…', '已抑制的警告…'),
    'Downloads': ('下载', '下載'),
    'Uploads': ('上传', '上傳'),
    'Clear All': ('清除全部', '清除全部'),
    'Colors Scheme Imported': ('配色方案已导入', '配色方案已匯入'),
    'The color scheme was imported and added to presets. You can find it under Settings > Profiles > Colors > Load Presets….': ('配色方案已导入并添加到预设。您可以在"设置 > 配置文件 > 颜色 > 加载预设…"中找到它。', '配色方案已匯入並新增到預設。您可以在「設定 > 設定檔 > 顏色 > 載入預設…」中找到它。'),
    'Quit iTerm2?': ('退出 iTerm2？', '結束 iTerm2？'),
    'OK': ('好', '好'),
    'Cancel': ('取消', '取消'),
    'New Window (Default Profile)': ('新窗口（默认配置文件）', '新視窗（預設設定檔）'),
    'Choose a JSON File': ('选择 JSON 文件', '選擇 JSON 檔案'),
    'Settings': ('设置', '設定'),
    'Bring All Windows to Front': ('将所有窗口置前', '將所有視窗置前'),
    'Buried Sessions': ('埋藏的会话', '埋藏的工作階段'),
    'Check For Updates': ('检查更新', '檢查更新'),
    'Main Menu': ('主菜单', '主選單'),
    'Quit iTerm2': ('退出 iTerm2', '結束 iTerm2'),
    'Restore Arrangement': ('恢复窗口排列', '還原視窗排列'),
    'No Retrospective Logs': ('没有回溯日誌', '沒有回溯日誌'),
    'No retrospective debug logs have been recorded yet.': ('尚未录制任何回溯调试日志。', '尚未錄製任何回溯偵錯日誌。'),
    'Save Retrospective Debug Logs': ('保存回溯调试日志', '儲存回溯偵錯日誌'),
    'Could Not Save': ('无法保存', '無法儲存'),
    'Installation Failed': ('安装失败', '安裝失敗'),
    'Python Environment Unavailable': ('Python 环境不可用', 'Python 環境無法使用'),
    'GPU Renderer Availability': ('GPU 渲染器可用性', 'GPU 渲染器可用性'),
    'GPU rendering is enabled for the current session.': ('当前会话已启用 GPU 渲染。', '目前工作階段已啟用 GPU 渲染。'),
}

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def value_for(key, loc):
    if loc in ('Base', 'en'):
        return key
    if key not in NEW_KEYS:
        return key
    if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN'):
        return NEW_KEYS[key][0]
    return NEW_KEYS[key][1]

srcdir = 'sources/AppKit'
for loc in LOCALES:
    path = os.path.join(srcdir, f'{loc}.lproj', 'AppKit.strings')
    if not os.path.exists(path):
        print(f'  {path}: NOT FOUND, skipping')
        continue

    # Read existing content
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check which keys are missing
    added = 0
    for key in NEW_KEYS:
        if f'"{esc(key)}"' not in content:
            val = value_for(key, loc)
            content = content.rstrip('\n') + f'\n"{esc(key)}" = "{esc(val)}";\n'
            added += 1

    if added > 0:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'  {path}: added {added} keys')
    else:
        print(f'  {path}: all keys already present')

print('AppKit strings update done')
