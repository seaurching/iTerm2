//
//  iTermCursorBlinkFadePreset.m
//  iTerm2
//

#import "iTermCursorBlinkFadePreset.h"

@implementation iTermCursorBlinkFadePreset

- (instancetype)initWithName:(NSString *)name
              fadeInDuration:(NSTimeInterval)fadeInDuration
             fadeOutDuration:(NSTimeInterval)fadeOutDuration
                 fadeInCurve:(iTermCursorBlinkFadeCurve)fadeInCurve
                fadeOutCurve:(iTermCursorBlinkFadeCurve)fadeOutCurve
                visibleDwell:(NSTimeInterval)visibleDwell
                 hiddenDwell:(NSTimeInterval)hiddenDwell {
    self = [super init];
    if (self) {
        _name = [name copy];
        _fadeInDuration = fadeInDuration;
        _fadeOutDuration = fadeOutDuration;
        _fadeInCurve = fadeInCurve;
        _fadeOutCurve = fadeOutCurve;
        _visibleDwell = visibleDwell;
        _hiddenDwell = hiddenDwell;
    }
    return self;
}

+ (NSArray<iTermCursorBlinkFadePreset *> *)presets {
    static NSArray<iTermCursorBlinkFadePreset *> *presets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presets = @[
            // Slow, meditative, symmetric breath.
            [[iTermCursorBlinkFadePreset alloc] initWithName:NSLocalizedStringFromTableInBundle(@"Breathing", @"Settings", [NSBundle bundleForClass:[self class]], @"Cursor blink preset: breathing")
                                              fadeInDuration:0.9
                                             fadeOutDuration:0.9
                                                 fadeInCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                fadeOutCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                visibleDwell:0.5
                                                 hiddenDwell:0.5],
            // Neutral, constant-rate fade.
            [[iTermCursorBlinkFadePreset alloc] initWithName:NSLocalizedStringFromTableInBundle(@"Linear", @"Settings", [NSBundle bundleForClass:[self class]], @"Cursor blink preset: linear")
                                              fadeInDuration:0.4
                                             fadeOutDuration:0.4
                                                 fadeInCurve:iTermCursorBlinkFadeCurveLinear
                                                fadeOutCurve:iTermCursorBlinkFadeCurveLinear
                                                visibleDwell:0.7
                                                 hiddenDwell:0.5],
            // Quick but still smooth.
            [[iTermCursorBlinkFadePreset alloc] initWithName:NSLocalizedStringFromTableInBundle(@"Fast", @"Settings", [NSBundle bundleForClass:[self class]], @"Cursor blink preset: fast")
                                              fadeInDuration:0.2
                                             fadeOutDuration:0.2
                                                 fadeInCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                fadeOutCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                visibleDwell:0.7
                                                 hiddenDwell:0.2],
            // Slow, with a longer fade-out than fade-in.
            [[iTermCursorBlinkFadePreset alloc] initWithName:NSLocalizedStringFromTableInBundle(@"Slow", @"Settings", [NSBundle bundleForClass:[self class]], @"Cursor blink preset: slow")
                                              fadeInDuration:0.5
                                             fadeOutDuration:0.75
                                                 fadeInCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                fadeOutCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                visibleDwell:1.0
                                                 hiddenDwell:0.2],
            // Mostly solid with a brief, soft dip.
            [[iTermCursorBlinkFadePreset alloc] initWithName:NSLocalizedStringFromTableInBundle(@"Subtle", @"Settings", [NSBundle bundleForClass:[self class]], @"Cursor blink preset: subtle")
                                              fadeInDuration:0.15
                                             fadeOutDuration:0.15
                                                 fadeInCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                fadeOutCurve:iTermCursorBlinkFadeCurveEaseInOut
                                                visibleDwell:0.9
                                                 hiddenDwell:0.2],
        ];
    });
    return presets;
}

+ (iTermCursorBlinkFadePreset *)presetWithTag:(NSInteger)tag {
    NSArray<iTermCursorBlinkFadePreset *> *presets = [self presets];
    if (tag < 0 || tag >= (NSInteger)presets.count) {
        return nil;
    }
    return presets[tag];
}

- (BOOL)matchesFadeInDuration:(NSTimeInterval)fadeInDuration
             fadeOutDuration:(NSTimeInterval)fadeOutDuration
                 fadeInCurve:(iTermCursorBlinkFadeCurve)fadeInCurve
                fadeOutCurve:(iTermCursorBlinkFadeCurve)fadeOutCurve
                visibleDwell:(NSTimeInterval)visibleDwell
                 hiddenDwell:(NSTimeInterval)hiddenDwell {
    const NSTimeInterval tolerance = 0.001;
    return (fabs(_fadeInDuration - fadeInDuration) < tolerance &&
            fabs(_fadeOutDuration - fadeOutDuration) < tolerance &&
            _fadeInCurve == fadeInCurve &&
            _fadeOutCurve == fadeOutCurve &&
            fabs(_visibleDwell - visibleDwell) < tolerance &&
            fabs(_hiddenDwell - hiddenDwell) < tolerance);
}

@end
