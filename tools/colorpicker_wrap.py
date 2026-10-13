# -*- coding: utf-8 -*-
"""Wrap UI strings in ColorPicker directory.
"""
import sys, warnings
warnings.filterwarnings('ignore')

def W(key, table, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

def F(key, table, comment):
    return f'[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"{key}", @"{table}", [NSBundle bundleForClass:[self class]], @"{comment}")'

EDITS = [
    # === CPKMainViewController.m ===
    ('alert.messageText = @"Name this color"',
     'alert.messageText = ' + W('Name this color', 'ColorPicker', '命名颜色警告标题')),
    ('alert.informativeText = @"Enter a name for this new saved color:"',
     'alert.informativeText = ' + W('Enter a name for this new saved color:', 'ColorPicker', '命名颜色警告内容')),
    ('[alert addButtonWithTitle:@"OK"]',
     '[alert addButtonWithTitle:' + W('OK', 'ColorPicker', '确定按钮标题') + ']'),
    ('[alert addButtonWithTitle:@"Cancel"]',
     '[alert addButtonWithTitle:' + W('Cancel', 'ColorPicker', '取消按钮标题') + ']'),
    
    # === CPKColorWell.m ===
    ('button.title = @"Default Picker"',
     'button.title = ' + W('Default Picker', 'ColorPicker', '默认选择器按钮标题')),
    ('button.title = @"No Color"',
     'button.title = ' + W('No Color', 'ColorPicker', '无颜色按钮标题')),
    
    # === CPKEyedropperWindow.m ===
    ('alert.messageText = @"Permission Needed"',
     'alert.messageText = ' + W('Permission Needed', 'ColorPicker', '需要权限警告标题'), 2),  # L45, L58
    ('alert.informativeText = @"The eyedropper needs Screen Recording permission to work."',
     'alert.informativeText = ' + W('The eyedropper needs Screen Recording permission to work.', 'ColorPicker', '需要屏幕录制权限警告内容')),
    ('alert.informativeText = [NSString stringWithFormat:@"The eyedropper requires screen recording permission.\\n\\nYou can enable this by adding %@ to System Preferences > Security & Privacy > Privacy > Screen Recording.", [NSRunningApplication currentApplication].localizedName]',
     'alert.informativeText = ' + F('The eyedropper requires screen recording permission.\\n\\nYou can enable this by adding %@ to System Preferences > Security & Privacy > Privacy > Screen Recording.', 'ColorPicker', '需要屏幕录制权限警告内容2') + ', [NSRunningApplication currentApplication].localizedName]'),
    ('[alert addButtonWithTitle:@"Open System Preferences"]',
     '[alert addButtonWithTitle:' + W('Open System Preferences', 'ColorPicker', '打开系统偏好设置按钮标题') + ']'),
]

SRCS = [
    'ColorPicker/ColorPicker/CPKMainViewController.m',
    'ColorPicker/ColorPicker/CPKColorWell.m',
    'ColorPicker/ColorPicker/CPKEyedropperWindow.m',
]

total = 0
for src in SRCS:
    try:
        s = open(src, encoding='utf-8').read()
    except FileNotFoundError:
        print(f'{src}: FILE NOT FOUND')
        sys.exit(1)
    count = 0
    for item in EDITS:
        if len(item) == 4:
            old, new, expected = item[0], item[1], item[3]
        else:
            old, new = item[0], item[1]
            expected = 1
        if old not in s:
            continue
        n = s.count(old)
        if n == 0:
            continue
        if n != expected:
            print(f'{src}: expected {expected} but found {n} for {old[:50]!r}')
            continue
        s = s.replace(old, new)
        count += n
    if count > 0:
        open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {count} edits OK')
    total += count

print(f'ColorPicker wrap done: {total} edits total')
