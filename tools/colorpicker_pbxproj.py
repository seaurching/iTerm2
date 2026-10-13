# -*- coding: utf-8 -*-
"""Inject ColorPicker.strings into ColorPicker.xcodeproj/project.pbxproj.
"""
import sys

PBX = 'ColorPicker/ColorPicker.xcodeproj/project.pbxproj'
s = open(PBX, encoding='utf-8').read()
errs = []

LOCALES = ['Base', 'en', 'zh_CN', 'zh_TW', 'zh-Hans', 'zh-Hans-CN', 'zh-Hant', 'zh-Hant-TW']
T = '\t'
NAME = 'ColorPicker'
VG = 'A6CP0001000000000000CP01'
FR = {loc: f'A6CP00{LOCALES.index(loc)+10:02d}000000000000CP0{LOCALES.index(loc)+1}' for loc in LOCALES}
BF = 'A6CP0099000000000000CP09'

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

# 1. PBXBuildFile definition (after colors.txt BF)
PREV_BF = f'{T*2}A6184F481BA9D75B0088EF3C /* colors.txt in Resources */ = {{isa = PBXBuildFile; fileRef = A6184F471BA9D75B0088EF3C /* colors.txt */; }};\n'
bf_new = f'{T*2}{BF} /* {NAME}.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {VG} /* {NAME}.strings */; }};\n'
inject_after(PREV_BF, bf_new, 'ColorPicker PBXBuildFile def')

# 2. PBXFileReference entries (after CPKLogging.h FR - no fileEncoding)
PREV_FR = f'{T*2}A6D398592BD9A4A600C4C1AD /* CPKLogging.h */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = CPKLogging.h; sourceTree = "<group>"; }};\n'
fr_new = ''.join(
    f'{T*2}{FR[loc]} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; '
    f'name = {q(loc)}; path = {q(loc + ".lproj/" + NAME + ".strings")}; sourceTree = "<group>"; }};\n'
    for loc in LOCALES)
inject_after(PREV_FR, fr_new, 'ColorPicker PBXFileReference defs')

# 3. PBXVariantGroup definition (after MainMenu.xib VG end)
PREV_VG_END = f'{T*3}name = MainMenu.xib;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n'
vg_def = (f'{T*2}{VG} /* {NAME}.strings */ = {{\n{T*3}isa = PBXVariantGroup;\n{T*3}children = (\n'
          + ''.join(f'{T*4}{FR[loc]} /* {loc} */,\n' for loc in LOCALES)
          + f'{T*3});\n{T*3}name = {NAME}.strings;\n{T*3}sourceTree = "<group>";\n{T*2}}};\n')
inject_after(PREV_VG_END, vg_def, 'ColorPicker PBXVariantGroup def')

# 4. Group child (after CPKLogging.h in ColorPicker group)
GRP_ANCHOR = f'{T*4}A6D398592BD9A4A600C4C1AD /* CPKLogging.h */,\n'
inject_after(GRP_ANCHOR, f'{T*4}{VG} /* {NAME}.strings */,\n', 'ColorPicker group child')

# 5. knownRegions update (3-tab indent)
PREV_REGIONS = f'{T*3}knownRegions = (\n{T*4}en,\n{T*4}Base,\n{T*3});\n'
NEW_REGIONS = f'{T*3}knownRegions = (\n{T*4}en,\n{T*4}Base,\n{T*4}zh_CN,\n{T*4}zh_TW,\n{T*4}"zh-Hans",\n{T*4}"zh-Hans-CN",\n{T*4}"zh-Hant",\n{T*4}"zh-Hant-TW",\n{T*3});\n'
check_replace(PREV_REGIONS, NEW_REGIONS, 'ColorPicker knownRegions')

# 6. BF in Resources phase (after colors.txt in Resources)
PREV_RES = f'{T*4}A6184F481BA9D75B0088EF3C /* colors.txt in Resources */,\n'
NEW_RES = f'{T*4}{BF} /* {NAME}.strings in Resources */,\n'
inject_after(PREV_RES, NEW_RES, 'ColorPicker BF in Resources')

if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

open(PBX, 'w', encoding='utf-8').write(s)
print('All ColorPicker pbxproj injections OK')
