//
//  NSDateFormatterExtras.m
//  iTerm
//
//  Created by George Nachman on 10/26/10.
//  Copyright 2010 George Nachman. All rights reserved.
//

#import "NSDateFormatterExtras.h"

@implementation NSDateFormatter (Extras)

+ (NSString *)durationString:(NSTimeInterval)duration {
    int seconds = duration;
    int minutes = seconds / 60;
    int hours = minutes / 60;
    int remainderMinutes = minutes - hours * 60;
    return [NSString stringWithFormat:@"%d:%02d", hours, remainderMinutes];
}

+ (NSString *)dateDifferenceStringFromDate:(NSDate *)date {
    return [self dateDifferenceStringFromDate:date options:0];
}

+ (NSString *)dateDifferenceStringFromDate:(NSDate *)date
                                   options:(iTermDateDifferenceOptions)options {
    const BOOL lowerCase = (options & iTermDateDifferenceOptionsLowercase) != 0;
    NSDate *now = [NSDate date];
    double theTime = [date timeIntervalSinceDate:now];
    theTime *= -1;
    if (theTime < 60) {
        if (lowerCase) {
            return NSLocalizedStringFromTableInBundle(@"moments ago", @"Categories", [NSBundle mainBundle], @"Relative time: moments ago (lowercase)");
        } else {
            return NSLocalizedStringFromTableInBundle(@"Moments ago", @"Categories", [NSBundle mainBundle], @"Relative time: Moments ago (capitalized)");
        }
    } else if (theTime < 3600) {
        int diff = round(theTime / 60);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 minute ago", @"Categories", [NSBundle mainBundle], @"Relative time: 1 minute ago");
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d minutes ago", @"Categories", [NSBundle mainBundle], @"Relative time: N minutes ago"), diff];
    } else if (theTime < 86400) {
        int diff = round(theTime / 60 / 60);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 hour ago", @"Categories", [NSBundle mainBundle], @"Relative time: 1 hour ago");
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hours ago", @"Categories", [NSBundle mainBundle], @"Relative time: N hours ago"), diff];
    } else if (theTime < 604800) {
        int diff = round(theTime / 60 / 60 / 24);
        if (diff == 1) {
            if (lowerCase) {
                return NSLocalizedStringFromTableInBundle(@"yesterday", @"Categories", [NSBundle mainBundle], @"Relative time: yesterday (lowercase)");
            } else {
                return NSLocalizedStringFromTableInBundle(@"Yesterday", @"Categories", [NSBundle mainBundle], @"Relative time: Yesterday (capitalized)");
            }
        }
        if (diff == 7) {
            if (lowerCase) {
                return NSLocalizedStringFromTableInBundle(@"one week ago", @"Categories", [NSBundle mainBundle], @"Relative time: one week ago (lowercase)");
            } else {
                return NSLocalizedStringFromTableInBundle(@"One week ago", @"Categories", [NSBundle mainBundle], @"Relative time: One week ago (capitalized)");
            }
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d days ago", @"Categories", [NSBundle mainBundle], @"Relative time: N days ago"), diff];
    } else {
        int diff = round(theTime / 60 / 60 / 24 / 7);
        if (diff == 1) {
            if (lowerCase) {
                return NSLocalizedStringFromTableInBundle(@"last week", @"Categories", [NSBundle mainBundle], @"Relative time: last week (lowercase)");
            } else {
                return NSLocalizedStringFromTableInBundle(@"Last week", @"Categories", [NSBundle mainBundle], @"Relative time: Last week (capitalized)");
            }

        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d weeks ago", @"Categories", [NSBundle mainBundle], @"Relative time: N weeks ago"), diff];
    }
}

+ (NSString *)compactDateDifferenceStringFromDate:(NSDate *)date
{
    NSDate *now = [NSDate date];
    double theTime = [date timeIntervalSinceDate:now];
    theTime *= -1;
    return [self compactDateDifferenceStringFromTimeDelta:theTime];
}

+ (NSString *)compactDateDifferenceStringFromTimeDelta:(NSTimeInterval)theTime {
    if (theTime < 60) {
        return NSLocalizedStringFromTableInBundle(@"< 1 min", @"Categories", [NSBundle mainBundle], @"Compact relative time: less than 1 minute");
    } else if (theTime < 3600) {
        int diff = round(theTime / 60);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 min", @"Categories", [NSBundle mainBundle], @"Compact relative time: 1 minute");
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d min", @"Categories", [NSBundle mainBundle], @"Compact relative time: N minutes"), diff];
    } else if (theTime < 86400) {
        int diff = round(theTime / 60 / 60);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 hour", @"Categories", [NSBundle mainBundle], @"Compact relative time: 1 hour");
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d hrs", @"Categories", [NSBundle mainBundle], @"Compact relative time: N hours"), diff];
    } else if (theTime < 604800) {
        int diff = round(theTime / 60 / 60 / 24);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 day", @"Categories", [NSBundle mainBundle], @"Compact relative time: 1 day");
        }
        if (diff == 7) {
            return NSLocalizedStringFromTableInBundle(@"1 week", @"Categories", [NSBundle mainBundle], @"Compact relative time: 1 week");
        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d days", @"Categories", [NSBundle mainBundle], @"Compact relative time: N days"), diff];
    } else {
        int diff = round(theTime / 60 / 60 / 24 / 7);
        if (diff == 1) {
            return NSLocalizedStringFromTableInBundle(@"1 week", @"Categories", [NSBundle mainBundle], @"Compact relative time: 1 week");

        }
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%d wks", @"Categories", [NSBundle mainBundle], @"Compact relative time: N weeks"), diff];
    }
}

+ (NSString *)highResolutionCompactRelativeTimeStringFromSeconds:(NSTimeInterval)seconds {
    const BOOL negative = (seconds < 0);
    const NSTimeInterval interval = fabs(seconds);

    if (interval == 0) {
        return NSLocalizedStringFromTableInBundle(@"Baseline", @"Categories", [NSBundle mainBundle], @"High-res relative time: zero baseline label");
    }
    NSString *sign = negative ? @"-" : @"+";

    // < 10 sec → "X.yyys"
    if (interval < 10) {
        return [NSString stringWithFormat:@"%@%0.3fs", sign, interval];
    }

    // < 1 min → "Xs"
    if (interval < 60) {
        return [NSString stringWithFormat:@"%@%ds", sign, (int)interval];
    }

    // < 1 hr → "XmYs" (omit seconds if zero)
    if (interval < 3600) {
        int mins = (int)interval / 60;
        int secs = (int)interval % 60;
        if (secs == 0) {
            return [NSString stringWithFormat:@"%@%dm", sign, mins];
        }
        return [NSString stringWithFormat:@"%@%dm%ds", sign, mins, secs];
    }

    // < 1 day → "XhYmZs" (omit zero components)
    if (interval < 86400) {
        int hrs = (int)interval / 3600;
        int mins = ((int)interval % 3600) / 60;
        int secs = (int)interval % 60;
        NSMutableString *t = [NSMutableString stringWithFormat:@"%@%dh", sign, hrs];
        if (mins > 0) {
            [t appendFormat:@"%dm", mins];
        }
        if (secs > 0) {
            [t appendFormat:@"%ds", secs];
        }
        return t;
    }

    // ≥ 1 day → pick two largest non-zero of [y, mo, w, d, h, m, s]
    // "mo" is used for month to avoid colliding with "m" for minute.
    NSInteger secsInYr  = 31536000;  // 365 d
    NSInteger secsInMo  = 2592000;   // 30 d
    NSInteger secsInWk  = 604800;
    NSInteger secsInDay = 86400;

    NSInteger rem = (NSInteger)interval;
    NSInteger vals[] = {
        rem / secsInYr,
        (rem % secsInYr) / secsInMo,
        (rem % secsInMo) / secsInWk,
        (rem % secsInWk) / secsInDay,
        (rem % secsInDay) / 3600,
        (rem % 3600) / 60,
        rem % 60
    };
    const char *units[] = { "y", "mo", "w", "d", "h", "m", "s" };

    NSMutableString *out = [NSMutableString string];
    int components = 0;
    for (int i = 0; i < 7 && components < 2; i++) {
        if (vals[i] > 0) {
            [out appendFormat:@"%ld%s", (long)vals[i], units[i]];
            components++;
        }
    }
    if (out.length == 0) {
        [out appendString:@"0s"];
    }
    return [sign stringByAppendingString:out];
}
@end
