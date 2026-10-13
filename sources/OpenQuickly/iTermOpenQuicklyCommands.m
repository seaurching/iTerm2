//
//  iTermOpenQuicklyCommands.m
//  iTerm2
//
//  Created by George Nachman on 3/7/16.
//
//

#import "iTermOpenQuicklyCommands.h"

@implementation iTermOpenQuicklyCommand

@synthesize text = _text;

- (void)dealloc {
    [_text release];
    [super dealloc];
}
+ (NSString *)tipTitle {

    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Tip: Start your query with “/%@”", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: tip title"), [self command]];
}

+ (NSString *)tipDetail {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Restricts results to %@", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: tip detail"), [self restrictionDescription]];
}

+ (NSString *)command {
    return nil;
}

+ (NSString *)restrictionDescription {
    return nil;
}

- (BOOL)supportsSessionLocation {
    return NO;
}

- (BOOL)supportsWindowLocation {
    return NO;
}

- (BOOL)supportsCreateNewTab {
    return NO;
}

- (BOOL)supportsChangeProfile {
    return NO;
}

- (BOOL)supportsOpenArrangement:(out BOOL *)tabsOnlyPtr {
    return NO;
}

- (BOOL)supportsScript {
    return NO;
}

- (BOOL)supportsColorPreset {
    return NO;
}

- (BOOL)supportsAction {
    return NO;
}

- (BOOL)supportsSnippet {
    return NO;
}

- (BOOL)supportsNamedMarks {
    return NO;
}

- (BOOL)supportsMenuItems {
    return NO;
}

- (BOOL)supportsBookmarks {
    return NO;
}

- (BOOL)supportsURLs {
    return NO;
}

@end

@implementation iTermOpenQuicklyInTabsWindowArrangementCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"window arrangements that open in tabs", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: in-tabs arrangement restriction");
}

+ (NSString *)command {
    return @"A";
}

- (BOOL)supportsOpenArrangement:(out BOOL *)tabsOnlyPtr {
    *tabsOnlyPtr = YES;
    return YES;
}

@end

@implementation iTermOpenQuicklyWindowArrangementCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"window arrangements", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: arrangement restriction");
}

+ (NSString *)command {
    return @"a";
}

- (BOOL)supportsOpenArrangement:(out BOOL *)tabsOnlyPtr {
    *tabsOnlyPtr = NO;
    return YES;
}

@end

@implementation iTermOpenQuicklySearchSessionsCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"existing sessions", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: sessions restriction");
}

+ (NSString *)command {
    return @"f";
}

- (BOOL)supportsSessionLocation {
    return YES;
}

@end

@implementation iTermOpenQuicklySearchWindowsCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"existing windows", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: windows restriction");
}

+ (NSString *)command {
    return @"w";
}

- (BOOL)supportsWindowLocation {
    return YES;
}

@end

@implementation iTermOpenQuicklySwitchProfileCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"switch profiles", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: switch profiles restriction");
}

+ (NSString *)command {
    return @"p";
}

- (BOOL)supportsChangeProfile {
    return YES;
}

@end

@implementation iTermOpenQuicklyCreateTabCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"create tab", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: create tab restriction");
}

+ (NSString *)command {
    return @"t";
}

- (BOOL)supportsCreateNewTab {
    return YES;
}

@end

@implementation iTermOpenQuicklyScriptCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"run script", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: run script restriction");
}

+ (NSString *)command {
    return @"s";
}

- (BOOL)supportsScript {
    return YES;
}

@end

@implementation iTermOpenQuicklyColorPresetCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"load color preset", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: load color preset restriction");
}

+ (NSString *)command {
    return @"c";
}

- (BOOL)supportsColorPreset {
    return YES;
}

@end

@implementation iTermOpenQuicklyNoCommand

- (BOOL)supportsSessionLocation {
    return YES;
}

- (BOOL)supportsCreateNewTab {
    return YES;
}

- (BOOL)supportsChangeProfile {
    return YES;
}

- (BOOL)supportsOpenArrangement:(out BOOL *)tabsOnlyPtr {
    *tabsOnlyPtr = NO;
    return YES;
}

- (BOOL)supportsScript {
    return YES;
}

- (BOOL)supportsColorPreset {
    return YES;
}

- (BOOL)supportsAction {
    return YES;
}

- (BOOL)supportsSnippet {
    return YES;
}

- (BOOL)supportsWindowLocation {
    return YES;
}

- (BOOL)supportsNamedMarks {
    return YES;
}

- (BOOL)supportsMenuItems {
    return YES;
}

- (BOOL)supportsBookmarks {
    return YES;
}

- (BOOL)supportsURLs {
    return YES;
}

@end

@implementation iTermOpenQuicklyActionCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"perform action", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: perform action restriction");
}

+ (NSString *)command {
    return @":";
}

- (BOOL)supportsAction {
    return YES;
}

@end

@implementation iTermOpenQuicklySnippetCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"send snippet", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: send snippet restriction");
}

+ (NSString *)command {
    return @".";
}

- (BOOL)supportsSnippet {
    return YES;
}

@end

@implementation iTermOpenQuicklyBookmarkCommand

+ (NSString *)restrictionDescription {
    return NSLocalizedStringFromTableInBundle(@"open bookmark", @"OpenQuickly", [NSBundle bundleForClass:[self class]], @"Open Quickly: open bookmark restriction");
}

+ (NSString *)command {
    return @"b";
}

- (BOOL)supportsBookmarks {
    return YES;
}

@end
