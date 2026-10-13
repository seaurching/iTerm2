# -*- coding: utf-8 -*-
"""Inject TerminalView.strings into iTerm2.xcodeproj/project.pbxproj.

Pattern follows tasks_pbxproj.py / SSH convention:
  - 8 PBXFileReference entries (one per locale)
  - 1 PBXVariantGroup
  - 4 PBXBuildFile definitions (A/B/C/D, one per target)
  - 1 group child reference
  - 4 BF entries in Resources phases (A->target1, B->target2, C->target3, D->main app)

Predecessor for all definitions: Tasks.strings (just injected before this).
VG = A6B1F4012F988A06007CAA0B
FR = A6B1F402..4092F988A06007CAA0B
BF = A6B1F40A/B/C/D2F988A06007CAA0B
"""
import sys

PBX = 'iTerm2.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'TerminalView'
VG = 'A6B1F4012F988A06007CAA0B'
FR = {loc: f'A6B1F4{LOCALES.index(loc)+2:02d}2F988A06007CAA0B' for loc in LOCALES}
BF = ['A6B1F40A2F988A06007CAA0B', 'A6B1F40B2F988A06007CAA0B',
      'A6B1F40C2F988A06007CAA0B', 'A6B1F40D2F988A06007CAA0B']

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
# 1. PBXBuildFile definitions (after Tasks BF-D definition)
# ============================================================================
TASKS_BF_D = (f'{T*2}A6B1F30D2F988A06007CAA0B /* Tasks.strings in Resources */ '
              f'= {{isa = PBXBuildFile; fileRef = A6B1F3012F988A06007CAA0B /* Tasks.strings */; }};\n')
bf_new = ''.join(
    f'{T*2}{bid} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
    for bid in BF)
inject_after(TASKS_BF_D, bf_new, 'TerminalView PBXBuildFile defs')

# ============================================================================
# 2. PBXFileReference entries (after Tasks zh-Hant-TW FR)
# ============================================================================
TASKS_FR_LAST = (f'{T*2}A6B1F3092F988A06007CAA0B /* zh-Hant-TW */ = {{isa = PBXFileReference; '
                 f'lastKnownFileType = text.plist.strings; name = "zh-Hant-TW"; '
                 f'path = "zh-Hant-TW.lproj/Tasks.strings"; sourceTree = "<group>"; }};\n')
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(TASKS_FR_LAST, fr_new, 'TerminalView PBXFileReference defs')

# ============================================================================
# 3. PBXVariantGroup definition (after Tasks VG end)
# ============================================================================
TASKS_VG_END = f'{T*3}name = Tasks.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(TASKS_VG_END, vg_def, 'TerminalView PBXVariantGroup def')

# ============================================================================
# 4. Group child (after iTermGutterPanelWidths.swift in TerminalView group)
# ============================================================================
GRP_ANCHOR = f'{T*4}F98ADE6D889E9911953ECB78 /* iTermGutterPanelWidths.swift */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'TerminalView group child')

# ============================================================================
# 5. BF in 4 Resources phases (A->target1, B->target2, C->target3, D->main app)
# ============================================================================
SSH_A_RES = f'{T*4}A6B1F00A2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_B_RES = f'{T*4}A6B1F00B2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_C_RES = f'{T*4}A6B1F00C2F988A06007CAA0B /* SSH.strings in Resources */,\n'
SSH_D_RES = f'{T*4}A6B1F00D2F988A06007CAA0B /* SSH.strings in Resources */,\n'

TV_A = f'{T*4}{BF[0]} /* {NAME}.strings in Resources */,\n'
TV_B = f'{T*4}{BF[1]} /* {NAME}.strings in Resources */,\n'
TV_C = f'{T*4}{BF[2]} /* {NAME}.strings in Resources */,\n'
TV_D = f'{T*4}{BF[3]} /* {NAME}.strings in Resources */,\n'
inject_after(SSH_A_RES, TV_A, 'TerminalView BF-A in target1')
inject_after(SSH_B_RES, TV_B, 'TerminalView BF-B in target2')
inject_after(SSH_C_RES, TV_C, 'TerminalView BF-C in target3')
inject_after(SSH_D_RES, TV_D, 'TerminalView BF-D in main app')

# ============================================================================
# Write & verify
# ============================================================================
if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All TerminalView pbxproj injections OK')
