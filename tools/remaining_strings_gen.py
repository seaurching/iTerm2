# -*- coding: utf-8 -*-
"""Add new keys to .strings files for remaining stringWithFormat wraps.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# New keys per table
NEW_KEYS = {
    'AppKit': {
        '1 Alert Suppressed': ('已抑制 1 个警告', '已抑制 1 個警告'),
        '%@ Alerts Suppressed': ('已抑制 %@ 个警告', '已抑制 %@ 個警告'),
        '%@ (%@ ago)…': ('%@（%@ 前）…', '%@（%@ 前）…'),
        '%@…': ('%@…', '%@…'),
        'Toggle Key Recording': ('切换按键录制', '切換按鍵錄製'),
        'Replay Recorded Keys': ('回放录制的按键', '回放錄製的按鍵'),
        'Failed to save retrospective debug logs: %@': ('保存回溯调试日志失败：%@', '儲存回溯偵錯日誌失敗：%@'),
        'Could not install the Python runtime: %@': ('无法安装 Python 运行时：%@', '無法安裝 Python 執行階段：%@'),
        'Could not prepare the Python environment for the REPL: %@': ('无法为 REPL 准备 Python 环境：%@', '無法為 REPL 準備 Python 環境：%@'),
        'GPU rendering is off in the current session because %@': ('当前会话已关闭 GPU 渲染，因为%@', '目前工作階段已關閉 GPU 渲染，因為%@'),
    },
    'Settings': {
        'Could not save to %@': ('无法保存到%@', '無法儲存到%@'),
    },
    'API': {
        'Open new script in %@?': ('在%@中打开新脚本？', '在%@中開啟新腳本？'),
        '“%@” uses an Intel-only Python environment, which cannot run on this version of macOS because Rosetta is not available.': ('“%@”使用仅限 Intel 的 Python 环境，由于 Rosetta 不可用，无法在此版本的 macOS 上运行。', '「%@」使用僅限 Intel 的 Python 環境，由於 Rosetta 不可用，無法在此版本的 macOS 上執行。'),
    },
    'ProcessInfo': {
        'SIG%@ (%d)': ('SIG%@ (%d)', 'SIG%@ (%d)'),
    },
    'TerminalView': {
        '%@ — %@': ('%@ — %@', '%@ — %@'),
    },
}

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def value_for(key, loc, table):
    if loc in ('Base', 'en'):
        return key
    translations = NEW_KEYS[table]
    if key not in translations:
        return key
    if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN'):
        return translations[key][0]
    return translations[key][1]

for table, keys in NEW_KEYS.items():
    srcdir = f'sources/{table}'
    for loc in LOCALES:
        path = os.path.join(srcdir, f'{loc}.lproj', f'{table}.strings')
        if not os.path.exists(path):
            print(f'  {path}: NOT FOUND, skipping')
            continue
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        added = 0
        for key in keys:
            if f'"{esc(key)}"' not in content:
                val = value_for(key, loc, table)
                content = content.rstrip('\n') + f'\n"{esc(key)}" = "{esc(val)}";\n'
                added += 1
        if added > 0:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'  {path}: added {added} keys')
        else:
            print(f'  {path}: all keys already present')

print('Remaining strings gen done')
