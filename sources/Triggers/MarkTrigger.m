//
//  MarkTrigger.m
//  iTerm
//
//  Created by George Nachman on 4/22/14.
//
//

#import "MarkTrigger.h"
#import "PTYScrollView.h"
#import "iTerm2SharedARC-Swift.h"
#import "SessionView.h"

// Whether to stop scrolling.
typedef enum {
    kMarkTriggerParamTagKeepScrolling,
    kMarkTriggerParamTagStopScrolling,
} MarkTriggerParam;

@implementation MarkTrigger

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Set Mark", @"Triggers", [NSBundle bundleForClass:[self class]], @"设置标记触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Set Mark and %@ scrolling", @"Triggers", [NSBundle bundleForClass:[self class]], @"标记触发器描述"), [self shouldStopScrolling] ? NSLocalizedStringFromTableInBundle(@"stop", @"Triggers", [NSBundle bundleForClass:[self class]], @"滚动：停止") : NSLocalizedStringFromTableInBundle(@"continue", @"Triggers", [NSBundle bundleForClass:[self class]], @"滚动：继续")];
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return @"";
}

- (BOOL)takesParameter {
    return YES;
}

- (BOOL)paramIsPopupButton {
    return YES;
}

- (BOOL)isIdempotent {
    return YES;
}

- (NSSet<NSNumber *> *)allowedMatchTypes {
    NSMutableSet *set = [NSMutableSet setWithObject:@(iTermTriggerMatchTypeRegex)];
    [set unionSet:[iTermEventTriggerMatchTypeHelper allEventTypesSet]];
    return set;
}

- (NSInteger)indexForObject:(id)object {
    int i = 0;
    for (NSNumber *n in [self objectsSortedByValueInDict:[self menuItemsForPoupupButton]]) {
        if ([n isEqual:object]) {
            return i;
        }
        i++;
    }
    return -1;
}

- (id)objectAtIndex:(NSInteger)index {
    int i = 0;

    for (NSNumber *n in [self objectsSortedByValueInDict:[self menuItemsForPoupupButton]]) {
        if (i == index) {
            return n;
        }
        i++;
    }
    return nil;
}

- (NSDictionary *)menuItemsForPoupupButton
{
    return @{ @(kMarkTriggerParamTagKeepScrolling): NSLocalizedStringFromTableInBundle(@"Keep Scrolling", @"Triggers", [NSBundle bundleForClass:[self class]], @"标记：继续滚动"),
              @(kMarkTriggerParamTagStopScrolling): NSLocalizedStringFromTableInBundle(@"Stop Scrolling", @"Triggers", [NSBundle bundleForClass:[self class]], @"标记：停止滚动") };
}

- (BOOL)shouldStopScrolling {
    return [self.param intValue] == kMarkTriggerParamTagStopScrolling;
}

- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    [aSession triggerSession:self saveCursorLineAndStopScrolling:[self shouldStopScrolling]];
    return YES;
}

- (int)defaultIndex {
    return [self indexForObject:@(kMarkTriggerParamTagKeepScrolling)];
}

- (NSAttributedString *)paramAttributedString {
    NSString *message = self.shouldStopScrolling ? NSLocalizedStringFromTableInBundle(@"and stop scrolling", @"Triggers", [NSBundle bundleForClass:[self class]], @"标记：并停止滚动") : @"";
    return [[NSAttributedString alloc] initWithString:message attributes:self.regularAttributes];
}

@end
