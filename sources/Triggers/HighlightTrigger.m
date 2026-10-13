//
//  HighlightTrigger.m
//  iTerm2
//
//  Created by George Nachman on 9/23/11.
//

#import "HighlightTrigger.h"
#import "NSColor+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "NSImage+iTerm.h"
#import "ScreenChar.h"

NSString * const kHighlightForegroundColor = @"kHighlightForegroundColor";
NSString * const kHighlightBackgroundColor = @"kHighlightBackgroundColor";


// Preserve these values - they are the tags and are saved in preferences.
enum {
    kYellowOnBlackHighlight,
    kBlackOnYellowHighlight,
    kWhiteOnRedHighlight,
    kRedOnWhiteHighlight,
    kBlackOnOrangeHighlight,
    kOrangeOnBlackHighlight,
    kBlackOnPurpleHighlight,
    kPurpleOnBlackHighlight,

    kBlackHighlight = 1000,
    kDarkGrayHighlight,
    kLightGrayHighlight,
    kWhiteHighlight,
    kGrayHighlight,
    kRedHighlight,
    kGreenHighlight,
    kBlueHighlight,
    kCyanHighlight,
    kYellowHighlight,
    kMagentaHighlight,
    kOrangeHighlight,
    kPurpleHighlight,
    kBrownHighlight,

    kBlackBackgroundHighlight = 2000,
    kDarkGrayBackgroundHighlight,
    kLightGrayBackgroundHighlight,
    kWhiteBackgroundHighlight,
    kGrayBackgroundHighlight,
    kRedBackgroundHighlight,
    kGreenBackgroundHighlight,
    kBlueBackgroundHighlight,
    kCyanBackgroundHighlight,
    kYellowBackgroundHighlight,
    kMagentaBackgroundHighlight,
    kOrangeBackgroundHighlight,
    kPurpleBackgroundHighlight,
    kBrownBackgroundHighlight,


};

@implementation HighlightTrigger {
    NSDictionary *_cachedColors;
}

+ (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Highlight Text…", @"Triggers", [NSBundle bundleForClass:[self class]], @"高亮文本触发器标题");
}

- (NSString *)description {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Highlight text %@ over %@", @"Triggers", [NSBundle bundleForClass:[self class]], @"高亮触发器描述"), self.textColor.humanReadableDescription ?: NSLocalizedStringFromTableInBundle(@"(no color)", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：无颜色"), self.backgroundColor.humanReadableDescription ?: NSLocalizedStringFromTableInBundle(@"(no color)", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：无颜色")];
}

- (NSString *)triggerOptionalParameterPlaceholderWithInterpolation:(BOOL)interpolation {
    return @"";
}

- (BOOL)takesParameter
{
    return YES;
}

- (BOOL)paramIsPopupButton {
    return NO;
}

- (BOOL)paramIsTwoColorWells {
    return YES;
}

- (BOOL)isIdempotent {
    return YES;
}

- (void)sanitize {
    NSDictionary *colors = [self colorsPreservingColorSpace:YES];
    self.textColor = colors[kHighlightForegroundColor];
    self.backgroundColor = colors[kHighlightBackgroundColor];
}

- (NSColor *)textColorInParam:(id)param {
    NSDictionary *colors = [HighlightTrigger colorsPreservingColorSpace:NO param:param];
    return colors[kHighlightForegroundColor];
}

- (NSColor *)backgroundColorInParam:(id)param {
    NSDictionary *colors = [HighlightTrigger colorsPreservingColorSpace:NO param:param];
    return colors[kHighlightBackgroundColor];
}

- (NSDictionary *)menuItemsForPoupupButton {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedStringFromTableInBundle(@"Yellow on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黄字黑底"), [NSNumber numberWithInt:(int)kYellowOnBlackHighlight],
            NSLocalizedStringFromTableInBundle(@"Black on Yellow", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字黄底"), [NSNumber numberWithInt:(int)kBlackOnYellowHighlight],
            NSLocalizedStringFromTableInBundle(@"White on Red", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：白字红底"), [NSNumber numberWithInt:(int)kWhiteOnRedHighlight],
            NSLocalizedStringFromTableInBundle(@"Red on White", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：红字白底"), [NSNumber numberWithInt:(int)kRedOnWhiteHighlight],
            NSLocalizedStringFromTableInBundle(@"Black on Orange", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字橙底"), [NSNumber numberWithInt:(int)kBlackOnOrangeHighlight],
            NSLocalizedStringFromTableInBundle(@"Orange on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：橙字黑底"), [NSNumber numberWithInt:(int)kOrangeOnBlackHighlight],
            NSLocalizedStringFromTableInBundle(@"Purple on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：紫字黑底"), [NSNumber numberWithInt:(int)kPurpleOnBlackHighlight],
            NSLocalizedStringFromTableInBundle(@"Black on Purple", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字紫底"), [NSNumber numberWithInt:(int)kBlackOnPurpleHighlight],

            NSLocalizedStringFromTableInBundle(@"Black Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：黑色"), [NSNumber numberWithInt:(int)kBlackHighlight],
            NSLocalizedStringFromTableInBundle(@"Blue Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：蓝色"), [NSNumber numberWithInt:(int)kBlueHighlight],
            NSLocalizedStringFromTableInBundle(@"Brown Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：棕色"), [NSNumber numberWithInt:(int)kBrownHighlight],
            NSLocalizedStringFromTableInBundle(@"Cyan Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：青色"), [NSNumber numberWithInt:(int)kCyanHighlight],
            NSLocalizedStringFromTableInBundle(@"Dark Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：深灰"), [NSNumber numberWithInt:(int)kDarkGrayHighlight],
            NSLocalizedStringFromTableInBundle(@"Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：灰色"), [NSNumber numberWithInt:(int)kGrayHighlight],
            NSLocalizedStringFromTableInBundle(@"Green Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：绿色"), [NSNumber numberWithInt:(int)kGreenHighlight],
            NSLocalizedStringFromTableInBundle(@"Light Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：浅灰"), [NSNumber numberWithInt:(int)kLightGrayHighlight],
            NSLocalizedStringFromTableInBundle(@"Magenta Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：洋红"), [NSNumber numberWithInt:(int)kMagentaHighlight],
            NSLocalizedStringFromTableInBundle(@"Orange Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：橙色"), [NSNumber numberWithInt:(int)kOrangeHighlight],
            NSLocalizedStringFromTableInBundle(@"Purple Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：紫色"), [NSNumber numberWithInt:(int)kPurpleHighlight],
            NSLocalizedStringFromTableInBundle(@"Red Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：红色"), [NSNumber numberWithInt:(int)kRedHighlight],
            NSLocalizedStringFromTableInBundle(@"White Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：白色"), [NSNumber numberWithInt:(int)kWhiteHighlight],
            NSLocalizedStringFromTableInBundle(@"Yellow Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：黄色"), [NSNumber numberWithInt:(int)kYellowHighlight],

            NSLocalizedStringFromTableInBundle(@"Black Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：黑色"), [NSNumber numberWithInt:(int)kBlackBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Blue Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：蓝色"), [NSNumber numberWithInt:(int)kBlueBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Brown Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：棕色"), [NSNumber numberWithInt:(int)kBrownBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Cyan Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：青色"), [NSNumber numberWithInt:(int)kCyanBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Dark Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：深灰"), [NSNumber numberWithInt:(int)kDarkGrayBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：灰色"), [NSNumber numberWithInt:(int)kGrayBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Green Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：绿色"), [NSNumber numberWithInt:(int)kGreenBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Light Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：浅灰"), [NSNumber numberWithInt:(int)kLightGrayBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Magenta Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：洋红"), [NSNumber numberWithInt:(int)kMagentaBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Orange Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：橙色"), [NSNumber numberWithInt:(int)kOrangeBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Purple Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：紫色"), [NSNumber numberWithInt:(int)kPurpleBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Red Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：红色"), [NSNumber numberWithInt:(int)kRedBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"White Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：白色"), [NSNumber numberWithInt:(int)kWhiteBackgroundHighlight],
            NSLocalizedStringFromTableInBundle(@"Yellow Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：黄色"), [NSNumber numberWithInt:(int)kYellowBackgroundHighlight],

            nil];
}

- (NSArray *)groupedMenuItemsForPopupButton {
    NSDictionary *fgbg = [NSDictionary dictionaryWithObjectsAndKeys:
                          NSLocalizedStringFromTableInBundle(@"Yellow on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黄字黑底"), [NSNumber numberWithInt:(int)kYellowOnBlackHighlight],
                          NSLocalizedStringFromTableInBundle(@"Black on Yellow", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字黄底"), [NSNumber numberWithInt:(int)kBlackOnYellowHighlight],
                          NSLocalizedStringFromTableInBundle(@"White on Red", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：白字红底"), [NSNumber numberWithInt:(int)kWhiteOnRedHighlight],
                          NSLocalizedStringFromTableInBundle(@"Red on White", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：红字白底"), [NSNumber numberWithInt:(int)kRedOnWhiteHighlight],
                          NSLocalizedStringFromTableInBundle(@"Black on Orange", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字橙底"), [NSNumber numberWithInt:(int)kBlackOnOrangeHighlight],
                          NSLocalizedStringFromTableInBundle(@"Orange on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：橙字黑底"), [NSNumber numberWithInt:(int)kOrangeOnBlackHighlight],
                          NSLocalizedStringFromTableInBundle(@"Purple on Black", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：紫字黑底"), [NSNumber numberWithInt:(int)kPurpleOnBlackHighlight],
                          NSLocalizedStringFromTableInBundle(@"Black on Purple", @"Triggers", [NSBundle bundleForClass:[self class]], @"颜色：黑字紫底"), [NSNumber numberWithInt:(int)kBlackOnPurpleHighlight],
                          nil];
    NSDictionary *fg = [NSDictionary dictionaryWithObjectsAndKeys:
                        NSLocalizedStringFromTableInBundle(@"Black Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：黑色"), [NSNumber numberWithInt:(int)kBlackHighlight],
                        NSLocalizedStringFromTableInBundle(@"Blue Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：蓝色"), [NSNumber numberWithInt:(int)kBlueHighlight],
                        NSLocalizedStringFromTableInBundle(@"Brown Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：棕色"), [NSNumber numberWithInt:(int)kBrownHighlight],
                        NSLocalizedStringFromTableInBundle(@"Cyan Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：青色"), [NSNumber numberWithInt:(int)kCyanHighlight],
                        NSLocalizedStringFromTableInBundle(@"Dark Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：深灰"), [NSNumber numberWithInt:(int)kDarkGrayHighlight],
                        NSLocalizedStringFromTableInBundle(@"Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：灰色"), [NSNumber numberWithInt:(int)kGrayHighlight],
                        NSLocalizedStringFromTableInBundle(@"Green Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：绿色"), [NSNumber numberWithInt:(int)kGreenHighlight],
                        NSLocalizedStringFromTableInBundle(@"Light Gray Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：浅灰"), [NSNumber numberWithInt:(int)kLightGrayHighlight],
                        NSLocalizedStringFromTableInBundle(@"Magenta Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：洋红"), [NSNumber numberWithInt:(int)kMagentaHighlight],
                        NSLocalizedStringFromTableInBundle(@"Orange Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：橙色"), [NSNumber numberWithInt:(int)kOrangeHighlight],
                        NSLocalizedStringFromTableInBundle(@"Purple Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：紫色"), [NSNumber numberWithInt:(int)kPurpleHighlight],
                        NSLocalizedStringFromTableInBundle(@"Red Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：红色"), [NSNumber numberWithInt:(int)kRedHighlight],
                        NSLocalizedStringFromTableInBundle(@"White Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：白色"), [NSNumber numberWithInt:(int)kWhiteHighlight],
                        NSLocalizedStringFromTableInBundle(@"Yellow Foreground", @"Triggers", [NSBundle bundleForClass:[self class]], @"前景色：黄色"), [NSNumber numberWithInt:(int)kYellowHighlight],
                        nil];

    NSDictionary *bg = [NSDictionary dictionaryWithObjectsAndKeys:
                        NSLocalizedStringFromTableInBundle(@"Black Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：黑色"), [NSNumber numberWithInt:(int)kBlackBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Blue Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：蓝色"), [NSNumber numberWithInt:(int)kBlueBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Brown Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：棕色"), [NSNumber numberWithInt:(int)kBrownBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Cyan Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：青色"), [NSNumber numberWithInt:(int)kCyanBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：灰色（原 typo 行）"), [NSNumber numberWithInt:(int)kDarkGrayBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：灰色"), [NSNumber numberWithInt:(int)kGrayBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Green Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：绿色"), [NSNumber numberWithInt:(int)kGreenBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Light Gray Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：浅灰"), [NSNumber numberWithInt:(int)kLightGrayBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Magenta Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：洋红"), [NSNumber numberWithInt:(int)kMagentaBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Orange Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：橙色"), [NSNumber numberWithInt:(int)kOrangeBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Purple Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：紫色"), [NSNumber numberWithInt:(int)kPurpleBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Red Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：红色"), [NSNumber numberWithInt:(int)kRedBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"White Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：白色"), [NSNumber numberWithInt:(int)kWhiteBackgroundHighlight],
                        NSLocalizedStringFromTableInBundle(@"Yellow Background", @"Triggers", [NSBundle bundleForClass:[self class]], @"背景色：黄色"), [NSNumber numberWithInt:(int)kYellowBackgroundHighlight],
                        nil];
    return [NSArray arrayWithObjects:fgbg, fg, bg, nil];
}

- (BOOL)instantTriggerCanFireMultipleTimesPerLine {
    return YES;
}

- (NSInteger)indexForObject:(id)object {
    int i = 0;
    BOOL isFirst = YES;
    for (NSDictionary *dict in [self groupedMenuItemsForPopupButton]) {
        if (!isFirst) {
            ++i;
        }
        isFirst = NO;
        for (NSNumber *n in [self objectsSortedByValueInDict:dict]) {
            if ([n isEqual:object]) {
                return i;
            }
            i++;
        }
    }
    return -1;
}

- (id)objectAtIndex:(NSInteger)theIndex {
    int i = 0;
    BOOL isFirst = YES;
    for (NSDictionary *dict in [self groupedMenuItemsForPopupButton]) {
        if (!isFirst) {
            ++i;
        }
        isFirst = NO;
        for (NSNumber *n in [self objectsSortedByValueInDict:dict]) {
            if (i == theIndex) {
                return n;
            }
            i++;
        }
    }
    return nil;
}

- (NSDictionary *)dictionaryWithForegroundColor:(NSColor *)foreground
                                backgroundColor:(NSColor *)background {
    return [HighlightTrigger dictionaryWithForegroundColor:foreground
                                           backgroundColor:background];
}

+ (NSDictionary *)dictionaryWithForegroundColor:(NSColor *)foreground
                                backgroundColor:(NSColor *)background {
    return [NSDictionary dictionaryWithObjectsAndKeys:foreground, kHighlightForegroundColor, background, kHighlightBackgroundColor, nil];
}

- (NSDictionary *)dictionaryWithForegroundColor:(NSColor *)foreground {
    return [HighlightTrigger dictionaryWithForegroundColor:foreground];
}

+ (NSDictionary *)dictionaryWithForegroundColor:(NSColor *)foreground {
    return [NSDictionary dictionaryWithObjectsAndKeys:foreground, kHighlightForegroundColor, nil];
}

- (NSDictionary *)dictionaryWithBackgroundColor:(NSColor *)background {
    return [HighlightTrigger dictionaryWithBackgroundColor:background];
}

+ (NSDictionary *)dictionaryWithBackgroundColor:(NSColor *)background {
    return [NSDictionary dictionaryWithObjectsAndKeys:background, kHighlightBackgroundColor, nil];
}

- (NSString *)stringValue {
    return [self stringForTextColor:self.textColor backgroundColor:self.backgroundColor];
}

- (NSString *)stringForTextColor:(NSColor *)textColor backgroundColor:(NSColor *)backgroundColor {
    return [NSString stringWithFormat:@"{%@,%@}",
            textColor.hexStringPreservingColorSpace ?: @"",
            backgroundColor.hexStringPreservingColorSpace ?: @""];
}

- (NSColor *)textColor {
    NSDictionary *colors = [self colorsPreservingColorSpace:NO];
    return colors[kHighlightForegroundColor];
}

- (NSColor *)backgroundColor {
    NSDictionary *colors = [self colorsPreservingColorSpace:NO];
    return colors[kHighlightBackgroundColor];
}

- (void)setTextColor:(NSColor *)textColor {
    [super setTextColor:textColor];
    NSMutableArray *temp = [[self stringsForColors] mutableCopy];
    temp[0] = textColor ? textColor.hexStringPreservingColorSpace: @"";
    self.param = [NSString stringWithFormat:@"{%@,%@}", temp[0], temp[1]];
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    NSMutableArray *temp = [[self stringsForColors] mutableCopy];
    temp[1] = backgroundColor ? backgroundColor.hexStringPreservingColorSpace: @"";
    self.param = [NSString stringWithFormat:@"{%@,%@}", temp[0], temp[1]];
}

- (void)setParam:(id)param {
    _cachedColors = nil;
    [super setParam:param];
}

// Returns a string of the form {text components,background components} from self.param.
- (NSArray<NSString *> *)stringsForColors {
    return [HighlightTrigger stringsForColorsInParam:self.param];
}

+ (NSArray<NSString *> *)stringsForColorsInParam:(id)param {
    if (param == nil) {
        return @[ [[NSColor whiteColor] hexString], [[NSColor redColor] hexString] ];
    }
    if ([param isKindOfClass:[NSString class]] &&
        [param hasPrefix:@"{"] && [param hasSuffix:@"}"]) {
        NSString *stringParam = param;
        NSString *inner = [param substringWithRange:NSMakeRange(1, stringParam.length - 2)];
        NSArray *parts = [inner componentsSeparatedByString:@","];
        if (parts.count == 2) {
            return parts;
        }
        return @[ @"", @"" ];
    }

    if ([param isKindOfClass:[NSNumber class]]) {
        NSNumber *numberParam = param;
        NSDictionary *dict = [self colorDictionaryForInteger:numberParam.intValue];
        NSColor *text = dict[kHighlightForegroundColor];
        NSColor *background = dict[kHighlightBackgroundColor];
        return @[ text ? text.hexString : @"",
                  background ? background.hexString : @"" ];
    }

    return @[ @"", @"" ];
}

// Returns a dictionary with text and background color from the self.param string.
- (NSDictionary<NSString *, NSColor *> *)colorsPreservingColorSpace:(BOOL)preserveColorSpace {
    if (_cachedColors) {
        return _cachedColors;
    }
    NSDictionary *dict = [HighlightTrigger colorsPreservingColorSpace:preserveColorSpace param:self.param];
    _cachedColors = [dict copy];
    return dict;
}

+ (NSDictionary<NSString *, NSColor *> *)colorsPreservingColorSpace:(BOOL)preserveColorSpace
                                                              param:(id)param {
    NSArray *parts = [HighlightTrigger stringsForColorsInParam:param];
    NSMutableDictionary<NSString *, NSColor *> *dict = [NSMutableDictionary dictionary];
    NSColor *textColor = nil;
    NSColor *backgroundColor = nil;
    if (parts.count == 2) {
        if (preserveColorSpace) {
            textColor = [NSColor colorPreservingColorspaceFromString:parts[0]];
            backgroundColor = [NSColor colorPreservingColorspaceFromString:parts[1]];
        } else {
            textColor = [NSColor colorWithString:parts[0]];
            backgroundColor = [NSColor colorWithString:parts[1]];
        }
    }
    if (textColor) {
        dict[kHighlightForegroundColor] = textColor;
    }
    if (backgroundColor) {
        dict[kHighlightBackgroundColor] = backgroundColor;
    }
    return dict;
}

- (NSDictionary *)colorDictionaryForInteger:(int)param {
    return [HighlightTrigger colorDictionaryForInteger:param];
}

+ (NSDictionary *)colorDictionaryForInteger:(int)param {
    switch (param) {
        case kYellowOnBlackHighlight:
            return [self dictionaryWithForegroundColor:[NSColor yellowColor] backgroundColor:[NSColor blackColor]];

        case kBlackOnYellowHighlight:
            return [self dictionaryWithForegroundColor:[NSColor blackColor] backgroundColor:[NSColor yellowColor]];

        case kWhiteOnRedHighlight:
            return [self dictionaryWithForegroundColor:[NSColor whiteColor] backgroundColor:[NSColor redColor]];

        case kRedOnWhiteHighlight:
            return [self dictionaryWithForegroundColor:[NSColor redColor] backgroundColor:[NSColor whiteColor]];

        case kBlackOnOrangeHighlight:
            return [self dictionaryWithForegroundColor:[NSColor blackColor] backgroundColor:[NSColor orangeColor]];

        case kOrangeOnBlackHighlight:
            return [self dictionaryWithForegroundColor:[NSColor orangeColor] backgroundColor:[NSColor blackColor]];

        case kBlackOnPurpleHighlight:
            return [self dictionaryWithForegroundColor:[NSColor blackColor] backgroundColor:[NSColor purpleColor]];

        case kPurpleOnBlackHighlight:
            return [self dictionaryWithForegroundColor:[NSColor purpleColor] backgroundColor:[NSColor blackColor]];

        case kBlackHighlight:
            return [self dictionaryWithForegroundColor:[NSColor blackColor]];

        case kDarkGrayHighlight:
            return [self dictionaryWithForegroundColor:[NSColor darkGrayColor]];

        case kLightGrayHighlight:
            return [self dictionaryWithForegroundColor:[NSColor lightGrayColor]];

        case kWhiteHighlight:
            return [self dictionaryWithForegroundColor:[NSColor whiteColor]];

        case kGrayHighlight:
            return [self dictionaryWithForegroundColor:[NSColor grayColor]];

        case kRedHighlight:
            return [self dictionaryWithForegroundColor:[NSColor redColor]];

        case kGreenHighlight:
            return [self dictionaryWithForegroundColor:[NSColor greenColor]];

        case kBlueHighlight:
            return [self dictionaryWithForegroundColor:[NSColor blueColor]];

        case kCyanHighlight:
            return [self dictionaryWithForegroundColor:[NSColor cyanColor]];

        case kYellowHighlight:
            return [self dictionaryWithForegroundColor:[NSColor yellowColor]];

        case kMagentaHighlight:
            return [self dictionaryWithForegroundColor:[NSColor magentaColor]];

        case kOrangeHighlight:
            return [self dictionaryWithForegroundColor:[NSColor orangeColor]];

        case kPurpleHighlight:
            return [self dictionaryWithForegroundColor:[NSColor purpleColor]];

        case kBrownHighlight:
            return [self dictionaryWithForegroundColor:[NSColor brownColor]];

        case kBlackBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor blackColor]];

        case kDarkGrayBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor darkGrayColor]];

        case kLightGrayBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor lightGrayColor]];

        case kWhiteBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor whiteColor]];

        case kGrayBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor grayColor]];

        case kRedBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor redColor]];

        case kGreenBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor greenColor]];

        case kBlueBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor blueColor]];

        case kCyanBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor cyanColor]];

        case kYellowBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor yellowColor]];

        case kMagentaBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor magentaColor]];

        case kOrangeBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor orangeColor]];

        case kPurpleBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor purpleColor]];

        case kBrownBackgroundHighlight:
            return [self dictionaryWithBackgroundColor:[NSColor brownColor]];
    }
    return nil;
}

- (BOOL)performActionWithCapturedStrings:(NSArray<NSString *> *)stringArray
                          capturedRanges:(const NSRange *)capturedRanges
                               inSession:(id<iTermTriggerSession>)aSession
                                onString:(iTermStringLine *)stringLine
                    atAbsoluteLineNumber:(long long)lineNumber
                        useInterpolation:(BOOL)useInterpolation
                                    stop:(BOOL *)stop {
    NSRange rangeInString = capturedRanges[0];
    NSRange rangeInScreenChars = [stringLine rangeOfScreenCharsForRangeInString:rangeInString];

    [aSession triggerSession:self
        highlightTextInRange:rangeInScreenChars
                absoluteLine:lineNumber
                      colors:[self colorsPreservingColorSpace:NO]];
    return YES;
}

- (NSAttributedString *)paramAttributedString {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    [result appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Text: ", @"Triggers", [NSBundle bundleForClass:[self class]], @"参数标签：文本")]];

    NSTextAttachment *textColorAttachment = [[NSTextAttachment alloc] init];
    textColorAttachment.image = [self imageForColor:self.textColor];
    NSAttributedString *textAttachmentString = [NSAttributedString attributedStringWithAttachment:textColorAttachment];
    NSMutableAttributedString *mutableTextAttachmentString = [textAttachmentString mutableCopy];
    // Lower the image by adjusting the baseline offset.
    [mutableTextAttachmentString addAttribute:NSBaselineOffsetAttributeName value:@(-2) range:NSMakeRange(0, mutableTextAttachmentString.length)];
    [result appendAttributedString:mutableTextAttachmentString];

    [result appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@" Background: ", @"Triggers", [NSBundle bundleForClass:[self class]], @"参数标签：背景")]];

    NSTextAttachment *backgroundColorAttachment = [[NSTextAttachment alloc] init];
    backgroundColorAttachment.image = [self imageForColor:self.backgroundColor];
    NSAttributedString *backgroundAttachmentString = [NSAttributedString attributedStringWithAttachment:backgroundColorAttachment];
    NSMutableAttributedString *mutableBackgroundAttachmentString = [backgroundAttachmentString mutableCopy];
    // Lower the image by adjusting the baseline offset.
    [mutableBackgroundAttachmentString addAttribute:NSBaselineOffsetAttributeName value:@(-2) range:NSMakeRange(0, mutableBackgroundAttachmentString.length)];
    [result appendAttributedString:mutableBackgroundAttachmentString];

    return result;
}

- (NSImage *)imageForColor:(NSColor *)color {
    return [NSImage it_imageForColorSwatch:color size:NSMakeSize(22, 14)];
}

@end
