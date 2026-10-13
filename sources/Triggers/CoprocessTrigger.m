//
//  InteractiveScriptTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/24/11.
//  Copyright 2011 Georgetech. All rights reserved.
//

#import "CoprocessTrigger.h"
#import "iTermAnnouncementViewController.h"
#import "PTYSession.h"
#import "iTerm2SharedARC-Swift.h"

static NSString *const kSuppressCoprocessTriggerWarning = @"NoSyncSuppressCoprocessTriggerWarning";

@implementation CoprocessTrigger

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Run Coprocess…", @"Triggers", [NSBundle bundleForClass:[self class]], @"运行协进程触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Run Coprocess “%@”", @"Triggers", [NSBundle bundleForClass:[self class]], @"运行协进程触发器描述"), self.param];
}

- (BOOL)takesParameter {
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter coprocess command to run", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：输入协进程命令");
}

// Requires a live session to launch a coprocess
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
    // Need to stop the world to get scope, provided it is needed. Coprocesses are so slow & rare that this is ok.
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull command) {
        [scheduler scheduleTriggerCallback:^{
            [aSession triggerSession:self
          launchCoprocessWithCommand:command
                          identifier:kSuppressCoprocessTriggerWarning
                              silent:self.isSilent];
        }];
    }];
    return YES;
}

- (BOOL)isSilent {
    return NO;
}

@end

@implementation MuteCoprocessTrigger

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Run Silent Coprocess…", @"Triggers", [NSBundle bundleForClass:[self class]], @"运行静默协进程触发器标题");
}

- (BOOL)takesParameter {
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter coprocess command to run", @"Triggers", [NSBundle bundleForClass:[self class]], @"占位符：输入协进程命令");
}

- (BOOL)isSilent {
    return YES;
}

@end
