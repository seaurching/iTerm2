//
//  iTermSetTitleTrigger.m
//  iTerm2
//
//  Created by George Nachman on 1/1/17.
//
//

#import "iTermSetTitleTrigger.h"

#import "iTermSessionNameController.h"
#import "iTerm2SharedARC-Swift.h"

@implementation iTermSetTitleTrigger

+ (NSString *)title
{
    return NSLocalizedStringFromTableInBundle(@"Set Title…", @"Triggers", [NSBundle bundleForClass:[self class]], @"设置标题触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Set Title to “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"设置标题触发器描述"), self.param];
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter new title", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：输入新标题");
}

- (BOOL)isIdempotent {
    return YES;
}

- (BOOL)takesParameter
{
    return YES;
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
    // Need to stop the world to get scope, provided it is needed. Title changes are slow & rare that this is ok.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull newName) {
        [scheduler scheduleTriggerCallback:^{
            [aSession triggerSession:self didChangeNameTo:newName];
        }];
    }];
    return YES;
}

@end
