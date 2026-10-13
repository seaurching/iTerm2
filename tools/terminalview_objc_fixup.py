# -*- coding: utf-8 -*-
"""Fixup: apply the 2 replacements that failed in terminalview_wrap_gen_objc.py
(kill tmux warning in PseudoTerminal.m, upload single file in PTYTextView.m).
Files already have the other 46 replacements applied."""
import sys

T = 'TerminalView'
errs = []

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def NL(key, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{esc(key)}", @"{T}", [NSBundle bundleForClass:[self class]], @"{comment}")'

# === PseudoTerminal.m: kill tmux warning (exact 8/43/35 space indent) ===
f = 'sources/TerminalView/PseudoTerminal.m'
s = open(f, encoding='utf-8').read()
old1 = ('        [iTermWarning showWarningWithTitle:@"Kill tmux window, terminating its jobs, or hide it? "\n'
        '                                           @"Hidden windows may be restored from the tmux dashboard."\n'
        '                                   actions:@[ @"Hide", @"Cancel", @"Kill" ]')
new1 = ('        [iTermWarning showWarningWithTitle:' + NL("Kill tmux window, terminating its jobs, or hide it? Hidden windows may be restored from the tmux dashboard.", "tmux: kill or hide warning title") + '\n'
        '                                   actions:@[ ' + NL("Hide", "tmux: hide button") + ', ' + NL("Cancel", "tmux: cancel button") + ', ' + NL("Kill", "tmux: kill button") + ' ]')
c = s.count(old1)
if c != 1:
    errs.append(f'PseudoTerminal.m kill tmux: count {c}')
else:
    s = s.replace(old1, new1)
    print('PseudoTerminal.m: kill tmux warning applied')

# === PTYTextView.m: upload single file (exact 8/16 space indent) ===
f2 = 'sources/TerminalView/PTYTextView.m'
s2 = open(f2, encoding='utf-8').read()
old2 = ('        text = [NSString stringWithFormat:@"OK to %@\\n%@\\nto\\n%@@%@:%@?",\n'
        '                useSSHIntegration ? @"copy" : @"scp",\n'
        '                [files componentsJoinedByString:@", "],\n'
        '                path.username, path.hostname, path.path];')
new2 = ('        text = [NSString stringWithFormat:' + NL("OK to %@\n%@\nto\n%@@%@:%@?", "upload: single file confirm") + ',\n'
        '                useSSHIntegration ? @"copy" : @"scp",\n'
        '                [files componentsJoinedByString:@", "],\n'
        '                path.username, path.hostname, path.path];')
c2 = s2.count(old2)
if c2 != 1:
    errs.append(f'PTYTextView.m upload single: count {c2}')
else:
    s2 = s2.replace(old2, new2)
    print('PTYTextView.m: upload single file applied')

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)

open(f, 'w', encoding='utf-8').write(s)
open(f2, 'w', encoding='utf-8').write(s2)
print('Fixup OK')
