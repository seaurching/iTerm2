//
//  BellTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/23/11.
//

#import "BellTrigger.h"

#import "DebugLogging.h"
#import "VT100Screen.h"
#import "iTerm2SharedARC-Swift.h"

@implementation BellTrigger

- (NSString *)description {
    return NSLocalizedStringFromTableInBundle(@"Ring Bell", @"Triggers", [NSBundle bundleForClass:[self class]], @"响铃触发器");
}

+ (NSString *)title
{
    return NSLocalizedStringFromTableInBundle(@"Ring Bell", @"Triggers", [NSBundle bundleForClass:[self class]], @"响铃触发器");
}

- (BOOL)takesParameter
{
    return NO;
}

- (NSSet<NSNumber *> *)allowedMatchTypes {
    NSMutableSet *set = [NSMutableSet setWithObject:@(iTermTriggerMatchTypeRegex)];
    [set unionSet:[iTermEventTriggerMatchTypeHelper allEventTypesSet]];
    return set;
}

- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    DLog(@"Ring bell trigger running");
    [aSession triggerSessionRingBell:self];
    return YES;
}

@end
