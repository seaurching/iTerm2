//
//  ObjCExceptions.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 5/25/22.
//

#import "ObjCExceptions.h"
#import "iTermWarning.h"

NSError * _Nullable ObjCTryImpl(void (^NS_NOESCAPE block)(void)) {
    @try {
        block();
        return nil;
    } @catch (NSException *e) {
        return [NSError errorWithDomain:e.name
                                   code:0
                               userInfo:@{ NSUnderlyingErrorKey: e,
                                           NSDebugDescriptionErrorKey: e.userInfo ?: @{ },
                                           NSLocalizedFailureReasonErrorKey: (e.reason ?: NSLocalizedStringFromTableInBundle(@"Unknown reason", @"Infrastructure", [NSBundle bundleForClass:[iTermWarning class]], @"Fallback failure reason when exception reason is nil")) }];
    }
}
