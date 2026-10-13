# -*- coding: utf-8 -*-
"""Inject tmux.strings into iTerm2.xcodeproj/project.pbxproj.

Pattern follows tips_pbxproj.py (Tips is the predecessor, just injected before this):
  - 8 PBXFileReference entries (one per locale)
  - 1 PBXVariantGroup
  - 4 PBXBuildFile definitions (A/B/C/D, one per target)
  - 1 group child reference
  - 4 BF entries in Resources phases (A->target1, B->target2, C->target3, D->main app)

Predecessor for all definitions: Tips.strings.
VG = A6B1F4212F988A06007CAA0B
FR = A6B1F422..4292F988A06007CAA0B
BF = A6B1F42A/B/C/D2F988A06007CAA0B
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'tmux'
VG = 'A6B1F4212F988A06007CAA0B'
FR = {loc: f'A6B1F4{LOCALES.index(loc)+22:02d}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F42A2F988A06007CAA0B', 'A6B1F42B2F988A06007CAA0B',
      'A6B1F42C2F988A06007CAA0B', 'A6B1F42D2F988A06007CAA0B']

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
# 1. PBXBuildFile definitions (after Tips BF-D definition)
# ============================================================================
TIPS_BF_D = (f'{T*2}A6B1F41D2F988A06007CAA0B /* Tips.strings in Resources */ '
             f'= {{isa = PBXBuildFile; fileRef = A6B1F4112F988A06007CAA0B /* Tips.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(TIPS_BF_D, bf_new, 'tmux PBXBuildFile defs')

# ============================================================================
# 2. PBXFileReference entries (after Tips zh-Hant-TW FR)
# ============================================================================
TIPS_FR_LAST = (f'{T*2}A6B1F4192F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
                f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
                f'path = "zh-Hant-TW.lproj/Tips.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(TIPS_FR_LAST, fr_new, 'tmux PBXFileReference defs')

# ============================================================================
# 3. PBXVariantGroup definition (after Tips VG end)
# ============================================================================
TIPS_VG_END = f'{T*3}name = Tips.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(TIPS_VG_END, vg_def, 'tmux PBXVariantGroup def')

# ============================================================================
# 4. Group child (after iTermTmuxClientTracker.swift in tmux group)
# ============================================================================
GRP_ANCHOR = f'{T*4}A6B6C93F2F3BD942006AB7BE /* iTermTmuxClientTracker.swift */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'tmux group child')

# ============================================================================
# 5. BF in 4 Resources phases (A->target1, B->target2, C->target3, D->main app)
# ============================================================================
TIPS_A_RES = f'{T*4}A6B1F41A2F988A06007CAA0B /* Tips.strings in Resources */,\n'
TIPS_B_RES = f'{T*4}A6B1F41B2F988A06007CAA0B /* Tips.strings in Resources */,\n'
TIPS_C_RES = f'{T*4}A6B1F41C2F988A06007CAA0B /* Tips.strings in Resources */,\n'
TIPS_D_RES = f'{T*4}A6B1F41D2F988A06007CAA0B /* Tips.strings in Resources */,\n'

TMUX_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
TMUX_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
TMUX_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
TMUX_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(TIPS_A_RES, TMUX_A, 'tmux BF-A in target1')
inject_after(TIPS_B_RES, TMUX_B, 'tmux BF-B in target2')
inject_after(TIPS_C_RES, TMUX_C, 'tmux BF-C in target3')
inject_after(TIPS_D_RES, TMUX_D, 'tmux BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All tmux pbxproj injections OK')
