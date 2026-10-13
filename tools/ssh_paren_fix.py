# -*- coding: utf-8 -*-
"""Fix missing closing parens for NLf calls nested inside outer calls."""
import sys
errs = []

def fix(path, old, new, count=1):
    s = open(path, encoding='utf-8').read()
    c = s.count(old)
    if c != count:
        errs.append(f'{path}: count {c} (expected {count}) for {old[:60]}')
        return
    s = s.replace(old, new)
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{path}: fixed ({c})')

D = 'sources/SSH/'

# SSHFilePanel.swift: subtitle + connection lost
fix(D + 'SSHFilePanel.swift',
    'comment: "file panel: new folder subtitle"), currentPath.absolutePath.lastPathComponent)',
    'comment: "file panel: new folder subtitle"), currentPath.absolutePath.lastPathComponent))')
fix(D + 'SSHFilePanel.swift',
    'comment: "file panel: connection lost error"), file.sshIdentity.displayName))',
    'comment: "file panel: connection lost error"), file.sshIdentity.displayName)))')

# Conductor+ConductorFileTransferDelegate.swift: 3 NLf-in-outer
fix(D + 'Conductor+ConductorFileTransferDelegate.swift',
    'comment: "conductor delegate: could not open error"), path)',
    'comment: "conductor delegate: could not open error"), path))')
fix(D + 'Conductor+ConductorFileTransferDelegate.swift',
    'comment: "conductor delegate: directory transfer not allowed"), remotePath)',
    'comment: "conductor delegate: directory transfer not allowed"), remotePath))')
fix(D + 'Conductor+ConductorFileTransferDelegate.swift',
    'comment: "conductor delegate: not regular file error"), remoteFile.absolutePath, sshIdentity.displayName)',
    'comment: "conductor delegate: not regular file error"), remoteFile.absolutePath, sshIdentity.displayName))')

# Conductor.swift: 5 NLf-in-fail (unexpected status x2, python status, unexpected output, invalid pid)
fix(D + 'Conductor.swift',
    'comment: "conductor: unexpected status error"), executionContext.command.stringValue, status)',
    'comment: "conductor: unexpected status error"), executionContext.command.stringValue, status))',
    count=2)
fix(D + 'Conductor.swift',
    'comment: "conductor: python status error"), status)',
    'comment: "conductor: python status error"), status))')
fix(D + 'Conductor.swift',
    'comment: "conductor: unexpected output error"), executionContext.command.stringValue)',
    'comment: "conductor: unexpected output error"), executionContext.command.stringValue))')
fix(D + 'Conductor.swift',
    'comment: "conductor: invalid pid error"), lines.string)',
    'comment: "conductor: invalid pid error"), lines.string))')

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)
print('All paren fixes OK')
