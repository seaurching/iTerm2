# -*- coding: utf-8 -*-
"""Add new keys to Settings.strings for all locales.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# New keys to add
NEW_KEYS = {
    'No deletable color presets.': ('没有可删除的颜色预设。', '沒有可刪除的顏色預設。'),
    'You cannot erase the built-in presets and no custom presets have been imported.': ('无法删除内置预设，且尚未导入自定义预设。', '無法刪除內建設定，且尚未匯入自訂預設。'),
    'Select a preset to delete:': ('选择要删除的预设：', '選擇要刪除的預設：'),
    'Save Failed.': ('保存失败。', '儲存失敗。'),
    'Apply to current session': ('应用到当前会话', '套用到目前工作階段'),
    'Apply to all sessions': ('应用到所有会话', '套用到所有工作階段'),
    'Apply to all sessions except current': ('应用到除当前外所有会话', '套用到除目前外所有工作階段'),
    'Apply to all sessions in window': ('应用到窗口中所有会话', '套用到視窗中所有工作階段'),
    'Apply to all sessions in tab': ('应用到标签页中所有会话', '套用到分頁中所有工作階段'),
    'Apply to broadcasted-to sessions': ('应用到广播目标会话', '套用到廣播目標工作階段'),
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

srcdir = 'sources/Settings'
for loc in LOCALES:
    path = os.path.join(srcdir, f'{loc}.lproj', 'Settings.strings')
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

print('Settings strings update done')
