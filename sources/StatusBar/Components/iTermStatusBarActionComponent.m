//
//  iTermStatusBarActionComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 3/22/19.
//

#import "iTermStatusBarActionComponent.h"
#import "iTermActionsModel.h"
#import "iTermScriptHistory.h"
#import "iTermSwiftyString.h"
#import "NSArray+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "NSImage+iTerm.h"
#import "RegexKitLite.h"

static NSString *const iTermStatusBarActionKey = @"action";

@implementation iTermStatusBarActionComponent {
    NSString *_value;
    iTermSwiftyString *_swiftyString;
}

- (nullable NSArray<NSString *> *)stringVariants {
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    [_value enumerateStringsSeparatedByRegex:@"\\h+"
                                     options:RKLNoOptions
                                     inRange:NSMakeRange(0, _value.length)
                                       error:nil
                          enumerationOptions:RKLRegexEnumerationNoOptions
                                  usingBlock:
     ^(NSInteger captureCount,
       NSString *const __unsafe_unretained *capturedStrings,
       const NSRange *capturedRanges,
       volatile BOOL *const stop) {

        [result addObject:[self->_value substringToIndex:NSMaxRange(capturedRanges[0])]];
    }];
    return result;
}

- (void)setStringValue:(NSString *)value {
    _value = [value copy];
    [self updateTextFieldIfNeeded];
}

- (NSArray<iTermStatusBarComponentKnob *> *)statusBarComponentKnobs {
    iTermStatusBarComponentKnob *actionKnob =
    [[iTermStatusBarComponentKnob alloc] initWithLabelText:NSLocalizedStringFromTableInBundle(@"Action", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Knob label for action")
                                                      type:iTermStatusBarComponentKnobTypeAction
                                               placeholder:nil
                                              defaultValue:nil
                                                       key:iTermStatusBarActionKey];
    return [@[ actionKnob, [super statusBarComponentKnobs] ] flattenedArray];
}

- (NSDictionary *)actionDictionary {
    return self.configuration[iTermStatusBarComponentConfigurationKeyKnobValues][iTermStatusBarActionKey];
}

- (iTermAction *)action {
    return [[iTermAction alloc] initWithDictionary:self.actionDictionary];
}

- (void)updateTitleInButton {
    if (_swiftyString) {
        _swiftyString.swiftyString = self.action.title;
        return;
    }
    __weak __typeof(self) weakSelf = self;
    NSString *expression = self.action.title.copy ?: @"";
    _swiftyString = [[iTermSwiftyString alloc] initWithString:expression
                                                        scope:self.scope
                                           sideEffectsAllowed:false
                                                     observer:^(NSString * _Nonnull newValue, NSError *error) {
        if (error != nil) {
            [[iTermScriptHistoryEntry globalEntry] addOutput:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Error while evaluating %@ in status bar action button: %@", @"StatusBar", [NSBundle bundleForClass:[iTermStatusBarActionComponent class]], @"Error log format for action button title evaluation"), expression, error]
                                                  completion:^{}];
            return [NSString stringWithFormat:@"🐞 %@", error.localizedDescription];
        }
        [weakSelf setStringValue:newValue];
        return newValue;
    }];
}

- (NSString *)statusBarComponentShortDescription {
    return NSLocalizedStringFromTableInBundle(@"Custom Action", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status bar component short description");
}

- (BOOL)statusBarComponentCanStretch {
    return YES;
}

- (NSString *)statusBarComponentDetailedDescription {
    return NSLocalizedStringFromTableInBundle(@"Adds a button that performs a user-configurable action, similar to a key binding.", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status bar component detailed description");
}

- (id)statusBarComponentExemplarWithBackgroundColor:(NSColor *)backgroundColor
                                          textColor:(NSColor *)textColor {
    NSDictionary *dict = self.actionDictionary;
    if (dict.count) {
        return self.action.title;
    } else {
        return NSLocalizedStringFromTableInBundle(@"Custom Action", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Exemplar text for custom action component");
    }
}

- (void)setDelegate:(id<iTermStatusBarComponentDelegate> _Nullable)delegate {
    [super setDelegate:delegate];
    [self updateTitleInButton];
}

- (nullable NSImage *)statusBarComponentIcon {
    return [NSImage it_cacheableImageNamed:@"StatusBarIconAction" forClass:[self class]];
}

- (NSString *)statusBarComponentCopyableString {
    return nil;
}

- (BOOL)statusBarComponentHandlesClicks {
    return YES;
}

- (BOOL)statusBarComponentIsEmpty {
    return NO;
}

- (void)statusBarComponentDidClickWithView:(NSView *)view {
    if (self.actionDictionary) {
        [self.delegate statusBarComponentPerformAction:self.action];
    }
}

@end

@implementation iTermStatusBarActionMenuComponent

- (NSString *)statusBarComponentCopyableString {
    return nil;
}

- (nullable NSImage *)statusBarComponentIcon {
    return [NSImage it_cacheableImageNamed:@"StatusBarIconAction" forClass:[self class]];
}

- (NSString *)statusBarComponentShortDescription {
    return NSLocalizedStringFromTableInBundle(@"Actions Menu", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status bar component short description");
}

- (NSString *)statusBarComponentDetailedDescription {
    return NSLocalizedStringFromTableInBundle(@"When clicked, opens a menu of actions. Actions are like custom key bindings, but without a keystroke attached.", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status bar component detailed description");
}

- (id)statusBarComponentExemplarWithBackgroundColor:(NSColor *)backgroundColor
                                          textColor:(NSColor *)textColor {
    return NSLocalizedStringFromTableInBundle(@"Action…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Exemplar text for actions menu component");
}

- (BOOL)statusBarComponentCanStretch {
    return YES;
}

- (nullable NSString *)stringValue {
    return NSLocalizedStringFromTableInBundle(@"Perform Action…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"String value for actions menu button");
}

- (nullable NSString *)stringValueForCurrentWidth {
    return self.stringValue;
}

- (nullable NSArray<NSString *> *)stringVariants {
    return @[ self.stringValue ];
}

- (BOOL)statusBarComponentHandlesClicks {
    return YES;
}

- (BOOL)statusBarComponentIsEmpty {
    return [[[iTermActionsModel sharedInstance] actions] count] == 0;
}

- (void)statusBarComponentDidClickWithView:(NSView *)view {
    [self openMenuWithView:view];
}

- (void)statusBarComponentMouseDownWithView:(NSView *)view {
    [self openMenuWithView:view];
}

- (BOOL)statusBarComponentHandlesMouseDown {
    return YES;
}

- (void)openMenuWithView:(NSView *)view {
    NSView *containingView = view.superview;

    NSMenu *menu = [[NSMenu alloc] init];
    for (iTermAction *action in [[iTermActionsModel sharedInstance] actions]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:action.title action:@selector(performAction:) keyEquivalent:@""];
        item.identifier = [@(action.identifier) stringValue];
        item.target = self;
        [menu addItem:item];
    }

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Edit Actions…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item title for editing actions") action:@selector(editActions:) keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];

    [menu popUpMenuPositioningItem:menu.itemArray.firstObject atLocation:NSMakePoint(0, 0) inView:containingView];
}

- (void)performAction:(id)sender {
    NSMenuItem *menuItem = [NSMenuItem castFrom:sender];
    if (!menuItem) {
        return;
    }
    iTermAction *action = [[iTermActionsModel sharedInstance] actionWithIdentifier:[menuItem.identifier integerValue]];
    if (!action) {
        return;
    }
    [self.delegate statusBarComponentPerformAction:action];
}

- (void)editActions:(id)sender {
    [self.delegate statusBarComponentEditActions:self];
}

@end
