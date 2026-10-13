# -*- coding: utf-8 -*-
"""Inject Snippets.strings PBXVariantGroup into project.pbxproj (code-only table)."""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

# IDs (24-char hex, uppercase)
VG = 'A6B150012F985560006C7417'  # variant group for Snippets.strings
FR = {
    'Base':       'A6B150022F985560006C7417',
    'en':         'A6B150032F985560006C7417',
    'zh_CN':      'A6B150042F985560006C7417',
    'zh_TW':      'A6B150052F985560006C7417',
    'zh-Hans':    'A6B150062F985560006C7417',
    'zh-Hans-CN': 'A6B150072F985560006C7417',
    'zh-Hant':    'A6B150082F985560006C7417',
    'zh-Hant-TW': 'A6B150092F985560006C7417',
}
ORDER = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
BF = [  # 4 build file IDs (one per Resources phase / target)
    'A6B1500A2F985560006C7417',
    'A6B1500B2F985560006C7417',
    'A6B1500C2F985560006C7417',
    'A6B1500D2F985560006C7417',
]

def replace_exact(old, new, label, count=1):
    global s
    c = s.count(old)
    if c != count:
        errs.append(f'{label}: count {c} (expected {count})'); return False
    s = s.replace(old, new)
    return True

def inject_after(anchor, new_text, label, count=1):
    global s
    c = s.count(anchor)
    if c != count:
        errs.append(f'{label}: anchor count {c} (expected {count})'); return False
    s = s.replace(anchor, anchor + new_text, 1)
    return True

# 1. Add 4 PBXBuildFile entries — anchor after ShellIntegration.strings build files (line ~1099-1102 block)
# Build files section: anchor on the last ShellIntegration.strings build file line
bf_anchor = '\t\tBACFA4020B344917DC5FF578 /* ShellIntegration.strings in Resources */ = {isa = PBXBuildFile; fileRef = 0C1703221C4C755711189668 /* ShellIntegration.strings */; };\n'
bf_new = ''
for bid in BF:
    bf_new += f'\t\t{bid} /* Snippets.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* Snippets.strings */; }};\n'
inject_after(bf_anchor, bf_new, 'PBXBuildFile entries')

# 2. Add 8 PBXFileReference entries — anchor after last ShellIntegration.strings file ref (line ~10655)
fr_anchor = '\t\t9B818665FB1C6885166AF7E1 /* zh-Hant-TW */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = zh-Hant-TW; path = zh-Hant-TW.lproj/ShellIntegration.strings; sourceTree = "<group>"; };\n'
fr_new = ''
for loc in ORDER:
    fr_new += f'\t\t{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {loc}; path = {loc}.lproj/Snippets.strings; sourceTree = "<group>"; }};\n'
inject_after(fr_anchor, fr_new, 'PBXFileReference entries')

# 3. Add PBXVariantGroup definition — anchor after ShellIntegration.strings variant group definition
vg_anchor = '\t\t\tname = ShellIntegration.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
vg_def = f'\t\t{VG} /* Snippets.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n'
for loc in ORDER:
    vg_def += f'\t\t\t\t{FR[loc]} /* {loc} */,\n'
vg_def += '\t\t\t);\n\t\t\tname = Snippets.strings;\n\t\t\tsourceTree = "<group>";\n\t\t};\n'
inject_after(vg_anchor, vg_def, 'PBXVariantGroup definition')

# 4. Add variant group to Snippets group children — anchor after iTermSnippetsModel.m in the group
grp_anchor = '\t\t\t\tA6EC936E24E787BA00EEADEF /* iTermSnippetsModel.m */,\n'
grp_new = f'\t\t\t\t{VG} /* Snippets.strings */,\n'
inject_after(grp_anchor, grp_new, 'Snippets group child')

# 5. Add 4 build files to the 4 Resources phases — after ShellIntegrationInstaller.strings in each phase
# Each phase has a distinct ShellIntegrationInstaller.strings build file ID; anchor on each
si_inst_bf = [
    '513DD3A5757BD126AD6EF713',  # phase 1
    '82E215C0F48915AFE7E0B881',  # phase 2
    'C7DAC94B057A36305BE128BD',  # phase 3
    '5BB5D4CC48CE77EBFB337207',  # phase 4
]
for i, sid in enumerate(si_inst_bf):
    a = f'\t\t\t\t{sid} /* ShellIntegrationInstaller.strings in Resources */,\n'
    n = f'\t\t\t\t{BF[i]} /* Snippets.strings in Resources */,\n'
    inject_after(a, n, f'Resources phase {i+1}')

open(PBX, 'w', encoding='utf-8').write(s)
if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print('All Snippets injections OK')
