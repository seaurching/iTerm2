//
//  iTermStatusBarSnippetComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 9/9/20.
//

#import "iTermStatusBarSnippetComponent.h"
#import "iTermSnippetsMenuController.h"
#import "iTermSnippetsModel.h"
#import "iTermScriptHistory.h"
#import "iTermSwiftyString.h"
#import "NSArray+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "NSImage+iTerm.h"
#import "RegexKitLite.h"

@implementation iTermStatusBarSnippetMenuComponent

- (nullable NSImage *)statusBarComponentIcon {
    return [NSImage it_cacheableImageNamed:@"StatusBarIconSnippet" forClass:[self class]];
}

- (NSString *)statusBarComponentShortDescription {
    return NSLocalizedStringFromTableInBundle(@"Snippets Menu", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Short description for snippets menu component");
}

- (NSString *)statusBarComponentDetailedDescription {
    return NSLocalizedStringFromTableInBundle(@"When clicked, opens a menu of snippets. Snippets are saved text strings that can be pasted quickly.", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Detailed description for snippets menu component");
}

- (id)statusBarComponentExemplarWithBackgroundColor:(NSColor *)backgroundColor
                                          textColor:(NSColor *)textColor {
    return NSLocalizedStringFromTableInBundle(@"Snippet…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Exemplar text for snippets menu component");
}

- (BOOL)statusBarComponentCanStretch {
    return YES;
}

- (nullable NSString *)stringValue {
    return NSLocalizedStringFromTableInBundle(@"Send Snippet…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Status bar string value for snippets menu component");
}

- (nullable NSString *)stringValueForCurrentWidth {
    return self.stringValue;
}

- (nullable NSArray<NSString *> *)stringVariants {
    return @[ self.stringValue ];
}

- (NSString *)statusBarComponentCopyableString {
    return nil;
}

- (BOOL)statusBarComponentHandlesClicks {
    return YES;
}

- (BOOL)statusBarComponentIsEmpty {
    return [[[iTermSnippetsModel sharedInstance] snippets] count] == 0;
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
    iTermSnippetsMenuController *menuController = [[iTermSnippetsMenuController alloc] init];
    menuController.menu = menu;

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Edit Snippets…", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Menu item to edit snippets") action:@selector(editSnippets:) keyEquivalent:@""];
    item.target = self;
    [menu addItem:item];

    [menu popUpMenuPositioningItem:menu.itemArray.firstObject atLocation:NSMakePoint(0, 0) inView:containingView];
}

- (void)editSnippets:(id)sender {
    [self.delegate statusBarComponentEditSnippets:self];
}

@end
