# -*- coding: utf-8 -*-
"""Add 6 Chinese localizations (zh_CN/zh-Hans/zh-Hans-CN/zh_TW/zh-Hant/zh-Hant-TW)
to 3 TerminalView xcstrings files that currently only have 'en'.

Simplified value shared by zh_CN/zh-Hans/zh-Hans-CN.
Traditional value shared by zh_TW/zh-Hant/zh-Hant-TW.
Sample/placeholder values (e.g. '/directory', '12 bytes', '1h 35m', '127') are
left en-only (Xcode falls back to en for missing locales).
Preserves original file format (sort_keys=False, ' : ' separators, indent=2)."""
import json, os, sys

SIMPLE = ['zh_CN', 'zh-Hans', 'zh-Hans-CN']
TRAD   = ['zh_TW', 'zh-Hant', 'zh-Hant-TW']

# en_value -> (simplified, traditional). Values not in this dict are skipped.
T = {
    'Copy directory': ('拷贝目录', '拷貝目錄'),
    'Select command’s output': ('选择命令的输出', '選擇指令的輸出'),
    'Output:': ('输出：', '輸出：'),
    'Copied': ('已拷贝', '已拷貝'),
    'Copy command to clipboard': ('将命令拷贝到剪贴板', '將指令拷貝到剪貼簿'),
    'Started at %@': ('开始于 %@', '開始於 %@'),
    'Open command in Composer': ('在 Composer 中打开命令', '在 Composer 中開啟指令'),
    'Draggable Folder': ('可拖动文件夹', '可拖曳資料夾'),
    'command': ('命令', '指令'),
    'Write command to terminal': ('将命令写入终端', '將指令寫入終端機'),
    'Directory:': ('目录：', '目錄：'),
    'Return Code:': ('返回码：', '返回碼：'),
    'Write directory to terminal': ('将目录写入终端', '將目錄寫入終端機'),
    'Running Time:': ('运行时间：', '執行時間：'),
    'Copy command’s output': ('拷贝命令的输出', '拷貝指令的輸出'),
    'Share command…': ('分享命令…', '分享指令…'),
    'Command:': ('命令：', '指令：'),
    'Disable showing offscreen command': ('禁用显示屏幕外命令', '停用顯示螢幕外指令'),
    'Label': ('标签', '標籤'),
    'Silently ignore errors from this command': ('静默忽略此命令的错误', '靜默忽略此指令的錯誤'),
    'Coprocess command to run:': ('要运行的辅助进程命令：', '要執行的輔助處理序指令：'),
    'OK': ('确定', '確定'),
    'Cancel': ('取消', '取消'),
    'Enter Command': ('输入命令', '輸入指令'),
}

files = [
    'sources/TerminalView/mul.lproj/CommandInfoViewController.xcstrings',
    'sources/TerminalView/mul.lproj/iTermWindowShortcutAccessoryView.xcstrings',
    'sources/TerminalView/mul.lproj/PseudoTerminal.xcstrings',
]

errs = []
total = 0
for fp in files:
    d = json.load(open(fp))
    strings = d.get('strings', {})
    n = 0
    skipped = []
    for key, val in strings.items():
        locs = val.setdefault('localizations', {})
        en_val = locs.get('en', {}).get('stringUnit', {}).get('value', '')
        if en_val not in T:
            skipped.append(f'{key}={en_val!r}')
            continue
        hans, hant = T[en_val]
        for loc in SIMPLE:
            if loc not in locs:
                locs[loc] = {'stringUnit': {'state': 'translated', 'value': hans}}
                n += 1
        for loc in TRAD:
            if loc not in locs:
                locs[loc] = {'stringUnit': {'state': 'translated', 'value': hant}}
                n += 1
    out = json.dumps(d, indent=2, ensure_ascii=False, sort_keys=False, separators=(',', ' : ')) + '\n'
    open(fp, 'w', encoding='utf-8').write(out)
    print(f'{os.path.basename(fp)}: +{n} locale entries ({len(strings)} keys, {len(skipped)} samples kept en)')
    if skipped:
        print(f'  skipped samples: {skipped}')
    total += n

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print(f'\nTotal: +{total} locale entries across {len(files)} files')
