//
//  iTermRequestCookieCommand.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 4/5/20.
//

#import "iTermRequestCookieCommand.h"

#import "iTermAnnouncementViewController.h"
#import "iTermAPIConnectionIdentifierController.h"
#import "iTermAPIHelper.h"
#import "iTermController.h"
#import "iTermScriptHistory.h"
#import "iTermWebSocketCookieJar.h"
#import "PseudoTerminal.h"
#import "PTYSession.h"

static NSString *const kReusableCookieAnnouncementIdentifier = @"ReusableCookieAnnouncement";

@implementation iTermRequestCookieCommand

- (id)performDefaultImplementation {
    if (![iTermAPIHelper isEnabled]) {
        [self setScriptErrorNumber:1];
        [self setScriptErrorString:NSLocalizedStringFromTableInBundle(@"The Python API is not enabled.", @"Applescript", [NSBundle bundleForClass:[self class]], @"Python API 未启用。")];
        return nil;
    }

    BOOL reusable = [self.arguments[@"reusable"] boolValue];
    if (reusable) {
        [self suspendExecution];
        [self showReusableCookieAnnouncement];
        return nil;
    }

    return [self issueResultWithCookie:[[iTermWebSocketCookieJar sharedInstance] randomStringForCookie]];
}

#pragma mark - Reusable Cookie Flow

- (void)showReusableCookieAnnouncement {
    PTYSession *session = [self targetSession];
    if (!session) {
        // No session to show announcement in — fall back to single-use.
        [self resumeExecutionWithResult:[self issueResultWithCookie:[[iTermWebSocketCookieJar sharedInstance] randomStringForCookie]]];
        return;
    }

    NSString *appName = self.arguments[@"appName"] ?: NSLocalizedStringFromTableInBundle(@"An app", @"Applescript", [NSBundle bundleForClass:[self class]], @"某个应用");
    NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ requests a reusable API cookie.", @"Applescript", [NSBundle bundleForClass:[self class]], @"%@ 请求一个可重用的 API cookie。"), appName];

    __weak __typeof(self) weakSelf = self;
    iTermAnnouncementViewController *announcement =
        [iTermAnnouncementViewController announcementWithTitle:message
                                                         style:kiTermAnnouncementViewStyleQuestion
                                                   withActions:@[ NSLocalizedStringFromTableInBundle(@"_24 Hours", @"Applescript", [NSBundle bundleForClass:[self class]], @"_24 小时"),
                                                                  NSLocalizedStringFromTableInBundle(@"Forever", @"Applescript", [NSBundle bundleForClass:[self class]], @"永久"),
                                                                  NSLocalizedStringFromTableInBundle(@"Always Allow All Apps", @"Applescript", [NSBundle bundleForClass:[self class]], @"始终允许所有应用"),
                                                                  NSLocalizedStringFromTableInBundle(@"Deny", @"Applescript", [NSBundle bundleForClass:[self class]], @"拒绝") ]
                                                    completion:^(int selection) {
            [weakSelf handleReusableCookieSelection:selection];
        }];
    [session queueAnnouncement:announcement identifier:kReusableCookieAnnouncementIdentifier];
}

- (void)handleReusableCookieSelection:(int)selection {
    NSString *cookie = nil;
    switch (selection) {
        case 0: {
            // 24 hours.
            NSTimeInterval duration = 24 * 60 * 60;
            cookie = [[iTermWebSocketCookieJar sharedInstance] randomStringForReusableCookieWithDuration:duration];
            [self logEntry:NSLocalizedStringFromTableInBundle(@"Reusable API cookie granted (24 hours) by Applescript.", @"Applescript", [NSBundle bundleForClass:[self class]], @"已通过 AppleScript 授予可重用的 API cookie（24 小时）。")];
            break;
        }
        case 1: {
            // Forever — reusable with no expiration.
            cookie = [[iTermWebSocketCookieJar sharedInstance] randomStringForCookie];
            // Remove the cookie from single-use tracking by adding a far-future expiration.
            // Actually, just use removeCookieExpiration after making it reusable.
            // Simpler: add it as reusable with a very long duration.
            [[iTermWebSocketCookieJar sharedInstance] removeCookie:cookie];
            cookie = [[iTermWebSocketCookieJar sharedInstance] randomStringForReusableCookieWithDuration:100 * 365.25 * 24 * 60 * 60];
            [self logEntry:NSLocalizedStringFromTableInBundle(@"Permanent reusable API cookie granted by Applescript.", @"Applescript", [NSBundle bundleForClass:[self class]], @"已通过 AppleScript 授予永久可重用的 API cookie。")];
            break;
        }
        case 2: {
            // Always allow all apps — disable automation auth.
            [iTermAPIHelper setRequireApplescriptAuth:NO window:nil];
            cookie = [[iTermWebSocketCookieJar sharedInstance] randomStringForCookie];
            [self logEntry:NSLocalizedStringFromTableInBundle(@"Automation auth disabled. Single-use API cookie granted by Applescript.", @"Applescript", [NSBundle bundleForClass:[self class]], @"自动化认证已禁用。已通过 AppleScript 授予单次使用的 API cookie。")];
            break;
        }
        default: {
            // Deny or dismissed.
            [self setScriptErrorNumber:2];
            [self setScriptErrorString:NSLocalizedStringFromTableInBundle(@"User denied the reusable cookie request.", @"Applescript", [NSBundle bundleForClass:[self class]], @"用户拒绝了可重用 cookie 请求。")];
            [self resumeExecutionWithResult:nil];
            return;
        }
    }

    [self resumeExecutionWithResult:[self issueResultWithCookie:cookie]];
}

#pragma mark - Helpers

- (NSString *)issueResultWithCookie:(NSString *)cookie {
    NSString *name = self.arguments[@"appName"];
    if (name) {
        NSString *key = [[NSUUID UUID] UUIDString];
        NSString *identifier = [[iTermAPIConnectionIdentifierController sharedInstance] identifierForKey:key];
        iTermScriptHistoryEntry *entry = [[iTermScriptHistoryEntry alloc] initWithName:[@"\u2248" stringByAppendingString:name]
                                                                              fullPath:nil
                                                                            identifier:identifier
                                                                              relaunch:nil];
        [[iTermScriptHistory sharedInstance] addHistoryEntry:entry];
        return [NSString stringWithFormat:@"%@ %@", cookie, key];
    }
    return cookie;
}

- (void)logEntry:(NSString *)message {
    NSString *name = self.arguments[@"appName"];
    if (!name) {
        return;
    }
    NSString *key = [[NSUUID UUID] UUIDString];
    NSString *identifier = [[iTermAPIConnectionIdentifierController sharedInstance] identifierForKey:key];
    iTermScriptHistoryEntry *entry = [[iTermScriptHistoryEntry alloc] initWithName:[@"\u2248" stringByAppendingString:name]
                                                                          fullPath:nil
                                                                        identifier:identifier
                                                                          relaunch:nil];
    [[iTermScriptHistory sharedInstance] addHistoryEntry:entry];
    [entry addOutput:message completion:^{}];
}

- (PTYSession *)targetSession {
    NSString *sessionId = self.arguments[@"sessionId"];
    if (sessionId) {
        NSRange colonRange = [sessionId rangeOfString:@":"];
        NSString *guid = colonRange.location != NSNotFound
            ? [sessionId substringFromIndex:colonRange.location + 1]
            : sessionId;
        PTYSession *session = [[iTermAPIHelper sharedInstance] sessionForAPIIdentifier:guid
                                                                includeBuriedSessions:NO];
        if (session) {
            return session;
        }
    }
    return [[[iTermController sharedInstance] currentTerminal] currentSession];
}

@end
