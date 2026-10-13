//
//  iTermMoveTabToWindowBuiltInFunction.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 2/10/19.
//

#import "iTermMoveTabToWindowBuiltInFunction.h"
#import "PseudoTerminal.h"
#import "PTYTab.h"
#import "iTermController.h"
#import "iTermVariables.h"

@implementation iTermMoveTabToWindowBuiltInFunction

+ (void)registerBuiltInFunction {
    iTermBuiltInFunction *func =
    [[iTermBuiltInFunction alloc] initWithName:@"move_tab_to_window"
                                     arguments:@{ }
                             optionalArguments:[NSSet set]
                                 defaultValues:@{ @"tab_id": iTermVariableKeyTabID }
                                       context:iTermVariablesSuggestionContextTab
                        sideEffectsPlaceholder:@"[move_tab_to_window]"
                                         block:
     ^(NSDictionary * _Nonnull parameters, iTermBuiltInFunctionCompletionBlock  _Nonnull completion) {
         NSString *tabID = parameters[@"tab_id"];
         [self moveTabWithID:tabID completion:completion];
     }];
    [[iTermBuiltInFunctions sharedInstance] registerFunction:func
                                                   namespace:@"iterm2"];
}

+ (void)moveTabWithID:(NSString *)tabID completion:(iTermBuiltInFunctionCompletionBlock)completion {
    PTYTab *tab = [[iTermController sharedInstance] tabWithID:tabID];
    if (!tabID) {
        completion(nil, [NSError errorWithDomain:@"com.iterm2.move-tab-to-window"
                                            code:1
                                        userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"No such tab", @"Language", [NSBundle bundleForClass:[self class]], @"Move tab to window error: no such tab") }]);
        return;
    }

    PseudoTerminal *term = [[iTermController sharedInstance] terminalWithTab:tab];
    if (!term) {
        completion(nil, [NSError errorWithDomain:@"com.iterm2.move-tab-to-window"
                                            code:2
                                        userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Tab has no window", @"Language", [NSBundle bundleForClass:[self class]], @"Move tab to window error: tab has no window") }]);
        return;
    }

    if (term.tabs.count < 2) {
        completion(nil, [NSError errorWithDomain:@"com.iterm2.move-tab-to-window"
                                            code:3
                                        userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Window has only one tab", @"Language", [NSBundle bundleForClass:[self class]], @"Move tab to window error: window has only one tab") }]);
    }
    PseudoTerminal *newWindowController = [term it_moveTabToNewWindow:tab];
    if (!newWindowController) {
        completion(nil, [NSError errorWithDomain:@"com.iterm2.move-tab-to-window"
                                            code:4
                                        userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Failed to create new window", @"Language", [NSBundle bundleForClass:[self class]], @"Move tab to window error: failed to create new window") }]);
        return;
    }

    completion(newWindowController.terminalGuid, nil);
}

@end
