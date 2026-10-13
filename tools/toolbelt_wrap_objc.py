# -*- coding: utf-8 -*-
"""Wrap Toolbelt ObjC user-visible strings with NSLocalizedStringFromTableInBundle.

Table name: Toolbelt
Bundle: [NSBundle bundleForClass:[self class]]

Files modified:
  sources/Toolbelt/iTermToolActions.m
  sources/Toolbelt/iTermToolbeltView.m
  sources/Toolbelt/iTermToolSnippets.m
  sources/Toolbelt/ToolProfiles.m
  sources/Toolbelt/ToolPasteHistory.m
  sources/Toolbelt/ToolCommandHistoryView.m
  sources/Toolbelt/ToolDirectoriesView.m
  sources/Toolbelt/ToolNotes.m

NOT adapted (logical identifiers):
  - Tool name constants kXxxToolName (used as gRegisteredTools dict keys,
    UserDefaults values, identifier construction; toggleToolbeltTool: uses
    [menuItem title] as logical key via toggleShouldShowTool:)
  - defaultTools @"Profiles" literal (must match kProfilesToolName value)
"""
import sys

B = 'NSLocalizedStringFromTableInBundle'
BUNDLE = '[NSBundle bundleForClass:[self class]]'

def wrap(literal, comment):
    """Return the wrapped form of an @\"literal\" token."""
    return f'{B}({literal}, @"Toolbelt", {BUNDLE}, @"{comment}")'

edits = []

# ============================================================================
# iTermToolActions.m
# ============================================================================
A = 'sources/Toolbelt/iTermToolActions.m'

edits.append((A,
    'iTermToolActionsNewButton(@"play", @"Apply", self, @selector(apply:), frame)',
    'iTermToolActionsNewButton(@"play", ' + wrap('@"Apply"', 'tool actions: apply button accessibility') + ', self, @selector(apply:), frame)',
    1))
edits.append((A,
    'iTermToolActionsNewButton(@"plus", @"Add", self, @selector(add:), frame)',
    'iTermToolActionsNewButton(@"plus", ' + wrap('@"Add"', 'tool actions: add button accessibility') + ', self, @selector(add:), frame)',
    1))
edits.append((A,
    'iTermToolActionsNewButton(@"minus", @"Remove", self, @selector(remove:), frame)',
    'iTermToolActionsNewButton(@"minus", ' + wrap('@"Remove"', 'tool actions: remove button accessibility') + ', self, @selector(remove:), frame)',
    1))
edits.append((A,
    'iTermToolActionsNewButton(@"pencil", @"Edit", self, @selector(edit:), frame)',
    'iTermToolActionsNewButton(@"pencil", ' + wrap('@"Edit"', 'tool actions: edit button accessibility') + ', self, @selector(edit:), frame)',
    1))
edits.append((A,
    'iTermToolActionsNewButton(nil, @"Apply", self, @selector(apply:), frame)',
    'iTermToolActionsNewButton(nil, ' + wrap('@"Apply"', 'tool actions: apply button title fallback') + ', self, @selector(apply:), frame)',
    1))
edits.append((A,
    'return @"Untitled";',
    'return ' + wrap('@"Untitled"', 'tool actions: untitled action name') + ';',
    1))

# ============================================================================
# iTermToolbeltView.m  (tool name constants NOT adapted — logical identifiers)
# ============================================================================
V = 'sources/Toolbelt/iTermToolbeltView.m'

edits.append((V,
    '_noToolsMessage.stringValue = @"No Tools enabled. Select them from the menu above.";',
    '_noToolsMessage.stringValue = ' + wrap('@"No Tools enabled. Select them from the menu above."', 'toolbelt: no tools message label') + ';',
    1))
edits.append((V,
    'NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];',
    'NSMenu *menu = [[NSMenu alloc] initWithTitle:' + wrap('@"Contextual Menu"', 'toolbelt: contextual menu title') + '];',
    1))

# ============================================================================
# iTermToolSnippets.m
# ============================================================================
S = 'sources/Toolbelt/iTermToolSnippets.m'

edits.append((S,
    'accessibilityDescription:@"Snippet icon"',
    'accessibilityDescription:' + wrap('@"Snippet icon"', 'tool snippets: snippet icon accessibility'),
    1))
edits.append((S,
    'accessibilityDescription:@"Folder icon"',
    'accessibilityDescription:' + wrap('@"Folder icon"', 'tool snippets: folder icon accessibility'),
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(@"play", @"Send", self, @selector(apply:), frame)',
    'iTermToolSnippetsNewButton(@"play", ' + wrap('@"Send"', 'tool snippets: send button accessibility') + ', self, @selector(apply:), frame)',
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(@"plus", @"Add", self, @selector(add:), frame)',
    'iTermToolSnippetsNewButton(@"plus", ' + wrap('@"Add"', 'tool snippets: add button accessibility') + ', self, @selector(add:), frame)',
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(@"minus", @"Remove", self, @selector(remove:), frame)',
    'iTermToolSnippetsNewButton(@"minus", ' + wrap('@"Remove"', 'tool snippets: remove button accessibility') + ', self, @selector(remove:), frame)',
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(@"square.and.pencil", @"Edit", self, @selector(edit:), frame)',
    'iTermToolSnippetsNewButton(@"square.and.pencil", ' + wrap('@"Edit"', 'tool snippets: edit button accessibility') + ', self, @selector(edit:), frame)',
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(@"rectangle.and.pencil.and.ellipsis", @"Open in Advanced Paste", self, @selector(openInAdvancedPaste:), frame)',
    'iTermToolSnippetsNewButton(@"rectangle.and.pencil.and.ellipsis", ' + wrap('@"Open in Advanced Paste"', 'tool snippets: open in advanced paste button accessibility') + ', self, @selector(openInAdvancedPaste:), frame)',
    1))
edits.append((S,
    'iTermToolSnippetsNewButton(nil, @"Send", self, @selector(apply:), frame)',
    'iTermToolSnippetsNewButton(nil, ' + wrap('@"Send"', 'tool snippets: send button title fallback') + ', self, @selector(apply:), frame)',
    1))
edits.append((S,
    'initWithTitle:@"Send Snippet"',
    'initWithTitle:' + wrap('@"Send Snippet"', 'tool snippets: send snippet action title'),
    1))
edits.append((S,
    '}] ?: @"Untitled";',
    '}] ?: ' + wrap('@"Untitled"', 'tool snippets: untitled snippet name') + ';',
    1))

# ============================================================================
# ToolProfiles.m
# ============================================================================
P = 'sources/Toolbelt/ToolProfiles.m'

edits.append((P,
    'accessibilityDescription:@"Open Profile"',
    'accessibilityDescription:' + wrap('@"Open Profile"', 'tool profiles: open profile button accessibility'),
    1))
edits.append((P,
    '[_openButton setTitle:@"Open"];',
    '[_openButton setTitle:' + wrap('@"Open"', 'tool profiles: open button title fallback') + '];',
    1))
edits.append((P,
    '[[popup_ menu] addItemWithTitle:@"New Tab"',
    '[[popup_ menu] addItemWithTitle:' + wrap('@"New Tab"', 'tool profiles: new tab menu item'),
    1))
edits.append((P,
    '[[popup_ menu] addItemWithTitle:@"New Window"',
    '[[popup_ menu] addItemWithTitle:' + wrap('@"New Window"', 'tool profiles: new window menu item'),
    1))
edits.append((P,
    '[[popup_ menu] addItemWithTitle:@"New Horizontal Split"',
    '[[popup_ menu] addItemWithTitle:' + wrap('@"New Horizontal Split"', 'tool profiles: new horizontal split menu item'),
    1))
edits.append((P,
    '[[popup_ menu] addItemWithTitle:@"New Vertical Split"',
    '[[popup_ menu] addItemWithTitle:' + wrap('@"New Vertical Split"', 'tool profiles: new vertical split menu item'),
    1))

# ============================================================================
# ToolPasteHistory.m
# ============================================================================
PH = 'sources/Toolbelt/ToolPasteHistory.m'

edits.append((PH,
    'accessibilityDescription:@"Delete All"',
    'accessibilityDescription:' + wrap('@"Delete All"', 'tool paste history: delete all button accessibility'),
    1))
edits.append((PH,
    '[clear_ setTitle:@"Clear All"];',
    '[clear_ setTitle:' + wrap('@"Clear All"', 'tool paste history: clear all button title fallback') + '];',
    1))
edits.append((PH,
    '_secureKeyboardEntryWarning.stringValue = @"⚠️ Secure keyboard entry disables paste history.";',
    '_secureKeyboardEntryWarning.stringValue = ' + wrap('@"⚠️ Secure keyboard entry disables paste history."', 'tool paste history: secure keyboard entry warning label') + ';',
    1))
edits.append((PH,
    'item = [[NSMenuItem alloc] initWithTitle:@"Copy"',
    'item = [[NSMenuItem alloc] initWithTitle:' + wrap('@"Copy"', 'tool paste history: copy menu item'),
    1))
edits.append((PH,
    'item = [[NSMenuItem alloc] initWithTitle:@"Open in Advanced Paste"',
    'item = [[NSMenuItem alloc] initWithTitle:' + wrap('@"Open in Advanced Paste"', 'tool paste history: open in advanced paste menu item'),
    1))
edits.append((PH,
    'alert.messageText = @"Erase Paste History";',
    'alert.messageText = ' + wrap('@"Erase Paste History"', 'tool paste history: erase paste history alert title') + ';',
    1))
edits.append((PH,
    'alert.informativeText = @"Paste history will be erased. Continue?";',
    'alert.informativeText = ' + wrap('@"Paste history will be erased. Continue?"', 'tool paste history: erase paste history alert info') + ';',
    1))
edits.append((PH,
    '[alert addButtonWithTitle:@"OK"];',
    '[alert addButtonWithTitle:' + wrap('@"OK"', 'tool paste history: erase alert ok button') + '];',
    1))
edits.append((PH,
    '[alert addButtonWithTitle:@"Cancel"];',
    '[alert addButtonWithTitle:' + wrap('@"Cancel"', 'tool paste history: erase alert cancel button') + '];',
    1))

# ============================================================================
# ToolCommandHistoryView.m
# ============================================================================
CH = 'sources/Toolbelt/ToolCommandHistoryView.m'

edits.append((CH,
    'accessibilityDescription:@"Clear"',
    'accessibilityDescription:' + wrap('@"Clear"', 'tool command history: clear button accessibility'),
    1))
edits.append((CH,
    '[clear_ setTitle:@"Clear All"];',
    '[clear_ setTitle:' + wrap('@"Clear All"', 'tool command history: clear all button title fallback') + '];',
    1))
edits.append((CH,
    'alert.messageText = @"Erase Command History";',
    'alert.messageText = ' + wrap('@"Erase Command History"', 'tool command history: erase command history alert title') + ';',
    1))
edits.append((CH,
    'alert.informativeText = @"Command history for all hosts will be erased. Continue?";',
    'alert.informativeText = ' + wrap('@"Command history for all hosts will be erased. Continue?"', 'tool command history: erase alert info') + ';',
    1))
edits.append((CH,
    '[alert addButtonWithTitle:@"OK"];',
    '[alert addButtonWithTitle:' + wrap('@"OK"', 'tool command history: erase alert ok button') + '];',
    1))
edits.append((CH,
    '[alert addButtonWithTitle:@"Cancel"];',
    '[alert addButtonWithTitle:' + wrap('@"Cancel"', 'tool command history: erase alert cancel button') + '];',
    1))

# ============================================================================
# ToolDirectoriesView.m
# ============================================================================
D = 'sources/Toolbelt/ToolDirectoriesView.m'

edits.append((D,
    'accessibilityDescription:@"Clear"',
    'accessibilityDescription:' + wrap('@"Clear"', 'tool directories: clear button accessibility'),
    1))
edits.append((D,
    '[clear_ setTitle:@"Clear All"];',
    '[clear_ setTitle:' + wrap('@"Clear All"', 'tool directories: clear all button title fallback') + '];',
    1))
edits.append((D,
    'item = [[NSMenuItem alloc] initWithTitle:@"Toggle Star"',
    'item = [[NSMenuItem alloc] initWithTitle:' + wrap('@"Toggle Star"', 'tool directories: toggle star menu item'),
    1))
edits.append((D,
    'alert.messageText = @"Erase Saved Directories?";',
    'alert.messageText = ' + wrap('@"Erase Saved Directories?"', 'tool directories: erase saved directories alert title') + ';',
    1))
edits.append((D,
    '[alert addButtonWithTitle:@"OK"];',
    '[alert addButtonWithTitle:' + wrap('@"OK"', 'tool directories: erase alert ok button') + '];',
    1))
edits.append((D,
    '[alert addButtonWithTitle:@"Cancel"];',
    '[alert addButtonWithTitle:' + wrap('@"Cancel"', 'tool directories: erase alert cancel button') + '];',
    1))

# ============================================================================
# ToolNotes.m
# ============================================================================
N = 'sources/Toolbelt/ToolNotes.m'

edits.append((N,
    'modeControl_ = [NSSegmentedControl segmentedControlWithLabels:@[@"Global", @"Session"]',
    'modeControl_ = [NSSegmentedControl segmentedControlWithLabels:@['
    + wrap('@"Global"', 'tool notes: global segment label') + ', '
    + wrap('@"Session"', 'tool notes: session segment label') + ']',
    1))

# ============================================================================
# Apply
# ============================================================================
errs = []
file_contents = {}
for f in sorted(set(e[0] for e in edits)):
    file_contents[f] = open(f, encoding='utf-8').read()

for (f, old, new, expected) in edits:
    c = file_contents[f].count(old)
    if c != expected:
        errs.append(f'{f}: expected {expected}, got {c} for:\n  {old[:140]!r}')
        continue
    file_contents[f] = file_contents[f].replace(old, new)

if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

for f in sorted(set(e[0] for e in edits)):
    open(f, 'w', encoding='utf-8').write(file_contents[f])

print(f'All Toolbelt ObjC wraps OK: {len(edits)} edits across {len(file_contents)} files')
