# -*- coding: utf-8 -*-
"""Wrap 3 ObjC files in sources/Tasks/ with NSLocalizedStringFromTableInBundle
and generate Tasks.strings for 8 locales.

Files:
  Coprocess.m                        - 2 sites (2 keys)
  PTYTask.m                          - 6 sites (6 keys, OK shared)
  iTermFileDescriptorMultiClient.m   - 8 sites (8 keys)

Total: 16 sites, 15 unique keys.
"""
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

T = 'Tasks'

# ==================== Coprocess.m ====================
wrap_file('sources/Tasks/Coprocess.m', [
    ('alert.messageText = @"Failed to launch coprocess.";',
     f'alert.messageText = {NL(T, "Failed to launch coprocess.", "coprocess: launch failed alert message")};',
     'coprocess messageText'),
    ('[alert addButtonWithTitle:@"OK"];',
     f'[alert addButtonWithTitle:{NL(T, "OK", "coprocess: OK button")}];',
     'coprocess OK'),
])

# ==================== PTYTask.m ====================
wrap_file('sources/Tasks/PTYTask.m', [
    ('NSString *error = @"Unable to fork child process: you may have too many processes already running.";',
     f'NSString *error = {NL(T, "Unable to fork child process: you may have too many processes already running.", "fork: unable to fork error message")};',
     'fork error message'),
    ('error = [NSString stringWithFormat:@"%@ The system error was: %s", error, strerror(optionalErrorCode.intValue)];',
     f'error = [NSString stringWithFormat:{NL(T, "%@ The system error was: %s", "fork: system error suffix")}, error, strerror(optionalErrorCode.intValue)];',
     'fork system error suffix'),
    ('notify:@"Unable to fork!"',
     f'notify:{NL(T, "Unable to fork!", "fork: notification title")}',
     'fork notify title'),
    ('alert.messageText = @"Error";',
     f'alert.messageText = {NL(T, "Error", "temp socket: error alert title")};',
     'temp socket Error title'),
    ('alert.informativeText = [NSString stringWithFormat:@"An error was encountered while creating a temporary file with mkstemps. Verify that %@ exists and is writable.", NSTemporaryDirectory()];',
     f'alert.informativeText = [NSString stringWithFormat:{NL(T, "An error was encountered while creating a temporary file with mkstemps. Verify that %@ exists and is writable.", "temp socket: informative text")}, NSTemporaryDirectory()];',
     'temp socket informative'),
    ('[alert addButtonWithTitle:@"OK"];',
     f'[alert addButtonWithTitle:{NL(T, "OK", "temp socket: OK button")}];',
     'temp socket OK'),
])

# ==================== iTermFileDescriptorMultiClient.m ====================
wrap_file('sources/Tasks/iTermFileDescriptorMultiClient.m', [
    ('alert.messageText = @"Problem Starting iTerm2 Daemon";',
     f'alert.messageText = {NL(T, "Problem Starting iTerm2 Daemon", "daemon: problem starting alert title")};',
     'daemon problem title'),
    ('message:[NSString stringWithFormat:@"Neither ~/Library/Application Support/iTerm2 nor ~/.iterm2 are writable directories. This prevents the session restoration server from running. Please correct the problem and restart iTerm2."]',
     f'message:[NSString stringWithFormat:{NL(T, "Neither ~/Library/Application Support/iTerm2 nor ~/.iterm2 are writable directories. This prevents the session restoration server from running. Please correct the problem and restart iTerm2.", "daemon: no writable directory message")}]',
     'no writable dir'),
    ('alert.messageText = @"Required File Missing";',
     f'alert.messageText = {NL(T, "Required File Missing", "daemon: required file missing alert title")};',
     'required file title'),
    ('alert.informativeText = @"The iTermServer executable is missing from the application bundle. This indicates iTerm2 is corrupted or incomplete. Please reinstall iTerm2 from the official website.";',
     f'alert.informativeText = {NL(T, "The iTermServer executable is missing from the application bundle. This indicates iTerm2 is corrupted or incomplete. Please reinstall iTerm2 from the official website.", "daemon: iTermServer missing informative")};',
     'iTermServer missing'),
    ('[alert addButtonWithTitle:@"Quit"];',
     f'[alert addButtonWithTitle:{NL(T, "Quit", "daemon: quit button")}];',
     'daemon quit'),
    ('message:[NSString stringWithFormat:@"Could not copy %@ to %@: %@", sourcePath, desiredPath, error.localizedDescription]',
     f'message:[NSString stringWithFormat:{NL(T, "Could not copy %@ to %@: %@", "daemon: copy failed message")}, sourcePath, desiredPath, error.localizedDescription]',
     'copy failed'),
    ('message:[NSString stringWithFormat:@"Could not check permissions on %@", desiredPath]',
     f'message:[NSString stringWithFormat:{NL(T, "Could not check permissions on %@", "daemon: check permissions failed message")}, desiredPath]',
     'check perms'),
    ('message:[NSString stringWithFormat:@"Could not set 0700 permissions on %@", desiredPath]',
     f'message:[NSString stringWithFormat:{NL(T, "Could not set 0700 permissions on %@", "daemon: set permissions failed message")}, desiredPath]',
     'set perms'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

# ==================== Generate .strings ====================
KEYS = [
    ('Failed to launch coprocess.',
     '启动辅助进程失败。',
     '啟動輔助處理序失敗。'),
    ('OK', '确定', '確定'),
    ('Unable to fork child process: you may have too many processes already running.',
     '无法派生子进程：您可能已经运行了太多进程。',
     '無法分支子處理序：您可能已經執行了太多處理序。'),
    ('%@ The system error was: %s',
     '%@ 系统错误为：%s',
     '%@ 系統錯誤為：%s'),
    ('Unable to fork!', '无法派生子进程！', '無法分支子處理序！'),
    ('Error', '错误', '錯誤'),
    ('An error was encountered while creating a temporary file with mkstemps. Verify that %@ exists and is writable.',
     '使用 mkstemps 创建临时文件时遇到错误。请验证 %@ 是否存在且可写。',
     '使用 mkstemps 建立暫存檔案時遇到錯誤。請驗證 %@ 是否存在且可寫入。'),
    ('Problem Starting iTerm2 Daemon',
     '启动 iTerm2 守护程序时出现问题',
     '啟動 iTerm2 常駐程式時發生問題'),
    ('Neither ~/Library/Application Support/iTerm2 nor ~/.iterm2 are writable directories. This prevents the session restoration server from running. Please correct the problem and restart iTerm2.',
     '~/Library/Application Support/iTerm2 和 ~/.iterm2 都不是可写目录。这会阻止会话恢复服务器运行。请纠正此问题并重启 iTerm2。',
     '~/Library/Application Support/iTerm2 與 ~/.iterm2 都不是可寫入目錄。這會阻止工作階段還原伺服器執行。請修正此問題並重新啟動 iTerm2。'),
    ('Required File Missing',
     '缺少必需的文件',
     '缺少必要的檔案'),
    ('The iTermServer executable is missing from the application bundle. This indicates iTerm2 is corrupted or incomplete. Please reinstall iTerm2 from the official website.',
     '应用程序包中缺少 iTermServer 可执行文件。这表明 iTerm2 已损坏或不完整。请从官方网站重新安装 iTerm2。',
     '應用程式套件中缺少 iTermServer 可執行檔。這表示 iTerm2 已損壞或不完整。請從官方網站重新安裝 iTerm2。'),
    ('Quit', '退出', '結束'),
    ('Could not copy %@ to %@: %@',
     '无法将 %@ 拷贝到 %@：%@',
     '無法將 %@ 拷貝到 %@：%@'),
    ('Could not check permissions on %@',
     '无法检查 %@ 的权限',
     '無法檢查 %@ 的權限'),
    ('Could not set 0700 permissions on %@',
     '无法为 %@ 设置 0700 权限',
     '無法為 %@ 設定 0700 權限'),
]

root = 'sources/Tasks'
for loc in LOCALES:
    d = f'{root}/{loc}.lproj'
    os.makedirs(d, exist_ok=True)
    lines = []
    for key, hans, hant in KEYS:
        v = val(key, hans, hant, loc)
        lines.append(f'"{esc(key)}" = "{esc(v)}";')
    fp = f'{d}/{T}.strings'
    open(fp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(f'{fp}: {len(lines)} keys')

print(f'\nTotal applied: {total}')
print('All OK')
