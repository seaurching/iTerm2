//
//  iTermUserNotificationTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/23/11.
//

#import "iTermUserNotificationTrigger.h"
#import "iTermAdvancedSettingsModel.h"
#import "iTerm2SharedARC-Swift.h"
#import "iTermNotificationController.h"
#import "iTermRateLimitedUpdate.h"
#import "PTYSession.h"
#import "PTYTab.h"

// I foolishly renamed GrowlTrigger to iTermUserNotificationTrigger in 3.2.1, which broke everyone's triggers.
// It got renamed back in 3.2.2. If someone created a new trigger in 3.2.1 it would have the bogus name.
// Then the 3.3.0 betas didn't cherrypick the fix, so more problems. I'm done with this so let's just
// keep both around forever.
@interface GrowlTrigger : iTermUserNotificationTrigger
@end

@implementation GrowlTrigger
@end

@implementation iTermUserNotificationTrigger {
    iTermRateLimitedUpdate *_rateLimit;
}

+ (NSSet<NSString *> *)synonyms {
    return [NSSet setWithObject:@"GrowlTrigger"];
}

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Post Notification…", @"Triggers", [NSBundle bundleForClass:[self class]], @"发送通知触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Post Notification “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"发送通知触发器描述"), self.param];
}

- (BOOL)takesParameter {
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter Message", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：输入消息");
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
    // Need to stop the world to get scope, provided it is needed. Notifs are so slow & rare that this is ok.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull notificationText) {
        [scheduler scheduleTriggerCallback:^{
            [self postNotificationWithText:notificationText inSession:aSession];
        }];
    }];
    return YES;
}

- (iTermRateLimitedUpdate *)rateLimit {
    if (!_rateLimit) {
        _rateLimit = [[iTermRateLimitedUpdate alloc] initWithName:@"UserNotificationTrigger"
                                                  minimumInterval:[iTermAdvancedSettingsModel userNotificationTriggerRateLimit]];
        _rateLimit.suppressionMode = YES;
    }
    return _rateLimit;
}

- (void)postNotificationWithText:(NSString *)notificationText
                       inSession:(id<iTermTriggerSession>)aSession {
    if (!notificationText) {
        return;
    }
    [aSession triggerSession:self postUserNotificationWithMessage:notificationText rateLimit:[self rateLimit]];
}

@end
