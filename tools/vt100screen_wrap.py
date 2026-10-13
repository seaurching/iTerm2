# -*- coding: utf-8 -*-
# Wrap user-visible strings in VT100Screen ObjC sources with
# NSLocalizedStringFromTableInBundle(@"key", @"VT100Screen", [NSBundle bundleForClass:[self class]], @"comment").
#
# Table: VT100Screen
# Sources:
#   sources/VT100Screen/VT100ScreenMutableState.m
#   sources/VT100Screen/VT100ScreenMutableState+TerminalDelegate.m
import sys

SRCS = [
    'sources/VT100Screen/VT100ScreenMutableState.m',
    'sources/VT100Screen/VT100ScreenMutableState+TerminalDelegate.m',
]

def W(key, comment):
    return (f'NSLocalizedStringFromTableInBundle(@"{key}", @"VT100Screen", '
            f'[NSBundle bundleForClass:[self class]], @"{comment}")')

edits = [
    # === VT100ScreenMutableState.m ===
    # L6249: archive restored banner
    ('[self appendRestoredBanner:@"Archive Restored"];',
     f'[self appendRestoredBanner:{W("Archive Restored", "横幅：归档已恢复")}];'),
    # L6256: session contents restored banner (format string)
    ('[NSString stringWithFormat:@"Session Contents Restored on %@", [dateFormatter stringFromDate:[NSDate date]]]',
     f'[NSString stringWithFormat:{W("Session Contents Restored on %@", "横幅：会话内容恢复时间")}, [dateFormatter stringFromDate:[NSDate date]]]'),
    # L7022: ssh exited preamble
    ('preamble = @"ssh exited";',
     f'preamble = {W("ssh exited", "横幅：ssh 已退出")};'),
    # L7024: ssh sessions ended preamble (format string)
    ('[NSString stringWithFormat:@"%@ ssh sessions ended.", @(count)]',
     f'[NSString stringWithFormat:{W("%@ ssh sessions ended.", "横幅：ssh 会话结束")}, @(count)]'),
    # L7027: now at location (format string)
    ('[NSString stringWithFormat:@"%@ — now at %@.", preamble, sshLocation]',
     f'[NSString stringWithFormat:{W("%@ — now at %@.", "横幅：ssh 现位于新位置")}, preamble, sshLocation]'),
    # L7029: preamble only (format string)
    ('[NSString stringWithFormat:@"%@.", preamble]',
     f'[NSString stringWithFormat:{W("%@.", "横幅：前导语句收尾")}, preamble]'),
    # L7227: trigger name (format string, user-visible via announcement)
    ('[NSString stringWithFormat:@"%@ trigger", [[trigger.class title] stringByRemovingSuffix:@"…"]]',
     f'[NSString stringWithFormat:{W("%@ trigger", "横幅：触发器名称")}, [[trigger.class title] stringByRemovingSuffix:@"…"]]'),

    # === VT100ScreenMutableState+TerminalDelegate.m ===
    # L3759: out-of-date it2ssh
    ('[self appendBannerMessage:@"Out-of-date version of it2ssh detected. Please upgrade it2ssh."];',
     f'[self appendBannerMessage:{W("Out-of-date version of it2ssh detected. Please upgrade it2ssh.", "横幅：it2ssh 版本过旧")}];'),
    # L3763: future version of it2ssh
    ('[self appendBannerMessage:@"Future version of it2ssh detected. Please upgrade iTerm2."];',
     f'[self appendBannerMessage:{W("Future version of it2ssh detected. Please upgrade iTerm2.", "横幅：it2ssh 版本超前")}];'),
    # L3832: recovering ssh connection
    ('[self appendBannerMessage:@"Recovering ssh connection…"];',
     f'[self appendBannerMessage:{W("Recovering ssh connection…", "横幅：正在恢复 ssh 连接")}];'),
    # L3852: ssh connection recovered
    ('[weakSelf appendBanner:@"ssh connection recovered!" andUnpause:unpauser];',
     f'[weakSelf appendBanner:{W("ssh connection recovered!", "横幅：ssh 连接已恢复")} andUnpause:unpauser];'),
    # L4024: started command banner (format string)
    ('[NSString stringWithFormat:@"   Started %@", command]',
     f'[NSString stringWithFormat:{W("   Started %@", "横幅：命令已启动")}, command]'),
]

total = 0
for src in SRCS:
    s = open(src, encoding='utf-8').read()
    n = 0
    for old, new in edits:
        c = s.count(old)
        if c == 0:
            continue  # edit belongs to the other file
        if c != 1:
            print(f'ERROR: {src}: expected 1, got {c} for: {old!r}')
            sys.exit(1)
        s = s.replace(old, new)
        n += 1
    open(src, 'w', encoding='utf-8').write(s)
    print(f'{src}: {n} edits OK')
    total += n

print(f'VT100Screen wrap done: {total} edits total')
