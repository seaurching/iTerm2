# -*- coding: utf-8 -*-
"""Wrap System/iTermLaunchServices.m (ObjC, 8 sites, 7 unique keys) and
   StatusWindowsViews/iTermPleaseWaitWindow.swift (Swift, 1 key).
   Generate 8 locale .strings for each table + inject pbxproj."""
import os, sys

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

def NL(table, key, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

def NL_swift(table, key, comment):
    k = key.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return f'NSLocalizedString("{k}", tableName: "{table}", comment: "{comment}")'

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

# ==================== System/iTermLaunchServices.m ====================
T = 'System'
f = 'sources/System/iTermLaunchServices.m'
# L81-82: messageText stringWithFormat (multi-line concat)
wrap_file(f, [
    ('alert.messageText = [NSString stringWithFormat:@"iTerm is not the default handler for %@. "\n                     @"Would you like to set iTerm as the default handler?",\n                     scheme];',
     f'alert.messageText = [NSString stringWithFormat:{NL(T, "iTerm is not the default handler for %@. Would you like to set iTerm as the default handler?", "default handler: not default alert message")},\n                     scheme];',
     'msgText no handler'),
    ('alert.informativeText = @"There is currently no handler.";',
     f'alert.informativeText = {NL(T, "There is currently no handler.", "default handler: no handler informative")};',
     'no handler informative'),
    ('[alert addButtonWithTitle:@"OK"];\n        [alert addButtonWithTitle:@"Cancel"];\n        set = ([alert runModal] == NSAlertFirstButtonReturn);\n    } else if',
     f'[alert addButtonWithTitle:{NL(T, "OK", "default handler: OK button")}];\n        [alert addButtonWithTitle:{NL(T, "Cancel", "default handler: cancel button")}];\n        set = ([alert runModal] == NSAlertFirstButtonReturn);\n    }} else if',
     'OK/Cancel first'),
    # L89-90: theTitle stringWithFormat
    ('NSString *theTitle = [NSString stringWithFormat:@"iTerm is not the default handler for %@. "\n                                                        @"Would you like to set iTerm as the default handler?", scheme];',
     f'NSString *theTitle = [NSString stringWithFormat:{NL(T, "iTerm is not the default handler for %@. Would you like to set iTerm as the default handler?", "default handler: not default alert message")}, scheme];',
     'theTitle'),
    ('alert.informativeText = [NSString stringWithFormat:@"The current handler is: %@",\n                                 [[NSFileManager defaultManager] displayNameAtPath:[appURL path]]];',
     f'alert.informativeText = [NSString stringWithFormat:{NL(T, "The current handler is: %@", "default handler: current handler informative")},\n                                 [[NSFileManager defaultManager] displayNameAtPath:[appURL path]]];',
     'current handler'),
    ('[alert addButtonWithTitle:@"OK"];\n        [alert addButtonWithTitle:@"Cancel"];\n        set = ([alert runModal] == NSAlertFirstButtonReturn);\n    }',
     f'[alert addButtonWithTitle:{NL(T, "OK", "default handler: OK button")}];\n        [alert addButtonWithTitle:{NL(T, "Cancel", "default handler: cancel button")}];\n        set = ([alert runModal] == NSAlertFirstButtonReturn);\n    }}',
     'OK/Cancel second'),
    # L178: no application
    ('alert.messageText = [NSString stringWithFormat:@"There is no application set to open the document “%@”", [fullPath lastPathComponent]];',
     f'alert.messageText = [NSString stringWithFormat:{NL(T, "There is no application set to open the document “%@”", "open file: no app alert message")}, [fullPath lastPathComponent]];',
     'no app message'),
    ('alert.informativeText = @"Choose an application on your computer to open this file.";',
     f'alert.informativeText = {NL(T, "Choose an application on your computer to open this file.", "open file: choose app informative")};',
     'choose app informative'),
    ('[alert addButtonWithTitle:@"Choose Application…"];\n    [alert addButtonWithTitle:@"Cancel"];',
     f'[alert addButtonWithTitle:{NL(T, "Choose Application…", "open file: choose application button")}];\n    [alert addButtonWithTitle:{NL(T, "Cancel", "open file: cancel button")}];',
     'choose app/cancel'),
])

# ==================== StatusWindowsViews/iTermPleaseWaitWindow.swift ====================
T2 = 'StatusWindowsViews'
f2 = 'sources/StatusWindowsViews/iTermPleaseWaitWindow.swift'
wrap_file(f2, [
    ('cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))',
     f'cancelButton = NSButton(title: {NL_swift(T2, "Cancel", "please wait: cancel button")}, target: self, action: #selector(cancel(_:)))',
     'cancel button'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

# ==================== Generate .strings ====================
KEYS_SYSTEM = [
    ('iTerm is not the default handler for %@. Would you like to set iTerm as the default handler?',
     'iTerm 不是 %@ 的默认处理程序。是否要将 iTerm 设为默认处理程序？',
     'iTerm 不是 %@ 的預設處理程式。是否要將 iTerm 設為預設處理程式？'),
    ('There is currently no handler.', '目前没有处理程序。', '目前沒有處理程式。'),
    ('OK', '确定', '確定'),
    ('Cancel', '取消', '取消'),
    ('The current handler is: %@', '当前处理程序为：%@', '目前處理程式為：%@'),
    ('There is no application set to open the document “%@”',
     '没有设置用于打开文稿“%@”的应用程序',
     '沒有設定用於開啟文件「%@」的應用程式'),
    ('Choose an application on your computer to open this file.',
     '选择您电脑上的一个应用程序来打开此文件。',
     '選擇您電腦上的一個應用程式來開啟此檔案。'),
    ('Choose Application…', '选择应用程序…', '選擇應用程式…'),
]

KEYS_PLEASEWAIT = [
    ('Cancel', '取消', '取消'),
]

def gen_strings(table, root, keys):
    for loc in LOCALES:
        d = f'{root}/{loc}.lproj'
        os.makedirs(d, exist_ok=True)
        lines = []
        for key, hans, hant in keys:
            v = val(key, hans, hant, loc)
            lines.append(f'"{esc(key)}" = "{esc(v)}";')
        fp = f'{d}/{table}.strings'
        open(fp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
        print(f'{fp}: {len(lines)} keys')

gen_strings('System', 'sources/System', KEYS_SYSTEM)
gen_strings('StatusWindowsViews', 'sources/StatusWindowsViews', KEYS_PLEASEWAIT)

print(f'\nTotal applied: {total}')
print('All OK')
