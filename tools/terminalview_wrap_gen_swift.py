# -*- coding: utf-8 -*-
"""Wrap 6 Swift files in sources/TerminalView/ with NSLocalizedString(tableName: "TerminalView").

Files:
  CommandInfoViewController.swift  - 7 sites
  TerminalButton.swift            - 9 sites (10 keys; L505 has 2)
  PseudoTerminal.swift            - 1 site
  SelectSessionButton.swift       - 1 site
  iTermUploadIndicator.swift      - 1 site
  iTermLayoutMutator.swift        - 7 sites (errorDescription; interpolated ones -> String(format:))

Interpolated strings (\(guid)) are converted to String(format: NSLocalizedString(...), guid).
"""
import os, sys

T = 'TerminalView'
errs = []
total = 0

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def NL(key, comment):
    return f'NSLocalizedString("{esc(key)}", tableName: "{T}", comment: "{esc(comment)}")'

def FMT(key, comment):
    # Returns String(format: NSLocalizedString(...) with the String( paren left OPEN;
    # caller appends ", arg)" to close it.
    return f'String(format: NSLocalizedString("{esc(key)}", tableName: "{T}", comment: "{esc(comment)}")'

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
# CommandInfoViewController.swift
# ============================================================================
wrap_file('sources/TerminalView/CommandInfoViewController.swift', [
    ('returnCode.stringValue = "Still Running"',
     f'returnCode.stringValue = {NL("Still Running", "command info: return code still running")}',
     'still running'),
    ('runningTime.stringValue = "Unknown"',
     f'runningTime.stringValue = {NL("Unknown", "command info: running time unknown")}',
     'unknown running time'),
    ('startedAt.stringValue = "Started at " + formattedDate(_startDate)',
     f'startedAt.stringValue = {FMT("Started at %@", "command info: started at")}, formattedDate(_startDate))',
     'started at'),
    ('menu.addItem(title: "Add Command as Snippet") {',
     f'menu.addItem(title: {NL("Add Command as Snippet", "command info: add command as snippet menu")}) {{',
     'add command as snippet'),
    ('ToastWindowController.showToast(withMessage: "Snippet Added",',
     f'ToastWindowController.showToast(withMessage: {NL("Snippet Added", "command info: snippet added toast")},',
     'snippet added toast'),
    ('menu.addItem(title: "Copy Command URL to Clipboard") {',
     f'menu.addItem(title: {NL("Copy Command URL to Clipboard", "command info: copy command url menu")}) {{',
     'copy command url'),
    ('menu.addItem(title: "Open Share Sheet…") {',
     f'menu.addItem(title: {NL("Open Share Sheet…", "command info: open share sheet menu")}) {{',
     'open share sheet'),
])

# ============================================================================
# TerminalButton.swift
# ============================================================================
wrap_file('sources/TerminalView/TerminalButton.swift', [
    ('tooltip: "Reveal embedded command")',
     f'tooltip: {NL("Reveal embedded command", "terminal button: reveal embedded command tooltip")})',
     'reveal embedded command'),
    ('tooltip: currentlyFolded ? "Unfold block" : "Fold block")',
     f'tooltip: currentlyFolded ? {NL("Unfold block", "terminal button: unfold block tooltip")} : {NL("Fold block", "terminal button: fold block tooltip")})',
     'unfold/fold block'),
    ('tooltip: "Copy command to clipboard")',
     f'tooltip: {NL("Copy command to clipboard", "terminal button: copy command tooltip")})',
     'copy command tooltip'),
    ('tooltip: "Toggle named mark")',
     f'tooltip: {NL("Toggle named mark", "terminal button: toggle named mark tooltip")})',
     'toggle named mark'),
    ('tooltip: "Share command…")',
     f'tooltip: {NL("Share command…", "terminal button: share command tooltip")})',
     'share command tooltip'),
    ('tooltip: "Open Command Info…")',
     f'tooltip: {NL("Open Command Info…", "terminal button: open command info tooltip")})',
     'open command info tooltip'),
    ('tooltip: "Fold command")',
     f'tooltip: {NL("Fold command", "terminal button: fold command tooltip")})',
     'fold command tooltip'),
    ('tooltip: "Unfold command")',
     f'tooltip: {NL("Unfold command", "terminal button: unfold command tooltip")})',
     'unfold command tooltip'),
    ('tooltip: "Command Settings…")',
     f'tooltip: {NL("Command Settings…", "terminal button: command settings tooltip")})',
     'command settings tooltip'),
])

# ============================================================================
# PseudoTerminal.swift
# ============================================================================
wrap_file('sources/TerminalView/PseudoTerminal.swift', [
    ('button.title = "Default Picker"',
     f'button.title = {NL("Default Picker", "color picker: default picker button title")}',
     'default picker'),
])

# ============================================================================
# SelectSessionButton.swift
# ============================================================================
wrap_file('sources/TerminalView/SelectSessionButton.swift', [
    ('private let button = NSButton(title: "Select this Session", target: nil, action: nil)',
     f'private let button = NSButton(title: {NL("Select this Session", "select session button: title")}, target: nil, action: nil)',
     'select this session'),
])

# ============================================================================
# iTermUploadIndicator.swift
# ============================================================================
wrap_file('sources/TerminalView/iTermUploadIndicator.swift', [
    ('cancelButton.title = "Cancel"',
     f'cancelButton.title = {NL("Cancel", "upload indicator: cancel button")}',
     'upload cancel'),
])

# ============================================================================
# iTermLayoutMutator.swift  (errorDescription -> LocalizedError)
# ============================================================================
wrap_file('sources/TerminalView/iTermLayoutMutator.swift', [
    ('return "Creating new tabs or windows via apply_layout is not supported."',
     f'return {NL("Creating new tabs or windows via apply_layout is not supported.", "layout mutator: new tab or window not supported")}',
     'newTabOrWindowNotSupported'),
    ('return "Unknown session: \\(guid)"',
     f'return {FMT("Unknown session: %@", "layout mutator: unknown session")}, guid)',
     'unknownSession'),
    ('return "Unknown tab: \\(guid)"',
     f'return {FMT("Unknown tab: %@", "layout mutator: unknown tab")}, guid)',
     'unknownTab'),
    ('return "Unknown window: \\(guid)"',
     f'return {FMT("Unknown window: %@", "layout mutator: unknown window")}, guid)',
     'unknownWindow'),
    ('return "Unknown profile: \\(guid)"',
     f'return {FMT("Unknown profile: %@", "layout mutator: unknown profile")}, guid)',
     'unknownProfile'),
    ('return "Cannot create a new session: there is no existing window to size it against."',
     f'return {NL("Cannot create a new session: there is no existing window to size it against.", "layout mutator: no context for new session")}',
     'noContextForNewSession'),
    ('return "Session \\(guid) has no owning tab"',
     f'return {FMT("Session %@ has no owning tab", "layout mutator: session without owning tab")}, guid)',
     'sessionWithoutOwningTab'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

print(f'\nTotal Swift replacements applied: {total}')
print('All OK')
