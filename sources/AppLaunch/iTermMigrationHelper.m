//
//  iTermMigrationHelper.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 6/1/18.
//

#import "iTermMigrationHelper.h"

#import "DebugLogging.h"
#import "ITAddressBookMgr.h"
#import "NSArray+iTerm.h"
#import "NSFileManager+iTerm.h"
#import "NSWorkspace+iTerm.h"
#import "iTerm2SharedARC-Swift.h"
#import "iTermDisclosableView.h"
#import "iTermPreferences.h"
#import "iTermProfilePreferences.h"
#import "iTermUserDefaults.h"
#import "iTermWarning.h"

@implementation iTermMigrationHelper

+ (BOOL)removeLegacyAppSupportFolderIfPossible {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *legacy = [fileManager legacyApplicationSupportDirectory];

    if (![fileManager itemIsDirectory:legacy]) {
        return NO;
    }

    BOOL foundVersionTxt = NO;
    for (NSString *file in [fileManager enumeratorAtPath:legacy]) {
        if ([file isEqualToString:@"version.txt"]) {
            foundVersionTxt = YES;
        } else {
            return NO;
        }
    }
    if (foundVersionTxt) {
        NSError *error = nil;
        [fileManager removeItemAtPath:[legacy stringByAppendingPathComponent:@"version.txt"] error:&error];
        if (error) {
            return NO;
        }
    }

    NSError *error = nil;
    [fileManager removeItemAtPath:legacy error:&error];
    return error == nil;
}

+ (void)migrateOpenAIKeyIfNeeded {
    NSString *key = [[iTermUserDefaults userDefaults] stringForKey:kPreferenceKeyOpenAIAPIKey];
    if (!key) {
        return;
    }
    NSString *trimmedKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedKey length] == 0) {
        return;
    }
    const iTermWarningSelection selection =
    [iTermWarning showWarningWithTitle:NSLocalizedStringFromTableInBundle(@"Move OpenAI API key into the keychain? It is currently stored in User Defaults, which is not as secure.", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"将 OpenAI API 密钥移入钥匙串？它当前存储在用户默认设置中，安全性较低。")
                               actions:@[ NSLocalizedStringFromTableInBundle(@"OK", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"好"), NSLocalizedStringFromTableInBundle(@"Erase from Settings", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"从设置中删除") ]
                             accessory:nil
                            identifier:@"NoSyncMoveOpenAIAPIKeyIntoKeychain"
                           silenceable:kiTermWarningTypePersistent
                               heading:NSLocalizedStringFromTableInBundle(@"Move Key", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"移动密钥")
                                window:nil];
    if (selection == kiTermWarningSelection0) {
        [self addOpenAIKeyToKeychain:key];
    }
    [[iTermUserDefaults userDefaults] removeObjectForKey:kPreferenceKeyOpenAIAPIKey];
}

+ (void)addOpenAIKeyToKeychain:(NSString *)key {
    [AITermControllerObjC setApiKey:key];
}

+ (void)migrateApplicationSupportDirectoryIfNeeded {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *modern = [fileManager applicationSupportDirectory];
    NSString *legacy = [fileManager legacyApplicationSupportDirectory];

    if ([fileManager itemIsSymlink:legacy]) {
        // Looks migrated, or crazy and impossible to reason about.
        return;
    }

    if ([self removeLegacyAppSupportFolderIfPossible]) {
        return;
    }

    if ([fileManager itemIsDirectory:modern] && [fileManager itemIsDirectory:legacy]) {
        // This is the normal code path for migrating users.
        const BOOL legacyEmpty = [fileManager directoryEmpty:legacy];

        if (legacyEmpty) {
            [fileManager removeItemAtPath:legacy error:nil];
            [fileManager createSymbolicLinkAtPath:legacy withDestinationPath:modern error:nil];
            return;
        }

        const BOOL modernEmpty = [fileManager directoryEmpty:modern];
        if (modernEmpty) {
            [fileManager removeItemAtPath:modern error:nil];
            [fileManager moveItemAtPath:legacy toPath:modern error:nil];
            [fileManager createSymbolicLinkAtPath:legacy withDestinationPath:modern error:nil];
            return;
        }

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedStringFromTableInBundle(@"Manual Update Needed", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"需要手动更新");
        alert.informativeText = [NSString stringWithFormat:@"%@\n\n%@\n\n%@",
                                 NSLocalizedStringFromTableInBundle(@"iTerm2's Application Support directory has changed.", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"iTerm2 的应用程序支持目录已更改。"),
                                 NSLocalizedStringFromTableInBundle(@"Previously, both these directories were supported:\n~/Library/Application Support/iTerm\n~/Library/Application Support/iTerm2.", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"之前，以下两个目录都受支持：\n~/Library/Application Support/iTerm\n~/Library/Application Support/iTerm2。"),
                                 NSLocalizedStringFromTableInBundle(@"Now, only the iTerm2 version is supported. But you have files in both so please move everything from iTerm to iTerm2.", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"现在仅支持 iTerm2 版本。但两个目录中都有文件，请将所有内容从 iTerm 移动到 iTerm2。")];

        NSMutableArray<NSString *> *files = [NSMutableArray array];
        int over = 0;
        for (NSString *file in [fileManager enumeratorAtPath:legacy]) {
            if (files.count > 5) {
                over++;
            } else {
                [files addObject:file];
            }
        }
        [files sortUsingSelector:@selector(compare:)];
        NSString *message;
        if (over == 0) {
            message = [files componentsJoinedByString:@"\n"];
        } else {
            message = [NSString stringWithFormat:@"%@\n…and %@ more", [files componentsJoinedByString:@"\n"], @(over)];
        }

        iTermDisclosableView *accessory = [[iTermDisclosableView alloc] initWithFrame:NSZeroRect
                                                                               prompt:@"Directory Listing"
                                                                              message:message];
        iTermAccessoryViewUnfucker *unfucker = [[iTermAccessoryViewUnfucker alloc] initWithView:accessory];
        accessory.frame = NSMakeRect(0, 0, accessory.intrinsicContentSize.width, accessory.intrinsicContentSize.height);
        accessory.textView.selectable = YES;
        accessory.requestLayout = ^{
            [unfucker layout];
            [alert layout];
            [alert layout];
        };
        [unfucker layout];
        alert.accessoryView = unfucker;

        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Open in Finder", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"在 Finder 中打开")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"I Fixed It", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"我已修复")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Not Now", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"暂不")];
        switch ([alert runModal]) {
            case NSAlertFirstButtonReturn:
                [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ [NSURL fileURLWithPath:legacy],
                                                                              [NSURL fileURLWithPath:modern] ]];
                [self migrateApplicationSupportDirectoryIfNeeded];
                break;

            case NSAlertThirdButtonReturn:
                return;

            default:
                [self migrateApplicationSupportDirectoryIfNeeded];
                break;
        }
    }
}

+ (void)copyProfileToBookmark:(NSMutableDictionary *)dict
{
    NSString* plistFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"MigrationMap"
                                                                           ofType:@"plist"];
    NSDictionary* fileDict = [NSDictionary dictionaryWithContentsOfFile: plistFile];
    NSUserDefaults* prefs = [iTermUserDefaults userDefaults];
    NSDictionary* keybindingProfiles = [prefs objectForKey: @"KeyBindings"];
    NSDictionary* displayProfiles =  [prefs objectForKey: @"Displays"];
    NSDictionary* terminalProfiles = [prefs objectForKey: @"Terminals"];
    NSArray* xforms = [fileDict objectForKey:@"Migration Map"];
    for (int i = 0; i < [xforms count]; ++i) {
        NSDictionary* xform = [xforms objectAtIndex:i];
        NSString* destination = [xform objectForKey:@"Destination"];
        if ([dict objectForKey:destination]) {
            continue;
        }
        NSString* prefix = [xform objectForKey:@"Prefix"];
        NSString* suffix = [xform objectForKey:@"Suffix"];
        id defaultValue = [xform objectForKey:@"Default"];

        NSDictionary* parent = nil;
        if ([prefix isEqualToString:@"Terminal"]) {
            parent = [terminalProfiles objectForKey:[dict objectForKey:KEY_TERMINAL_PROFILE]];
        } else if ([prefix isEqualToString:@"Displays"]) {
            parent = [displayProfiles objectForKey:[dict objectForKey:KEY_DISPLAY_PROFILE]];
        } else if ([prefix isEqualToString:@"KeyBindings"]) {
            parent = [keybindingProfiles objectForKey:[dict objectForKey:KEY_KEYBOARD_PROFILE]];
        } else {
            ITAssertWithMessage(0, @"Bad prefix");
        }
        id value = nil;
        if (parent) {
            value = [parent objectForKey:suffix];
        }
        if (!value) {
            value = defaultValue;
        }
        [dict setObject:value forKey:destination];
    }
}

+ (void)recursiveMigrateBookmarks:(NSDictionary*)node path:(NSArray*)path {
    NSDictionary* data = [node objectForKey:@"Data"];

    if ([data objectForKey:KEY_COMMAND_LINE]) {
        // Not just a folder if it has a command.
        NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:data];
        [self copyProfileToBookmark:temp];
        [temp setObject:[ProfileModel freshGuid] forKey:KEY_GUID];
        [temp setObject:path forKey:KEY_TAGS];
        [temp setObject:kProfilePreferenceCommandTypeCustomValue forKey:KEY_CUSTOM_COMMAND];
        NSString* dir = [data objectForKey:KEY_WORKING_DIRECTORY];
        if (dir && [dir length] > 0) {
            [temp setObject:kProfilePreferenceInitialDirectoryCustomValue
                     forKey:KEY_CUSTOM_DIRECTORY];
        } else if (dir && [dir length] == 0) {
            [temp setObject:kProfilePreferenceInitialDirectoryRecycleValue
                     forKey:KEY_CUSTOM_DIRECTORY];
        } else {
            [temp setObject:kProfilePreferenceInitialDirectoryHomeValue
                     forKey:KEY_CUSTOM_DIRECTORY];
        }
        [[ProfileModel sharedInstance] addBookmark:temp];
    }

    NSArray* entries = [node objectForKey:@"Entries"];
    for (int i = 0; i < [entries count]; ++i) {
        NSMutableArray* childPath = [NSMutableArray arrayWithArray:path];
        NSDictionary* dataDict = [node objectForKey:@"Data"];
        if (dataDict) {
            NSString* name = [dataDict objectForKey:@"Name"];
            if (name) {
                [childPath addObject:name];
            }
        }
        [self recursiveMigrateBookmarks:[entries objectAtIndex:i] path:childPath];
    }
}

static NSString *const iTermMigrationHelperRemoveDeprecatedKeyMappingsUserDefaultKey = @"NoSyncRemoveDeprecatedKeyMappings";

+ (iTermMigrationHelperShouldRemoveDeprecatedKeyMappings)shouldRemoveDeprecatedKeyMappings {
    NSUserDefaults *ud = [iTermUserDefaults userDefaults];
    NSNumber *n = [NSNumber castFrom:[ud objectForKey:iTermMigrationHelperRemoveDeprecatedKeyMappingsUserDefaultKey]];
    if (!n) {
        // User hasn't been prompted.
        return iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsDefault;
    }
    return (iTermMigrationHelperShouldRemoveDeprecatedKeyMappings)n.unsignedIntegerValue;
}

+ (void)setShouldRemoveDeprecatedKeyMappings:(iTermMigrationHelperShouldRemoveDeprecatedKeyMappings)value {
    NSUserDefaults *ud = [iTermUserDefaults userDefaults];
    [ud setObject:@(value)
           forKey:iTermMigrationHelperRemoveDeprecatedKeyMappingsUserDefaultKey];
}

+ (void)askToRemoveDeprecatedKeyMappingsIfNeeded NS_AVAILABLE_MAC(15) {
    switch ([self shouldRemoveDeprecatedKeyMappings]) {
        case iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsNoneFound:
            // Didn't find any last time. To avoid slowing launch, assume it hasn't changed.
            return;
        case iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsNo:
            // User declined previously.
            return;
        case iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsYes:
            // Already removed them. To avoid slowing launch, assume they are still gone.
            return;
        case iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsDefault:
            // First launch since this user defaultw as added.
            if (![self anyProfileOrArrangementHasDeprecatedKeyMappings]) {
                [self setShouldRemoveDeprecatedKeyMappings:iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsNoneFound];
                return;
            }
            // Go on to prompt the user.
            break;

    }

    if ([self askToRemoveDeprecatedKeyMappings:nil]) {
        [self removeDeprecatedKeyMappingsTestOnly:NO];
    }
}

+ (BOOL)askToRemoveDeprecatedKeyMappings:(NSString *)specialReason NS_AVAILABLE_MAC(15) {
    NSString *message = specialReason ?: NSLocalizedStringFromTableInBundle(@"Some profiles have unnecessary key mappings which may interfere with window tiling shortcuts added in macOS Sequoia. These were in the default profile for many years but are no longer needed. Remove the key mappings? It shouldn’t break anything, and it won’t modify the on-disk copy of the dynamic profile.", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"一些配置文件有不必要的按键映射，可能会干扰 macOS Sequoia 中添加的窗口平铺快捷键。这些映射在默认配置文件中存在多年，但已不再需要。是否移除这些按键映射？这不会破坏任何功能，也不会修改动态配置文件的磁盘副本。");


    const iTermWarningSelection selection =
    [iTermWarning showWarningWithTitle:message
                               actions:@[ NSLocalizedStringFromTableInBundle(@"OK", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"好"), NSLocalizedStringFromTableInBundle(@"Learn More", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"了解更多"), NSLocalizedStringFromTableInBundle(@"Cancel", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"取消") ]
                             accessory:nil
                            identifier:nil
                           silenceable:kiTermWarningTypePersistent
                               heading:NSLocalizedStringFromTableInBundle(@"Remove Deprecated Key Mappings?", @"AppLaunch", [NSBundle bundleForClass:[self class]], @"移除已弃用的按键映射？")
                                window:nil];
    switch (selection) {
        case kiTermWarningSelection0:  // ok
            [self setShouldRemoveDeprecatedKeyMappings:iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsYes];
            return YES;
            break;
        case kiTermWarningSelection1:  // lean more
            [[NSWorkspace sharedWorkspace] it_openURL:[NSURL URLWithString:@"https://gitlab.com/gnachman/iterm2/-/wikis/Deprecated-Key-Mappings"]
                                               target:nil
                                                style:iTermOpenStyleTab
                                               window:nil];
            return [self askToRemoveDeprecatedKeyMappings:specialReason];
            break;
        default:  // cancel
            [self setShouldRemoveDeprecatedKeyMappings:iTermMigrationHelperShouldRemoveDeprecatedKeyMappingsNo];
            return NO;
            break;
    }
}

// Returns true if any change would be made.
+ (BOOL)anyProfileOrArrangementHasDeprecatedKeyMappings {
    return [self removeDeprecatedKeyMappingsTestOnly:YES];
}

// Returns true if any change was/would be made.
+ (BOOL)removeDeprecatedKeyMappingsTestOnly:(BOOL)testOnly {
    const BOOL global = [self removeDeprecatedKeyMappingsInModel:[ProfileModel sharedInstance]
                                                        testOnly:testOnly];
    const BOOL divorced = [self removeDeprecatedKeyMappingsInModel:[ProfileModel sessionsInstance]
                                                          testOnly:testOnly];
    const BOOL arrangement = [self removeDeprecatedKeyMappingsFromArrangementsTestOnly:testOnly];
    return global || divorced || arrangement;
}

+ (BOOL)removeDeprecatedKeyMappingsFromArrangementsTestOnly:(BOOL)testOnly {
    __block BOOL changed = NO;
    for (NSString *name in [WindowArrangements allNames]) {
        NSArray *windowArrangements = [WindowArrangements arrangementWithName:name];
        NSArray *modifiedArrangements = [windowArrangements mapWithBlock:^id _Nullable(NSDictionary *arrangement) {
            return [PseudoTerminal repairedArrangement:arrangement profileMutator:^NSDictionary *(NSDictionary *profile) {
                NSDictionary *keyMappings = profile[KEY_KEYBOARD_MAP];
                if (!keyMappings) {
                    return profile;
                }
                NSDictionary *dict = [self keyMappingsByRemovingDeprecatedKeyMappingsFrom:keyMappings];
                if (dict) {
                    changed = YES;
                }
                NSMutableDictionary *fixed = [profile mutableCopy];
                fixed[KEY_KEYBOARD_MAP] = dict;
                return fixed;
            }];
        }];
        if (!testOnly) {
            [WindowArrangements setArrangement:modifiedArrangements withName:name];
        }
    }
    return changed;
}

+ (BOOL)removeDeprecatedKeyMappingsInModel:(ProfileModel *)model
                                  testOnly:(BOOL)testOnly {
    NSArray<Profile *> *profiles = [[model bookmarks] copy];
    __block BOOL changed = NO;
    [profiles enumerateObjectsUsingBlock:^(NSDictionary *profile, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self removeDeprecatedKeyMappingsInProfile:profile model:model testOnly:testOnly]) {
            changed = YES;
        }
    }];
    return changed;
}

// Returns nil if nothing was changed.
+ (NSDictionary *)keyMappingsByRemovingDeprecatedKeyMappingsFrom:(NSDictionary *)input {
    if (!input) {
        return nil;
    }
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"DeprecatedProfileKeyMappings"
                      ofType:@"plist"];
    NSDictionary *deprecations = [NSDictionary dictionaryWithContentsOfFile:path];
    NSMutableDictionary *mappings = nil;

    for (NSString *key in deprecations) {
        id deprecatedValue = deprecations[key];
        id actualValue = input[key];
        if ([deprecatedValue isEqual:actualValue]) {
            if (!mappings) {
                mappings = [input mutableCopy];
            }
            [mappings removeObjectForKey:key];
        }
    }
    return mappings;
}

+ (BOOL)removeDeprecatedKeyMappingsInProfile:(Profile *)profile
                                       model:(ProfileModel *)model
                                    testOnly:(BOOL)testOnly {
    NSDictionary *mappings = [self keyMappingsByRemovingDeprecatedKeyMappingsFrom:profile[KEY_KEYBOARD_MAP]];
    if (mappings && !testOnly) {
        [iTermProfilePreferences setObject:mappings
                                    forKey:KEY_KEYBOARD_MAP
                                 inProfile:profile
                                     model:model];
    }
    return mappings != nil;
}

// 3.5.14 and earlier had a lot fewer settings. This code is meant to migrate
// them to the modern equivalent. It should be idempotent because once user
// defaults has values for these settings they will not be changed by this
// function.
+ (void)migrateAISettings {
    // One-time: the AI command safety check used to run on-device via Apple
    // Intelligence (free); it can now use the configured AI model instead
    // (more accurate, but may incur provider charges). Runs regardless of
    // whether AI is currently enabled.
    //
    // Only grandfather the free on-device behavior when Apple Intelligence is
    // actually working on this Mac right now. That is the only case where the
    // 3.6 check was really running on-device. If it is not working now (too old
    // or ineligible hardware, Apple Intelligence turned off in System Settings,
    // or the model not yet downloaded) the 3.6 check was a no-op that returned
    // "safe" here, so there is no on-device behavior to preserve: clear the
    // (syncing) pref and the nag flag so the standard opt-in nag re-fires and
    // the user knowingly chooses the configured-model behavior. This avoids
    // both a silent cloud send and a fail-closed dead end.
    NSUserDefaults *safetyDefaults = [iTermUserDefaults userDefaults];
    if (![safetyDefaults boolForKey:kPreferenceKeyAISafetyCheckProviderMigrationDone]) {
        [safetyDefaults setBool:YES forKey:kPreferenceKeyAISafetyCheckProviderMigrationDone];
        if ([iTermPreferences boolForKey:kPreferenceKeyAISafetyCheck]) {
            if ([iTermAIAvailabilityProbe check]) {
                // Genuine on-device user: keep using Apple Intelligence and ask
                // before the next checked command whether to switch to the paid
                // model (see RemoteCommand.isSafe).
                [safetyDefaults setBool:YES forKey:kPreferenceKeyAISafetyCheckUsesAppleIntelligence];
                [safetyDefaults setBool:YES forKey:kPreferenceKeyAISafetyCheckProviderSwitchPending];
            } else {
                [iTermPreferences setObject:nil forKey:kPreferenceKeyAISafetyCheck];
                [safetyDefaults removeObjectForKey:kPreferenceKeyAISafetyCheckNagComplete];
            }
        }
    }

    if ([iTermSecureUserDefaults.instance enableAI]) {
        // A default configuration has no model or URL set.
        iTermAIModel *model;
        NSUserDefaults *ud = [iTermUserDefaults userDefaults];
        NSString *originalModelName = [ud stringForKey:kPreferenceKeyAIModel];
        NSString *originalURL = [iTermPreferences stringForKey:kPreferenceKeyAITermURL];
        const BOOL originalLegacy = [ud boolForKey:kPreferenceKeyAITermUseLegacyAPI];
        if (originalModelName == nil) {
            model = [AIMetadata defaultModel];
            [ud setObject:model.name
                   forKey:kPreferenceKeyAIModel];
        } else {
            model = [[iTermAIModel alloc] initWithModelName:originalModelName
                                            url:originalURL
                                         legacy:originalLegacy];
        }
        if ([ud objectForKey:kPreferenceKeyAITermAPI] == nil) {
            if (originalLegacy) {
                [ud setInteger:iTermAIAPICompletions
                        forKey:kPreferenceKeyAITermAPI];
            } else {
                [ud setInteger:model.api
                        forKey:kPreferenceKeyAITermAPI];
            }
        }
        if (originalURL.length == 0) {
            [ud setObject:model.url
                   forKey:kPreferenceKeyAITermURL];
        }
        if ([ud objectForKey:kPreferenceKeyAIFeatureFunctionCalling] == nil) {
            [ud setBool:model.functionCallingFeatureEnabled
                 forKey:kPreferenceKeyAIFeatureFunctionCalling];
        }
        if ([ud objectForKey:kPreferenceKeyAIFeatureHostedWebSearch] == nil) {
            [ud setBool:model.hostedWebSearchFeatureEnabled
                 forKey:kPreferenceKeyAIFeatureHostedWebSearch];
        }
        if ([ud objectForKey:kPreferenceKeyAIFeatureHostedFileSearch] == nil) {
            [ud setBool:model.hostedFileSearchFeatureEnabled
                 forKey:kPreferenceKeyAIFeatureHostedFileSearch];
        }
        if ([ud objectForKey:kPreferenceKeyAIFeatureHostedCodeInterpreter] == nil) {
            [ud setBool:model.hostedCodeInterpreterFeatureEnabled
                 forKey:kPreferenceKeyAIFeatureHostedCodeInterpreter];
        }
        if ([ud objectForKey:kPreferenceKeyAIFeatureStreamingResponses] == nil) {
            [ud setBool:model.streamingFeatureEnabled
                 forKey:kPreferenceKeyAIFeatureStreamingResponses];
        }
        if ([ud objectForKey:kPreferenceKeyAITokenLimit] == nil) {
            [ud setInteger:model.contextWindowTokens
                    forKey:kPreferenceKeyAITokenLimit];
        }
        if ([ud objectForKey:kPreferenceKeyAIResponseTokenLimit] == nil) {
            [ud setInteger:model.maxResponseTokens
                    forKey:kPreferenceKeyAIResponseTokenLimit];
        }
    }
}

@end

