//
//  iTermNewWindowCommand.m
//  iTerm2
//
//  Created by George Nachman on 8/19/14.
//
//

#import "iTermNewWindowCommand.h"
#import "iTermController.h"
#import "iTermHotKeyController.h"
#import "iTermProfileHotKey.h"
#import "iTermScriptingWindow.h"
#import "iTermSessionLauncher.h"
#import "NSStringITerm.h"
#import "PTYSession.h"
#import "PTYTab.h"
#import "ProfileModel.h"
#import "PseudoTerminal.h"

@implementation iTermNewWindowCommand

- (id)performDefaultImplementation {
    NSString *profileName = self.directParameter;
    Profile *profile;
    if (!profileName) {
        profile = [[ProfileModel sharedInstance] defaultBookmark];
    } else {
        profile = [[ProfileModel sharedInstance] bookmarkWithName:profileName];
        if (!profile) {
            [self setScriptErrorNumber:1];
            [self setScriptErrorString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"No profile exists named '%@'", @"Applescript", [NSBundle bundleForClass:[self class]], @"不存在名为 '%@' 的配置文件"),
                                        profileName]];
            return nil;
        }
    }
    if (profile) {
        NSDictionary *args = [self evaluatedArguments];
        NSString *command = args[@"command"];
        // maybe pass isUTF8 all the way through?
        [self suspendExecution];
        [iTermSessionLauncher launchBookmark:profile
                                  inTerminal:nil
                                       style:iTermOpenStyleTab
                                     withURL:nil
                            hotkeyWindowType:iTermHotkeyWindowTypeNone
                                     makeKey:YES
                                 canActivate:YES
                          respectTabbingMode:NO
                                       index:nil
                                     command:command
                                 makeSession:nil
                              didMakeSession:nil
                                  completion:^(PTYSession *session, BOOL ok) {
            dispatch_async(dispatch_get_main_queue(), ^{
                    [self resumeExecutionWithResult:[iTermScriptingWindow scriptingWindowWithWindow:session.delegate.realParentWindow.window]];
            });
        }];
    }
    return nil;
}

@end

@implementation iTermNewHotkeyWindowCommand

- (id)performDefaultImplementation {
    NSString *profileName = self.directParameter;
    Profile *profile;
    if (!profileName) {
        [self setScriptErrorNumber:4];
        [self setScriptErrorString:NSLocalizedStringFromTableInBundle(@"No profile name was specified", @"Applescript", [NSBundle bundleForClass:[self class]], @"未指定配置文件名称")];
        return nil;
    }
    profile = [[ProfileModel sharedInstance] bookmarkWithName:profileName];
    if (!profile) {
        [self setScriptErrorNumber:1];
        [self setScriptErrorString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"No profile exists named '%@'", @"Applescript", [NSBundle bundleForClass:[self class]], @"不存在名为 '%@' 的配置文件"),
                                    profileName]];
        return nil;
    }

    if (!profile[KEY_GUID]) {
        [self setScriptErrorNumber:1];
        [self setScriptErrorString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The profile '%@' is damaged.", @"Applescript", [NSBundle bundleForClass:[self class]], @"配置文件 '%@' 已损坏。"),
                                    profileName]];
        return nil;
    }

    iTermProfileHotKey *profileHotkey = [[iTermHotKeyController sharedInstance] profileHotKeyForGUID:profile[KEY_GUID]];
    if (!profileHotkey) {
        [self setScriptErrorNumber:3];
        [self setScriptErrorString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The profile '%@' does not have a hotkey defined.", @"Applescript", [NSBundle bundleForClass:[self class]], @"配置文件 '%@' 未定义热键。"),
                                    profileName]];
        return nil;
    }
    if (profileHotkey.windowController.weaklyReferencedObject) {
        [self setScriptErrorNumber:2];
        [self setScriptErrorString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"A hotkey window for profile '%@' already exists. Use “reveal hotkey window” instead.", @"Applescript", [NSBundle bundleForClass:[self class]], @"配置文件 '%@' 的热键窗口已存在。请改用“显示热键窗口”。"),
                                    profileName]];
        return nil;
    }
    [profileHotkey showHotKeyWindow];
    return profileHotkey.windowController.window;
}

@end
