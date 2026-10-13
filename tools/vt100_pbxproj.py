# -*- coding: utf-8 -*-
"""Inject VT100.strings into iTerm2.xcodeproj/project.pbxproj.

Predecessor for all definitions: TryingTooHard.strings (last injected directory).
  VG = A6B1F4612F988A06007CAA0B
  FR = A6B1F462..4692F988A06007CAA0B
  BF = A6B1F46A/B/C/D2F988A06007CAA0B

Group child anchor: iTermRowContentIdentity.h (last file in VT100 source group).
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'VT100'
VG = 'A6B1F4612F988A06007CAA0B'
FR = {loc: f'A6B1F4{LOCALES.index(loc)+62:02d}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F46A2F988A06007CAA0B', 'A6B1F46B2F988A06007CAA0B',
      'A6B1F46C2F988A06007CAA0B', 'A6B1F46D2F988A06007CAA0B']

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
# 1. PBXBuildFile definitions (after TryingTooHard BF-D definition)
# ============================================================================
PREV_BF_D = (f'{T*2}A6B1F45D2F988A06007CAA0B /* TryingTooHard.strings in Resources */ '
             f'= {{isa = PBXBuildFile; fileRef = A6B1F4512F988A06007CAA0B /* TryingTooHard.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(PREV_BF_D, bf_new, 'VT100 PBXBuildFile defs')

# ============================================================================
# 2. PBXFileReference entries (after TryingTooHard zh-Hant-TW FR)
# ============================================================================
PREV_FR_LAST = (f'{T*2}A6B1F4592F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
                f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
                f'path = "zh-Hant-TW.lproj/TryingTooHard.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(PREV_FR_LAST, fr_new, 'VT100 PBXFileReference defs')

# ============================================================================
# 3. PBXVariantGroup definition (after TryingTooHard VG end)
# ============================================================================
PREV_VG_END = f'{T*3}name = TryingTooHard.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(PREV_VG_END, vg_def, 'VT100 PBXVariantGroup def')

# ============================================================================
# 4. Group child (after iTermRowContentIdentity.h in VT100 group)
# ============================================================================
GRP_ANCHOR = f'{T*4}8363B81B060F3C03B5F2A3BA /* iTermRowContentIdentity.h */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'VT100 group child')

# ============================================================================
# 5. BF in 4 Resources phases (A->target1, B->target2, C->target3, D->main app)
# ============================================================================
PREV_A_RES = f'{T*4}A6B1F45A2F988A06007CAA0B /* TryingTooHard.strings in Resources */,\n'
PREV_B_RES = f'{T*4}A6B1F45B2F988A06007CAA0B /* TryingTooHard.strings in Resources */,\n'
PREV_C_RES = f'{T*4}A6B1F45C2F988A06007CAA0B /* TryingTooHard.strings in Resources */,\n'
PREV_D_RES = f'{T*4}A6B1F45D2F988A06007CAA0B /* TryingTooHard.strings in Resources */,\n'

NEW_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
NEW_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
NEW_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
NEW_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(PREV_A_RES, NEW_A, 'VT100 BF-A in target1')
inject_after(PREV_B_RES, NEW_B, 'VT100 BF-B in target2')
inject_after(PREV_C_RES, NEW_C, 'VT100 BF-C in target3')
inject_after(PREV_D_RES, NEW_D, 'VT100 BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All VT100 pbxproj injections OK')
