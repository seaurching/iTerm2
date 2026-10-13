# -*- coding: utf-8 -*-
# Wrap user-visible strings in sources/TouchBar/PseudoTerminal+TouchBar.m
# with NSLocalizedStringFromTableInBundle(@"key", @"TouchBar", bundle, comment).
#
# Table: TouchBar  Bundle: [NSBundle bundleForClass:[self class]]
# Only PseudoTerminal+TouchBar.m has user-visible strings in this directory.
import sys

SRC = 'sources/TouchBar/PseudoTerminal+TouchBar.m'

def W(key, comment):
    return (f'NSLocalizedStringFromTableInBundle(@"{key}", @"TouchBar", '
            f'[NSBundle bundleForClass:[self class]], @"{comment}")')

edits = [
    ('button.title = @"Status";',
     'button.title = ' + W('Status', 'touch bar: default status button title') + ';'),
    ('item.customizationLabel = @"Function Keys";',
     'item.customizationLabel = ' + W('Function Keys', 'touch bar: function keys customization label') + ';'),
    ('self.tabsTouchBarItem.customizationLabel = @"Full Screen Tab Bar";',
     'self.tabsTouchBarItem.customizationLabel = ' + W('Full Screen Tab Bar', 'touch bar: full screen tab bar customization label') + ';'),
    ('self.autocompleteCandidateListItem.customizationLabel = @"Autocomplete Suggestions";',
     'self.autocompleteCandidateListItem.customizationLabel = ' + W('Autocomplete Suggestions', 'touch bar: autocomplete suggestions customization label') + ';'),
    ('label = @"Man Page";',
     'label = ' + W('Man Page', 'touch bar: man page button label') + ';'),
    ('label = @"Your Message Here";',
     'label = ' + W('Your Message Here', 'touch bar: status button placeholder label') + ';'),
    ('label = @"Add Mark";',
     'label = ' + W('Add Mark', 'touch bar: add mark button label') + ';'),
    ('label = @"Next Mark";',
     'label = ' + W('Next Mark', 'touch bar: next mark button label') + ';'),
    ('label = @"Previous Mark";',
     'label = ' + W('Previous Mark', 'touch bar: previous mark button label') + ';'),
    ('item.customizationLabel = @"Color Preset";',
     'item.customizationLabel = ' + W('Color Preset', 'touch bar: color preset customization label') + ';'),
    ('item.customizationLabel = @"Function Keys Popover";',
     'item.customizationLabel = ' + W('Function Keys Popover', 'touch bar: function keys popover customization label') + ';'),
]

s = open(SRC, encoding='utf-8').read()
n = 0
for old, new in edits:
    c = s.count(old)
    if c != 1:
        print(f'ERROR: expected 1, got {c} for: {old!r}')
        sys.exit(1)
    s = s.replace(old, new)
    n += 1

open(SRC, 'w', encoding='utf-8').write(s)
print(f'PseudoTerminal+TouchBar.m: {n} strings wrapped OK')
