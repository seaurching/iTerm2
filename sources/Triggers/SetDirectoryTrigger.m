//
//  SetDirectoryTrigger.m
//  iTerm2
//
//  Created by George Nachman on 11/9/15.
//
//

#import "SetDirectoryTrigger.h"

#import "DebugLogging.h"

@implementation SetDirectoryTrigger

+ (NSString *)title {
  return NSLocalizedStringFromTableInBundle(@"Report Directory", @"Triggers", [NSBundle bundleForClass:[self class]], @"报告目录触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Report Directory as “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"报告目录触发器描述"), self.param];
}

- (BOOL)takesParameter{
  return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
  return NSLocalizedStringFromTableInBundle(@"Directory", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：目录");
}

- (BOOL)isIdempotent {
    return YES;
}

- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    // Need to stop the world to get scope, provided it is needed. Directory changes slow & rare that this is ok.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull currentDirectory) {
        RLog(@"SetDirectoryTrigger completed substitution with %@", currentDirectory);
        if (currentDirectory.length) {
            [scheduler scheduleTriggerCallback:^{
                [aSession triggerSession:self setCurrentDirectory:currentDirectory];
            }];
        }
    }];
    return YES;
}


@end
