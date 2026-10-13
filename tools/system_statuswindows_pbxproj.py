# -*- coding: utf-8 -*-
"""Inject System.strings and StatusWindowsViews.strings PBXVariantGroups into project.pbxproj."""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']

def q(loc):
    """Quote locale name/path if it contains a hyphen (Xcode requirement)."""
    return f'"{loc}"' if '-' in loc else loc

TABLES = [
    {
        'name': 'StatusWindowsViews',
        'vg': 'A6B1F1012F988A06007CAA0B',
        'fr': {loc: f'A6B1F1{["Base","en","zh_CN","zh_TW","zh-Hans","zh-Hans-CN","zh-Hant","zh-Hant-TW"].index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES},
        'bf': ['A6B1F10A2F988A06007CAA0B','A6B1F10B2F988A06007CAA0B','A6B1F10C2F988A06007CAA0B','A6B1F10D2F988A06007CAA0B'],
        'grp_anchor': '\t\t\t\tA6A39EBE24B9A96B00A64433 /* iTermUnobtrusiveMessage.m */,\n',
    },
    {
        'name': 'System',
        'vg': 'A6B1F2012F988A06007CAA0B',
        'fr': {loc: f'A6B1F2{["Base","en","zh_CN","zh_TW","zh-Hans","zh-Hans-CN","zh-Hant","zh-Hant-TW"].index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES},
        'bf': ['A6B1F20A2F988A06007CAA0B','A6B1F20B2F988A06007CAA0B','A6B1F20C2F988A06007CAA0B','A6B1F20D2F988A06007CAA0B'],
        'grp_anchor': '\t\t\t\t3C05599DA2E4F97B75124672 /* iTermOpenDirectory+MainApp.m */,\n',
    },
]

def inject_after(anchor, new_text, label, count=1):
    global s
    c = s.count(anchor)
    if c != count:
        errs.append(f'{label}: anchor count {c} (expected {count})'); return False
    s = s.replace(anchor, anchor + new_text, 1)
    return True

# Anchor: SSH.strings (last injected table) for sequential ordering
SSH_BF_LAST = 'A6B1F00D2F988A06007CAA0B /* SSH.strings in Resources */ = {isa = PBXBuildFile; fileRef = A6B1F0012F988A06007CAA0B /* SSH.strings */; };\n'
SSH_FR_LAST = 'A6B1F0092F988A06007CAA0B /* zh-Hant-TW */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; path = "zh-Hant-TW.lproj/SSH.strings"; sourceTree = "<group>"; };\n'
SSH_VG_END = '\t\t\tname = SSH.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
SSH_RES_LAST = 'A6B1F00D2F988A06007CAA0B /* SSH.strings in Resources */,\n'

prev_bf = SSH_BF_LAST
prev_fr = SSH_FR_LAST
prev_vg = SSH_VG_END
prev_res = [SSH_RES_LAST] * 4

for t in TABLES:
    name = t['name']; VG = t['vg']; FR = t['fr']; BF = t['bf']
    # 1. PBXBuildFile entries
    bf_new = ''
    for bid in BF:
        bf_new += f'\t\t{bid} /* {name}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {name}.strings */; }};\n'
    inject_after(prev_bf, bf_new, f'{name} PBXBuildFile')
    # 2. PBXFileReference entries
    fr_new = ''
    for loc in LOCALES:
        fr_new += f'\t\t{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {q(loc)}; path = {q(loc + ".lproj/" + name + ".strings")}; sourceTree = "<group>"; }};\n'
    inject_after(prev_fr, fr_new, f'{name} PBXFileReference')
    # 3. PBXVariantGroup definition
    vg_def = f'\t\t{VG} /* {name}.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
    for loc in LOCALES:
        vg_def += f'\t\t\t\t{FR[loc]} /* {loc} */,\n'
    vg_def += '\t\t\t);\n\t\t\tname = {name}.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'.replace('{name}', name)
    inject_after(prev_vg, vg_def, f'{name} PBXVariantGroup')
    # 4. Group child
    grp_new = f'\t\t\t\t{VG} /* {name}.strings */,\n'
    inject_after(t['grp_anchor'], grp_new, f'{name} group child')
    # 5. Resources phases
    for i, bid in enumerate(BF):
        a = prev_res[i]
        n = f'\t\t\t\t{bid} /* {name}.strings in Resources */,\n'
        inject_after(a, n, f'{name} Resources phase {i+1}')
    # update prev anchors for next table
    prev_bf = BF[3] + f' /* {name}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {name}.strings */; }};\n'
    prev_fr = FR['zh-Hant-TW'] + f' /* zh-Hant-TW */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; path = "zh-Hant-TW.lproj/{name}.strings"; sourceTree = "<group>"; }};\n'
    prev_vg = f'\t\t\tname = {name}.strings;\n\t\t\tsourceTree = "<group>";\n\t\t}};\n'
    prev_res = [f'{bid} /* {name}.strings in Resources */,\n' for bid in BF]

open(PBX, 'w', encoding='utf-8').write(s)
if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print('All injections OK')
