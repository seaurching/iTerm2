# -*- coding: utf-8 -*-
"""Inject TryingTooHard.strings into iTerm2.xcodeproj/project.pbxproj.

Predecessor for all definitions: TouchBar.strings (last injected directory).
  VG = A6B1F4512F988A06007CAA0B
  FR = A6B1F452..4592F988A06007CAA0B
  BF = A6B1F45A/B/C/D2F988A06007CAA0B

Group child anchor: iTermWindowOcclusionChangeMonitor.m (last file in
TryingTooHard source group).
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'TryingTooHard'
VG = 'A6B1F4512F988A06007CAA0B'
FR = {loc: f'A6B1F4{LOCALES.index(loc)+52:02d}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F45A2F988A06007CAA0B', 'A6B1F45B2F988A06007CAA0B',
      'A6B1F45C2F988A06007CAA0B', 'A6B1F45D2F988A06007CAA0B']

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
# 1. PBXBuildFile definitions (after TouchBar BF-D definition)
# ============================================================================
TB_BF_D = (f'{T*2}A6B1F44D2F988A06007CAA0B /* TouchBar.strings in Resources */ '
           f'= {{isa = PBXBuildFile; fileRef = A6B1F4412F988A06007CAA0B /* TouchBar.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(TB_BF_D, bf_new, 'TryingTooHard PBXBuildFile defs')

# ============================================================================
# 2. PBXFileReference entries (after TouchBar zh-Hant-TW FR)
# ============================================================================
TB_FR_LAST = (f'{T*2}A6B1F4492F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
              f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
              f'path = "zh-Hant-TW.lproj/TouchBar.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(TB_FR_LAST, fr_new, 'TryingTooHard PBXFileReference defs')

# ============================================================================
# 3. PBXVariantGroup definition (after TouchBar VG end)
# ============================================================================
TB_VG_END = f'{T*3}name = TouchBar.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(TB_VG_END, vg_def, 'TryingTooHard PBXVariantGroup def')

# ============================================================================
# 4. Group child (after iTermWindowOcclusionChangeMonitor.m in TryingTooHard group)
# ============================================================================
GRP_ANCHOR = f'{T*4}A6936B481D2D756200521B04 /* iTermWindowOcclusionChangeMonitor.m */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'TryingTooHard group child')

# ============================================================================
# 5. BF in 4 Resources phases (A->target1, B->target2, C->target3, D->main app)
# ============================================================================
TB_A_RES = f'{T*4}A6B1F44A2F988A06007CAA0B /* TouchBar.strings in Resources */,\n'
TB_B_RES = f'{T*4}A6B1F44B2F988A06007CAA0B /* TouchBar.strings in Resources */,\n'
TB_C_RES = f'{T*4}A6B1F44C2F988A06007CAA0B /* TouchBar.strings in Resources */,\n'
TB_D_RES = f'{T*4}A6B1F44D2F988A06007CAA0B /* TouchBar.strings in Resources */,\n'

TTH_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
TTH_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
TTH_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
TTH_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(TB_A_RES, TTH_A, 'TryingTooHard BF-A in target1')
inject_after(TB_B_RES, TTH_B, 'TryingTooHard BF-B in target2')
inject_after(TB_C_RES, TTH_C, 'TryingTooHard BF-C in target3')
inject_after(TB_D_RES, TTH_D, 'TryingTooHard BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All TryingTooHard pbxproj injections OK')
