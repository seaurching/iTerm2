//
//  ProfilesSessionViewController.m
//  iTerm
//
//  Created by George Nachman on 4/18/14.
//
//

#import "ProfilesSessionPreferencesViewController.h"
#import "ITAddressBookMgr.h"
#import "iTermColorMap.h"
#import "iTermFunctionCallTextFieldDelegate.h"
#import "iTermPreferences.h"
#import "iTermProfilePreferences.h"
#import "iTermStatusBarSetupViewController.h"
#import "iTermTheme.h"
#import "iTermUserDefaultsObserver.h"
#import "iTermVariableHistory.h"
#import "iTermVariables.h"
#import "iTermWarning.h"
#import "NSAppearance+iTerm.h"
#import "NSArray+iTerm.h"
#import "NSColor+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "NSFileManager+iTerm.h"
#import "NSImage+iTerm.h"
#import "NSObject+iTerm.h"
#import "NSStringITerm.h"
#import "NSView+iTerm.h"
#import "PSMMinimalTabStyle.h"
#import "PreferencePanel.h"
#import "Trigger.h"

#import "iTerm2SharedARC-Swift.h"

static NSString *const ProfilesSessionPreferencesViewControllerPhonyShortLivedSessionsKey = @"ProfilesSessionPreferencesViewControllerPhonyShortLivedSessionsKey";

@interface iTermStatusBarSetupPanel : NSPanel
@end

@implementation iTermStatusBarSetupPanel

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    return YES;
}

@end

@interface ProfilesSessionPreferencesViewController () <NSTableViewDelegate, NSTableViewDataSource, PSMMinimalTabStyleDelegate>
@end

@implementation ProfilesSessionPreferencesViewController {
    IBOutlet NSPopUpButton *_onEndAction;
    IBOutlet NSTableView *_jobsTable;
    IBOutlet NSButton *_addJob;
    IBOutlet NSButton *_removeJob;
    IBOutlet NSButton *_autoLog;
    IBOutlet NSPopUpButton *_loggingStyle;
    IBOutlet NSTextField *_logDir;
    IBOutlet NSTextField *_logFilenameFormat;
    iTermFunctionCallTextFieldDelegate *_logFilenameFormatDelegate;

    IBOutlet NSButton *_sendCodeWhenIdle;
    IBOutlet NSTextField *_idleCode;
    IBOutlet NSTextField *_idlePeriod;

    IBOutlet NSImageView *_logDirWarning;
    IBOutlet NSButton *_changeLogDir;

    IBOutlet NSButton *_archive;
    IBOutlet NSButton *_archiveHelp;
    IBOutlet NSImageView *_archiveDirWarning;
    IBOutlet NSButton *_changeArchiveDir;
    IBOutlet NSTextField *_archiveDir;

    IBOutlet NSTextField *_undoTimeout;
    IBOutlet NSButton *_reduceFlicker;

    IBOutlet NSPopUpButton *_promptBeforeClosing;

    IBOutlet NSButton *_statusBarEnabled;
    IBOutlet NSButton *_configureStatusBar;

    IBOutlet NSButton *_openPasswordManagerAutomatically;
    IBOutlet NSPopUpButton *_showTimestampsPopup;
    IBOutlet NSButton *_timestampsEnabled;
    IBOutlet NSTextField *_showTimestampsLabel;
    IBOutlet NSButton *_warnAboutShortLivedSessions;

    IBOutlet NSButton *_enableProgressBars;
    IBOutlet NSTextField *_progressBarHeight;
    IBOutlet NSStepper *_progressBarHeightStepper;
    IBOutlet NSPopUpButton *_progressBarColorScheme;

    IBOutlet NSButton *_defaultPaneLocked;
    IBOutlet NSButton *_bufferByDefault;
    IBOutlet NSButton *_bufferHelp;
    IBOutlet NSTextField *_bufferWarning;

    iTermStatusBarSetupViewController *_statusBarSetupViewController;
    iTermStatusBarSetupPanel *_statusBarSetupWindow;
    BOOL _awoken;
    iTermUserDefaultsObserver *_topBottomMarginsObserver;
    PreferenceInfo *_progressBarHeightInfo;
}

- (void)dealloc {
    _jobsTable.dataSource = nil;
    _jobsTable.delegate = nil;
}

- (NSSet<NSString *> *(^)(NSString *))prenatalPathSource {
    NSArray<NSString *> *allowList = @[
        iTermVariableKeySessionAutoLogID,
        iTermVariableKeySessionBadge,
        iTermVariableKeySessionColumns,
        iTermVariableKeySessionCreationTimeString,
        iTermVariableKeySessionID,
        iTermVariableKeySessionProfileName,
        iTermVariableKeySessionRows,
        iTermVariableKeySessionTermID,

        [@[ iTermVariableKeyGlobalScopeName, iTermVariableKeyApplicationEffectiveTheme] componentsJoinedByString:@"."],
        [@[ iTermVariableKeyGlobalScopeName, iTermVariableKeyApplicationLocalhostName] componentsJoinedByString:@"."],
        [@[ iTermVariableKeyGlobalScopeName, iTermVariableKeyApplicationPID] componentsJoinedByString:@"."],
        [@[ iTermVariableKeyGlobalScopeName, iTermVariableKeyApplicationBundlePath] componentsJoinedByString:@"."],
    ];
    return ^NSSet<NSString *> *(NSString *prefix) {
        NSArray<NSString *> *array = [allowList filteredArrayUsingBlock:^BOOL(NSString *anObject) {
            return [anObject it_hasPrefix:prefix];
        }];
        return [NSSet setWithArray:array];
    };
}

- (void)awakeFromNib {
    if (_awoken) {
        return;
    }
    _awoken = YES;
    [_archive it_fitBeforeHelpButton:_archiveHelp];
    [_bufferByDefault it_fitBeforeHelpButton:_bufferHelp
                               trailingViews:@[ _bufferWarning ]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadProfiles)
                                                 name:kReloadAllProfiles
                                               object:nil];
    __weak __typeof(self) weakSelf = self;
    PreferenceInfo *info;
    info = [self defineControl:_onEndAction
                           key:KEY_SESSION_END_ACTION
                   displayName:NSLocalizedStringFromTableInBundle(@"Close or restart session on end", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for session end action")
                          type:kPreferenceInfoTypePopup];
    info.customSettingChangedHandler = ^(id sender) {
        [weakSelf onEndSettingDidChange];
    };
    info.onUpdate = ^BOOL{
        [weakSelf updateEnabledState];
        return NO;
    };
    
    info = [self defineControl:_promptBeforeClosing
                           key:KEY_PROMPT_CLOSE
                   relatedView:nil
                   displayName:nil
                          type:kPreferenceInfoTypePopup
                settingChanged:^(id obj) { [weakSelf promptBeforeClosingDidChange]; }
                        update:^BOOL{ [weakSelf updatePromptBeforeClosing]; return YES; }
                    searchable:YES];
    info.observer = ^{
        [weakSelf updateJobsUIEnabled];
    };

    [self defineControl:_undoTimeout
                    key:KEY_UNDO_TIMEOUT
            displayName:NSLocalizedStringFromTableInBundle(@"Undo close session timeout", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for undo close session timeout")
                   type:kPreferenceInfoTypeIntegerTextField];

    info = [self defineControl:_autoLog
                           key:KEY_AUTOLOG
                   relatedView:nil
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        const BOOL loggingEnabled = [strongSelf boolForKey:KEY_AUTOLOG];
        strongSelf->_logDir.enabled = loggingEnabled;
        strongSelf->_logFilenameFormat.enabled = loggingEnabled;
        strongSelf->_changeLogDir.enabled = loggingEnabled;
        strongSelf->_loggingStyle.enabled = loggingEnabled;
        [strongSelf updateLogDirWarning];
    };

    info = [self defineControl:_archive
                           key:KEY_ARCHIVE
                   relatedView:nil
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        const BOOL archivingEnabled = [strongSelf boolForKey:KEY_ARCHIVE];
        strongSelf->_archiveDir.enabled = archivingEnabled;
        strongSelf->_changeArchiveDir.enabled = archivingEnabled;
        [strongSelf updateArchiveDirWarning];
    };
    info = [self defineUnsearchableControl:_archiveDir
                                       key:KEY_ARCHIVEDIR
                                      type:kPreferenceInfoTypeStringTextField];
    info.observer = ^{ [weakSelf updateArchiveDirWarning]; };

    [self defineControl:_loggingStyle
                    key:KEY_LOGGING_STYLE
            displayName:NSLocalizedStringFromTableInBundle(@"Log plain text, igoring control sequences", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for logging style")
                   type:kPreferenceInfoTypePopup];

    info = [self defineUnsearchableControl:_logDir
                                       key:KEY_LOGDIR
                                      type:kPreferenceInfoTypeStringTextField];
    info.observer = ^() { [weakSelf updateLogDirWarning]; };

    _logFilenameFormatDelegate = [[iTermFunctionCallTextFieldDelegate alloc] initWithPathSource:[self prenatalPathSource]
                                                                                    passthrough:_logFilenameFormat.delegate
                                                                                  functionsOnly:NO];
    _logFilenameFormat.delegate = _logFilenameFormatDelegate;

    [self defineUnsearchableControl:_logFilenameFormat
                                key:KEY_LOG_FILENAME_FORMAT
                               type:kPreferenceInfoTypeStringTextField];

    info = [self defineControl:_sendCodeWhenIdle
                           key:KEY_SEND_CODE_WHEN_IDLE
                   displayName:NSLocalizedStringFromTableInBundle(@"Send ASCII code when idle?", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for send code when idle checkbox")
                          type:kPreferenceInfoTypeCheckbox];
    info.customSettingChangedHandler = ^(id sender) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        BOOL isOn = [(NSButton *)sender state] == NSControlStateValueOn;
        if (isOn) {
            static NSString *const kWarnAboutSendCodeWhenIdle = @"NoSyncWarnAboutSendCodeWhenIdle";
            // This stupid feature was inherited from iTerm 0.1. It doesn't work because people
            // set a code of 0, thinking it will keep their ssh sessions alive. While it does, it
            // will also fill your prompt with ^@ characters, if you're lucky. If you're not at your
            // prompt it could do basically anything. It's useful for people working with awful
            // outdated networking equipment who know what they're doing so I'm not killing it.
            // If you came here because you want to keep your ssh sessions alive, look into enabling
            // KeepAlive on your ssh client. Put this in your ~/.ssh/config:
            // Host *
            //   ServerAliveInterval 60
            iTermWarningSelection selection =
                [iTermWarning showWarningWithTitle:NSLocalizedStringFromTableInBundle(@"You probably don’t want to turn this on. It’s not suitable for keeping ssh sessions alive, even with a code of “0”. Are you sure you want this?", @"Settings", [NSBundle bundleForClass:[self class]], @"Warning when enabling send code when idle")
                                           actions:@[ NSLocalizedStringFromTableInBundle(@"Enable Send Code", @"Settings", [NSBundle bundleForClass:[self class]], @"Enable send code button"), NSLocalizedStringFromTableInBundle(@"Cancel", @"Settings", [NSBundle bundleForClass:[self class]], @"Cancel button") ]
                                        identifier:kWarnAboutSendCodeWhenIdle
                                       silenceable:kiTermWarningTypePermanentlySilenceable
                                            window:weakSelf.view.window];
            if (selection == kiTermWarningSelection0) {
                [strongSelf setBool:YES forKey:KEY_SEND_CODE_WHEN_IDLE];
            } else {
                strongSelf->_sendCodeWhenIdle.state = NSControlStateValueOff;
            }
        } else {
            [strongSelf setBool:NO forKey:KEY_SEND_CODE_WHEN_IDLE];
        }
    };
    info.observer = ^() {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf->_idleCode.enabled = [self boolForKey:KEY_SEND_CODE_WHEN_IDLE];
        strongSelf->_idlePeriod.enabled = [self boolForKey:KEY_SEND_CODE_WHEN_IDLE];
    };

    info = [self defineControl:_idleCode
                           key:KEY_IDLE_CODE
                   displayName:NSLocalizedStringFromTableInBundle(@"Send character periodically while idle", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for idle code field")
                          type:kPreferenceInfoTypeIntegerTextField];
    info.range = NSMakeRange(0, 256);

    [self defineControl:_idlePeriod
                    key:KEY_IDLE_PERIOD
            displayName:NSLocalizedStringFromTableInBundle(@"Time between sending characters when idle", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for idle period field")
                   type:kPreferenceInfoTypeDoubleTextField];

    [self updateRemoveJobButtonEnabled];

    [self defineControl:_reduceFlicker
                    key:KEY_REDUCE_FLICKER
            relatedView:nil
                   type:kPreferenceInfoTypeCheckbox];

    info = [self defineControl:_defaultPaneLocked
                    key:KEY_DEFAULT_PANE_LOCKED
            relatedView:nil
                   type:kPreferenceInfoTypeCheckbox];
    info.observer = ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        DLog(@"Default pane locked changed to: %@", @(strongSelf->_defaultPaneLocked.state));
    };

    info = [self defineControl:_bufferByDefault
                           key:KEY_BUFFER_BY_DEFAULT
                   relatedView:nil
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^{
        [weakSelf updateBufferWarning];
    };

    info = [self defineControl:_statusBarEnabled
                           key:KEY_SHOW_STATUS_BAR
                   relatedView:nil
                          type:kPreferenceInfoTypeCheckbox];
    info.observer = ^{
        [weakSelf updateStatusBarSettingsEnabled];
    };
    [weakSelf updateStatusBarSettingsEnabled];
    info.onChange = ^() { [weakSelf postRefreshNotification]; };

    [self defineControl:_openPasswordManagerAutomatically
                    key:KEY_OPEN_PASSWORD_MANAGER_AUTOMATICALLY
            relatedView:nil
                   type:kPreferenceInfoTypeCheckbox];

    info = [self defineControl:_showTimestampsPopup
                           key:KEY_TIMESTAMPS_STYLE
                   relatedView:_showTimestampsLabel
                          type:kPreferenceInfoTypePopup];

    info = [self defineControl:_timestampsEnabled
                    key:KEY_TIMESTAMPS_VISIBLE
            relatedView:nil
                   type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_enableProgressBars
                    key:KEY_ENABLE_PROGRESS_BARS
            displayName:nil
                   type:kPreferenceInfoTypeCheckbox];

    _progressBarHeightInfo = [self defineControl:_progressBarHeight
                                              key:KEY_PROGRESS_BAR_HEIGHT
                                      displayName:NSLocalizedStringFromTableInBundle(@"Progress bar height", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for progress bar height field")
                                             type:kPreferenceInfoTypeIntegerTextField];
    _progressBarHeightInfo.shouldBeEnabled = ^BOOL {
        return [weakSelf boolForKey:KEY_ENABLE_PROGRESS_BARS];
    };
    __weak NSView *heightView = _progressBarHeight;
    _progressBarHeightInfo.didClamp = ^(int oobValue) {
        if (oobValue > [iTermPreferences topBottomMargins]) {
            [heightView it_showInformativeMessageWithMarkdown:NSLocalizedStringFromTableInBundle(@"The progress bar height cannot exceed the top margin’s height. You can adjust it in **Settings > Appearance > Panes > Top & Bottom Margins**.", @"Settings", [NSBundle bundleForClass:[heightView class]], @"Warning that progress bar height exceeds top margin")];
        }
    };
    [_progressBarHeightInfo addShouldBeEnabledDependencyOnSetting:KEY_ENABLE_PROGRESS_BARS
                                                       controller:self];
    [self associateStepper:_progressBarHeightStepper withPreference:_progressBarHeightInfo];
    [self updateProgressBarHeightRange];

    [self populateProgressBarColorSchemes];
    info = [self defineControl:_progressBarColorScheme
                           key:KEY_PROGRESS_BAR_COLOR_SCHEME
                   displayName:NSLocalizedStringFromTableInBundle(@"Progress bar color scheme", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for progress bar color scheme popup")
                          type:kPreferenceInfoTypeStringPopup];
    info.shouldBeEnabled = ^BOOL {
        return [weakSelf boolForKey:KEY_ENABLE_PROGRESS_BARS];
    };
    [info addShouldBeEnabledDependencyOnSetting:KEY_ENABLE_PROGRESS_BARS
                                     controller:self];
    _topBottomMarginsObserver = [[iTermUserDefaultsObserver alloc] init];
    [_topBottomMarginsObserver observeKey:kPreferenceKeyTopBottomMargins block:^{
        [weakSelf updateProgressBarHeightRange];
    }];

    info = [self unsafeDefineControl:_warnAboutShortLivedSessions
                                 key:ProfilesSessionPreferencesViewControllerPhonyShortLivedSessionsKey
                         relatedView:nil
                         displayName:nil
                                type:kPreferenceInfoTypeCheckbox
                      settingChanged:nil
                              update:nil
                          searchable:YES];
    __weak __typeof(info) weakInfo = info;
    info.syntheticGetter = ^id{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return @NO;
        }
        NSString *guid = [strongSelf stringForKey:KEY_GUID];
        if (!guid) {
            return @NO;
        }
        NSString *theKey = [iTermPreferences warningIdentifierForNeverWarnAboutShortLivedSessions:guid];
        return @(![iTermWarning identifierIsSilenced:theKey]);
    };
    info.syntheticSetter = ^(id newValue) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSString *guid = [strongSelf stringForKey:KEY_GUID];
        if (!guid) {
            return;
        }
        NSString *theKey = [iTermPreferences warningIdentifierForNeverWarnAboutShortLivedSessions:guid];
        if ([NSNumber castFrom:newValue].boolValue) {
            [iTermWarning unsilenceIdentifier:theKey];
        } else {
            [iTermWarning setIdentifier:theKey permanentSelection:kiTermWarningSelection0];
        }
        if (weakInfo) {
            [weakSelf updateNonDefaultIndicatorVisibleForInfo:weakInfo];
        }
    };
    info.shouldBeEnabled = ^BOOL {
        return [self unsignedIntegerForKey:KEY_SESSION_END_ACTION] == iTermSessionEndActionClose;
    };
    info.hasDefaultValue = ^BOOL{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return YES;
        }
        NSString *guid = [strongSelf stringForKey:KEY_GUID];
        if (!guid) {
            return YES;
        }
        NSString *theKey = [iTermPreferences warningIdentifierForNeverWarnAboutShortLivedSessions:guid];
        return ![iTermWarning identifierIsSilenced:theKey];
    };
    [self updateNonDefaultIndicatorVisibleForInfo:info];
    [self addViewToSearchIndex:_configureStatusBar
                   displayName:NSLocalizedStringFromTableInBundle(@"Configure status bar", @"Settings", [NSBundle bundleForClass:[self class]], @"Display name for configure status bar button")
                       phrases:@[]
                           key:nil];
    [self commitControls];
}

- (void)populateProgressBarColorSchemes {
    [_progressBarColorScheme removeAllItems];
    NSArray<NSString *> *schemes = @[
        iTermProgressBarColorSchemeDefault,
        iTermProgressBarColorSchemeRainbow,
        iTermProgressBarColorSchemeRed,
        iTermProgressBarColorSchemeGreen,
        iTermProgressBarColorSchemeBlue,
        iTermProgressBarColorSchemeYellow,
        iTermProgressBarColorSchemePurple,
        iTermProgressBarColorSchemeCyan,
        iTermProgressBarColorSchemeOrange
    ];
    NSDictionary<NSString *, NSString *> *titles = @{
        iTermProgressBarColorSchemeDefault: NSLocalizedStringFromTableInBundle(@"Default", @"Settings", [NSBundle bundleForClass:[self class]], @"Default progress bar color scheme title"),
        iTermProgressBarColorSchemeRainbow: NSLocalizedStringFromTableInBundle(@"Rainbow", @"Settings", [NSBundle bundleForClass:[self class]], @"Rainbow progress bar color scheme title"),
        iTermProgressBarColorSchemeRed: NSLocalizedStringFromTableInBundle(@"Red", @"Settings", [NSBundle bundleForClass:[self class]], @"Red progress bar color scheme title"),
        iTermProgressBarColorSchemeGreen: NSLocalizedStringFromTableInBundle(@"Green", @"Settings", [NSBundle bundleForClass:[self class]], @"Green progress bar color scheme title"),
        iTermProgressBarColorSchemeBlue: NSLocalizedStringFromTableInBundle(@"Blue", @"Settings", [NSBundle bundleForClass:[self class]], @"Blue progress bar color scheme title"),
        iTermProgressBarColorSchemeYellow: NSLocalizedStringFromTableInBundle(@"Yellow", @"Settings", [NSBundle bundleForClass:[self class]], @"Yellow progress bar color scheme title"),
        iTermProgressBarColorSchemePurple: NSLocalizedStringFromTableInBundle(@"Purple", @"Settings", [NSBundle bundleForClass:[self class]], @"Purple progress bar color scheme title"),
        iTermProgressBarColorSchemeCyan: NSLocalizedStringFromTableInBundle(@"Cyan", @"Settings", [NSBundle bundleForClass:[self class]], @"Cyan progress bar color scheme title"),
        iTermProgressBarColorSchemeOrange: NSLocalizedStringFromTableInBundle(@"Orange", @"Settings", [NSBundle bundleForClass:[self class]], @"Orange progress bar color scheme title")
    };
    for (NSString *scheme in schemes) {
        NSString *title = titles[scheme];
        [_progressBarColorScheme addItemWithTitle:title];
        [[_progressBarColorScheme lastItem] setRepresentedObject:scheme];
    }
}

- (void)updateBufferWarning {
    _bufferWarning.hidden = !([self boolForKey:KEY_BUFFER_BY_DEFAULT] && ![self hasUnbufferTrigger]);
}

- (BOOL)hasUnbufferTrigger {
    NSArray *triggers = [NSArray castFrom:[self objectForKey:KEY_TRIGGERS]];
    if (!triggers) {
        return NO;
    }
    return [triggers anyWithBlock:^BOOL(id obj) {
        NSDictionary *dict = [NSDictionary castFrom:obj];
        if (!dict) {
            return NO;
        }
        iTermBufferInputTrigger *trigger = [iTermBufferInputTrigger castFrom:[Trigger triggerFromUntrustedDict:dict]];
        if (!trigger) {
            return NO;
        }
        return !trigger.shouldBuffer;
    }];
}

- (void)onEndSettingDidChange {
    [self setUnsignedInteger:_onEndAction.selectedTag forKey:KEY_SESSION_END_ACTION];
}

// Ensure the anti-idle period's value is constrained to the legal range.
- (void)setDouble:(double)value forKey:(NSString *)key {
    if ([key isEqualToString:KEY_IDLE_PERIOD]) {
        value = MAX(kMinimumAntiIdlePeriod, value);
    }
    [super setDouble:value forKey:key];
}

- (void)layoutSubviewsForEditCurrentSessionMode {
    NSArray *viewsToDisable = @[ _autoLog,
                                 _logDir,
                                 _logFilenameFormat,
                                 _changeLogDir,
                                 _archive,
                                 _archiveDir,
                                 _defaultPaneLocked,
                                 _bufferByDefault ];
    for (id view in viewsToDisable) {
        [view setEnabled:NO];
    }
    [self awakeFromNib];  // We can get called before awakeFromNib
    [self infoForControl:_autoLog].observer = NULL;
    [self infoForControl:_logDir].observer = NULL;
    [self infoForControl:_archive].observer = NULL;
    [self infoForControl:_archiveDir].observer = NULL;
    [self infoForControl:_bufferByDefault].observer = NULL;

    [self updateStatusBarSettingsEnabled];
}

- (void)updateStatusBarSettingsEnabled {
    const BOOL tmux = [self.delegate editingTmuxSession];
    _statusBarEnabled.enabled = !tmux;
    _configureStatusBar.enabled = !tmux && [self boolForKey:KEY_SHOW_STATUS_BAR];
}

- (void)reloadProfile {
    [super reloadProfile];
    [_jobsTable reloadData];
    [self updateRemoveJobButtonEnabled];
    [self updateStatusBarSettingsEnabled];
    [self updateBufferWarning];
    if (_awoken) {
        [self updateNonDefaultIndicatorVisibleForInfo:[self infoForControl:_logFilenameFormat]];
    }
}

- (NSArray *)keysForBulkCopy {
    NSArray *keys = @[ KEY_JOBS, KEY_STATUS_BAR_LAYOUT ];
    return [[super keysForBulkCopy] arrayByAddingObjectsFromArray:keys];
}

- (BOOL)allowRainbow {
    // I was going to make this an easter egg but it was revealed by the Whats New screenshot.
    return YES;
}

- (iTermColorMap *)colorMap {
    iTermColorMap *colorMap = [[iTermColorMap alloc] init];
    const BOOL dark = self.view.effectiveAppearance.it_isDark;
    Profile *profile = [self.delegate profilePreferencesCurrentProfile];
    colorMap.mutingAmount = [iTermProfilePreferences floatForColorKey:KEY_CURSOR_BOOST dark:dark profile:profile];
    colorMap.dimOnlyText = [iTermPreferences dimOnlyText];
    colorMap.minimumContrast = [iTermProfilePreferences floatForColorKey:KEY_MINIMUM_CONTRAST
                                                                    dark:dark
                                                                 profile:profile];
    colorMap.faintTextAlpha = [iTermProfilePreferences floatForColorKey:KEY_FAINT_TEXT_ALPHA
                                                                   dark:dark
                                                                profile:profile];
    return colorMap;
}

- (id<PSMTabStyle>)tabStyle {
    return [[iTermTheme sharedInstance] tabStyleWithDelegate:self
                                         effectiveAppearance:self.view.window.effectiveAppearance];
}

- (NSColor *)sessionBackgroundColor {
    NSString *key = [iTermProfilePreferences amendedColorKey:KEY_BACKGROUND_COLOR
                                                        dark:self.view.effectiveAppearance.it_isDark
                                                     profile:[self.delegate profilePreferencesCurrentProfile]];
    NSDictionary *dict = [NSDictionary castFrom:[self objectForKey:key]];
    if (!dict) {
        return [NSColor colorWithRed:0 green:0 blue:0 alpha:1];
    }
    return [dict colorValue];
}

- (NSColor *)tabColor {
    const BOOL dark = self.view.effectiveAppearance.it_isDark;
    Profile *profile = [self.delegate profilePreferencesCurrentProfile];
    if (![iTermProfilePreferences boolForTabColorKey:KEY_USE_TAB_COLOR
                                               dark:dark
                                            profile:profile]) {
        return nil;
    }
    return [iTermProfilePreferences colorForTabColorKey:KEY_TAB_COLOR dark:dark profile:profile];
}

- (NSAppearance *)appearanceForCurrentTheme {
    const iTermPreferencesTabStyle preferredStyle = [iTermPreferences intForKey:kPreferenceKeyTabStyle];
    switch (preferredStyle) {
        case TAB_STYLE_DARK:
        case TAB_STYLE_DARK_HIGH_CONTRAST:
            return [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        case TAB_STYLE_LIGHT:
        case TAB_STYLE_LIGHT_HIGH_CONTRAST:
            return [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        case TAB_STYLE_AUTOMATIC:
        case TAB_STYLE_COMPACT:
        case TAB_STYLE_MINIMAL:
            return self.view.effectiveAppearance;
    }
}

- (IBAction)configureStatusBar:(id)sender {
    NSDictionary *layoutDictionary = [NSDictionary castFrom:[self objectForKey:KEY_STATUS_BAR_LAYOUT]] ?: @{};
    NSColor *backgroundColor = [self sessionBackgroundColor];
    const BOOL dark = [backgroundColor perceivedBrightness] < 0.5;
    _statusBarSetupViewController =
        [[iTermStatusBarSetupViewController alloc] initWithLayoutDictionary:layoutDictionary
                                                             darkBackground:[NSAppearance it_decorationsAreDarkWithTerminalBackgroundColorIsDark:dark]
                                                               allowRainbow:[self allowRainbow]
                                                                profileType:[Profile profileTypeForCustomCommand:[self stringForKey:KEY_CUSTOM_COMMAND]]];
    _statusBarSetupViewController.defaultTextColor = [[iTermTheme sharedInstance] statusBarTextColorForEffectiveAppearance:[self appearanceForCurrentTheme]
                                                                                                               marginColor:nil
                                                                                                                  colorMap:[self colorMap]
                                                                                                                  tabStyle:[self tabStyle]
                                                                                                             mainAndActive:YES];
    _statusBarSetupViewController.defaultBackgroundColor = [[iTermTheme sharedInstance] statusBarContainerBackgroundColorForTabColor:[self tabColor]
                                                                                                                 effectiveAppearance:[self appearanceForCurrentTheme]
                                                                                                                            tabStyle:[self tabStyle]
                                                                                                              sessionBackgroundColor:[self sessionBackgroundColor]
                                                                                                                    isFirstResponder:YES
                                                                                                                         dimOnlyText:[self boolForKey:kPreferenceKeyDimOnlyText]
                                                                                                               adjustedDimmingAmount:0
                                                                                                                   transparencyAlpha:1];
    __weak __typeof(self) weakSelf = self;
    _statusBarSetupViewController.applyBlock = ^(NSDictionary *layoutDictionary) {
        [weakSelf setObject:layoutDictionary forKey:KEY_STATUS_BAR_LAYOUT];
    };

    _statusBarSetupWindow =
        [[iTermStatusBarSetupPanel alloc] initWithContentRect:_statusBarSetupViewController.view.frame
                                                    styleMask:NSWindowStyleMaskResizable
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    _statusBarSetupWindow.minSize = _statusBarSetupViewController.view.frame.size;
    NSDictionary *savedLayoutDictionary = [_statusBarSetupViewController.layoutDictionary copy];
    _statusBarSetupWindow.contentView = _statusBarSetupViewController.view;
    [self.view.window beginSheet:_statusBarSetupWindow completionHandler:^(NSModalResponse returnCode) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            if (!strongSelf->_statusBarSetupViewController.ok) {
                [strongSelf setObject:savedLayoutDictionary forKey:KEY_STATUS_BAR_LAYOUT];
            }
            strongSelf->_statusBarSetupWindow = nil;
            strongSelf->_statusBarSetupViewController = nil;
        }
    }];
}

- (void)configureStatusBarComponentWithIdentifier:(NSString *)identifier {
    if (_statusBarEnabled.state != NSControlStateValueOn) {
        return;
    }
    [self configureStatusBar:nil];
    [_statusBarSetupViewController configureStatusBarComponentWithIdentifier:identifier];
}

#pragma mark - Prompt before closing

- (void)promptBeforeClosingDidChange {
    int tag = [_promptBeforeClosing selectedTag];
    [self setInt:tag forKey:KEY_PROMPT_CLOSE];
    [self updateEnabledState];
    [self updateJobsUIEnabled];
}

- (void)updateJobsUIEnabled {
    const BOOL enableTable = ([self intForKey:KEY_PROMPT_CLOSE] == PROMPT_EX_JOBS);
    _jobsTable.enabled = enableTable;
    _addJob.enabled = enableTable;
    _removeJob.enabled = enableTable &&  ([_jobsTable selectedRow] != -1);
}

- (void)updatePromptBeforeClosing {
    int tag = [self intForKey:KEY_PROMPT_CLOSE];
    [_promptBeforeClosing selectItemWithTag:tag];
}

#pragma mark - Jobs

- (NSArray *)jobs {
    return (NSArray *)[self objectForKey:KEY_JOBS];
}

- (IBAction)addJob:(id)sender {
    NSArray *jobNames = [self jobs];
    NSMutableArray *augmented;
    if (jobNames) {
        augmented = [NSMutableArray arrayWithArray:jobNames];
        [augmented addObject:NSLocalizedStringFromTableInBundle(@"Job Name", @"Settings", [NSBundle bundleForClass:[self class]], @"Default name for a new job")];
    } else {
        augmented = [NSMutableArray arrayWithObject:NSLocalizedStringFromTableInBundle(@"Job Name", @"Settings", [NSBundle bundleForClass:[self class]], @"Default name for a new job")];
    }
    [self setObject:augmented forKey:KEY_JOBS];
    [_jobsTable reloadData];
    [_jobsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[augmented count] - 1]
            byExtendingSelection:NO];
    [_jobsTable editColumn:0
                       row:[self numberOfRowsInTableView:_jobsTable] - 1
                 withEvent:nil
                    select:YES];
    [self updateRemoveJobButtonEnabled];
    [self postRefreshNotification];
}

- (IBAction)removeJob:(id)sender {
    // Causes editing to end. If you try to remove a cell that is being edited,
    // it tries to dereference the deleted cell. There doesn't seem to be an
    // API that explicitly ends editing.
    [_jobsTable reloadData];

    NSInteger selectedIndex = [_jobsTable selectedRow];
    if (selectedIndex < 0) {
        return;
    }
    NSArray *jobNames = [self jobs];
    NSMutableArray *mod = [NSMutableArray arrayWithArray:jobNames];
    [mod removeObjectAtIndex:selectedIndex];

    [self setObject:mod forKey:KEY_JOBS];
    [_jobsTable reloadData];
    [self updateRemoveJobButtonEnabled];
    [self postRefreshNotification];
}

- (void)updateRemoveJobButtonEnabled {
    _removeJob.enabled = _jobsTable.isEnabled && ([_jobsTable selectedRow] != -1);
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView: (NSTableView *)aTableView {
    return [[self jobs] count];
}


- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex {
    NSMutableArray *jobs = [NSMutableArray arrayWithArray:[self jobs]];
    [jobs replaceObjectAtIndex:rowIndex withObject:anObject];
    [self setObject:jobs forKey:KEY_JOBS];
    [self postRefreshNotification];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
                row:(NSInteger)rowIndex {
    NSArray *jobs = self.jobs;
    if (rowIndex >= jobs.count) {
        // Can happen during teardown when the ProfilePreferencesViewController's delegate is nilled.
        return @"";
    }
    return jobs[rowIndex];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateRemoveJobButtonEnabled];
}

#pragma mark - Notifications

- (void)reloadProfiles {
    [_jobsTable reloadData];
    [self updateBufferWarning];
}

#pragma mark - Archive Directory

- (IBAction)selectArchiveDir:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];

    if ([panel runModal] == NSModalResponseOK) {
        NSString *path = [[panel URL] path];
        _archiveDir.stringValue = path;
        [self setString:path forKey:KEY_ARCHIVEDIR];
    }
    [self updateArchiveDirWarning];
}

- (void)updateArchiveDirWarning {
    if ([_archive state] == NSControlStateValueOff) {
        _archiveDirWarning.hidden = YES;
        return;
    }
    _archiveDirWarning.hidden = NO;
    if ([self archiveDirIsWritable]) {
        _archiveDirWarning.image = [NSImage it_imageNamed:@"CheckMark" forClass:self.class];
    } else {
        _archiveDirWarning.image = [NSImage it_imageNamed:@"WarningSign" forClass:self.class];
    }
}

- (BOOL)archiveDirIsWritable {
    return [[NSFileManager defaultManager] directoryIsWritable:[_archiveDir stringValue].stringByExpandingTildeInPath];
}

#pragma mark - Log directory

- (IBAction)selectLogDir:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];

    if ([panel runModal] == NSModalResponseOK) {
        NSString *path = [[panel URL] path];
        _logDir.stringValue = path;
        [self setString:path forKey:KEY_LOGDIR];
    }
    [self updateLogDirWarning];
}

- (void)updateLogDirWarning {
    if ([_autoLog state] == NSControlStateValueOff) {
        _logDirWarning.hidden = YES;
        return;
    }
    _logDirWarning.hidden = NO;
    if ([self logDirIsWritable]) {
        _logDirWarning.image = [NSImage it_imageNamed:@"CheckMark" forClass:self.class];
    } else {
        _logDirWarning.image = [NSImage it_imageNamed:@"WarningSign" forClass:self.class];
    }
}

- (BOOL)logDirIsWritable {
    return [[NSFileManager defaultManager] directoryIsWritable:[_logDir stringValue].stringByExpandingTildeInPath];
}

- (void)updateProgressBarHeightRange {
    if (!_progressBarHeightInfo) {
        return;
    }
    const NSInteger topBottomMargin = [iTermPreferences topBottomMargins];
    _progressBarHeightInfo.range = NSMakeRange(1, topBottomMargin);
}

#pragma mark - PSMMinimalTabStyleDelegate

- (NSColor *)minimalTabStyleBackgroundColor {
    return [self sessionBackgroundColor];
}

@end
