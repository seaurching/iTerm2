# -*- coding: utf-8 -*-
"""Wrap Toolbelt Swift user-visible strings with NSLocalizedString.

Table name: Toolbelt (default Bundle.main)

Files modified:
  sources/Toolbelt/ToolCodecierge.swift
  sources/Toolbelt/ToolStatus.swift
  sources/Toolbelt/StatusPrioritySettings.swift
  sources/Toolbelt/ToolNamedMarks.swift
  sources/Toolbelt/ToolStatusCellView.swift

NOT adapted:
  - AI prompts sent to the LLM (message(forCommand:), contextualInfo,
    "Tell me how to get started.", ChatGPTFunctionDeclaration descriptions)
  - Markdown headings with emoji + interpolation (### 👤 You / 🔮 Assistant / 💻 Terminal)
  - goalLabel = NSTextField(labelWithString: ")")  (debug placeholder, immediately overwritten)
  - NSUserInterfaceItemIdentifier("Pattern"/"Notify")  (internal identifiers)
  - "\(modString)\(ordinal)" shortcut symbol strings (not prose)
  - diagnosis() debug strings (log only)
  - RLog/DLog/log strings
"""
import sys

def W(key, comment):
    """Wrap a plain string literal key."""
    return f'NSLocalizedString("{key}", tableName: "Toolbelt", comment: "{comment}")'

def Wfmt(key, comment, arg):
    """Wrap a format-string interpolation: String(format: NSLocalizedString(...), arg)."""
    return f'String(format: NSLocalizedString("{key}", tableName: "Toolbelt", comment: "{comment}"), {arg})'

edits = []  # (file, old, new, expected, replace_all)

# ============================================================================
# ToolCodecierge.swift
# ============================================================================
C = 'sources/Toolbelt/ToolCodecierge.swift'

edits.append((C,
    'withTitle: "Your codecierge session has been going on for a long time. Are you still using it? If not, stop it to save money and privacy.",',
    'withTitle: ' + W('Your codecierge session has been going on for a long time. Are you still using it? If not, stop it to save money and privacy.', 'codecierge: long-running session warning title') + ',',
    1, False))
edits.append((C,
    'actions: ["Keep Going", "Stop Codecierge"],',
    'actions: [' + W('Keep Going', 'codecierge: keep going button') + ', ' + W('Stop Codecierge', 'codecierge: stop codecierge button') + '],',
    1, False))
edits.append((C,
    'heading: "Codecierge Usage Warning",',
    'heading: ' + W('Codecierge Usage Warning', 'codecierge: usage warning heading') + ',',
    1, False))
edits.append((C,
    'delegate?.session(session: self, didProduceText: "There was an error: \\(error.localizedDescription)")',
    'delegate?.session(session: self, didProduceText: ' + Wfmt('There was an error: %@', 'codecierge: error message shown in suggestion view', 'error.localizedDescription') + ')',
    1, False))
edits.append((C,
    'delegate?.session(session: self, didProduceAdditionalText: "There was an error: \\(error.localizedDescription)")',
    'delegate?.session(session: self, didProduceAdditionalText: ' + Wfmt('There was an error: %@', 'codecierge: error message shown in suggestion view', 'error.localizedDescription') + ')',
    1, False))
edits.append((C,
    'session.suggestion = "Thinking…"',
    'session.suggestion = ' + W('Thinking…', 'codecierge: thinking placeholder'),
    1, False))
edits.append((C,
    'private let originalLabelText = "Codecierge uses AI to help you in your terminal."',
    'private let originalLabelText = ' + W('Codecierge uses AI to help you in your terminal.', 'codecierge: onboarding label text'),
    1, False))
edits.append((C,
    'startButton = NSButton(title: "Get Started", target: nil, action: nil)',
    'startButton = NSButton(title: ' + W('Get Started', 'codecierge: get started button title') + ', target: nil, action: nil)',
    1, False))
edits.append((C,
    'revealButton = NSButton(title: "Reveal Setting", target: nil, action: nil)',
    'revealButton = NSButton(title: ' + W('Reveal Setting', 'codecierge: reveal setting button title') + ', target: nil, action: nil)',
    1, False))
edits.append((C,
    'label.stringValue = "Generative AI has been disabled by the system administrator."',
    'label.stringValue = ' + W('Generative AI has been disabled by the system administrator.', 'codecierge: ai disabled by admin label'),
    1, False))
edits.append((C,
    'label.stringValue = "You must enable AI features to use Codecierge."',
    'label.stringValue = ' + W('You must enable AI features to use Codecierge.', 'codecierge: must enable ai label'),
    1, False))
edits.append((C,
    'label = NSTextField(labelWithString: "What are you trying to do? I\'ll suggest commands and explain their output.")',
    'label = NSTextField(labelWithString: ' + W("What are you trying to do? I'll suggest commands and explain their output.", 'codecierge: goal prompt label') + ')',
    1, False))
edits.append((C,
    'textView.it_placeholderString = "I want to…"',
    'textView.it_placeholderString = ' + W('I want to…', 'codecierge: goal placeholder'),
    1, False))
edits.append((C,
    'autoButton.title = "Run commands automatically"',
    'autoButton.title = ' + W('Run commands automatically', 'codecierge: run commands automatically checkbox title'),
    1, False))
edits.append((C,
    'startButton = NSButton(title: "Start", target: nil, action: nil)',
    'startButton = NSButton(title: ' + W('Start', 'codecierge: start button title') + ', target: nil, action: nil)',
    1, False))
edits.append((C,
    'withTitle: "This lets an AI completely control your computer. It could delete your files, do something stupid or dangerous, or lead to the downfall of humanity. Proceed with caution.",',
    'withTitle: ' + W('This lets an AI completely control your computer. It could delete your files, do something stupid or dangerous, or lead to the downfall of humanity. Proceed with caution.', 'codecierge: ai control danger warning title') + ',',
    1, False))
edits.append((C,
    'actions: [ "OK", "Cancel" ],',
    'actions: [ ' + W('OK', 'codecierge: warning ok button') + ', ' + W('Cancel', 'codecierge: warning cancel button') + ' ],',
    2, True))
edits.append((C,
    'heading: "Danger!",',
    'heading: ' + W('Danger!', 'codecierge: danger heading') + ',',
    1, False))
edits.append((C,
    'withTitle: "Everything that happens in your terminal while Codecierge is running will be sent to your AI provider. Don\'t send them confidential information!",',
    'withTitle: ' + W("Everything that happens in your terminal while Codecierge is running will be sent to your AI provider. Don't send them confidential information!", 'codecierge: privacy warning title') + ',',
    1, False))
edits.append((C,
    'heading: "Privacy Warning",',
    'heading: ' + W('Privacy Warning', 'codecierge: privacy warning heading') + ',',
    1, False))
edits.append((C,
    'goalLabel.stringValue = "Goal: " + newValue',
    'goalLabel.stringValue = ' + W('Goal: ', 'codecierge: goal label prefix') + ' + newValue',
    1, False))
edits.append((C,
    'endButton = NSButton(title: "End Task", target: nil, action: nil)',
    'endButton = NSButton(title: ' + W('End Task', 'codecierge: end task button title') + ', target: nil, action: nil)',
    1, False))
edits.append((C,
    'replyTextField.placeholderString = "Response"',
    'replyTextField.placeholderString = ' + W('Response', 'codecierge: reply placeholder'),
    1, False))
edits.append((C,
    'accessibilityDescription: "Send reply"',
    'accessibilityDescription: ' + W('Send reply', 'codecierge: send reply button accessibility'),
    1, False))
edits.append((C,
    'replyButton.stringValue = "Send"',
    'replyButton.stringValue = ' + W('Send', 'codecierge: send button title fallback'),
    1, False))

# ============================================================================
# ToolStatus.swift
# ============================================================================
TS = 'sources/Toolbelt/ToolStatus.swift'

edits.append((TS,
    'accessibilityDescription: "Settings")',
    'accessibilityDescription: ' + W('Settings', 'tool status: settings button accessibility') + ')',
    1, False))
# helpMarkdown: wrap the multi-line string literal with NSLocalizedString
edits.append((TS,
    '    static let helpMarkdown = """',
    '    static let helpMarkdown = NSLocalizedString("""',
    1, False))
edits.append((TS,
    '    """\n}',
    '    """, tableName: "Toolbelt", comment: "tool status: help markdown text")\n}',
    1, False))
edits.append((TS,
    'accessibilityDescription: "Notify on status change")',
    'accessibilityDescription: ' + W('Notify on status change', 'tool status: notify button accessibility') + ')',
    1, False))
edits.append((TS,
    '? "Watching the selected session for a status change. An alert will appear on the next change, then turn this off."',
    '? ' + W('Watching the selected session for a status change. An alert will appear on the next change, then turn this off.', 'tool status: watching selected session tooltip'),
    1, False))
edits.append((TS,
    ': "Watching this window for a session status change. An alert will appear on the next change, then turn this off."',
    ': ' + W('Watching this window for a session status change. An alert will appear on the next change, then turn this off.', 'tool status: watching window tooltip'),
    1, False))
edits.append((TS,
    '? "Notify with an alert when the selected session’s status changes."',
    '? ' + W('Notify with an alert when the selected session’s status changes.', 'tool status: notify selected session tooltip'),
    1, False))
edits.append((TS,
    ': "Notify with an alert when any session in this window changes status."',
    ': ' + W('Notify with an alert when any session in this window changes status.', 'tool status: notify any session tooltip'),
    1, False))
edits.append((TS,
    'return "Pane \\(ordinal)"',
    'return ' + Wfmt('Pane %ld', 'tool status: pane shortcut label', 'ordinal'),
    1, False))
edits.append((TS,
    'return "Tab \\(tabIndex)"',
    'return ' + Wfmt('Tab %ld', 'tool status: tab shortcut label', 'tabIndex'),
    1, False))
edits.append((TS,
    'let item = NSMenuItem(title: "Snooze",',
    'let item = NSMenuItem(title: ' + W('Snooze', 'tool status: snooze menu item') + ',',
    1, False))

# ============================================================================
# StatusPrioritySettings.swift
# ============================================================================
SP = 'sources/Toolbelt/StatusPrioritySettings.swift'

edits.append((SP,
    'alert.messageText = "New Priority Pattern"',
    'alert.messageText = ' + W('New Priority Pattern', 'status priority: new pattern alert title'),
    1, False))
edits.append((SP,
    'alert.informativeText = "Enter a substring to match against status text (case-insensitive)."',
    'alert.informativeText = ' + W('Enter a substring to match against status text (case-insensitive).', 'status priority: new pattern alert info'),
    1, False))
edits.append((SP,
    'alert.addButton(withTitle: "OK")',
    'alert.addButton(withTitle: ' + W('OK', 'status priority: new pattern alert ok button') + ')',
    1, False))
edits.append((SP,
    'alert.addButton(withTitle: "Cancel")',
    'alert.addButton(withTitle: ' + W('Cancel', 'status priority: new pattern alert cancel button') + ')',
    1, False))
edits.append((SP,
    'let label = NSTextField(wrappingLabelWithString: "Statuses are sorted by priority. Items near the top have higher priority. Drag to reorder. Click to edit.")',
    'let label = NSTextField(wrappingLabelWithString: ' + W('Statuses are sorted by priority. Items near the top have higher priority. Drag to reorder. Click to edit.', 'status priority: instructional label') + ')',
    1, False))
edits.append((SP,
    'let toggle = NSButton(checkboxWithTitle: "Show status in tab subtitle",',
    'let toggle = NSButton(checkboxWithTitle: ' + W('Show status in tab subtitle', 'status priority: show subtitle checkbox title') + ',',
    1, False))
edits.append((SP,
    'let mergeToggle = NSButton(checkboxWithTitle: "Merge workgroup statuses",',
    'let mergeToggle = NSButton(checkboxWithTitle: ' + W('Merge workgroup statuses', 'status priority: merge workgroup checkbox title') + ',',
    1, False))
edits.append((SP,
    'mergeToggle.toolTip = "When enabled, only the most recent status from each workgroup is shown."',
    'mergeToggle.toolTip = ' + W('When enabled, only the most recent status from each workgroup is shown.', 'status priority: merge workgroup tooltip'),
    1, False))
edits.append((SP,
    'accessibilityDescription: "Add")!',
    'accessibilityDescription: ' + W('Add', 'status priority: add button accessibility') + ')!',
    1, False))
edits.append((SP,
    'accessibilityDescription: "Remove")!',
    'accessibilityDescription: ' + W('Remove', 'status priority: remove button accessibility') + ')!',
    1, False))
edits.append((SP,
    'patternColumn.title = "Pattern"',
    'patternColumn.title = ' + W('Pattern', 'status priority: pattern column title'),
    1, False))
edits.append((SP,
    'notifyColumn.title = "Notify"',
    'notifyColumn.title = ' + W('Notify', 'status priority: notify column title'),
    1, False))

# ============================================================================
# ToolNamedMarks.swift
# ============================================================================
NM = 'sources/Toolbelt/ToolNamedMarks.swift'

edits.append((NM,
    'title: "Add",',
    'title: ' + W('Add', 'tool named marks: add button title accessibility') + ',',
    1, False))
edits.append((NM,
    'title: "Remove",',
    'title: ' + W('Remove', 'tool named marks: remove button title accessibility') + ',',
    1, False))
edits.append((NM,
    'title: "Edit",',
    'title: ' + W('Edit', 'tool named marks: edit button title accessibility') + ',',
    1, False))
edits.append((NM,
    'string: marks[row].name ?? "(Unnamed)"',
    'string: marks[row].name ?? ' + W('(Unnamed)', 'tool named marks: unnamed mark placeholder'),
    1, False))

# ============================================================================
# ToolStatusCellView.swift
# ============================================================================
SC = 'sources/Toolbelt/ToolStatusCellView.swift'

edits.append((SC,
    'accessibilityDescription: "Notify on status change armed")?',
    'accessibilityDescription: ' + W('Notify on status change armed', 'tool status cell: armed bell accessibility') + ')?',
    1, False))
edits.append((SC,
    'accessibilityDescription: "Snoozed")?',
    'accessibilityDescription: ' + W('Snoozed', 'tool status cell: snoozed icon accessibility') + ')?',
    1, False))

# ============================================================================
# Apply
# ============================================================================
errs = []
file_contents = {}
for f in sorted(set(e[0] for e in edits)):
    file_contents[f] = open(f, encoding='utf-8').read()

for (f, old, new, expected, replace_all) in edits:
    c = file_contents[f].count(old)
    if c != expected:
        errs.append(f'{f}: expected {expected}, got {c} for:\n  {old[:140]!r}')
        continue
    if replace_all:
        file_contents[f] = file_contents[f].replace(old, new)
    else:
        file_contents[f] = file_contents[f].replace(old, new, 1)

if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

for f in sorted(set(e[0] for e in edits)):
    open(f, 'w', encoding='utf-8').write(file_contents[f])

n_replacements = sum(e[3] for e in edits)
print(f'All Toolbelt Swift wraps OK: {n_replacements} replacements across {len(file_contents)} files')
