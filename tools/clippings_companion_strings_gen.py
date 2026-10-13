# -*- coding: utf-8 -*-
"""Generate .strings files for Clippings and Companion directories.
"""
import os, re, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

# Translation tables
TRANSLATIONS = {
    'Clippings': {
        'Hide clippings': ('隐藏剪辑', '隱藏剪輯'),
        'Viewing archived clippings (%d of %d)': ('查看归档剪辑（第 %d 个，共 %d 个）', '檢視歸檔剪輯（第 %d 個，共 %d 個）'),
        'Preview (Space)': ('预览（空格）', '預覽（空白鍵）'),
        'New Clipping': ('新建剪辑', '新增剪輯'),
        'Cancel': ('取消', '取消'),
        'Add': ('添加', '新增'),
    },
    'Companion': {
        'Companion Device Needs an Update': ('伴侣设备需要更新', '伴侶裝置需要更新'),
        'The iTerm2 Buddy app on your phone is too old to connect to ': ('您手机上的 iTerm2 伙伴应用版本太旧，无法连接到 ', '您手機上的 iTerm2 夥伴應用程式版本太舊，無法連線到 '),
        'iTerm2 Needs an Update': ('iTerm2 需要更新', 'iTerm2 需要更新'),
        'This version of iTerm2 is too old to connect to the iTerm2 ': ('此版本的 iTerm2 太旧，无法连接到 iTerm2 ', '此版本的 iTerm2 太舊，無法連線到 iTerm2 '),
        'OK': ('好', '好'),
        'Re-pair Your Companion Device': ('重新配对您的伴侣裝置', '重新配對您的伴侶裝置'),
        'Re-pair…': ('重新配对…', '重新配對…'),
        'Later': ('稍后', '稍後'),
        'Companion Device Settings…': ('伴侣设备设置…', '伴侶裝置設定…'),
        'Install Companion App on your iPhone': ('在 iPhone 上安装伴侣应用', '在 iPhone 上安裝伴侶應用程式'),
        'Unpair': ('取消配对', '取消配對'),
        'Verify': ('验证', '驗證'),
        'Cancel Pairing': ('取消配对', '取消配對'),
        'Companion Device Settings': ('伴侣设备设置', '伴侶裝置設定'),
        'Set Up a Companion Device': ('设置伴侣设备', '設定伴侶裝置'),
        'Setup Could Not Be Completed': ('设置无法完成', '設定無法完成'),
        'Show Pairing Code': ('显示配对码', '顯示配對碼'),
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

# Extract keys from source files
PAT = re.compile(r'NSLocalizedString\("((?:[^"\\]|\\.)*)",\s*tableName:\s*"(\w+)"')

for table in TRANSLATIONS:
    srcdir = f'sources/{table}'
    if not os.path.exists(srcdir):
        print(f'  {srcdir}: NOT FOUND, skipping')
        continue

    # Extract keys from source
    keys = set()
    for f in os.listdir(srcdir):
        if not f.endswith('.swift'):
            continue
        s = open(os.path.join(srcdir, f), encoding='utf-8').read()
        for m in PAT.finditer(s):
            if m.group(2) == table:
                keys.add(m.group(1))

    print(f'{table}: {len(keys)} keys extracted')

    # Generate .strings files
    for loc in LOCALES:
        d = os.path.join(srcdir, f'{loc}.lproj')
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, f'{table}.strings')
        lines = [f'/* {table}.strings - {loc} */']
        for key in sorted(keys):
            val = value_for(key, loc, table)
            lines.append(f'"{esc(key)}" = "{esc(val)}";')
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
        print(f'  {path}: {len(keys)} keys')

print('Clippings/Companion strings gen done')
