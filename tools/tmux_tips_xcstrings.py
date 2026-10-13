# -*- coding: utf-8 -*-
# Adapt Toolbelt-adjacent xcstrings (String Catalog) files for Chinese locales.
#
# Files:
#   sources/tmux/mul.lproj/TmuxDashboard.xcstrings
#   sources/Tips/mul.lproj/iTermTipCardViewController.xcstrings
#   (sources/Tips/mul.lproj/iTermTipWindowController.xcstrings is empty - skipped)
#
# For each key whose en value is in the translation table, add 7 Chinese
# localizations:
#   zh_CN, zh-Hans, zh-Hans-CN  -> simplified value  (state "translated")
#   zh_TW, zh-Hant, zh-Hant-TW  -> traditional value  (state "translated")
# Keys with shouldTranslate == false are skipped.
# JSON output matches Xcode's xcstrings format (2-space indent, " : " separator).
import json
import sys

FILES = [
    'sources/tmux/mul.lproj/TmuxDashboard.xcstrings',
    'sources/Tips/mul.lproj/iTermTipCardViewController.xcstrings',
]

# decoded en value -> (simplified, traditional)
T = {}

# --- TmuxDashboard.xcstrings ---
T['tmux Dashboard'] = ('tmux 控制面板', 'tmux 控制面板')
T['Session'] = ('会话', '工作階段')
T['Attach'] = ('附加', '附加')
T['Search Windows'] = ('搜索窗口', '搜尋視窗')
T['Window'] = ('窗口', '視窗')
T['Open in Windows'] = ('在窗口中打开', '在視窗中開啟')
T['Hide'] = ('隐藏', '隱藏')
T['Open in Tabs'] = ('在标签页中打开', '在分頁中開啟')
T['Detach'] = ('分离', '分離')
T['Open dashboard when attaching if there are hidden windows'] = (
    '附加时若存在隐藏窗口则打开控制面板',
    '附加時若存在隱藏視窗則開啟控制面板')
T['Don’t open windows when attaching if there are at least this many windows:'] = (
    '附加时若窗口数量至少达到此值，则不打开窗口：',
    '附加時若視窗數量至少達到此值，則不開啟視窗：')

# --- iTermTipCardViewController.xcstrings ---
T['Shell Integration'] = ('Shell 集成', 'Shell 整合')

ZH_LOCS = ['zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']

total_added = 0
for path in FILES:
    d = json.load(open(path, encoding='utf-8'))
    strings = d.get('strings', {})
    added = 0
    skipped = []
    for key, entry in strings.items():
        if entry.get('shouldTranslate') is False:
            skipped.append((key, 'shouldTranslate=false'))
            continue
        locs = entry.get('localizations', {})
        en_unit = locs.get('en', {}).get('stringUnit', {})
        en_val = en_unit.get('value')
        if en_val is None:
            skipped.append((key, 'no en value'))
            continue
        if en_val not in T:
            skipped.append((key, f'no translation for en={en_val!r}'))
            continue
        simp, trad = T[en_val]
        vals = {
            'zh_CN': simp, 'zh-Hans': simp, 'zh-Hans-CN': simp,
            'zh_TW': trad, 'zh-Hant': trad, 'zh-Hant-TW': trad,
        }
        for loc, val in vals.items():
            if loc not in locs:
                locs[loc] = {'stringUnit': {'state': 'translated', 'value': val}}
                added += 1
            elif locs[loc].get('stringUnit', {}).get('value') != val:
                # update existing if value differs
                locs[loc]['stringUnit'] = {'state': 'translated', 'value': val}
                added += 1
        entry['localizations'] = locs
        strings[key] = entry
    d['strings'] = strings
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False, indent=2, separators=(',', ' : '))
        f.write('\n')
    print(f'{path}: {added} localizations added')
    for k, reason in skipped:
        print(f'  skipped {k!r}: {reason}')
    total_added += added

print(f'All xcstrings adapted: {total_added} localizations added')
