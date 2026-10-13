//
//  iTermPrintAccessoryViewController.m
//  iTerm2
//
//  Created by George Nachman on 11/19/15.
//
//

#import "iTermPrintAccessoryViewController.h"
#import "iTermUserDefaults.h"

static NSString *const kBlackAndWhiteKey = @"Print In Black And White";

@implementation iTermPrintAccessoryViewController

- (void)dealloc {
    [_userDidChangeSetting release];
    [super dealloc];
}

- (NSArray<NSDictionary<NSString *,NSString *> *> *)localizedSummaryItems {
  NSBundle *printingBundle = [NSBundle bundleForClass:[self class]];
  return @[ @{ NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedStringFromTableInBundle(@"blackAndWhite", @"Printing", printingBundle, @"Printing: print panel summary black and white option name"),
               NSPrintPanelAccessorySummaryItemDescriptionKey: NSLocalizedStringFromTableInBundle(@"Should the document print only in black and white?", @"Printing", printingBundle, @"Printing: print panel summary black and white option description") } ];
}

- (void)awakeFromNib {
  [[iTermUserDefaults userDefaults] registerDefaults:@{ kBlackAndWhiteKey: @YES } ];
  self.blackAndWhite = [[iTermUserDefaults userDefaults] boolForKey:kBlackAndWhiteKey];
  [super awakeFromNib];
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingPreview {
  return [NSSet setWithObject:@"blackAndWhite"];
}

- (void)setBlackAndWhite:(BOOL)blackAndWhite {
  [[iTermUserDefaults userDefaults] setBool:blackAndWhite forKey:kBlackAndWhiteKey];
  _blackAndWhite = blackAndWhite;
  if (self.userDidChangeSetting) {
    self.userDidChangeSetting();
  }
}

@end
