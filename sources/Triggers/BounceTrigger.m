//
//  BounceTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/23/11.
//

#import "BounceTrigger.h"
#import "iTerm2SharedARC-Swift.h"

// How to bounce. The parameter takes an integer value equal to one of these. This is the tag.
typedef NS_ENUM(int, BounceTriggerParamTag) {
    kBounceTriggerParamTagBounceUntilFocus,
    kBounceTriggerParamTagBounceOnce,
};

@implementation BounceTrigger

+ (NSString *)title
{
    return NSLocalizedStringFromTableInBundle(@"Bounce Dock Icon", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动 Dock 触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Bounce dock icon %@", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动触发器描述"), self.bounceType == NSCriticalRequest ? NSLocalizedStringFromTableInBundle(@"until focused", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动：直到获焦") : NSLocalizedStringFromTableInBundle(@"once", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动：一次")];
}

- (NSString *)paramPlaceholder
{
    return @"";
}

- (BOOL)takesParameter
{
    return YES;
}

- (BOOL)paramIsPopupButton
{
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

+ (NSString *)stringForParameter:(BounceTriggerParamTag)parameter {
    switch (parameter) {
        case kBounceTriggerParamTagBounceUntilFocus:
            return NSLocalizedStringFromTableInBundle(@"Bounce Until Activated", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动：直到激活");
        case kBounceTriggerParamTagBounceOnce:
            return NSLocalizedStringFromTableInBundle(@"Bounce Once", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动：一次");
    }
    return NSLocalizedStringFromTableInBundle(@"Bounce Until Activated", @"Triggers", [NSBundle bundleForClass:[self class]], @"跳动：直到激活");
}

- (NSDictionary *)menuItemsForPoupupButton
{
    return @{ @(kBounceTriggerParamTagBounceUntilFocus): [BounceTrigger stringForParameter:kBounceTriggerParamTagBounceUntilFocus],
              @(kBounceTriggerParamTagBounceOnce): [BounceTrigger stringForParameter:kBounceTriggerParamTagBounceOnce] };
}

- (NSRequestUserAttentionType)bounceType
{
    switch ([self.param intValue]) {
        case kBounceTriggerParamTagBounceUntilFocus:
            return NSCriticalRequest;

        case kBounceTriggerParamTagBounceOnce:
            return NSInformationalRequest;

        default:
            return NSCriticalRequest;
    }
}

- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    const NSRequestUserAttentionType bounceType = [self bounceType];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp requestUserAttention:bounceType];
    });
    return YES;
}

- (int)defaultIndex {
    return [self indexForObject:@(kBounceTriggerParamTagBounceUntilFocus)];
}

- (NSAttributedString *)paramAttributedString {
    return [[NSAttributedString alloc] initWithString:[BounceTrigger stringForParameter:[[NSNumber castFrom:self.param] intValue]]
                                           attributes:self.regularAttributes];
}

@end
