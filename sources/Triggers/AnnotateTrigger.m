//
//  AnnotateTrigger.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 2/13/19.
//

#import "AnnotateTrigger.h"
#import "ScreenChar.h"
#import "PTYAnnotation.h"

@implementation AnnotateTrigger

+ (NSString *)title
{
    return NSLocalizedStringFromTableInBundle(@"Annotate…",
                                              @"iTerm",
                                              [NSBundle bundleForClass: self],
                                              @"Trigger title");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Annotate as as “%@”",
                                                                        @"iTerm",
                                                                        [NSBundle bundleForClass: [self class]],
                                                                        @"Trigger description"),
            self.param];
}

- (BOOL)takesParameter
{
    return YES;
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return NSLocalizedStringFromTableInBundle(@"Enter annotation",
                                              @"iTerm",
                                              [NSBundle bundleForClass: [self class]],
                                              @"Trigger parameter placeholder");
}

// Annotations require captured text ranges, so not compatible with event triggers
- (NSSet<NSNumber *> *)allowedMatchTypes {
    return [NSSet setWithArray:@[ @(iTermTriggerMatchTypeRegex) ]];
}


- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    const NSRange rangeInString = capturedRanges[0];
    const NSRange rangeInScreenChars = [stringLine rangeOfScreenCharsForRangeInString:rangeInString];
    const long long length = rangeInScreenChars.length;
    if (length == 0) {
        return YES;
    }
    if ([aSession triggerSessionIsInAlternateScreen]) {
        // Don't allow annotations to be created in alternate screen mode because they won't behave
        // well.
        return YES;
    }
    // Need to stop the world to get scope, provided it is needed. This is potentially going to be a performance problem for a small number of users.
    id<PTYAnnotationReading> annotation =
        [aSession triggerSession:self
           makeAnnotationInRange:rangeInScreenChars
                            line:lineNumber];
    if (!annotation) {
        return YES;
    }
    id<iTermTriggerScopeProvider> scopeProvider = [aSession triggerSessionVariableScopeProvider:self];
    id<iTermTriggerCallbackScheduler> scheduler = [scopeProvider triggerCallbackScheduler];
    [[self paramWithBackreferencesReplacedWithValues:stringArray
                                             absLine:lineNumber
                                               scope:scopeProvider
                                    useInterpolation:useInterpolation] then:^(NSString * _Nonnull text) {
        [scheduler scheduleTriggerCallback:^{
            [aSession triggerSession:self
                       setAnnotation:annotation
                            stringTo:text];
        }];
    }];
    return YES;
}

@end
