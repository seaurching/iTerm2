# -*- coding: utf-8 -*-
"""Wrap tmux directory user-visible strings with NSLocalizedStringFromTableInBundle.

Table name: tmux
Bundle: [NSBundle bundleForClass:[self class]]  (all call sites are instance methods)

Files modified:
  sources/tmux/TmuxGateway.m
  sources/tmux/TmuxWindowOpener.m
  sources/tmux/TmuxWindowsTable.m
  sources/tmux/TmuxSessionsTable.m
  sources/tmux/TmuxController.m

Each replacement is verified to occur exactly `expected` times before applying.
"""
import sys

B = 'NSLocalizedStringFromTableInBundle'
BUNDLE = '[NSBundle bundleForClass:[self class]]'

def wrap(literal, comment):
    """Return the wrapped form of an @\"literal\" token."""
    return f'{B}({literal}, @"tmux", {BUNDLE}, @"{comment}")'

# (file, old, new, expected)
edits = []

# ============================================================================
# TmuxGateway.m
# ============================================================================
G = 'sources/tmux/TmuxGateway.m'

# L126: default abort title
edits.append((G,
    'title:@"tmux Reported a Problem"',
    'title:' + wrap('@"tmux Reported a Problem"', 'tmux gateway: abort alert title'),
    1))

# L136: OK button in abort alert
edits.append((G,
    '[alert addButtonWithTitle:@"OK"]',
    '[alert addButtonWithTitle:' + wrap('@"OK"', 'tmux gateway: abort alert ok button') + ']',
    1))

# L259: malformed num data
edits.append((G,
    '@"Malformed command (expected %%num data): \\"%s\\""',
    wrap('@"Malformed command (expected %%num data): \\"%s\\""', 'tmux gateway: malformed command num data'),
    1))

# L341: malformed layout-change
edits.append((G,
    '@"Malformed command (expected %%layout-change <window> <layout> [<window_visible_layout> <window_flags>]): \\"%@\\""',
    wrap('@"Malformed command (expected %%layout-change <window> <layout> [<window_visible_layout> <window_flags>]): \\"%@\\""', 'tmux gateway: malformed command layout-change'),
    1))

# L364: malformed window-add
edits.append((G,
    '@"Malformed command (expected %%window-add id): \\"%@\\""',
    wrap('@"Malformed command (expected %%window-add id): \\"%@\\""', 'tmux gateway: malformed command window-add'),
    1))

# L374: malformed window-close
edits.append((G,
    '@"Malformed command (expected %%window-close id): \\"%@\\""',
    wrap('@"Malformed command (expected %%window-close id): \\"%@\\""', 'tmux gateway: malformed command window-close'),
    1))

# L384: malformed window-renamed
edits.append((G,
    '@"Malformed command (expected %%window-renamed id new_name): \\"%@\\""',
    wrap('@"Malformed command (expected %%window-renamed id new_name): \\"%@\\""', 'tmux gateway: malformed command window-renamed'),
    1))

# L397: malformed session-renamed
edits.append((G,
    '@"Malformed command (expected %%session-renamed id name): \\"%@\\""',
    wrap('@"Malformed command (expected %%session-renamed id name): \\"%@\\""', 'tmux gateway: malformed command session-renamed'),
    1))

# L407: malformed session-changed
edits.append((G,
    '@"Malformed command (expected %%session-changed id name): \\"%@\\""',
    wrap('@"Malformed command (expected %%session-changed id name): \\"%@\\""', 'tmux gateway: malformed command session-changed'),
    1))

# L422: malformed sessions-changed
edits.append((G,
    '@"Malformed command (expected %%sessions-changed): \\"%@\\""',
    wrap('@"Malformed command (expected %%sessions-changed): \\"%@\\""', 'tmux gateway: malformed command sessions-changed'),
    1))

# L431: malformed window-pane-changed
edits.append((G,
    '@"Malformed command (expected %%window-pane-changed @window-id %%pane-id): \\"%@\\""',
    wrap('@"Malformed command (expected %%window-pane-changed @window-id %%pane-id): \\"%@\\""', 'tmux gateway: malformed command window-pane-changed'),
    1))

# L441: malformed session-window-changed
edits.append((G,
    '@"Malformed command (expected %%session-window-changed $session-id @window-id): \\"%@\\""',
    wrap('@"Malformed command (expected %%session-window-changed $session-id @window-id): \\"%@\\""', 'tmux gateway: malformed command session-window-changed'),
    1))

# L466: malformed pause
edits.append((G,
    '@"Malformed command (expected %%pause %%wp): \\"%@\\""',
    wrap('@"Malformed command (expected %%pause %%wp): \\"%@\\""', 'tmux gateway: malformed command pause'),
    1))

# L480: malformed subscription-changed
edits.append((G,
    '@"Malformed command (expected %%subscription-changed sid [...] : value): \\"%@\\""',
    wrap('@"Malformed command (expected %%subscription-changed sid [...] : value): \\"%@\\""', 'tmux gateway: malformed command subscription-changed'),
    1))

# L566: error tmux 2.1 working directory
edits.append((G,
    '@"Error: %@.\\n\\nTmux 2.1 and earlier will refuse to create a new window pane with a nonexistent initial working directory.\\n\\nInfo:\\n%@"',
    wrap('@"Error: %@.\\n\\nTmux 2.1 and earlier will refuse to create a new window pane with a nonexistent initial working directory.\\n\\nInfo:\\n%@"', 'tmux gateway: abort error tmux 2.1 working directory'),
    1))

# L569: error info
edits.append((G,
    '@"Error: %@.\\n\\nInfo:\\n%@"',
    wrap('@"Error: %@.\\n\\nInfo:\\n%@"', 'tmux gateway: abort error info'),
    1))

# L657: begin without end
edits.append((G,
    '@"%begin without %end"',
    wrap('@"%begin without %end"', 'tmux gateway: begin without end'),
    1))

# L666: malformed begin
edits.append((G,
    '@"Malformed command (expected %%begin command_id [flags]): \\"%@\\""',
    wrap('@"Malformed command (expected %%begin command_id [flags]): \\"%@\\""', 'tmux gateway: malformed command begin'),
    1))

# L684: begin with empty command queue
edits.append((G,
    '@"%begin with empty command queue"',
    wrap('@"%begin with empty command queue"', 'tmux gateway: begin with empty command queue'),
    1))

# ============================================================================
# TmuxWindowOpener.m
# ============================================================================
W = 'sources/tmux/TmuxWindowOpener.m'

# L98: can't open window missing layout
edits.append((W,
    '@"Can\'t open window: missing layout"',
    wrap('@"Can\'t open window: missing layout"', 'tmux window opener: missing layout'),
    1))

# L103/155/533: error parsing layout (3 occurrences, same key)
edits.append((W,
    '@"Error parsing layout %@"',
    wrap('@"Error parsing layout %@"', 'tmux window opener: error parsing layout'),
    3))

# L337: malformed history line
edits.append((W,
    'alert.messageText = @"Error: malformed history line from tmux."',
    'alert.messageText = ' + wrap('@"Error: malformed history line from tmux."', 'tmux window opener: malformed history line alert title'),
    1))

# L338: see console
edits.append((W,
    'alert.informativeText = @"See Console.app for details"',
    'alert.informativeText = ' + wrap('@"See Console.app for details"', 'tmux window opener: see console alert info'),
    1))

# ============================================================================
# TmuxWindowsTable.m
# ============================================================================
WT = 'sources/tmux/TmuxWindowsTable.m'

edits.append((WT,
    '[openInWindowsButton_ setTitle:@"Open in Window"]',
    '[openInWindowsButton_ setTitle:' + wrap('@"Open in Window"', 'tmux windows table: open in window button') + ']',
    1))

edits.append((WT,
    '[openInWindowsButton_ setTitle:@"Open in Windows"]',
    '[openInWindowsButton_ setTitle:' + wrap('@"Open in Windows"', 'tmux windows table: open in windows button') + ']',
    1))

# ============================================================================
# TmuxSessionsTable.m
# ============================================================================
ST = 'sources/tmux/TmuxSessionsTable.m'

edits.append((ST,
    'return @"New Session";',
    'return ' + wrap('@"New Session"', 'tmux sessions table: new session default name') + ';',
    1))

edits.append((ST,
    '@"New Session %d"',
    wrap('@"New Session %d"', 'tmux sessions table: new session numbered name'),
    1))

# ============================================================================
# TmuxController.m
# ============================================================================
C = 'sources/tmux/TmuxController.m'

# L595: bad response initial list windows
edits.append((C,
    '@"Bad response for initial list windows request: %@"',
    wrap('@"Bad response for initial list windows request: %@"', 'tmux controller: bad response initial list windows'),
    1))

# L642: too many tmux windows notification title
edits.append((C,
    'notify:@"Too many tmux windows!"',
    'notify:' + wrap('@"Too many tmux windows!"', 'tmux controller: too many windows notification title'),
    1))

# L644: some windows hidden notification title
edits.append((C,
    'notify:@"Some tmux windows were hidden."',
    'notify:' + wrap('@"Some tmux windows were hidden."', 'tmux controller: hidden windows notification title'),
    1))

# L642+L644: use dashboard description (2 occurrences, same key)
edits.append((C,
    'withDescription:@"Use the tmux dashboard to select which to open."',
    'withDescription:' + wrap('@"Use the tmux dashboard to select which to open."', 'tmux controller: use dashboard notification description'),
    2))

# L1541: utf-8 mode message
edits.append((C,
    '@"tmux is not in UTF-8 mode. Please pass the -u command line argument to tmux or change your LANG environment variable to end with “.UTF-8”."',
    wrap('@"tmux is not in UTF-8 mode. Please pass the -u command line argument to tmux or change your LANG environment variable to end with “.UTF-8”."', 'tmux controller: utf-8 mode not detected message'),
    1))

# L1542: utf-8 mode title
edits.append((C,
    'title:@"UTF-8 Mode Not Detected"',
    'title:' + wrap('@"UTF-8 Mode Not Detected"', 'tmux controller: utf-8 mode alert title'),
    1))

# L1859-1863: unsupported option message (multi-line concatenated literal -> single wrapped literal)
OLD_OPT = ('                            @"The \\"%@\\" option is turned on in tmux. "\n'
           '                             "It is not compatible with the iTerm2-tmux integration. "\n'
           '                             "Please disable it and try again.",')
NEW_OPT = ('                            ' + wrap('@"The \\"%@\\" option is turned on in tmux. It is not compatible with the iTerm2-tmux integration. Please disable it and try again."', 'tmux controller: unsupported option message') + ',')
edits.append((C, OLD_OPT, NEW_OPT, 1))

# L1865: unsupported tmux option title
edits.append((C,
    'title:@"Unsupported tmux option"',
    'title:' + wrap('@"Unsupported tmux option"', 'tmux controller: unsupported option alert title'),
    1))

# L3115: red tab colors warning
edits.append((C,
    '@"While attaching to tmux, some tabs were found whose color is pure red. This may be due to a bug in early versions of iTerm2 3.6.x. Would you like to reset those tabs’ colors?"',
    wrap('@"While attaching to tmux, some tabs were found whose color is pure red. This may be due to a bug in early versions of iTerm2 3.6.x. Would you like to reset those tabs’ colors?"', 'tmux controller: red tab colors warning'),
    1))

# L3116: reset / keep red action buttons
edits.append((C,
    '@[ @"Reset", @"Keep Red" ]',
    '@[ ' + wrap('@"Reset"', 'tmux controller: reset red tabs action') + ', ' + wrap('@"Keep Red"', 'tmux controller: keep red tabs action') + ' ]',
    1))

# L3120: fix corrupted tab colors heading
edits.append((C,
    'heading:@"Fix corrupted tab colors?"',
    'heading:' + wrap('@"Fix corrupted tab colors?"', 'tmux controller: fix corrupted tab colors heading'),
    1))

# L3370: bad response list windows
edits.append((C,
    '@"Bad response for list windows request: %@"',
    wrap('@"Bad response for list windows request: %@"', 'tmux controller: bad response list windows'),
    1))

# L3524: error opening tmux tab notification title
edits.append((C,
    'notify:@"Error opening tmux tab"',
    'notify:' + wrap('@"Error opening tmux tab"', 'tmux controller: error opening tmux tab notification title'),
    1))

# L3525: pane terminated description
edits.append((C,
    'withDescription:@"A tmux pane terminated immediately after creation"',
    'withDescription:' + wrap('@"A tmux pane terminated immediately after creation"', 'tmux controller: pane terminated notification description'),
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
        errs.append(f'{f}: expected {expected}, got {c} for:\n  {old[:120]!r}')
        continue
    file_contents[f] = file_contents[f].replace(old, new)

if errs:
    print('ERRORS:')
    for e in errs:
        print(' ', e)
    sys.exit(1)

for f in sorted(set(e[0] for e in edits)):
    open(f, 'w', encoding='utf-8').write(file_contents[f])

print(f'All tmux wraps OK: {len(edits)} edits across {len(file_contents)} files')
