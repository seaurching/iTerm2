# -*- coding: utf-8 -*-
"""Wrap 5 ObjC files in sources/Tips/ with NSLocalizedStringFromTableInBundle(@"...", @"Tips", ...).

Files:
  iTermTip.m                  - 1 site (Learn More in HTML link)
  iTermTipCardViewController.m - 3 sites (2 accessibilityLabel + 1 signature)
  iTermTipController.m         - 4 sites (alert messageText/informativeText + 2 buttons)
  iTermWindowController.m     - 13 sites (12 static const -> +initialize, 1 accessibilityLabel)
  iTermTipData.m              - 246 sites (123 title + 123 body, via regex)

For iTermTipWindowController.m, the 12 `static NSString *const kXxx = @"..."` cannot
be initialized with NSLocalizedStringFromTableInBundle at file scope (not a compile-time
constant). So we strip const/init and assign them in +initialize.
"""
import os, re, sys

T = 'Tips'
B = '[NSBundle bundleForClass:[self class]]'
errs = []
total = 0

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def NL(key, comment):
    return f'NSLocalizedStringFromTableInBundle(@"{esc(key)}", @"{T}", {B}, @"{esc(comment)}")'

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
# iTermTip.m  (Learn More inside HTML format string)
# ============================================================================
wrap_file('sources/Tips/iTermTip.m', [
    (f'NSString *link = self.url ? [NSString stringWithFormat:@"<p><a href=\\"%@\\">Learn More</a></p>", self.url] : @"";',
     f'NSString *link = self.url ? [NSString stringWithFormat:@"<p><a href=\\"%@\\">@{esc(chr(37))}@</a></p>", self.url, {NL("Learn More", "tip: learn more link text")}] : @"";',
     'learn more link'),
])

# ============================================================================
# iTermTipCardViewController.m
# ============================================================================
wrap_file('sources/Tips/iTermTipCardViewController.m', [
    ('_title.accessibilityLabel = @"Tip title";',
     f'_title.accessibilityLabel = {NL("Tip title", "tip card: title accessibility label")};',
     'title accessibility label'),
    ('_body.accessibilityLabel = @"Tip content";',
     f'_body.accessibilityLabel = {NL("Tip content", "tip card: body accessibility label")};',
     'body accessibility label'),
    ('[attributedString iterm_appendString:@"iTerm2 tip of the day"',
     f'[attributedString iterm_appendString:{NL("iTerm2 tip of the day", "tip card: signature text")}',
     'signature text'),
])

# ============================================================================
# iTermTipController.m
# ============================================================================
wrap_file('sources/Tips/iTermTipController.m', [
    ('alert.messageText = @"See Tips of the Day?";',
     f'alert.messageText = {NL("See Tips of the Day?", "tip controller: ask permission alert title")};',
     'ask permission title'),
    ('alert.informativeText = @"iTerm2 can show you a Tip of the Day message to help you learn about its many features. Are you interested?";',
     f'alert.informativeText = {NL("iTerm2 can show you a Tip of the Day message to help you learn about its many features. Are you interested?", "tip controller: ask permission alert informative text")};',
     'ask permission informative text'),
    ('[alert addButtonWithTitle:@"Yes"];',
     f'[alert addButtonWithTitle:{NL("Yes", "tip controller: yes button")}];',
     'yes button'),
    ('[alert addButtonWithTitle:@"No"];',
     f'[alert addButtonWithTitle:{NL("No", "tip controller: no button")}];',
     'no button'),
])

# ============================================================================
# iTermTipWindowController.m  (12 static const -> +initialize, 1 accessibilityLabel)
# ============================================================================
CONST_BLOCK = """static NSString *const kLearnMoreTitle = @"Learn More";
static NSString *const kDismissTipTitle = @"Dismiss Tip";
static NSString *const kFewerOptionsTitle = @"Fewer Options";
static NSString *const kMoreOptionsTitle = @"More Options";
static NSString *const kShowThisLaterTitle = @"Show This Later";
static NSString *const kDisableTipsTitle = @"Disable Tips";
static NSString *const kEnableTipsTitle = @"Enable Tips";
static NSString *const kShowNextTipTitle = @"Show Next Tip";
static NSString *const kShowPreviousTipTitle = @"Show Previous Tip";
static NSString *const kShowTipsWeeklyTitle = @"Show Tips Weekly";
static NSString *const kShowTipsDailyTitle = @"Show Tips Daily";
static NSString *const kShareTitle = @"Share";"""

CONST_DECL = """static NSString *kLearnMoreTitle;
static NSString *kDismissTipTitle;
static NSString *kFewerOptionsTitle;
static NSString *kMoreOptionsTitle;
static NSString *kShowThisLaterTitle;
static NSString *kDisableTipsTitle;
static NSString *kEnableTipsTitle;
static NSString *kShowNextTipTitle;
static NSString *kShowPreviousTipTitle;
static NSString *kShowTipsWeeklyTitle;
static NSString *kShowTipsDailyTitle;
static NSString *kShareTitle;"""

INITIALIZE = """+ (void)initialize {
    if (self != [iTermTipWindowController class]) {
        return;
    }
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    kLearnMoreTitle = NSLocalizedStringFromTableInBundle(@"Learn More", @"Tips", bundle, @"tip window: learn more button");
    kDismissTipTitle = NSLocalizedStringFromTableInBundle(@"Dismiss Tip", @"Tips", bundle, @"tip window: dismiss tip button");
    kFewerOptionsTitle = NSLocalizedStringFromTableInBundle(@"Fewer Options", @"Tips", bundle, @"tip window: fewer options button");
    kMoreOptionsTitle = NSLocalizedStringFromTableInBundle(@"More Options", @"Tips", bundle, @"tip window: more options button");
    kShowThisLaterTitle = NSLocalizedStringFromTableInBundle(@"Show This Later", @"Tips", bundle, @"tip window: show this later button");
    kDisableTipsTitle = NSLocalizedStringFromTableInBundle(@"Disable Tips", @"Tips", bundle, @"tip window: disable tips button");
    kEnableTipsTitle = NSLocalizedStringFromTableInBundle(@"Enable Tips", @"Tips", bundle, @"tip window: enable tips button");
    kShowNextTipTitle = NSLocalizedStringFromTableInBundle(@"Show Next Tip", @"Tips", bundle, @"tip window: show next tip button");
    kShowPreviousTipTitle = NSLocalizedStringFromTableInBundle(@"Show Previous Tip", @"Tips", bundle, @"tip window: show previous tip button");
    kShowTipsWeeklyTitle = NSLocalizedStringFromTableInBundle(@"Show Tips Weekly", @"Tips", bundle, @"tip window: show tips weekly button");
    kShowTipsDailyTitle = NSLocalizedStringFromTableInBundle(@"Show Tips Daily", @"Tips", bundle, @"tip window: show tips daily button");
    kShareTitle = NSLocalizedStringFromTableInBundle(@"Share", @"Tips", bundle, @"tip window: share button");
}
"""

# Anchor: end of ivar block + start of initWithTip: — insert +initialize between
IVAR_END = """    BOOL _dragging;
}

- (instancetype)initWithTip:(id)tip {"""

wrap_file('sources/Tips/iTermTipWindowController.m', [
    (CONST_BLOCK, CONST_DECL, '12 static const -> decl'),
    (IVAR_END, IVAR_END.replace('}\n\n- (instancetype)initWithTip', '}\n\n' + INITIALIZE + '- (instancetype)initWithTip'), 'insert +initialize'),
    ('self.window.accessibilityLabel = @"iTerm2 Tip of the Day";',
     f'self.window.accessibilityLabel = {NL("iTerm2 Tip of the Day", "tip window: accessibility label")};',
     'window accessibility label'),
])

# ============================================================================
# iTermTipData.m  (regex: 123 title + 123 body)
# ============================================================================
def wrap_tipdata(path):
    global total
    s = open(path, encoding='utf-8').read()

    def title_sub(m):
        tip_id = m.group(2)
        title = m.group(3)
        return (f'{m.group(1)}NSLocalizedStringFromTableInBundle(@"{title}", @"{T}", {B}, '
                f'@"tip {tip_id} title")')
    s, n_title = re.subn(
        r'(@"(\d+)"\s*:\s*@\{\s*kTipTitleKey:\s*)@"((?:[^"\\]|\\.)*)"',
        title_sub, s)

    def body_sub(m):
        return (f'{m.group(1)}NSLocalizedStringFromTableInBundle(@"{m.group(2)}", @"{T}", {B}, '
                f'@"tip body")')
    s, n_body = re.subn(
        r'(kTipBodyKey:\s*)@"((?:[^"\\]|\\.)*)"',
        body_sub, s)

    open(path, 'w', encoding='utf-8').write(s)
    print(f'iTermTipData.m: {n_title} titles, {n_body} bodies')
    total += n_title + n_body

wrap_tipdata('sources/Tips/iTermTipData.m')

if errs:
    print('ERRORS:')
    for e in errs:
        print(f'  {e}')
    sys.exit(1)

print(f'\nTotal replacements applied: {total}')
print('All OK')
