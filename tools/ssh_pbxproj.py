# -*- coding: utf-8 -*-
"""Inject SSH.strings PBXVariantGroup into project.pbxproj (code-only table)."""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

VG = 'A6B1F0012F988A06007CAA0B'
FR = {
    'Base':       'A6B1F0022F988A06007CAA0B',
    'en':         'A6B1F0032F988A06007CAA0B',
    'zh_CN':      'A6B1F0042F988A06007CAA0B',
    'zh_TW':      'A6B1F0052F988A06007CAA0B',
    'zh-Hans':    'A6B1F0062F988A06007CAA0B',
    'zh-Hans-CN': 'A6B1F0072F988A06007CAA0B',
    'zh-Hant':    'A6B1F0082F988A06007CAA0B',
    'zh-Hant-TW': 'A6B1F0092F988A06007CAA0B',
}
ORDER = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
BF = ['A6B1F00A2F988A06007CAA0B', 'A6B1F00B2F988A06007CAA0B',
      'A6B1F00C2F988A06007CAA0B', 'A6B1F00D2F988A06007CAA0B']

def inject_after(anchor, new_text, label, count=1):
    global s
    c = s.count(anchor)
    if c != count:
        errs.append(f'{label}: anchor count {c} (expected {count})'); return False
    s = s.replace(anchor, anchor + new_text, 1)
    return True

# 1. PBXBuildFile entries — after last StateRestoration.strings build file (A653F70C)
bf_anchor = '\t\tA653F70C2F988A06007CAA0B /* StateRestoration.strings in Resources */ = {isa = PBXBuildFile; fileRef = A653F7002F988A06007CAA0B /* StateRestoration.strings */; };\n'
bf_new = ''
for bid in BF:
    bf_new += f'\t\t{bid} /* SSH.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* SSH.strings */; }};\n'
inject_after(bf_anchor, bf_new, 'PBXBuildFile entries')

# 2. PBXFileReference entries — after last StateRestoration.strings file ref (zh-Hant-TW)
fr_anchor = '\t\tA653F7082F988A06007CAA0B /* zh-Hant-TW */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = zh-Hant-TW; path = zh-Hant-TW.lproj/StateRestoration.strings; sourceTree = "<group>"; };\n'
fr_new = ''
for loc in ORDER:
    fr_new += f'\t\t{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {loc}; path = {loc}.lproj/SSH.strings; sourceTree = "<group>"; }};\n'
inject_after(fr_anchor, fr_new, 'PBXFileReference entries')

# 3. PBXVariantGroup definition — after StateRestoration.strings variant group definition
vg_anchor = '\t\t\tname = StateRestoration.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
vg_def = f'\t\t{VG} /* SSH.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
for loc in ORDER:
    vg_def += f'\t\t\t\t{FR[loc]} /* {loc} */,\n'
vg_def += '\t\t\t);\n\t\t\tname = SSH.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
inject_after(vg_anchor, vg_def, 'PBXVariantGroup definition')

# 4. Add variant group to SSH group children — after Conductor+IT2.swift
grp_anchor = '\t\t\t\tA1B19743799E1009AC26E7F4 /* Conductor+IT2.swift */,\n'
grp_new = f'\t\t\t\t{VG} /* SSH.strings */,\n'
inject_after(grp_anchor, grp_new, 'SSH group child')

# 5. Add 4 build files to the 4 Resources phases — after StateRestoration.strings in each phase
sr_bf = ['A653F7092F988A06007CAA0B', 'A653F70A2F988A06007CAA0B', 'A653F70B2F988A06007CAA0B', 'A653F70C2F988A06007CAA0B']
for i, sid in enumerate(sr_bf):
    a = f'\t\t\t\t{sid} /* StateRestoration.strings in Resources */,\n'
    n = f'\t\t\t\t{BF[i]} /* SSH.strings in Resources */,\n'
    inject_after(a, n, f'Resources phase {i+1}')

open(PBX, 'w', encoding='utf-8').write(s)
if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print('All SSH injections OK')
