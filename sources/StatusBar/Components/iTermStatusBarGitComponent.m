//
//  iTermStatusBarGitComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 7/22/18.
//
// This is loosely based on hyperline git-status

#import "iTermStatusBarGitComponent.h"

#import "DebugLogging.h"
#import "FontSizeEstimator.h"
#import "iTermAdvancedSettingsModel.h"
#import "iTermCommandRunner.h"
#import "iTermController.h"
#import "iTermGitPollWorker.h"
#import "iTermGitPoller.h"
#import "iTermGitState+MainApp.h"
#import "iTermGitStringMaker.h"
#import "iTermSlowOperationGateway.h"
#import "iTermTextPopoverViewController.h"
#import "iTermVariableReference.h"
#import "iTermVariableScope.h"
#import "iTermVariableScope+Session.h"
#import "iTermWarning.h"
#import "NSArray+iTerm.h"
#import "NSDate+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "NSImage+iTerm.h"
#import "NSStringITerm.h"
#import "NSObject+iTerm.h"
#import "NSTimer+iTerm.h"
#import "PTYSession.h"
#import "PseudoTerminal.h"
#import "RegexKitLite.h"

@interface NSObject(BogusSelector)
- (void)bogusSelector;
@end

NS_ASSUME_NONNULL_BEGIN

static NSString *const iTermStatusBarGitComponentPollingIntervalKey = @"iTermStatusBarGitComponentPollingIntervalKey";
static const NSTimeInterval iTermStatusBarGitComponentDefaultCadence = 2;

@interface iTermGitMenuItemContext : NSObject
@property (nonatomic, copy) iTermGitState *state;
@property (nonatomic, copy) NSString *directory;
@property (nonatomic, strong) id userData;
@end

@implementation iTermGitMenuItemContext
@end

@interface iTermStatusBarGitComponent()<iTermGitPollerDelegate, iTermGitStringMakerDelegate, iTermAutoGitStringDelegate>
@end

@implementation iTermStatusBarGitComponent {
    iTermAutoGitString *_autoGitString;
    iTermVariableReference *_lastCommandRef;
    iTermGitStringMaker *_maker;
    PTYSession *_session;
    iTermCommandRunner *_logRunner;
    iTermTextPopoverViewController *_popoverVC;
    NSView *_view;
}

- (instancetype)initWithConfiguration:(NSDictionary<iTermStatusBarComponentConfigurationKey,id> *)configuration
                                scope:(nullable iTermVariableScope *)scope {
    self = [super initWithConfiguration:configuration scope:scope];
    if (self) {
        const NSTimeInterval cadence = [self cadenceInDictionary:configuration[iTermStatusBarComponentConfigurationKeyKnobValues]];
        __weak __typeof(self) weakSelf = self;
        iTermGitPoller *gitPoller = [[iTermGitPoller alloc] initWithCadence:cadence update:^{
            [weakSelf statusBarComponentUpdate];
        }];
        gitPoller.delegate = self;
        iTermGitStringMaker *stringMaker = [[iTermGitStringMaker alloc] initWithScope:scope
                                                        gitPoller:gitPoller];
        stringMaker.delegate = self;
        _autoGitString = [[iTermAutoGitString alloc] initWithStringMaker:stringMaker];
        _autoGitString.delegate = self;
        _maker = stringMaker;
        _lastCommandRef = [[iTermVariableReference alloc] initWithPath:iTermVariableKeySessionLastCommand vendor:scope];
        _lastCommandRef.onChangeBlock = ^{
            [weakSelf bumpIfLastCommandWasGit];
        };
    };
    return self;
}

+ (ProfileType)compatibleProfileTypes {
    return ProfileTypeTerminal;
}

- (void)setDelegate:(id<iTermStatusBarComponentDelegate> _Nullable)delegate {
    [super setDelegate:delegate];
    [self statusBarComponentUpdate];
}

- (nullable NSImage *)statusBarComponentIcon {
    return [NSImage it_cacheableImageNamed:@"StatusBarIconGitBranch" forClass:[self class]];
}

- (NSString *)statusBarComponentShortDescription {
    return NSLocalizedStringFromTableInBundle(@"git state", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Short description for git state component");
}

- (NSString *)statusBarComponentDetailedDescription {
    return NSLocalizedStringFromTableInBundle(@"Shows a summary of the git state of the current directory.", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Detailed description for git state component");
}

- (NSArray<iTermStatusBarComponentKnob *> *)statusBarComponentKnobs {
    NSArray<iTermStatusBarComponentKnob *> *knobs;

    iTermStatusBarComponentKnob *formatKnob =
    [[iTermStatusBarComponentKnob alloc] initWithLabelText:NSLocalizedStringFromTableInBundle(@"Polling Interval (seconds):", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Knob label for polling interval in seconds")
                                                      type:iTermStatusBarComponentKnobTypeDouble
                                               placeholder:nil
                                              defaultValue:@(iTermStatusBarGitComponentDefaultCadence)
                                                       key:iTermStatusBarGitComponentPollingIntervalKey];

    knobs = @[ formatKnob ];
    knobs = [knobs arrayByAddingObjectsFromArray:[super statusBarComponentKnobs]];
    knobs = [knobs arrayByAddingObjectsFromArray:self.minMaxWidthKnobs];
    return knobs;
}

+ (NSDictionary *)statusBarComponentDefaultKnobs {
    NSDictionary *knobs = [super statusBarComponentDefaultKnobs];
    knobs = [knobs dictionaryByMergingDictionary:@{ iTermStatusBarGitComponentPollingIntervalKey: @(iTermStatusBarGitComponentDefaultCadence) }];
    knobs = [knobs dictionaryByMergingDictionary:self.defaultMinMaxWidthKnobValues];
    return knobs;
}

- (CGFloat)statusBarComponentPreferredWidth {
    return [self clampedWidth:[super statusBarComponentPreferredWidth]];
}

- (id)statusBarComponentExemplarWithBackgroundColor:(NSColor *)backgroundColor
                                          textColor:(NSColor *)textColor {
    return NSLocalizedStringFromTableInBundle(@"⎇ main", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Exemplar text for git state component");
}

- (BOOL)statusBarComponentCanStretch {
    return YES;
}

- (BOOL)truncatesTail {
    return YES;
}

- (NSArray<NSAttributedString *> *)attributedStringVariants {
    if ([self shouldShowTimeoutError]) {
        return @[ [self timeoutWarningAttributedStringWithString:NSLocalizedStringFromTableInBundle(@"⚠️ timed out", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Timeout warning text with label")],
                  [self timeoutWarningAttributedStringWithString:NSLocalizedStringFromTableInBundle(@"⚠️", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Timeout warning symbol")]];
    }
    return [_maker attributedStringVariants];
}

// Build a small attributed string using this component's font / color so
// the timeout warning matches surrounding statusbar text. Mirrors what
// the maker does internally; kept local because the warning is the only
// thing the component renders directly without going through the maker.
- (NSAttributedString *)timeoutWarningAttributedStringWithString:(NSString *)string {
    NSDictionary *attributes = @{
        NSFontAttributeName: self.advancedConfiguration.font ?: [iTermStatusBarAdvancedConfiguration defaultFont],
        NSForegroundColorAttributeName: [self textColor],
        NSParagraphStyleAttributeName: self.paragraphStyle,
    };
    return [[NSAttributedString alloc] initWithString:string ?: @"" attributes:attributes];
}

- (BOOL)shouldShowTimeoutError {
    if (!_maker.onLocalhost) {
        return NO;
    }
    if (!_maker.gitPoller.enabled) {
        return NO;
    }
    if (_maker.gitPoller.hasSuccessfullyFetched) {
        return NO;
    }
    return _maker.gitPoller.lastPollTimedOut;
}

- (void)showTimeoutWarningInWindow:(NSWindow *)window {
    const double currentTimeout = [iTermAdvancedSettingsModel gitTimeout];
    const double proposedTimeout = MAX(currentTimeout * 2, currentTimeout + 2);
    NSString *title = [NSString stringWithFormat:
                       NSLocalizedStringFromTableInBundle(@"Running git in %@ didn’t finish within %@ seconds, so the status bar component can’t show the branch. This often happens in very large repositories or when the working tree is on a slow filesystem.\n\nWould you like to increase the timeout to %@ seconds?", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Timeout warning: git didn't finish in time"),
                       _maker.gitPoller.currentDirectory ?: NSLocalizedStringFromTableInBundle(@"the current directory", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Fallback for current directory in timeout warning"),
                       [self formatTimeoutSeconds:currentTimeout],
                       [self formatTimeoutSeconds:proposedTimeout]];
    NSString *increaseAction = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Increase to %@s", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Button to increase timeout"), [self formatTimeoutSeconds:proposedTimeout]];
    const iTermWarningSelection selection =
    [iTermWarning showWarningWithTitle:title
                               actions:@[ increaseAction, NSLocalizedStringFromTableInBundle(@"Cancel", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Cancel button") ]
                             accessory:nil
                            identifier:nil
                           silenceable:kiTermWarningTypePersistent
                               heading:NSLocalizedStringFromTableInBundle(@"git timed out", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Timeout warning heading")
                                window:window];
    if (selection == kiTermWarningSelection0) {
        [iTermAdvancedSettingsModel setGitTimeout:proposedTimeout];
        [_maker.gitPoller clearTimeoutFlagAndRetry];
    }
}

- (NSString *)formatTimeoutSeconds:(double)seconds {
    if (fabs(seconds - round(seconds)) < 0.01) {
        return [@((NSInteger)round(seconds)) stringValue];
    }
    return [NSString stringWithFormat:@"%.1f", seconds];
}

- (NSParagraphStyle *)paragraphStyle {
    static NSMutableParagraphStyle *paragraphStyle;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    });

    return paragraphStyle;
}

- (nullable NSFont *)gitFont {
    return self.advancedConfiguration.font ?: [iTermStatusBarAdvancedConfiguration defaultFont];
}

- (nullable NSColor *)gitTextColor {
    return [self textColor];
}
- (CGFloat)statusBarComponentMinimumWidth {
    return [self widthForAttributedString:[_maker attributedStringValueForBranch:@"M"]];
}

- (NSTimeInterval)cadenceInDictionary:(NSDictionary *)knobValues {
    return [knobValues[iTermStatusBarGitComponentPollingIntervalKey] doubleValue] ?: 1;
}

- (void)gitStringDidChange {
    [self statusBarComponentUpdate];
}

- (void)statusBarComponentSetKnobValues:(NSDictionary *)knobValues {
    _maker.gitPoller.cadence = [self cadenceInDictionary:knobValues];
    [super statusBarComponentSetKnobValues:knobValues];
}

- (void)statusBarComponentDidMoveToWindow {
    [super statusBarComponentDidMoveToWindow];
    [self bump];
}

- (void)bump {
    [_maker.gitPoller bump];
}

- (void)bumpIfLastCommandWasGit {
    NSString *wholeCommand = _lastCommandRef.value;
    NSInteger space = [wholeCommand rangeOfString:@" "].location;
    if (space == NSNotFound) {
        return;
    }
    NSString *command = [wholeCommand substringToIndex:space];
    NSInteger lastSlash = [command rangeOfString:@"/" options:NSBackwardsSearch].location;
    if (lastSlash != NSNotFound) {
        command = [command substringFromIndex:lastSlash + 1];
    }
    if ([command isEqualToString:@"git"]) {
        RLog(@"Bump because command %@ looks like git", RLogRedact(wholeCommand, @(wholeCommand.length)));
        [self bump];
    }
}

- (nullable NSString *)statusBarComponentCopyableString {
    return _maker.branch;
}

- (BOOL)statusBarComponentHandlesClicks {
    return YES;
}

- (BOOL)statusBarComponentIsEmpty {
    if ([self shouldShowTimeoutError]) {
        return NO;
    }
    return (_maker.branch.length == 0);
}

- (void)killSession:(id)sender {
    [[[iTermController sharedInstance] terminalWithSession:_session] closeSessionWithoutConfirmation:_session];
}

- (void)revealSession:(id)sender {
    [_session reveal];
}

- (void)statusBarComponentMouseDownWithView:(NSView *)view {
    [self openMenuWithView:view];
}

- (BOOL)statusBarComponentHandlesMouseDown {
    return YES;
}

- (void)openMenuWithView:(NSView *)view {
    NSView *containingView = view.superview;
    if (!containingView.window) {
        return;
    }
    if (_session) {
        NSMenu *menu = [[NSMenu alloc] init];
        NSString *actionName = [_maker.status stringByReplacingOccurrencesOfString:@"…" withString:@""];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Cancel %@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to cancel a running git action"), actionName] action:@selector(killSession:) keyEquivalent:@""];
        item.target = self;
        [menu addItem:item];

        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Reveal", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to reveal session") action:@selector(revealSession:) keyEquivalent:@""];
        item.target = self;
        [menu addItem:item];
        [menu popUpMenuPositioningItem:menu.itemArray.firstObject atLocation:NSMakePoint(0, 0) inView:containingView];
        return;
    }

    if (_maker.xcode.length > 0) {
        [iTermWarning showWarningWithTitle:[_maker.xcode stringByReplacingOccurrencesOfString:@"\t" withString:@"\n"]
                                   actions:@[ NSLocalizedStringFromTableInBundle(@"OK", @"StatusBar", [NSBundle bundleForClass:[self class]], @"OK button") ]
                                 accessory:nil
                                identifier:@"GitPollerXcodeWarning"
                               silenceable:kiTermWarningTypePersistent
                                   heading:NSLocalizedStringFromTableInBundle(@"Problem Running git", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Heading for problem running git alert")
                                    window:containingView.window];
        return;
    }

    if ([self shouldShowTimeoutError]) {
        [self showTimeoutWarningInWindow:containingView.window];
        return;
    }

    if (_maker.branch.length == 0) {
        NSMenu *menu = [[NSMenu alloc] init];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Show Debug Info", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to show debug info") action:@selector(debug) keyEquivalent:@""];
        item.target = self;
        [menu addItem:item];
        [menu popUpMenuPositioningItem:menu.itemArray.firstObject atLocation:NSMakePoint(0, 0) inView:containingView];
        return;
    }
    iTermGitState *state = _maker.currentState.copy;
    NSString *directory = _maker.gitPoller.currentDirectory;
    __weak __typeof(self) weakSelf = self;
    const NSInteger maxCount = 7;
    [self fetchRecentBranchesWithTimeout:0.5 count:maxCount + 1 completion:^(NSArray<NSString *> *branches) {
        NSMenu *menu = [[NSMenu alloc] init];
        iTermGitMenuItemContext *(^addItem)(NSString *, SEL, BOOL) = ^iTermGitMenuItemContext *(NSString *title, SEL selector, BOOL enabled) {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                          action:enabled ? selector : @selector(bogusSelector)
                                                   keyEquivalent:@""];
            item.target = weakSelf;
            iTermGitMenuItemContext *context = [[iTermGitMenuItemContext alloc] init];
            context.state = state;
            context.directory = directory;
            item.representedObject = context;
            [menu addItem:item];
            return context;
        };
        __strong __typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf->_view = view;
        addItem(NSLocalizedStringFromTableInBundle(@"Commit", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to commit"), @selector(commit:), state.dirty);
        addItem(NSLocalizedStringFromTableInBundle(@"Add & Commit", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to add and commit"), @selector(addAndCommit:), state.dirty);
        addItem(NSLocalizedStringFromTableInBundle(@"Stash", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to stash"), @selector(stash:), state.dirty);
        addItem(NSLocalizedStringFromTableInBundle(@"Log", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to show log"), @selector(log:), YES);
        addItem([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Push origin %@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to push origin"), state.branch],
                @selector(push:),
                state.ahead.intValue > 0 || [state.ahead isEqualToString:@"error"]);
        addItem([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Pull origin %@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to pull origin"), state.branch],
                @selector(pull:),
                !state.dirty);
        [menu addItem:[NSMenuItem separatorItem]];
        for (NSString *branch in [branches it_arrayByKeepingFirstN:maxCount]) {
            if (branch.length == 0) {
                continue;
            }
            if ([branch isEqualToString:state.branch]) {
                continue;
            }
            addItem([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Check out %@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to check out branch"), branch], @selector(checkout:), YES).userData = branch;
        }
        [menu addItem:[NSMenuItem separatorItem]];
        addItem(NSLocalizedStringFromTableInBundle(@"Show Debug Info", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to show debug info"), @selector(debug), YES);
        [menu popUpMenuPositioningItem:menu.itemArray.firstObject atLocation:NSMakePoint(0, 0) inView:containingView];
    }];
}

- (NSString *)pathToGit {
    NSString *custom = [iTermAdvancedSettingsModel gitSearchPath];
    NSString *path = [[custom componentsSeparatedByString:@":"] firstObject];
    if (path.length) {
        return [path stringByAppendingPathComponent:@"git"];
    }
    return @"/usr/bin/git";
}

- (void)runGitCommandWithArguments:(NSArray<NSString *> *)args
                           timeout:(NSTimeInterval)timeout
                        completion:(void (^)(NSString * _Nullable output, int status))completion {
    iTermBufferedCommandRunner *runner = [[iTermBufferedCommandRunner alloc] initWithCommand:[self pathToGit]
                                                                               withArguments:args
                                                                                        path:_maker.gitPoller.currentDirectory];

    __weak iTermBufferedCommandRunner *weakRunner = runner;
    runner.completion = ^(int status) {
        iTermBufferedCommandRunner *strongRunner = weakRunner;
        if (!strongRunner) {
            completion(nil, -1);
        }
        NSString *output = [[NSString alloc] initWithData:strongRunner.output  encoding:NSUTF8StringEncoding];
        completion(output, status);
    };
    [runner runWithTimeout:timeout];
}

- (void)fetchRecentBranchesWithTimeout:(NSTimeInterval)timeout
                                 count:(NSInteger)maxCount
                            completion:(void (^)(NSArray<NSString *> *branches))completion {
    if (!_maker.onLocalhost) {
        completion(@[]);
        return;
    }
    [[iTermSlowOperationGateway sharedInstance] fetchRecentBranchesAt:_maker.gitPoller.currentDirectory
                                                                count:maxCount
                                                           completion:^(NSArray<NSString *> * _Nonnull branches) {
        completion(branches);
    }];
}

- (void)showPopover {
    _popoverVC = [[iTermTextPopoverViewController alloc] initWithNibName:@"iTermTextPopoverViewController"
                                                                  bundle:[NSBundle bundleForClass:self.class]];
    _popoverVC.popover.behavior = NSPopoverBehaviorTransient;
    [_popoverVC view];
    if ([self.delegate statusBarComponentTerminalBackgroundColorIsDark:self]) {
        _popoverVC.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    } else {
        _popoverVC.view.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
    _popoverVC.textView.font = [self.delegate statusBarComponentTerminalFont:self];
    NSRect frame = _popoverVC.view.frame;
    NSSize inset = _popoverVC.textView.textContainerInset;
    frame.size.width = [FontSizeEstimator fontSizeEstimatorForFont:_popoverVC.textView.font].size.width * 60 + iTermTextPopoverViewControllerHorizontalMarginWidth * 2 + inset.width * 2;
    _popoverVC.view.frame = frame;
    NSView *view = _view.subviews.firstObject ?: _view;
    NSRect rect = view.bounds;
    rect.size.width = [self statusBarComponentMinimumWidth];
    [_popoverVC.popover showRelativeToRect:rect
                                    ofView:view
                             preferredEdge:NSRectEdgeMaxY];
}

- (void)log:(id)sender {
    if (_logRunner) {
        [_logRunner terminate];
    }

    NSArray<NSString *> *args = @[ @"log" ];
    if (!_maker.onLocalhost) {
        [self runGitOnRemoteHost:args];
        return;
    }
    [self showPopover];
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    _logRunner = [[iTermCommandRunner alloc] initWithCommand:[self pathToGit]
                                               withArguments:args
                                                        path:context.directory];
    iTermTextPopoverViewController *popoverVC = _popoverVC;
    __weak __typeof(_logRunner) weakLogRunner = _logRunner;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    __block BOOL stopped = NO;
    _logRunner.outputHandler = ^(NSData *data, void (^completion)(void)) {
        if (stopped) {
            completion();
            return;
        }
        [popoverVC appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        if (popoverVC.textView.textStorage.length > 100000) {
            stopped = YES;
            [popoverVC appendString:NSLocalizedStringFromTableInBundle(@"\n[Truncated]\n", @"StatusBar", bundle, @"Truncation notice in git log popover")];
            [weakLogRunner terminate];
        }
        completion();
    };
    [_logRunner runWithTimeout:5];
}

- (void)commit:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"commit" ] pwd:context.directory status:NSLocalizedStringFromTableInBundle(@"Committing…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while committing") bury:NO];
}

- (void)debug {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedStringFromTableInBundle(@"Debug Info", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Debug info alert title");
    alert.informativeText = [NSString stringWithFormat:
                             NSLocalizedStringFromTableInBundle(@"Directory: %@\n"
                             @"Polling cadence: %@ sec\n"
                             @"Polling enabled: %@\n"
                             @"Last polled %@ seconds ago\n"
                             @"Repo state: %@\n"
                             @"%@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Debug info alert informative text"),
                             _maker.gitPoller.currentDirectory,
                             @(_maker.gitPoller.cadence),
                             _maker.gitPoller.enabled ? NSLocalizedStringFromTableInBundle(@"Yes", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Yes value in debug info") : NSLocalizedStringFromTableInBundle(@"No", @"StatusBar", [NSBundle bundleForClass:[self class]], @"No value in debug info"),
                             @(-[_maker.gitPoller lastPollTime].timeIntervalSinceNow),
                             [_maker.gitPoller.state prettyDescription],
                             [[iTermGitPollWorker sharedInstance] debugInfoForDirectory:_maker.gitPoller.currentDirectory]];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"OK", @"StatusBar", [NSBundle bundleForClass:[self class]], @"OK button")];
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Copy", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Copy button")];
    if ([alert runModal] == NSAlertSecondButtonReturn) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:alert.informativeText forType:NSPasteboardTypeString];
    }
}

- (void)addAndCommit:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"commit", @"-a" ] pwd:context.directory status:NSLocalizedStringFromTableInBundle(@"Committing…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while committing") bury:NO];
}

- (void)stash:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"stash" ] pwd:context.directory status:NSLocalizedStringFromTableInBundle(@"Stashing…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while stashing") bury:YES];
}

- (void)push:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"push", @"origin", context.state.branch ]
                                  pwd:context.directory
                               status:NSLocalizedStringFromTableInBundle(@"Pushing…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while pushing")
                                 bury:YES];
}

- (void)pull:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"pull", @"origin", context.state.branch ]
                                  pwd:context.directory
                               status:NSLocalizedStringFromTableInBundle(@"Pulling…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while pulling")
                                 bury:YES];
}

- (void)checkout:(id)sender {
    NSMenuItem *menuItem = sender;
    iTermGitMenuItemContext *context = menuItem.representedObject;
    [self runGitInWindowWithArguments:@[ @"checkout", context.userData ]
                                  pwd:context.directory
                               status:NSLocalizedStringFromTableInBundle(@"Checking out…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status while checking out")
                                 bury:YES];
}

- (void)runGitOnRemoteHost:(NSArray<NSString *> *)args {
    NSArray<NSString *> *quotedArgs = [args mapWithBlock:^id(NSString *arg) {
        return [arg stringWithEscapedShellCharactersIncludingNewlines:YES];
    }];
    NSString *command = [NSString stringWithFormat:@"git %@", [quotedArgs componentsJoinedByString:@" "]];
    const iTermWarningSelection selection =
    [iTermWarning showWarningWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Looks like you're sshed somewhere. OK to send the command “%@”?", @"StatusBar", [NSBundle bundleForClass:[self class]], @"SSH command confirmation warning"), command]
                               actions:@[ NSLocalizedStringFromTableInBundle(@"OK", @"StatusBar", [NSBundle bundleForClass:[self class]], @"OK button"), NSLocalizedStringFromTableInBundle(@"Cancel", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Cancel button") ]
                             accessory:nil
                            identifier:@"GitPollerSshWarning"
                           silenceable:kiTermWarningTypePermanentlySilenceable
                               heading:NSLocalizedStringFromTableInBundle(@"Send Command?", @"StatusBar", [NSBundle bundleForClass:[self class]], @"SSH command confirmation heading")
                                window:self.statusBarComponentView.window];
    if (selection == kiTermWarningSelection0) {
        [self.delegate statusBarComponent:self writeString:[command stringByAppendingString:@"\n"]];
    }
}

- (void)runGitInWindowWithArguments:(NSArray<NSString *> *)args pwd:(NSString *)pwd status:(NSString *)status bury:(BOOL)bury {
    if (_maker.status) {
        RLog(@"Not running command because status is %@", _maker.status);
        return;
    }

    if (!_maker.onLocalhost) {
        [self runGitOnRemoteHost:args];
        return;
    }

    _maker.status = status;
    [self updateTextFieldIfNeeded];
    NSString *gitWrapper = [[NSBundle bundleForClass:self.class] pathForResource:@"iterm2_git_wrapper" ofType:@"sh"];
    __weak __typeof(self) weakSelf = self;
    iTermSingleUseWindowOptions options = (iTermSingleUseWindowOptionsCloseOnTermination |
                                           iTermSingleUseWindowOptionsShortLived);
    if (bury) {
        options |= iTermSingleUseWindowOptionsInitiallyBuried;
    }
    [[iTermController sharedInstance] openSingleUseWindowWithCommand:gitWrapper
                                                           arguments:args
                                                              inject:nil
                                                         environment:nil
                                                                 pwd:pwd
                                                             options:options
                                                      didMakeSession:^(PTYSession *newSession) { self->_session = newSession; }
                                                          completion:^{
        [weakSelf didFinishCommand];
    }];
}

- (void)didFinishCommand {
    _session = nil;
    [_maker didFinishCommand];
    [self updateTextFieldIfNeeded];
}

#pragma mark - iTermGitPollerDelegate

- (BOOL)gitPollerShouldPoll:(iTermGitPoller *)poller after:(NSDate * _Nullable)lastPoll {
    if ([self.delegate statusBarComponentIsInSetupUI:self]) {
        DLog(@"Don't poll: in setup UI");
        return NO;
    }
    if (![self.delegate statusBarComponentIsVisible:self]) {
        DLog(@"Don't poll: not visible");
        return NO;
    }
    if (lastPoll == nil) {
        DLog(@"First poll. Return YES.");
        return YES;
    }

    const iTermActivityInfo activityInfo = [self.delegate statusBarComponentActivityInfo:self];
    NSDate *lastNewline = [NSDate it_dateWithTimeSinceBoot:activityInfo.lastNewline];
    // Add a 3 second grace period since git takes a moment to update. You might only pick up
    // the change on the second check after pressing enter.
    if ([lastNewline compare:[lastPoll dateByAddingTimeInterval:-3]] == NSOrderedDescending) {
        DLog(@"Newline sent since last poll-3: returning YES");
        return YES;
    }
    const NSTimeInterval pollIntervalWhenInactive = 60;
    NSDate *lastActivity = [NSDate it_dateWithTimeSinceBoot:activityInfo.lastActivity];
    if ([[NSDate date] timeIntervalSinceDate:lastPoll] > pollIntervalWhenInactive &&
        [lastActivity compare:lastPoll] == NSOrderedDescending) {
        DLog(@"Activity since last poll more than %@ seconds ago: return YES", @(pollIntervalWhenInactive));
        return YES;
    }
    DLog(@"Don't poll. lastPoll=%@ lastNewline=%@ lastActivity=%@", lastPoll, lastNewline, lastActivity);
    return NO;
}

@end

NS_ASSUME_NONNULL_END
