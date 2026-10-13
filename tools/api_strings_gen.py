# -*- coding: utf-8 -*-
"""Add new keys to APIFiles.strings for all locales.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# New keys to add
NEW_KEYS = {
    'Code-sign exported script using identity: ': ('代码签名导出的脚本使用的身份：', '簽名匯出的腳本使用的身分：'),
    'Offer to launch automatically during installation': ('安装时自动启动', '安裝時自動啟動'),
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

srcdir = 'sources/API'
for loc in LOCALES:
    path = os.path.join(srcdir, f'{loc}.lproj', 'APIFiles.strings')
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

print('API strings update done')
