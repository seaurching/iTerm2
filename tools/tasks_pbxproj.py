# -*- coding: utf-8 -*-
"""Fix StatusWindowsViews/System Resources phase placement (misplaced by
previous run) and inject Tasks.strings with correct 4-phase distribution.

Background: each variant group has 4 BF entries (A/B/C/D), one per target:
  A -> target1 phase (after SSH-A, line ~19271)
  B -> target2 phase (after SSH-B, line ~19365)
  C -> target3 phase (after SSH-C, line ~20173)
  D -> main app phase (after SSH-D, line ~21163)
The previous SWV/System run dumped all 4 into the main app phase. This script
moves A/B/C to their correct phases and injects Tasks following the SSH pattern.
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'

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

def remove(old, label, expected=1):
    return check_replace(old, '', label, expected)

# ============================================================================
# PART 1: Fix StatusWindowsViews/System Resources phase placement
# ============================================================================

# 1a. Remove the 6 misplaced entries (SWV-C, System-C, SWV-B, System-B, SWV-A, System-A)
#     from the main app phase (the contiguous block after System-D).
REMOVE_BLOCK = (
    f'{T*4}A6B1F10C2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
    f'{T*4}A6B1F20C2F988A06007CAA0B /* System.strings in Resources */,\n'
    f'{T*4}A6B1F10B2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
    f'{T*4}A6B1F20B2F988A06007CAA0B /* System.strings in Resources */,\n'
    f'{T*4}A6B1F10A2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
    f'{T*4}A6B1F20A2F988A06007CAA0B /* System.strings in Resources */,\n'
)
remove(REMOVE_BLOCK, 'remove misplaced SWV/System block', 1)

# 1b. Add SWV-A + System-A to target1 phase (after SSH-A)
SSH_A_RES = f'{T*4}A6B1F00A2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_B_RES = f'{T*4}A6B1F00B2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_C_RES = f'{T*4}A6B1F00C2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_D_RES = f'{T*4}A6B1F00D2F988A06007CAA0B /* SSH.strings in Resources */,\n'

SWV_A = f'{T*4}A6B1F10A2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
SWV_B = f'{T*4}A6B1F10B2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
SWV_C = f'{T*4}A6B1F10C2F988A06007CAA0B /* StatusWindowsViews.strings in Resources */,\n'
SYS_A = f'{T*4}A6B1F20A2F988A06007CAA0B /* System.strings in Resources */,\n'
SYS_B = f'{T*4}A6B1F20B2F988A06007CAA0B /* System.strings in Resources */,\n'
SYS_C = f'{T*4}A6B1F20C2F988A06007CAA0B /* System.strings in Resources */,\n'

inject_after(SSH_A_RES, SWV_A + SYS_A, 'add SWV-A/System-A to target1')
inject_after(SSH_B_RES, SWV_B + SYS_B, 'add SWV-B/System-B to target2')
inject_after(SSH_C_RES, SWV_C + SYS_C, 'add SWV-C/System-C to target3')

# ============================================================================
# PART 2: Inject Tasks.strings
# ============================================================================

VG = 'A6B1F3012F988A06007CAA0B'
FR = {loc: f'A6B1F3{LOCALES.index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F30A2F988A06007CAA0B', 'A6B1F30B2F988A06007CAA0B',
      'A6B1F30C2F988A06007CAA0B', 'A6B1F30D2F988A06007CAA0B']
NAME = 'Tasks'

# 2a. PBXBuildFile definitions (after System BF-D definition)
SYS_BF_D = (f'{T*2}A6B1F20D2F988A06007CAA0B /* System.strings in Resources */ '
            f'= {{isa = PBXBuildFile; fileRef = A6B1F2012F988A06007CAA0B /* System.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(SYS_BF_D, bf_new, 'Tasks PBXBuildFile defs')

# 2b. PBXFileReference entries (after System zh-Hant-TW FR)
SYS_FR_LAST = (f'{T*2}A6B1F2092F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
               f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
               f'path = "zh-Hant-TW.lproj/System.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(SYS_FR_LAST, fr_new, 'Tasks PBXFileReference defs')

# 2c. PBXVariantGroup definition (after System VG end)
SYS_VG_END = f'{T*3}name = System.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(SYS_VG_END, vg_def, 'Tasks PBXVariantGroup def')

# 2d. Group child (after WinSizeController.swift in Tasks group)
GRP_ANCHOR = f'{T*4}A616CF102841AA1600EF82D0 /* WinSizeController.swift */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'Tasks group child')

# 2e. BF in 4 phases (A->target1, B->target2, C->target3, D->main app)
TASKS_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
TASKS_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
TASKS_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
TASKS_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(SSH_A_RES, TASKS_A, 'Tasks BF-A in target1')
inject_after(SSH_B_RES, TASKS_B, 'Tasks BF-B in target2')
inject_after(SSH_C_RES, TASKS_C, 'Tasks BF-C in target3')
inject_after(SSH_D_RES, TASKS_D, 'Tasks BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All injections OK')
