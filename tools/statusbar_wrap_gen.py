# -*- coding: utf-8 -*-
"""Wrap StatusBar .m files (4 files, 20 sites) and append 14 new keys to 8 locale StatusBar.strings.

Reuses existing keys: "Copy","OK","Cancel","Reveal in Finder","Background Color:","Text Color:"
"""
import os, sys

TABLE = 'StatusBar'
LOCALES = ['Base', 'en', 'zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']
SIMPLE = {'zh_CN', 'zh-Hans', 'zh-Hans-CN'}
TRAD   = {'zh_TW', 'zh-Hant', 'zh-Hant-TW'}
errs = []
total = 0

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def val(key, hans, hant, locale):
    if locale in ('Base', 'en'): return key
    if locale in SIMPLE: return hans
    if locale in TRAD: return hant
    return key

def NL(key, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{TABLE}", [NSBundle bundleForClass:[self class]], @"{comment}")'

def NLc(key, comment, cls):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{TABLE}", [NSBundle bundleForClass:[{cls} class]], @"{comment}")'

D = 'sources/StatusBar/'

def wrap_file(path, replacements):
    global total
    s = open(path, encoding='utf-8').read()
    n = 0
    for old, new, label in replacements:
        c = s.count(old)
        if c == 0:
            errs.append(f'{path}: NOT FOUND: {label}'); continue
        if c > 1:
            errs.append(f'{path}: AMBIGUOUS ({c}): {label}'); continue
        s = s.replace(old, new)
        n += 1
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{os.path.basename(path)}: {n} replacements')
    total += n

# ---- iTermStatusBarGraphicComponent.m (2) ----
wrap_file(D + 'Components/iTermStatusBarGraphicComponent.m', [
    ('initWithLabelText:@"Background Color:"', f'initWithLabelText:{NL("Background Color:", "graphic component: background color knob label")}', 'bg color'),
    ('initWithLabelText:@"Text Color:"', f'initWithLabelText:{NL("Text Color:", "graphic component: text color knob label")}', 'text color'),
])

# ---- iTermStatusBarContainerView.m (5) ----
wrap_file(D + 'Core/iTermStatusBarContainerView.m', [
    ('[menu addItemWithTitle:@"Copy"\n                            action:@selector(copyComponentValue:)',
     f'[menu addItemWithTitle:{NL("Copy", "container view: copy menu item")}\n                            action:@selector(copyComponentValue:)', 'copy'),
    ('[menu addItemWithTitle:[NSString stringWithFormat:@"Configure %@", [self.component statusBarComponentShortDescription]]\n                            action:@selector(configureComponent:)',
     f'[menu addItemWithTitle:[NSString stringWithFormat:{NL("Configure %@", "container view: configure component menu format")}, [self.component statusBarComponentShortDescription]]\n                            action:@selector(configureComponent:)', 'configure'),
    ('[menu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", [self.component statusBarComponentShortDescription]]\n                        action:@selector(hideComponent:)',
     f'[menu addItemWithTitle:[NSString stringWithFormat:{NL("Hide %@", "container view: hide component menu format")}, [self.component statusBarComponentShortDescription]]\n                        action:@selector(hideComponent:)', 'hide'),
    ('[menu addItemWithTitle:@"Configure Status Bar"\n                    action:@selector(configureStatusBar:)',
     f'[menu addItemWithTitle:{NL("Configure Status Bar", "container view: configure status bar menu item")}\n                    action:@selector(configureStatusBar:)', 'configure status bar'),
    ('[menu addItemWithTitle:@"Disable Status Bar"\n                    action:@selector(disableStatusBar:)',
     f'[menu addItemWithTitle:{NL("Disable Status Bar", "container view: disable status bar menu item")}\n                    action:@selector(disableStatusBar:)', 'disable status bar'),
])

# ---- iTermStatusBarSetupViewController.m (2) — class iTermStatusBarSetupViewController ----
wrap_file(D + 'Setup/iTermStatusBarSetupViewController.m', [
    ('button.title = @"Reset to System Font";', f'button.title = {NL("Reset to System Font", "setup: reset to system font button")};', 'reset font'),
    ('_fontLabel.stringValue = @"System Font";', f'_fontLabel.stringValue = {NL("System Font", "setup: system font label")};', 'system font'),
])

# ---- iTermStatusBarRPCProvidedTextComponent.m (11) ----
# L402-407: autolaunch warning
wrap_file(D + 'Components/iTermStatusBarRPCProvidedTextComponent.m', [
    ('if ([iTermWarning showWarningWithTitle:@"This will move the script into the AutoLaunch folder."',
     f'if ([iTermWarning showWarningWithTitle:{NL("This will move the script into the AutoLaunch folder.", "rpc component: autolaunch warning title")}', 'autolaunch title'),
    ('actions:@[ @"OK", @"Cancel" ]',
     f'actions:@[ {NL("OK", "rpc component: autolaunch OK button")}, {NL("Cancel", "rpc component: autolaunch Cancel button")} ]', 'autolaunch actions'),
    ('heading:@"Always launch this script when iTerm2 starts?"',
     f'heading:{NL("Always launch this script when iTerm2 starts?", "rpc component: autolaunch heading")}', 'autolaunch heading'),
    # L428: return value error
    ('_errorMessage = [NSString stringWithFormat:@"Return value from %@ invalid.\\n\\nIt should have returned a string or a list of strings.\\n\\nInstead, it returned:\\n\\n%@", self.invocation, value];',
     f'_errorMessage = [NSString stringWithFormat:{NL("Return value from %@ invalid.\\n\\nIt should have returned a string or a list of strings.\\n\\nInstead, it returned:\\n\\n%@", "rpc component: invalid return value error")}, self.invocation, value];', 'return value error'),
    # L438: component failed error (curly quotes)
    ('_errorMessage = [NSString stringWithFormat:@"Status bar component “%@” (%@) failed.\\n\\nThis function call had an error:\\n\\n%@\\n\\nThe error was:\\n\\n%@\\n\\n%@",',
     f'_errorMessage = [NSString stringWithFormat:{NL("Status bar component “%@” (%@) failed.\\n\\nThis function call had an error:\\n\\n%@\\n\\nThe error was:\\n\\n%@\\n\\n%@", "rpc component: status bar component failed error")},', 'component failed error'),
    # L537: heading (overwritten but wrap for consistency)
    ('warning.heading = @"Status Bar Component Problem";',
     f'warning.heading = {NL("Status Bar Component Problem", "rpc component: component problem heading")};', 'component problem heading'),
    # L538: OK action
    ('NSArray *actions = @[ [iTermWarningAction warningActionWithLabel:@"OK" block:nil] ];',
     f'NSArray *actions = @[ [iTermWarningAction warningActionWithLabel:{NL("OK", "rpc component: onClick OK button")} block:nil] ];', 'onClick ok'),
    # L540: Launch Script
    ('iTermWarningAction *launch = [iTermWarningAction warningActionWithLabel:@"Launch Script" block:^(iTermWarningSelection selection) {',
     f'iTermWarningAction *launch = [iTermWarningAction warningActionWithLabel:{NL("Launch Script", "rpc component: launch script button")} block:^(iTermWarningSelection selection) {{', 'launch script'),
    # L543: Reveal in Finder
    ('iTermWarningAction *reveal = [iTermWarningAction warningActionWithLabel:@"Reveal in Finder" block:^(iTermWarningSelection selection) {',
     f'iTermWarningAction *reveal = [iTermWarningAction warningActionWithLabel:{NL("Reveal in Finder", "rpc component: reveal in finder button")} block:^(iTermWarningSelection selection) {{', 'reveal in finder'),
    # L548: script not running
    ('warning.title = [NSString stringWithFormat:@"%@It looks like the script is not running. Launching it might fix the problem.", _errorMessage];',
     f'warning.title = [NSString stringWithFormat:{NL("%@It looks like the script is not running. Launching it might fix the problem.", "rpc component: script not running warning title")}, _errorMessage];', 'script not running'),
    # L552: final heading
    ('warning.heading = @"Status Bar Script Error";',
     f'warning.heading = {NL("Status Bar Script Error", "rpc component: script error heading")};', 'script error heading'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

# ============================================================
# Append 14 new keys to 8 locale StatusBar.strings
# ============================================================
NEW_KEYS = [
    ('Configure %@', '配置 %@', '設定 %@'),
    ('Hide %@', '隐藏 %@', '隱藏 %@'),
    ('Configure Status Bar', '配置状态栏', '設定狀態列'),
    ('Disable Status Bar', '禁用状态栏', '停用狀態列'),
    ('Reset to System Font', '重置为系统字体', '重設為系統字體'),
    ('System Font', '系统字体', '系統字體'),
    ('This will move the script into the AutoLaunch folder.', '这会将脚本移入 AutoLaunch 文件夹。', '這會將腳本移入 AutoLaunch 資料夾。'),
    ('Always launch this script when iTerm2 starts?', 'iTerm2 启动时始终运行此脚本吗？', 'iTerm2 啟動時始終執行此腳本嗎？'),
    ('Return value from %@ invalid.\n\nIt should have returned a string or a list of strings.\n\nInstead, it returned:\n\n%@',
     '%@ 的返回值无效。\n\n它应返回字符串或字符串列表。\n\n但它返回了：\n\n%@',
     '%@ 的傳回值無效。\n\n它應傳回字串或字串列表。\n\n但它傳回了：\n\n%@'),
    ('Status bar component “%@” (%@) failed.\n\nThis function call had an error:\n\n%@\n\nThe error was:\n\n%@\n\n%@',
     '状态栏组件“%@”（%@）失败。\n\n此函数调用出现错误：\n\n%@\n\n错误为：\n\n%@\n\n%@',
     '狀態列元件「%@」(%@) 失敗。\n\n此函式呼叫出現錯誤：\n\n%@\n\n錯誤為：\n\n%@\n\n%@'),
    ('Status Bar Component Problem', '状态栏组件问题', '狀態列元件問題'),
    ('Launch Script', '运行脚本', '執行腳本'),
    ('%@It looks like the script is not running. Launching it might fix the problem.',
     '%@看起来脚本未在运行。运行它可能会修复此问题。',
     '%@看起來腳本未在執行。執行它可能會修復此問題。'),
    ('Status Bar Script Error', '状态栏脚本错误', '狀態列腳本錯誤'),
]

for loc in LOCALES:
    fp = f'{D}{loc}.lproj/StatusBar.strings'
    existing = open(fp, encoding='utf-8').read()
    if not existing.endswith('\n'):
        existing += '\n'
    lines = []
    for key, hans, hant in NEW_KEYS:
        v = val(key, hans, hant, loc)
        lines.append(f'"{esc(key)}" = "{esc(v)}";')
    open(fp, 'w', encoding='utf-8').write(existing + '\n'.join(lines) + '\n')
    print(f'{fp}: appended {len(lines)} keys')

print(f'\nTotal applied: {total}')
print('All OK')
