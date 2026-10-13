# -*- coding: utf-8 -*-
"""Inject only the missing PBXFileReference entries for System.strings and
StatusWindowsViews.strings. The previous run of system_statuswindows_pbxproj.py
succeeded for BF/VG/group/Resources but failed on FR because of missing quotes
on hyphenated locale names. This patches just the 16 FR entries."""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

def q(loc):
    return f'"{loc}"' if '-' in loc else loc

TABLES = [
    {
        'name': 'StatusWindowsViews',
        'fr': {loc: f'A6B1F1{LOCALES.index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES},
        'anchor': 'A6B1F0092F988A06007CAA0B /* zh-Hant-TW */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; path = "zh-Hant-TW.lproj/SSH.strings"; sourceTree = "<group>"; };\n',
    },
    {
        'name': 'System',
        'fr': {loc: f'A6B1F2{LOCALES.index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES},
        'anchor': None,  # set dynamically to StatusWindowsViews zh-Hant-TW FR
    },
]

prev_anchor = TABLES[0]['anchor']
for t in TABLES:
    name = t['name']; FR = t['fr']
    anchor = t['anchor'] or prev_anchor
    fr_new = ''
    for loc in LOCALES:
        fr_new += f'\t\t{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {q(loc)}; path = {q(loc + ".lproj/" + name + ".strings")}; sourceTree = "<group>"; }};\n'
    c = s.count(anchor)
    if c != 1:
        errs.append(f'{name} FR anchor count {c} (expected 1)');
        # still update prev_anchor for next table
        prev_anchor = FR['zh-Hant-TW'] + f' /* zh-Hant-TW */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; path = "zh-Hant-TW.lproj/{name}.strings"; sourceTree = "<group>"; }};\n'
        continue
    s = s.replace(anchor, anchor + fr_new, 1)
    prev_anchor = FR['zh-Hant-TW'] + f' /* zh-Hant-TW */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; path = "zh-Hant-TW.lproj/{name}.strings"; sourceTree = "<group>"; }};\n'
    print(f'{name}: injected 8 FR entries')

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)

# Verify all 16 FR IDs now exist
missing = []
for t in TABLES:
    for loc in LOCALES:
        if t['fr'][loc] not in s:
            missing.append(f'{t["name"]}/{loc}')
if missing:
    print('MISSING after injection:')
    for m in missing: print(' ', m)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All 16 FR entries injected and verified')
