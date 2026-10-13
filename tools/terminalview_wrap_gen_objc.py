# -*- coding: utf-8 -*-
"""Wrap 6 ObjC files in sources/TerminalView/ with NSLocalizedStringFromTableInBundle
and generate TerminalView.strings for 8 locales.

IMPORTANT: keys with escapes (\\(…), \n) are stored as RUNTIME strings (plain:
actual newline, actual single backslash). esc() is applied to BOTH key and value
so ObjC source and .strings output stay consistent.

Files: PseudoTerminal.m, PTYTab.m, PTYTextView.m, PTYTextView+ARC.m,
       SessionTitleView.m, PTYNoteView.m
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']
SIMPLE = {'zh_CN', 'zh-Hans', 'zh-Hans-CN'}
TRAD   = {'zh_TW', 'zh-Hant', 'zh-Hant-TW'}
T = 'TerminalView'
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
    return f'NSLocalizedStringFromTableInBundle(@"{esc(key)}", @"{T}", [NSBundle bundleForClass:[self class]], @"{comment}")'

def wrap_file(path, replacements):
    global total
    s = open(path, encoding='utf-8').read()
    n = 0
    for old, new, label in replacements:
        c = s.count(old)
        if c == 0:
            errs.append(f'{os.path.basename(path)}: NOT FOUND: {label}'); continue
        if c > 1:
            errs.append(f'{os.path.basename(path)}: AMBIGUOUS ({c}): {label}'); continue
        s = s.replace(old, new)
        n += 1
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{os.path.basename(path)}: {n} replacements')
    total += n

# ============================================================================
# PseudoTerminal.m
# ============================================================================
PST = 'sources/TerminalView/PseudoTerminal.m'
wrap_file(PST, [
    # L2137: Close %@? alert
    ('alert.messageText = [NSString stringWithFormat:@"Close %@?", genericName];',
     f'alert.messageText = [NSString stringWithFormat:{NL("Close %@?", "close tab: alert title")}, genericName];',
     'close tab title'),
    # L2139-2141: OK/Cancel (first alert - close tab)
    ('    [alert addButtonWithTitle:@"OK"];\n    [alert addButtonWithTitle:@"Cancel"];\n    return [alert runSheetModalForWindow:self.window] == NSAlertFirstButtonReturn;',
     f'    [alert addButtonWithTitle:{NL("OK", "close tab: OK")}];\n    [alert addButtonWithTitle:{NL("Cancel", "close tab: cancel")}];\n    return [alert runSheetModalForWindow:self.window] == NSAlertFirstButtonReturn;',
     'close tab OK/Cancel'),
    # L2264-2265: kill tmux warning (multi-line concat title + actions)
    ('[iTermWarning showWarningWithTitle:@"Kill tmux window, terminating its jobs, or hide it? "\n'
     '                                       @"Hidden windows may be restored from the tmux dashboard."\n'
     '                               actions:@[ @"Hide", @"Cancel", @"Kill" ]',
     f'[iTermWarning showWarningWithTitle:{NL("Kill tmux window, terminating its jobs, or hide it? Hidden windows may be restored from the tmux dashboard.", "tmux: kill or hide warning title")}\n'
     f'                               actions:@[ {NL("Hide", "tmux: hide button")}, {NL("Cancel", "tmux: cancel button")}, {NL("Kill", "tmux: kill button")} ]',
     'kill tmux warning'),
    # L2637-2647: restart session warning
    ('iTermWarningAction *cancel = [iTermWarningAction warningActionWithLabel:@"Cancel" block:nil];',
     f'iTermWarningAction *cancel = [iTermWarningAction warningActionWithLabel:{NL("Cancel", "restart session: cancel button")} block:nil];',
     'restart cancel action'),
    ('[iTermWarningAction warningActionWithLabel:@"OK"\n                                                 block:^(iTermWarningSelection selection) {',
     f'[iTermWarningAction warningActionWithLabel:{NL("OK", "restart session: OK button")}\n                                                 block:^(iTermWarningSelection selection) {{',
     'restart OK action'),
    ('warning.heading = @"Restart session?";',
     f'warning.heading = {NL("Restart session?", "restart session: heading")};',
     'restart heading'),
    ('warning.title = @"Running jobs will be killed.";',
     f'warning.title = {NL("Running jobs will be killed.", "restart session: title")};',
     'restart title'),
    # L3615-3616: Set Window Title alert
    ('alert.messageText = @"Set Window Title";',
     f'alert.messageText = {NL("Set Window Title", "set window title: alert title")};',
     'set window title'),
    ('alert.informativeText = @"If this is empty, the window takes the active session’s title. Variables and function calls enclosed in \\\\(…) will be replaced with their evaluation. This interpolated string is evaluated in the window’s context.";',
     f'alert.informativeText = {NL("If this is empty, the window takes the active session’s title. Variables and function calls enclosed in \\(…) will be replaced with their evaluation. This interpolated string is evaluated in the window’s context.", "set window title: informative")};',
     'set window title informative'),
    # L3627-3630: OK/Cancel (window title alert) - use preceding stringValue line to disambiguate from tab title
    ('    titleTextField.stringValue = [self.scope valueForVariableName:iTermVariableKeyWindowTitleOverrideFormat] ?: @"";\n    alert.accessoryView = titleTextField;\n    [alert addButtonWithTitle:@"OK"];\n    [alert addButtonWithTitle:@"Cancel"];',
     f'    titleTextField.stringValue = [self.scope valueForVariableName:iTermVariableKeyWindowTitleOverrideFormat] ?: @"";\n    alert.accessoryView = titleTextField;\n    [alert addButtonWithTitle:{NL("OK", "set window title: OK")}];\n    [alert addButtonWithTitle:{NL("Cancel", "set window title: cancel")}];',
     'set window title OK/Cancel'),
    # L8404-8405: Set Tab Title alert
    ('alert.messageText = @"Set Tab Title";',
     f'alert.messageText = {NL("Set Tab Title", "set tab title: alert title")};',
     'set tab title'),
    ('alert.informativeText = @"If this is empty, the tab takes the active session’s title. Variables and function calls enclosed in \\\\(…) will be replaced with their evaluation. This interpolated string is evaluated in the tab’s context.";',
     f'alert.informativeText = {NL("If this is empty, the tab takes the active session’s title. Variables and function calls enclosed in \\(…) will be replaced with their evaluation. This interpolated string is evaluated in the tab’s context.", "set tab title: informative")};',
     'set tab title informative'),
    # L8415-8418: OK/Cancel (tab title alert) - use preceding stringValue line to disambiguate
    ('    titleTextField.stringValue = self.currentTab.variablesScope.tabTitleOverrideFormat ?: @"";\n    alert.accessoryView = titleTextField;\n    [alert addButtonWithTitle:@"OK"];\n    [alert addButtonWithTitle:@"Cancel"];',
     f'    titleTextField.stringValue = self.currentTab.variablesScope.tabTitleOverrideFormat ?: @"";\n    alert.accessoryView = titleTextField;\n    [alert addButtonWithTitle:{NL("OK", "set tab title: OK")}];\n    [alert addButtonWithTitle:{NL("Cancel", "set tab title: cancel")}];',
     'set tab title OK/Cancel'),
    # L8659-8661: tab group informative + OK/Cancel (combined for unique match)
    ('alert.informativeText = @"Enter a name for this tab group.";\n    [alert addButtonWithTitle:@"OK"];\n    [alert addButtonWithTitle:@"Cancel"];',
     f'alert.informativeText = {NL("Enter a name for this tab group.", "tab group rename: informative")};\n    [alert addButtonWithTitle:{NL("OK", "tab group rename: OK")}];\n    [alert addButtonWithTitle:{NL("Cancel", "tab group rename: cancel")}];',
     'tab group informative+OK/Cancel'),
    # L9545-9546: 1 tab / %lu tabs
    ('NSString *count = (closable.count == 1) ? @"1 tab"\n                                            : [NSString stringWithFormat:@"%lu tabs", (unsigned long)closable.count];',
     f'NSString *count = (closable.count == 1) ? {NL("1 tab", "close tabs: singular count")}\n                                            : [NSString stringWithFormat:{NL("%lu tabs", "close tabs: plural count")}, (unsigned long)closable.count];',
     'close tabs count'),
    # L9548-9549: Close Tabs heading + Close/Cancel actions
    ('   heading:@"Close Tabs"',
     f'   heading:{NL("Close Tabs", "close tabs: heading")}',
     'close tabs heading'),
    ('actions:@[ @"Close", @"Cancel" ]',
     f'actions:@[ {NL("Close", "close tabs: close button")}, {NL("Cancel", "close tabs: cancel button")} ]',
     'close tabs actions'),
    # L10252: restart feature warning
    ('[iTermWarning showWarningWithTitle:@"You must restart iTerm2 to turn on this feature."\n                               actions:@[ @"Restart Now", @"Cancel"]',
     f'[iTermWarning showWarningWithTitle:{NL("You must restart iTerm2 to turn on this feature.", "metal capture: restart warning title")}\n                               actions:@[ {NL("Restart Now", "metal capture: restart now button")}, {NL("Cancel", "metal capture: cancel button")}]',
     'metal restart warning'),
    # L4601: detach tmux actions
    ('actions:@[ @"Hide", @"Detach tmux Session", @"Kill", @"Cancel" ]',
     f'actions:@[ {NL("Hide", "close tmux window: hide button")}, {NL("Detach tmux Session", "close tmux window: detach button")}, {NL("Kill", "close tmux window: kill button")}, {NL("Cancel", "close tmux window: cancel button")} ]',
     'detach tmux actions'),
    # L13335-13336: broadcast title format
    ('NSString *title = [NSString stringWithFormat:@"%@ all sessions to which input is broadcast? This will affect %@ sessions.",\n                       action,\n                       @(broadcast.count)];',
     f'NSString *title = [NSString stringWithFormat:{NL("%@ all sessions to which input is broadcast? This will affect %@ sessions.", "broadcast: confirm title")},\n                       action,\n                       @(broadcast.count)];',
     'broadcast title'),
    # L13338: broadcast actions
    ('actions:@[ [NSString stringWithFormat:@"%@ All", action],\n                                          [NSString stringWithFormat:@"%@ Current Session Only", action],\n                                          @"Cancel" ]',
     f'actions:@[ [NSString stringWithFormat:{NL("%@ All", "broadcast: all button")}, action],\n                                          [NSString stringWithFormat:{NL("%@ Current Session Only", "broadcast: current only button")}, action],\n                                          {NL("Cancel", "broadcast: cancel button")} ]',
     'broadcast actions'),
    # L13342: broadcast heading
    ('heading:[NSString stringWithFormat:@"%@ in All Broadcasted-to Sessions?", action]',
     f'heading:[NSString stringWithFormat:{NL("%@ in All Broadcasted-to Sessions?", "broadcast: heading")}, action]',
     'broadcast heading'),
    # L15018-15019: password actions
    ('actions = @[ @"Cancel", @"Enter Password in Sessions at Prompt" ];',
     f'actions = @[ {NL("Cancel", "password prompt: cancel button")}, {NL("Enter Password in Sessions at Prompt", "password prompt: enter password button")} ];',
     'password actions'),
    # L15026: password heading
    ('heading:@"Not all sessions at password prompt"',
     f'heading:{NL("Not all sessions at password prompt", "password prompt: heading")}',
     'password heading'),
])

# ============================================================================
# PTYTab.m
# ============================================================================
wrap_file('sources/TerminalView/PTYTab.m', [
    ('notify:@"Idle"',
     f'notify:{NL("Idle", "tab: idle notification title")}',
     'idle notify title'),
    ('[NSString stringWithFormat:@"Session %@ in tab #%d became idle.",\n                            [[session name] removingHTMLFromTabTitleIfNeeded],\n                            [self tabNumber]]',
     f'[NSString stringWithFormat:{NL("Session %@ in tab #%d became idle.", "tab: idle notification description")},\n                            [[session name] removingHTMLFromTabTitleIfNeeded],\n                            [self tabNumber]]',
     'idle description'),
    ('withDescription:[NSString stringWithFormat:@"New output was received in %@, tab #%d.",\n                                                              [[[self activeSession] name] removingHTMLFromTabTitleIfNeeded],\n                                                              [self tabNumber]]',
     f'withDescription:[NSString stringWithFormat:{NL("New output was received in %@, tab #%d.", "tab: new output notification description")},\n                                                              [[[self activeSession] name] removingHTMLFromTabTitleIfNeeded],\n                                                              [self tabNumber]]',
     'new output description'),
    ('[theTab->tabViewItem_ setLabel:@"Restoring..."];',
     f'[theTab->tabViewItem_ setLabel:{NL("Restoring...", "tab: restoring label")}];',
     'restoring label'),
    ('NSLocalizedDescriptionKey: @"Invalid direction. Should be left, right, above or below."',
     f'NSLocalizedDescriptionKey: {NL("Invalid direction. Should be left, right, above or below.", "select pane: invalid direction error")}',
     'invalid direction error'),
])

# ============================================================================
# PTYTextView.m
# ============================================================================
wrap_file('sources/TerminalView/PTYTextView.m', [
    ('text = [NSString stringWithFormat:@"OK to %@\\n%@@%@:%@?",\n                useSSHIntegration ? @"copy" : @"scp",\n                [files componentsJoinedByString:@", "],\n                path.username, path.hostname, path.path];',
     f'text = [NSString stringWithFormat:{NL("OK to %@\\n%@@%@:%@?", "upload: single file confirm")},\n                useSSHIntegration ? @"copy" : @"scp",\n                [files componentsJoinedByString:@", "],\n                path.username, path.hostname, path.path];',
     'upload single file'),
    ('text = [NSString stringWithFormat:@"OK to %@ the following files:\\n%@\\n\\nto\\n%@@%@:%@?",\n                useSSHIntegration ? @"copy" : @"scp",\n                [files componentsJoinedByString:@", "],\n                path.username, path.hostname, path.path];',
     f'text = [NSString stringWithFormat:{NL("OK to %@ the following files:\\n%@\\n\\nto\\n%@@%@:%@?", "upload: multiple files confirm")},\n                useSSHIntegration ? @"copy" : @"scp",\n                [files componentsJoinedByString:@", "],\n                path.username, path.hostname, path.path];',
     'upload multiple files'),
    ('    [alert addButtonWithTitle:@"OK"];\n    [alert addButtonWithTitle:@"Cancel"];\n    [alert layout];',
     f'    [alert addButtonWithTitle:{NL("OK", "upload: OK button")}];\n    [alert addButtonWithTitle:{NL("Cancel", "upload: cancel button")}];\n    [alert layout];',
     'upload OK/Cancel'),
    ('tooltip:@"Copy block to clipboard"',
     f'tooltip:{NL("Copy block to clipboard", "copy block: tooltip")}',
     'copy block tooltip'),
    ('timestampsButton.title = @"Include timestamps";',
     f'timestampsButton.title = {NL("Include timestamps", "save panel: include timestamps checkbox")};',
     'include timestamps'),
    ('[iTermWarning showWarningWithTitle:@"Really remove annotation?"\n                                                                       actions:@[ @"OK", @"Cancel" ]',
     f'[iTermWarning showWarningWithTitle:{NL("Really remove annotation?", "annotation: remove warning title")}\n                                                                       actions:@[ {NL("OK", "annotation: OK button")}, {NL("Cancel", "annotation: cancel button")} ]',
     'remove annotation warning'),
    ('heading:@"Confirm"',
     f'heading:{NL("Confirm", "annotation: confirm heading")}',
     'annotation confirm heading'),
])

# ============================================================================
# PTYTextView+ARC.m
# ============================================================================
wrap_file('sources/TerminalView/PTYTextView+ARC.m', [
    ('item.title = [NSString stringWithFormat:@"Disconnect from %@", name];',
     f'item.title = [NSString stringWithFormat:{NL("Disconnect from %@", "ssh: disconnect from menu item")}, name];',
     'disconnect from'),
    ('item.title = @"Disconnect";',
     f'item.title = {NL("Disconnect", "ssh: disconnect menu item")};',
     'disconnect'),
    ('item.title = @"Fold/Unfold";',
     f'item.title = {NL("Fold/Unfold", "fold: toggle menu item")};',
     'fold unfold'),
    ('item.title = @"Unfold in Selection";',
     f'item.title = {NL("Unfold in Selection", "fold: unfold in selection menu item")};',
     'unfold in selection'),
    ('item.title = @"Fold Selected Lines";',
     f'item.title = {NL("Fold Selected Lines", "fold: fold selected lines menu item")};',
     'fold selected lines'),
    ('[menu addItemWithTitle:@"Look Up in Dictionary" action:^{',
     f'[menu addItemWithTitle:{NL("Look Up in Dictionary", "context menu: look up dictionary")} action:^{{',
     'look up dictionary'),
    ('[menu addItemWithTitle:@"Quick Look" action:^{',
     f'[menu addItemWithTitle:{NL("Quick Look", "context menu: quick look")} action:^{{',
     'quick look'),
    ('NSString *text = [NSString stringWithFormat:\n                          @"Filename: %@\\n"\n                          @"Dimensions: %d x %d",',
     f'NSString *text = [NSString stringWithFormat:\n                          {NL("Filename: %@\\nDimensions: %d x %d", "image: info alert text")},',
     'image info text'),
    ('        [alert addButtonWithTitle:@"OK"];\n        [alert layout];',
     f'        [alert addButtonWithTitle:{NL("OK", "image info: OK button")}];\n        [alert layout];',
     'image info OK'),
])

# ============================================================================
# SessionTitleView.m
# ============================================================================
wrap_file('sources/TerminalView/SessionTitleView.m', [
    ('accessibilityDescription:@"Pane is locked"',
     f'accessibilityDescription:{NL("Pane is locked", "session title: pane locked accessibility")}',
     'pane locked accessibility'),
    ('[lockButton_ setToolTip:@"This pane is locked. It cannot be moved, swapped, or dragged, and closing it requires confirmation. Right-click to unlock."];',
     f'[lockButton_ setToolTip:{NL("This pane is locked. It cannot be moved, swapped, or dragged, and closing it requires confirmation. Right-click to unlock.", "session title: pane locked tooltip")}];',
     'pane locked tooltip'),
])

# ============================================================================
# PTYNoteView.m
# ============================================================================
wrap_file('sources/TerminalView/PTYNoteView.m', [
    ('accessibilityDescription:@"Delete annotation"',
     f'accessibilityDescription:{NL("Delete annotation", "note view: delete annotation accessibility")}',
     'delete annotation accessibility'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

print(f'\nTotal ObjC replacements applied: {total}')
print('All OK')
