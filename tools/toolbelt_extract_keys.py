# -*- coding: utf-8 -*-
# Extract all Toolbelt-table keys from wrapped source files (deduplicated).
#
# Handles:
#   ObjC:  NSLocalizedStringFromTableInBundle(@"KEY", @"Toolbelt", ...)
#   Swift: NSLocalizedString("KEY", tableName: "Toolbelt", ...)
#   Swift: NSLocalizedString(triple-quoted multi-line, tableName: "Toolbelt", ...)
#   Swift: String(format: NSLocalizedString("KEY", tableName: "Toolbelt", ...), arg)
#          (inner NSLocalizedString captured by the plain Swift pattern)
import re

OBJC_FILES = [
    'sources/Toolbelt/iTermToolActions.m',
    'sources/Toolbelt/iTermToolbeltView.m',
    'sources/Toolbelt/iTermToolSnippets.m',
    'sources/Toolbelt/ToolProfiles.m',
    'sources/Toolbelt/ToolPasteHistory.m',
    'sources/Toolbelt/ToolCommandHistoryView.m',
    'sources/Toolbelt/ToolDirectoriesView.m',
    'sources/Toolbelt/ToolNotes.m',
]
SWIFT_FILES = [
    'sources/Toolbelt/ToolCodecierge.swift',
    'sources/Toolbelt/ToolStatus.swift',
    'sources/Toolbelt/StatusPrioritySettings.swift',
    'sources/Toolbelt/ToolNamedMarks.swift',
    'sources/Toolbelt/ToolStatusCellView.swift',
]

def decode_objc(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            c = s[i+1]
            if c == 'n': out.append('\n')
            elif c == 't': out.append('\t')
            elif c == 'r': out.append('\r')
            elif c == '\\': out.append('\\')
            elif c == '"': out.append('"')
            elif c == "'": out.append("'")
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

def decode_swift_single(s):
    """Decode a Swift single-quoted (double-quote) string literal body."""
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            c = s[i+1]
            if c == 'n': out.append('\n')
            elif c == 't': out.append('\t')
            elif c == 'r': out.append('\r')
            elif c == '\\': out.append('\\')
            elif c == '"': out.append('"')
            elif c == "'": out.append("'")
            elif c == '0': out.append('\0')
            else: out.append(c)
            i += 2
        else:
            out.append(s[i]); i += 1
    return ''.join(out)

def decode_swift_multi(s):
    """Decode a Swift triple-quoted string body. Backslashes are NOT processed
    the same way: in a raw multi-line literal, \ is literal unless followed by
    a newline (line continuation). For our keys, content is plain markdown."""
    # Strip leading newline if present (Swift strips leading whitespace/newline
    # after opening """), but keep content verbatim for key matching purposes
    # since we wrapped the literal verbatim.
    return s

keys = []
seen = set()

# ObjC pattern
pat_objc = re.compile(r'NSLocalizedStringFromTableInBundle\(@"((?:[^"\\]|\\.)*)", @"Toolbelt"')
for f in OBJC_FILES:
    s = open(f, encoding='utf-8').read()
    for m in pat_objc.finditer(s):
        k = decode_objc(m.group(1))
        if k not in seen:
            seen.add(k); keys.append((f, k))

# Swift plain single-line pattern
pat_swift = re.compile(r'NSLocalizedString\("((?:[^"\\]|\\.)*)", tableName: "Toolbelt"')
# Swift multi-line triple-quote pattern
pat_swift_multi = re.compile(r'NSLocalizedString\("""(.*?)""", tableName: "Toolbelt"', re.DOTALL)
# String(format: NSLocalizedString("KEY", tableName: "Toolbelt"  — captured by pat_swift

for f in SWIFT_FILES:
    s = open(f, encoding='utf-8').read()
    # First extract multi-line and mask them out so the single-line pattern
    # does not mis-parse content inside triple-quoted strings.
    multiline_spans = []
    for m in pat_swift_multi.finditer(s):
        k = decode_swift_multi(m.group(1))
        if k not in seen:
            seen.add(k); keys.append((f, k))
        multiline_spans.append(m.span())
    # Mask out multi-line regions
    masked = list(s)
    for a, b in multiline_spans:
        for j in range(a, b):
            if masked[j] != '\n':
                masked[j] = ' '
    s_masked = ''.join(masked)
    for m in pat_swift.finditer(s_masked):
        k = decode_swift_single(m.group(1))
        if k not in seen:
            seen.add(k); keys.append((f, k))

print(f'Total unique keys: {len(keys)}')
for f, k in keys:
    print(f'[{f.split("/")[-1]}] {k!r}')
