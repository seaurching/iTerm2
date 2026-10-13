//
//  SetHostnameTrigger.m
//  iTerm2
//
//  Created by George Nachman on 11/9/15.
//
//

#import "SetHostnameTrigger.h"

@implementation SetHostnameTrigger

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Report User & Host", @"Triggers", [NSBundle bundleForClass:[self class]], @"报告用户与主机触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Report User & Host as “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"报告用户与主机触发器描述"), self.param];
}

- (BOOL)takesParameter{
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"username@hostname", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：用户名@主机名");
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
    // Need to stop the world to get scope, provided it is needed. Hostname changes are slow & rare that this is ok.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull remoteHost) {
        if (remoteHost.length) {
            [scheduler scheduleTriggerCallback:^{
                [aSession triggerSession:self setRemoteHostName:remoteHost];
            }];
        }
    }];
    return YES;
}

@end
