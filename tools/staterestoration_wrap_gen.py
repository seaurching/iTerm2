# -*- coding: utf-8 -*-
"""Wrap StateRestoration .m files and generate 8 locale StateRestoration.strings.

Adaptation policy applied:
- NSError NSLocalizedDescriptionKey, iTermWarning titles/headings/actions, NSAlert
  messageText/informativeText/buttons, fallback "Unknown error" shown in warning -> ADAPT
- NSException reasons / it_rethrowWithMessage / internal invariant diagnostics
  (DuplicateRowID, MissingRowID, DeltaEncoder (1)/(2)/(3) comparisons) -> NOT ADAPT
  (assertion-style, feed DLog/fatalError, never user-facing)
"""
import os, sys

TABLE = 'StateRestoration'
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

# ============ Wrap iTermGraphTableTransformer.m (4) ============
f = 'sources/StateRestoration/iTermGraphTableTransformer.m'
s = open(f, encoding='utf-8').read()
n = 0
def rep(old, new, label, filename=f):
    global s, n
    c = s.count(old)
    if c == 0: errs.append(f'{filename}: NOT FOUND: {label}'); return
    if c > 1: errs.append(f'{filename}: AMBIGUOUS ({c}): {label}'); return
    s = s.replace(old, new); n += 1

rep('userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Wrong number of items in row: %@", row] }',
    f'userInfo:@{{ NSLocalizedDescriptionKey: [NSString stringWithFormat:{NL("Wrong number of items in row: %@", "graph transformer: wrong item count error")}, row] }}',
    'wrong item count')
rep('userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Bad row: %@", row] }',
    f'userInfo:@{{ NSLocalizedDescriptionKey: [NSString stringWithFormat:{NL("Bad row: %@", "graph transformer: bad row error")}, row] }}',
    'bad row')
rep('userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Two roots found"] }',
    f'userInfo:@{{ NSLocalizedDescriptionKey: {NL("Two roots found", "graph transformer: two roots error")} }}',
    'two roots')
rep('userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Dangling parent pointer %@ from %@", nodeDict[@"parent"], nodeid] }',
    f'userInfo:@{{ NSLocalizedDescriptionKey: [NSString stringWithFormat:{NL("Dangling parent pointer %@ from %@", "graph transformer: dangling parent error")}, nodeDict[@"parent"], nodeid] }}',
    'dangling parent')
open(f, 'w', encoding='utf-8').write(s)
print(f'iTermGraphTableTransformer.m: {n} replacements')
total += n

# ============ Wrap iTermEncoderGraphRecord.m (1) ============
f = 'sources/StateRestoration/iTermEncoderGraphRecord.m'
s = open(f, encoding='utf-8').read()
n = 0
rep('userInfo:@{ NSLocalizedDescriptionKey: @"No such record or wrong type" }',
    f'userInfo:@{{ NSLocalizedDescriptionKey: {NL("No such record or wrong type", "graph record: missing record error")} }}',
    'no such record', filename=f)
open(f, 'w', encoding='utf-8').write(s)
print(f'iTermEncoderGraphRecord.m: {n} replacements')
total += n

# ============ Wrap iTermRestorableStateDriver.m (4: title, OK, Cancel, heading) ============
f = 'sources/StateRestoration/iTermRestorableStateDriver.m'
s = open(f, encoding='utf-8').read()
n = 0
rep('[iTermWarning showWarningWithTitle:@"Some windows had trouble restoring last time iTerm2 launched. Try again?"',
    f'[iTermWarning showWarningWithTitle:{NL("Some windows had trouble restoring last time iTerm2 launched. Try again?", "restore driver: restore retry warning title")}',
    'driver title', filename=f)
rep('actions:@[ @"OK", @"Cancel" ]',
    f'actions:@[ {NL("OK", "restore driver: OK button")}, {NL("Cancel", "restore driver: Cancel button")} ]',
    'driver actions', filename=f)
rep('heading:@"Restore Windows?"',
    f'heading:{NL("Restore Windows?", "restore driver: restore windows heading")}',
    'driver heading', filename=f)
open(f, 'w', encoding='utf-8').write(s)
print(f'iTermRestorableStateDriver.m: {n} replacements')
total += n

# ============ Wrap iTermRestorableStateSQLite.m (4) ============
f = 'sources/StateRestoration/iTermRestorableStateSQLite.m'
s = open(f, encoding='utf-8').read()
n = 0
# Use curly apostrophe U+2019 to match source exactly
info_key = 'iTerm2 is taking longer than usual to verify your saved windows and tabs. This usually means the system is busy and it’s safe to keep waiting, but a damaged state restoration database could also cause it. You can discard the saved windows instead if you’d rather not wait.'
rep('alert.messageText = @"Still restoring your windows…";',
    f'alert.messageText = {NL("Still restoring your windows…", "restore sqlite: still restoring alert message")};',
    'sqlite messageText', filename=f)
rep(f'alert.informativeText = @"{info_key}";',
    f'alert.informativeText = {NL(info_key, "restore sqlite: still restoring alert informative text")};',
    'sqlite informativeText', filename=f)
rep('[alert addButtonWithTitle:@"Keep Waiting"]',
    f'[alert addButtonWithTitle:{NL("Keep Waiting", "restore sqlite: keep waiting button")}]',
    'sqlite keep waiting', filename=f)
rep('[alert addButtonWithTitle:@"Discard Saved Windows"]',
    f'[alert addButtonWithTitle:{NL("Discard Saved Windows", "restore sqlite: discard windows button")}]',
    'sqlite discard', filename=f)
open(f, 'w', encoding='utf-8').write(s)
print(f'iTermRestorableStateSQLite.m: {n} replacements')
total += n

# ============ Wrap iTermGraphDatabase.m (6: 2 titles, 2 OK, 2 Unknown error) ============
f = 'sources/StateRestoration/iTermGraphDatabase.m'
s = open(f, encoding='utf-8').read()
n = 0
# generation column warning (title + OK + Unknown error)
rep('[iTermWarning showWarningWithTitle:[NSString stringWithFormat:@"Failed to migrate session database (adding generation column): %@", error]',
    f'[iTermWarning showWarningWithTitle:[NSString stringWithFormat:{NL("Failed to migrate session database (adding generation column): %@", "graph database: generation migration failure warning")}, error]',
    'gen migration title', filename=f)
# large_data column warning (title + OK + Unknown error) — identical pattern, distinguish by column name
rep('[iTermWarning showWarningWithTitle:[NSString stringWithFormat:@"Failed to migrate session database (adding large_data column): %@", error]',
    f'[iTermWarning showWarningWithTitle:[NSString stringWithFormat:{NL("Failed to migrate session database (adding large_data column): %@", "graph database: large_data migration failure warning")}, error]',
    'large_data migration title', filename=f)
# Both OK buttons are identical: actions:@[ @"OK" ]  (appears twice)
c = s.count('actions:@[ @"OK" ]')
if c != 2:
    errs.append(f'{f}: actions:@[ @"OK" ] count {c} (expected 2)')
else:
    s = s.replace('actions:@[ @"OK" ]', f'actions:@[ {NL("OK", "graph database: OK button")} ]')
    n += 2
# Both "Unknown error" fallbacks are identical: ?: @"Unknown error"  (appears twice)
c = s.count('?: @"Unknown error"')
if c != 2:
    errs.append(f'{f}: ?: @"Unknown error" count {c} (expected 2)')
else:
    s = s.replace('?: @"Unknown error"', f'?: {NL("Unknown error", "graph database: unknown error fallback")}')
    n += 2
open(f, 'w', encoding='utf-8').write(s)
print(f'iTermGraphDatabase.m: {n} replacements')
total += n

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

# ============ Generate 8 locale StateRestoration.strings ============
KEYS = [
    ('Wrong number of items in row: %@',
     '行中项目数错误：%@', '列中項目數錯誤：%@'),
    ('Bad row: %@',
     '错误的行：%@', '錯誤的列：%@'),
    ('Two roots found',
     '发现两个根节点', '發現兩個根節點'),
    ('Dangling parent pointer %@ from %@',
     '悬空的父指针 %@ 来自 %@', '懸空的父指標 %@ 來自 %@'),
    ('No such record or wrong type',
     '无此记录或类型错误', '無此記錄或類型錯誤'),
    ('Some windows had trouble restoring last time iTerm2 launched. Try again?',
     '上次启动 iTerm2 时某些窗口恢复遇到问题。要重试吗？',
     '上次啟動 iTerm2 時某些視窗復原遇到問題。要重試嗎？'),
    ('OK', '确定', '確定'),
    ('Cancel', '取消', '取消'),
    ('Restore Windows?',
     '恢复窗口？', '復原視窗？'),
    ('Still restoring your windows…',
     '仍在恢复您的窗口…', '仍在復原您的視窗…'),
    (info_key,
     'iTerm2 验证您保存的窗口和标签页所需的时间比平时长。这通常意味着系统繁忙，继续等待是安全的，但状态恢复数据库损坏也可能导致此情况。如果您不想等待，可以选择丢弃已保存的窗口。',
     'iTerm2 驗證您儲存的視窗和分頁所需的時間比平常長。這通常表示系統繁忙，繼續等待是安全的，但狀態復原資料庫損壞也可能導致此情況。如果您不想等待，可以選擇捨棄已儲存的視窗。'),
    ('Keep Waiting',
     '继续等待', '繼續等待'),
    ('Discard Saved Windows',
     '丢弃已保存的窗口', '捨棄已儲存的視窗'),
    ('Failed to migrate session database (adding generation column): %@',
     '迁移会话数据库失败（添加 generation 列）：%@',
     '遷移工作階段資料庫失敗（新增 generation 欄位）：%@'),
    ('Failed to migrate session database (adding large_data column): %@',
     '迁移会话数据库失败（添加 large_data 列）：%@',
     '遷移工作階段資料庫失敗（新增 large_data 欄位）：%@'),
    ('Unknown error',
     '未知错误', '未知錯誤'),
]

for loc in LOCALES:
    d = f'sources/StateRestoration/{loc}.lproj'
    os.makedirs(d, exist_ok=True)
    lines = []
    for key, hans, hant in KEYS:
        v = val(key, hans, hant, loc)
        lines.append(f'"{esc(key)}" = "{esc(v)}";')
    fp = f'{d}/StateRestoration.strings'
    open(fp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(f'{fp}: {len(lines)} keys')

print(f'\nTotal applied: {total}')
print('All OK')
