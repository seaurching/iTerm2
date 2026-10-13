# -*- coding: utf-8 -*-
"""Inject Workgroups.strings into iTerm2.xcodeproj/project.pbxproj.

Predecessor for all definitions: Triggers.strings (last injected directory).
  VG = A6B1F4812F988A06007CAA0B
  FR = A6B1F48{2..9}2F988A06007CAA0B
  BF = A6B1F48A/B/C/D2F988A06007CAA0B

Group child anchor: WorkgroupAutoRequestReviewToolbarItem.swift (last file in
Workgroups source group).
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'Workgroups'
VG = 'A6B1F4A12F988A06007CAA0B'
FR = {loc: f'A6B1F4A{LOCALES.index(loc)+2}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F4AA2F988A06007CAA0B', 'A6B1F4AB2F988A06007CAA0B',
      'A6B1F4AC2F988A06007CAA0B', 'A6B1F4AD2F988A06007CAA0B']

def q(loc):
    return f'"{loc}"' if '-' in loc else loc

def check_replace(old, new, label, expected=1):
    global s
    c = s.count(old)
    if c != expected:
        errs.append(f'{label}: count {c} (expected {expected})')
        return False
    s = s.replace(old, new)
    return True

def inject_after(anchor, new_text, label, expected=1):
    return check_replace(anchor, anchor + new_text, label, expected)

# ============================================================================
# 1. PBXBuildFile definitions (after Triggers BF-D definition)
# ============================================================================
PREV_BF_D = (f'{T*2}A6B1F48D2F988A06007CAA0B /* Triggers.strings in Resources */ '
             f'= {{isa = PBXBuildFile; fileRef = A6B1F4812F988A06007CAA0B /* Triggers.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(PREV_BF_D, bf_new, 'Workgroups PBXBuildFile defs')

# ============================================================================
# 2. PBXFileReference entries (after Triggers zh-Hant-TW FR)
# ============================================================================
PREV_FR_LAST = (f'{T*2}A6B1F4892F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
                f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
                f'path = "zh-Hant-TW.lproj/Triggers.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(PREV_FR_LAST, fr_new, 'Workgroups PBXFileReference defs')

# ============================================================================
# 3. PBXVariantGroup definition (after Triggers VG end)
# ============================================================================
PREV_VG_END = f'{T*3}name = Triggers.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(PREV_VG_END, vg_def, 'Workgroups PBXVariantGroup def')

# ============================================================================
# 4. Group child (after WorkgroupAutoRequestReviewToolbarItem.swift in Workgroups group)
# ============================================================================
GRP_ANCHOR = f'{T*4}84897A6E8B159D2C3608965D /* WorkgroupAutoRequestReviewToolbarItem.swift */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'Workgroups group child')

# ============================================================================
# 5. BF in 4 Resources phases (A->target1, B->target2, C->target3, D->main app)
# ============================================================================
PREV_A_RES = f'{T*4}A6B1F48A2F988A06007CAA0B /* Triggers.strings in Resources */,\n'
PREV_B_RES = f'{T*4}A6B1F48B2F988A06007CAA0B /* Triggers.strings in Resources */,\n'
PREV_C_RES = f'{T*4}A6B1F48C2F988A06007CAA0B /* Triggers.strings in Resources */,\n'
PREV_D_RES = f'{T*4}A6B1F48D2F988A06007CAA0B /* Triggers.strings in Resources */,\n'

NEW_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
NEW_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
NEW_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
NEW_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(PREV_A_RES, NEW_A, 'Workgroups BF-A in target1')
inject_after(PREV_B_RES, NEW_B, 'Workgroups BF-B in target2')
inject_after(PREV_C_RES, NEW_C, 'Workgroups BF-C in target3')
inject_after(PREV_D_RES, NEW_D, 'Workgroups BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All Workgroups pbxproj injections OK')