# -*- coding: utf-8 -*-
"""Inject StateRestoration.strings PBXVariantGroup into project.pbxproj (code-only table)."""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

VG = 'A653F7002F988A06007CAA0B'  # variant group for StateRestoration.strings
FR = {
    'Base':       'A653F7012F988A06007CAA0B',
    'en':         'A653F7022F988A06007CAA0B',
    'zh_CN':      'A653F7032F988A06007CAA0B',
    'zh_TW':      'A653F7042F988A06007CAA0B',
    'zh-Hans':    'A653F7052F988A06007CAA0B',
    'zh-Hans-CN': 'A653F7062F988A06007CAA0B',
    'zh-Hant':    'A653F7072F988A06007CAA0B',
    'zh-Hant-TW': 'A653F7082F988A06007CAA0B',
}
ORDER = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
BF = [
    'A653F7092F988A06007CAA0B',
    'A653F70A2F988A06007CAA0B',
    'A653F70B2F988A06007CAA0B',
    'A653F70C2F988A06007CAA0B',
]

def inject_after(anchor, new_text, label, count=1):
    global s
    c = s.count(anchor)
    if c != count:
        errs.append(f'{label}: anchor count {c} (expected {count})'); return False
    s = s.replace(anchor, anchor + new_text, 1)
    return True

# 1. PBXBuildFile entries — after last Snippets.strings build file
bf_anchor = '\t\tA6B1500D2F985560006C7417 /* Snippets.strings in Resources */ = {isa = PBXBuildFile; fileRef = A6B150012F985560006C7417 /* Snippets.strings */; };\n'
bf_new = ''
for bid in BF:
    bf_new += f'\t\t{bid} /* StateRestoration.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* StateRestoration.strings */; }};\n'
inject_after(bf_anchor, bf_new, 'PBXBuildFile entries')

# 2. PBXFileReference entries — after last Snippets.strings file ref (zh-Hant-TW)
fr_anchor = '\t\tA6B150092F985560006C7417 /* zh-Hant-TW */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = zh-Hant-TW; path = zh-Hant-TW.lproj/Snippets.strings; sourceTree = "<group>"; };\n'
fr_new = ''
for loc in ORDER:
    fr_new += f'\t\t{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {loc}; path = {loc}.lproj/StateRestoration.strings; sourceTree = "<group>"; }};\n'
inject_after(fr_anchor, fr_new, 'PBXFileReference entries')

# 3. PBXVariantGroup definition — after Snippets.strings variant group definition
vg_anchor = '\t\t\tname = Snippets.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
vg_def = f'\t\t{VG} /* StateRestoration.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
for loc in ORDER:
    vg_def += f'\t\t\t\t{FR[loc]} /* {loc} */,\n'
vg_def += '\t\t\t);\n\t\t\tname = StateRestoration.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
inject_after(vg_anchor, vg_def, 'PBXVariantGroup definition')

# 4. Add variant group to StateRestoration group children — after iTermRestorableStateSQLite.m
grp_anchor = '\t\t\t\tA653F6A724D00FFE0062377E /* iTermRestorableStateSQLite.m */,\n'
grp_new = f'\t\t\t\t{VG} /* StateRestoration.strings */,\n'
inject_after(grp_anchor, grp_new, 'StateRestoration group child')

# 5. Add 4 build files to the 4 Resources phases — after Snippets.strings in each phase
snip_bf = ['A6B1500A2F985560006C7417', 'A6B1500B2F985560006C7417', 'A6B1500C2F985560006C7417', 'A6B1500D2F985560006C7417']
for i, sid in enumerate(snip_bf):
    a = f'\t\t\t\t{sid} /* Snippets.strings in Resources */,\n'
    n = f'\t\t\t\t{BF[i]} /* StateRestoration.strings in Resources */,\n'
    inject_after(a, n, f'Resources phase {i+1}')

open(PBX, 'w', encoding='utf-8').write(s)
if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print('All StateRestoration injections OK')
