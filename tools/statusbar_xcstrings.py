# -*- coding: utf-8 -*-
"""Add 6 Chinese localizations (zh_CN/zh-Hans/zh-Hans-CN/zh_TW/zh-Hant/zh-Hant-TW)
to 12 StatusBar xcstrings files that currently only have 'en'.

Simplified value shared by zh_CN/zh-Hans/zh-Hans-CN.
Traditional value shared by zh_TW/zh-Hant/zh-Hant-TW.
Preserves original file format (sort_keys=False, ' : ' separators, indent=2)."""
import json, os, sys

SIMPLE = ['zh_CN', 'zh-Hans', 'zh-Hans-CN']
TRAD   = ['zh_TW', 'zh-Hant', 'zh-Hant-TW']

# Translation table: en_value -> (simplified, traditional)
T = {
    'Label': ('标签', '標籤'),
    'OK': ('确定', '確定'),
    'Cancel': ('取消', '取消'),
    'Check': ('勾选', '勾選'),
    'Item 1': ('项目 1', '項目 1'),
    'Item 2': ('项目 2', '項目 2'),
    'Item 3': ('项目 3', '項目 3'),
    'Command': ('命令', '指令'),
    'Search': ('搜索', '搜尋'),
    'Filter': ('筛选', '篩選'),
    'Automatic': ('自动', '自動'),
    'Disabled': ('已禁用', '已停用'),
    'Change': ('更改', '更改'),
    'Dark Colors': ('深色', '深色'),
    'Light Colors': ('浅色', '淺色'),
    'AI': ('AI', 'AI'),
    'Font:': ('字体：', '字體：'),
    'Background Color:': ('背景颜色：', '背景顏色：'),
    'Separator Color:': ('分隔线颜色：', '分隔線顏色：'),
    'Default Text Color:': ('默认文本颜色：', '預設文字顏色：'),
    'Advanced…': ('高级…', '進階…'),
    'Active Components': ('活跃组件', '使用中元件'),
    'Status Bar Component Menu': ('状态栏组件菜单', '狀態列元件選單'),
    'Configure Component': ('配置组件', '設定元件'),
    'Font name goes here': ('字体名称显示于此', '字體名稱顯示於此'),
    '🌈 Auto-Rainbow:': ('🌈 自动彩虹：', '🌈 自動彩虹：'),
    'Prefer tight packing to stable positioning': ('优先紧凑排列而非稳定定位', '偏好緊湊排列而非穩定定位'),
    'Draw separator between status bar and terminal': ('在状态栏和终端之间绘制分隔线', '在狀態列與終端機之間繪製分隔線'),
    'Draws a thin line between the status bar and the terminal content.': ('在状态栏和终端内容之间绘制细线。', '在狀態列與終端機內容之間繪製細線。'),
    'Remove components with empty values': ('移除值为空的组件', '移除值為空的元件'),
    'The tight packing algorithm allows more status bar components to be visible at a time but they tend to jump around more.': ('紧凑排列算法允许同时显示更多状态栏组件，但它们往往跳动更频繁。', '緊湊排列演算法允許同時顯示更多狀態列元件，但它們往往跳動更頻繁。'),
    'Drag a component from the menu to Active Components to add it to your status bar.': ('从菜单拖动组件到“活跃组件”以将其添加到状态栏。', '從選單拖曳元件到「使用中元件」以將其新增到狀態列。'),
    'Erase Search History': ('清除搜索历史', '清除搜尋記錄'),
    'Case-Sensitive Substring': ('区分大小写子字符串', '區分大小寫子字串'),
    'Case-Sensitive Regex': ('区分大小写正则表达式', '區分大小寫正規表示式'),
    'Smart Case Substring': ('智能大小写子字符串', '智慧大小寫子字串'),
    'Case-Insensitive Regex': ('不区分大小写正则表达式', '不區分大小寫正規表示式'),
    'Case-Insensitive Substring': ('不区分大小写子字符串', '不區分大小寫子字串'),
    'Describes how to use the composer.': ('描述如何使用编辑器。', '描述如何使用編輯器。'),
    'AI completion enabled: all text sent to AI': ('AI 补全已启用：所有文本发送给 AI', 'AI 補全已啟用：所有文字傳送給 AI'),
    'Press ⇧↩\xa0to send.': ('按 ⇧↩\xa0发送。', '按 ⇧↩\xa0傳送。'),
}

files = [
    'sources/StatusBar/Setup/mul.lproj/iTermStatusBarSetupCollectionViewItem.xcstrings',
    'sources/StatusBar/Setup/mul.lproj/iTermStatusBarSetupConfigureComponentWindowController.xcstrings',
    'sources/StatusBar/Setup/mul.lproj/iTermStatusBarSetupViewController.xcstrings',
    'sources/StatusBar/Setup/Knobs/mul.lproj/iTermStatusBarKnobCheckboxViewController.xcstrings',
    'sources/StatusBar/Setup/Knobs/mul.lproj/iTermStatusBarKnobColorViewController.xcstrings',
    'sources/StatusBar/Setup/Knobs/mul.lproj/iTermStatusBarKnobFontViewController.xcstrings',
    'sources/StatusBar/Setup/Knobs/mul.lproj/iTermStatusBarKnobTextViewController.xcstrings',
    'sources/StatusBar/Setup/Knobs/mul.lproj/iTermStatusBarKnobNumericViewController.xcstrings',
    'sources/StatusBar/Components/mul.lproj/iTermsStatusBarComposerViewController.xcstrings',
    'sources/StatusBar/Components/mul.lproj/iTermMiniSearchFieldViewController.xcstrings',
    'sources/StatusBar/Components/mul.lproj/MiniFilterViewController.xcstrings',
    'sources/StatusBar/Components/mul.lproj/iTermStatusBarLargeComposerViewController.xcstrings',
]

errs = []
total = 0
for fp in files:
    d = json.load(open(fp))
    strings = d.get('strings', {})
    n = 0
    for key, val in strings.items():
        locs = val.setdefault('localizations', {})
        en_val = locs.get('en', {}).get('stringUnit', {}).get('value', '')
        if en_val not in T:
            errs.append(f'{os.path.basename(fp)}: no translation for {key!r} = {en_val!r}')
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
    print(f'{os.path.basename(fp)}: +{n} locale entries ({len(strings)} keys)')
    total += n

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print(f'\nTotal: +{total} locale entries across {len(files)} files')
