# -*- coding: utf-8 -*-
"""Generate .strings files for small directories: Toolbelt, StatusBar, PasswordManager, PTYSession, ContextMenu.
"""
import os, re, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# Translation tables for each directory
TRANSLATIONS = {
    'Toolbelt': {
        'Toggle Checkmark': ('切换复选标记', '切換複選標記'),
    },
    'StatusBar': {
        'Contextual Menu': ('右键菜单', '右鍵選單'),
    },
    'PasswordManager': {
        'Test Adapter (Dev)': ('测试适配器（开发）', '測試配接器（開發）'),
    },
    'PTYSession': {
        'Unpause tmux Pane': ('恢复 tmux 面板', '恢復 tmux 面板'),
        'Pause tmux Pane': ('暂停 tmux 面板', '暫停 tmux 面板'),
    },
    'ContextMenu': {
        'Contextual Menu': ('右键菜单', '右鍵選單'),
    },
}

def q(loc):
    return f'"{loc}"' if '-' in loc else loc

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def value_for(key, loc, table):
    if loc in ('Base', 'en'):
        return key
    translations = TRANSLATIONS[table]
    if key not in translations:
        return key
    if loc in ('zh_CN', 'zh-Hans', 'zh-Hans-CN'):
        return translations[key][0]
    return translations[key][1]

# Generate .strings files for each directory
for table, keys in TRANSLATIONS.items():
    srcdir = f'sources/{table}'
    if not os.path.exists(srcdir):
        # Handle special cases
        if table == 'Toolbelt':
            srcdir = 'sources/Toolbelt'
        elif table == 'PTYSession':
            srcdir = 'sources/PTYSession'
        elif table == 'ContextMenu':
            srcdir = 'sources/ContextMenu'

    for loc in LOCALES:
        d = os.path.join(srcdir, f'{loc}.lproj')
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, f'{table}.strings')
        lines = [f'/* {table}.strings - {loc} */']
        for key in sorted(keys.keys()):
            val = value_for(key, loc, table)
            lines.append(f'"{esc(key)}" = "{esc(val)}";')
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
        print(f'  {path}: {len(keys)} keys')

print('All small dirs .strings files generated')
