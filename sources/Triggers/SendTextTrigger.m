//
//  SendTextTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/24/11.
//

#import "SendTextTrigger.h"
#import "PTYSession.h"
#import "iTerm2SharedARC-Swift.h"

@implementation SendTextTrigger

+ (NSString *)title
{
    return NSLocalizedStringFromTableInBundle(@"Send Text…", @"Triggers", [NSBundle bundleForClass:[self class]], @"发送文本触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Send text “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"发送文本触发器描述"), self.param];
}

- (BOOL)takesParameter
{
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter text to send", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：输入要发送的文本");
}

// Requires a live session to send text to
- (NSSet<NSNumber *> *)allowedMatchTypes {
    NSMutableSet *set = [NSMutableSet setWithObject:@(iTermTriggerMatchTypeRegex)];
    [set unionSet:[iTermEventTriggerMatchTypeHelper allEventTypesExceptSessionEndedSet]];
    return set;
}


- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    // Need to stop the world to get scope, provided it is needed. This will be a modest performance issue at most.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull message) {
        [scheduler scheduleTriggerCallback:^{
            [aSession triggerSession:self writeText:message];
        }];
    }];
    return YES;
}

@end
