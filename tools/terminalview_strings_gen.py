# -*- coding: utf-8 -*-
"""Add new keys to TerminalView.strings for all locales.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# New keys to add
NEW_KEYS = {
    'Select': ('选择', '選擇'),
    'New Tab to the Right': ('在右侧新建标签页', '在右側新增分頁'),
    'Edit Session…': ('编辑会话…', '編輯工作階段…'),
    'Close Tab': ('关闭标签页', '關閉分頁'),
    'Duplicate Tab': ('复制标签页', '複製分頁'),
    'Save Tab as Window Arrangement': ('将标签页保存为窗口排列', '將分頁儲存為視窗排列'),
    'Move to New Window': ('移动到新窗口', '移動到新視窗'),
    'Close Other Tabs': ('关闭其他标签页', '關閉其他分頁'),
    'Tab Color': ('标签页颜色', '分頁顏色'),
    'New Group…': ('新建分组…', '新增群組…'),
    'Add Tab to Group': ('将标签页添加到分组', '將分頁加入群組'),
    'Rename Group…': ('重命名分组…', '重新命名群組…'),
    'Remove Tab from Group': ('将标签页从分组移除', '將分頁從群組移除'),
    'Group Color': ('分组颜色', '群組顏色'),
    'Enable GPU Frame Capture': ('启用 GPU 帧捕获', '啟用 GPU 畫面擷取'),
    'Capture GPU Frame': ('捕获 GPU 帧', '擷取 GPU 畫面'),
    'Disable Command Selection': ('禁用命令选择', '停用命令選擇'),
    'Help': ('帮助', '說明'),
    'Copy Command': ('复制命令', '複製命令'),
    'Copy Output': ('复制输出', '複製輸出'),
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

srcdir = 'sources/TerminalView'
for loc in LOCALES:
    path = os.path.join(srcdir, f'{loc}.lproj', 'TerminalView.strings')
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

print('TerminalView strings update done')
