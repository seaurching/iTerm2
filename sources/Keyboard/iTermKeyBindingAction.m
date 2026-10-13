//
//  iTermKeyBindingAction.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 3/21/20.
//

#import "iTermKeyBindingAction.h"

#import "DebugLogging.h"
#import "iTerm2SharedARC-Swift.h"
#import "ITAddressBookMgr.h"
#import "iTermPasteSpecialViewController.h"
#import "iTermSnippetsModel.h"
#import "NSArray+iTerm.h"
#import "NSDictionary+iTerm.h"
#import "PTYTextView.h"  // just for PTYTextViewSelectionExtensionUnit
#import "ProfileModel.h"

NSString *const iTermKeyBindingDictionaryKeyAction = @"Action";
NSString *const iTermKeyBindingDictionaryKeyParameter = @"Text";
NSString *const iTermKeyBindingDictionaryKeyLabel = @"Label";
NSString *const iTermKeyBindingDictionaryKeyVersion = @"Version";
NSString *const iTermKeyBindingDictionaryKeyEscaping = @"Escaping";
NSString *const iTermKeyBindingDictionaryKeyApplyMode = @"Apply Mode";


static NSString *GetProfileName(NSString *guid) {
    return [[[ProfileModel sharedInstance] bookmarkWithGuid:guid] objectForKey:KEY_NAME];
}

@implementation iTermKeyBindingAction {
    NSDictionary *_dictionary;
}

+ (NSString *)escapedText:(NSString *)text mode:(iTermSendTextEscaping)escaping {
    NSString *temp = text;
    switch (escaping) {
        case iTermSendTextEscapingNone:
            return text;
        case iTermSendTextEscapingCommon:
            return [temp stringByReplacingCommonlyEscapedCharactersWithControls];
        case iTermSendTextEscapingCompatibility:
            temp = [temp stringByReplacingEscapedChar:'n' withString:@"\n"];
            temp = [temp stringByReplacingEscapedChar:'e' withString:@"\e"];
            temp = [temp stringByReplacingEscapedChar:'a' withString:@"\a"];
            temp = [temp stringByReplacingEscapedChar:'t' withString:@"\t"];
            return temp;
        case iTermSendTextEscapingVimAndCompatibility:
            temp = [temp stringByExpandingVimSpecialCharacters];
            temp = [temp stringByReplacingEscapedChar:'n' withString:@"\n"];
            temp = [temp stringByReplacingEscapedChar:'e' withString:@"\e"];
            temp = [temp stringByReplacingEscapedChar:'a' withString:@"\a"];
            temp = [temp stringByReplacingEscapedChar:'t' withString:@"\t"];
            return temp;
        case iTermSendTextEscapingVim:
            return [temp stringByExpandingVimSpecialCharacters];
    }
    assert(NO);
    return @"";
}


+ (instancetype)fromString:(NSString *)string {
    NSData *decoded = [[NSData alloc] initWithBase64EncodedString:string options:0];
    if (!decoded) {
        return nil;
    }
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:decoded options:0 error:nil];
    if (!dict) {
        return nil;
    }
    return [self withDictionary:dict];
}

- (NSString *)stringValue {
    NSDictionary *dict = [self dictionaryValue];
    if (!dict) {
        return nil;
    }
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    if (!json) {
        return nil;
    }
    NSData *data = [json base64EncodedDataWithOptions:0];
    if (!data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (instancetype)withDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

+ (instancetype)withAction:(KEY_ACTION)action
                 parameter:(NSString *)parameter
                  escaping:(iTermSendTextEscaping)escaping
                 applyMode:(iTermActionApplyMode)applyMode {
    return [[self alloc] initWithDictionary:@{ iTermKeyBindingDictionaryKeyAction: @(action),
                                               iTermKeyBindingDictionaryKeyParameter: parameter ?: @"",
                                               iTermKeyBindingDictionaryKeyVersion: @2,
                                               iTermKeyBindingDictionaryKeyEscaping: @(escaping),
                                               iTermKeyBindingDictionaryKeyApplyMode: @(applyMode)
    }];
}

+ (instancetype)withAction:(KEY_ACTION)action
                 parameter:(NSString *)parameter
                     label:(NSString *)label
                  escaping:(iTermSendTextEscaping)escaping
                 applyMode:(iTermActionApplyMode)applyMode {
    if (label) {
        return [[self alloc] initWithDictionary:@{ iTermKeyBindingDictionaryKeyAction: @(action),
                                                   iTermKeyBindingDictionaryKeyParameter: parameter ?: @"",
                                                   iTermKeyBindingDictionaryKeyLabel: label,
                                                   iTermKeyBindingDictionaryKeyVersion: @2,
                                                   iTermKeyBindingDictionaryKeyEscaping: @(escaping),
                                                   iTermKeyBindingDictionaryKeyApplyMode: @(applyMode)
        }];
    } else {
        return [[self alloc] initWithDictionary:@{ iTermKeyBindingDictionaryKeyAction: @(action),
                                                   iTermKeyBindingDictionaryKeyParameter: parameter ?: @"",
                                                   iTermKeyBindingDictionaryKeyVersion: @2,
                                                   iTermKeyBindingDictionaryKeyEscaping: @(escaping),
                                                   iTermKeyBindingDictionaryKeyApplyMode: @(applyMode)
        }];
    }
}

+ (NSString *)stringForSelectionMovementUnit:(PTYTextViewSelectionExtensionUnit)unit {
    switch (unit) {
        case kPTYTextViewSelectionExtensionUnitLine:
            return NSLocalizedStringFromTableInBundle(@"By Line", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Selection movement unit: By Line");
        case kPTYTextViewSelectionExtensionUnitCharacter:
            return NSLocalizedStringFromTableInBundle(@"By Character", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Selection movement unit: By Character");
        case kPTYTextViewSelectionExtensionUnitWord:
            return NSLocalizedStringFromTableInBundle(@"By Word", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Selection movement unit: By Word");
        case kPTYTextViewSelectionExtensionUnitBigWord:
            return NSLocalizedStringFromTableInBundle(@"By WORD", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Selection movement unit: By WORD");
        case kPTYTextViewSelectionExtensionUnitMark:
            return NSLocalizedStringFromTableInBundle(@"By Mark", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Selection movement unit: By Mark");
    }
    XLog(@"Unrecognized selection movement unit %@", @(unit));
    return @"";
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (dictionary != nil && ![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    self = [super init];
    if (self) {
        _keyAction = [dictionary[iTermKeyBindingDictionaryKeyAction] intValue];
        _parameter = [dictionary[iTermKeyBindingDictionaryKeyParameter] ?: @"" copy];
        _label = [dictionary[iTermKeyBindingDictionaryKeyLabel] ?: @"" copy];
        _applyMode = [dictionary[iTermKeyBindingDictionaryKeyApplyMode] unsignedIntegerValue];

        const int version = [dictionary[iTermKeyBindingDictionaryKeyVersion] intValue];
        if (version == 0) {
            _escaping = iTermSendTextEscapingCompatibility;
        } else if (version == 1) {
            _escaping = iTermSendTextEscapingCommon;
        } else {
            _escaping = [dictionary[iTermKeyBindingDictionaryKeyEscaping] unsignedIntegerValue];
        }
        _dictionary = [dictionary copy];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    if (_dictionary) {
        return _dictionary;
    }
    // This is complicated because it wants to avoid changing the dictionary unless it is necessary.
    int version;
    id escaping;
    switch (_escaping) {
        case iTermSendTextEscapingCompatibility:
            version = 0;
            escaping = [NSNull null];
            break;
        case iTermSendTextEscapingCommon:
            version = 1;
            escaping = [NSNull null];
            break;
        default:
            version = 2;
            escaping = @(_escaping);
            break;
    }
    NSDictionary *temp = @{ iTermKeyBindingDictionaryKeyAction: @(_keyAction),
                            iTermKeyBindingDictionaryKeyParameter: _parameter ?: @"",
                            iTermKeyBindingDictionaryKeyLabel: _label ?: [NSNull null],
                            iTermKeyBindingDictionaryKeyVersion: @(version),
                            iTermKeyBindingDictionaryKeyEscaping: escaping,
                            iTermKeyBindingDictionaryKeyApplyMode: @(_applyMode)
    };
    return [temp dictionaryByRemovingNullValues];
}

- (iTermSendTextEscaping)vimEscaping {
    switch (_escaping) {
        case iTermSendTextEscapingNone:
        case iTermSendTextEscapingCommon:
        case iTermSendTextEscapingVim:
            return iTermSendTextEscapingVim;
        case iTermSendTextEscapingCompatibility:
        case iTermSendTextEscapingVimAndCompatibility:
            return iTermSendTextEscapingVimAndCompatibility;
    }
}

- (NSString *)displayName {
    NSString *actionString = nil;

    switch (_keyAction) {
        case KEY_ACTION_MOVE_TAB_LEFT:
            actionString = NSLocalizedStringFromTableInBundle(@"Move Tab Left", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Move Tab Left");
            break;
        case KEY_ACTION_MOVE_TAB_RIGHT:
            actionString = NSLocalizedStringFromTableInBundle(@"Move Tab Right", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Move Tab Right");
            break;
        case KEY_ACTION_NEXT_MRU_TAB:
            actionString = NSLocalizedStringFromTableInBundle(@"Cycle Tabs Forward", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Cycle Tabs Forward");
            break;
        case KEY_ACTION_PREVIOUS_MRU_TAB:
            actionString = NSLocalizedStringFromTableInBundle(@"Cycle Tabs Backward", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Cycle Tabs Backward");
            break;
        case KEY_ACTION_NEXT_PANE:
            actionString = NSLocalizedStringFromTableInBundle(@"Next Pane", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Next Pane");
            break;
        case KEY_ACTION_PREVIOUS_PANE:
            actionString = NSLocalizedStringFromTableInBundle(@"Previous Pane", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Previous Pane");
            break;
        case KEY_ACTION_NEXT_SESSION:
            actionString = NSLocalizedStringFromTableInBundle(@"Next Tab", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Next Tab");
            break;
        case KEY_ACTION_NEXT_WINDOW:
            actionString = NSLocalizedStringFromTableInBundle(@"Next Window", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Next Window");
            break;
        case KEY_ACTION_PREVIOUS_SESSION:
            actionString = NSLocalizedStringFromTableInBundle(@"Previous Tab", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Previous Tab");
            break;
        case KEY_ACTION_PREVIOUS_WINDOW:
            actionString = NSLocalizedStringFromTableInBundle(@"Previous Window", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Previous Window");
            break;
        case KEY_ACTION_SCROLL_END:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll To End", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll To End");
            break;
        case KEY_ACTION_SCROLL_HOME:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll To Top", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll To Top");
            break;
        case KEY_ACTION_SCROLL_LINE_DOWN:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll One Line Down", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll One Line Down");
            break;
        case KEY_ACTION_SCROLL_LINE_UP:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll One Line Up", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll One Line Up");
            break;
        case KEY_ACTION_SCROLL_PAGE_DOWN:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll One Page Down", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll One Page Down");
            break;
        case KEY_ACTION_SCROLL_PAGE_UP:
            actionString = NSLocalizedStringFromTableInBundle(@"Scroll One Page Up", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Scroll One Page Up");
            break;
        case KEY_ACTION_ESCAPE_SEQUENCE:
            actionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedStringFromTableInBundle(@"Send ^[", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send escape sequence"), _parameter];
            break;
        case KEY_ACTION_HEX_CODE:
            actionString = [NSString stringWithFormat: @"%@ %@", NSLocalizedStringFromTableInBundle(@"Send Hex Codes:", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send hex codes"), _parameter];
            break;
        case KEY_ACTION_VIM_TEXT:
            actionString = [NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedStringFromTableInBundle(@"Send:", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send text"), _parameter];
            break;
        case KEY_ACTION_VIM_TEXT_NO_BROADCAST:
            actionString = [NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedStringFromTableInBundle(@"Send (no broadcast):", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send text no broadcast"), _parameter];
            break;
        case KEY_ACTION_TEXT:
            actionString = [NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedStringFromTableInBundle(@"Send:", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send text"), _parameter];
            break;
        case KEY_ACTION_SEND_SNIPPET: {
            iTermSnippet *snippet = [[iTermSnippetsModel sharedInstance] snippetWithActionKey:_parameter];
            if (snippet) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Send Snippet “%@”", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: send snippet"), snippet.displayTitle];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Send Deleted Snippet (no action)", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Send Deleted Snippet (no action)");
            }
            break;
        }
        case KEY_ACTION_COMPOSE:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Compose “%@”", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: compose"), _parameter];
            break;
        case KEY_ACTION_SEND_TMUX_COMMAND:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"tmux: %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: tmux command"), _parameter];
            break;
        case KEY_ACTION_RUN_COPROCESS:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Run Coprocess \"%@\"", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: run coprocess"),
						    _parameter];
            break;
        case KEY_ACTION_SELECT_MENU_ITEM: {
            NSArray *parts = [_parameter componentsSeparatedByString:@"\n"];
            actionString = [NSString stringWithFormat:@"%@ “%@”", NSLocalizedStringFromTableInBundle(@"Select Menu Item", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: select menu item"), parts.firstObject];
            break;
        }
        case KEY_ACTION_NEW_WINDOW_WITH_PROFILE:
            if ([[ProfileModel sharedInstance] bookmarkWithGuid:_parameter]) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"New Window with \"%@\" Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: new window with profile"), GetProfileName(_parameter)];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"New Window with unavailable Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: New Window with unavailable Profile");
            }
            break;
        case KEY_ACTION_NEW_TAB_WITH_PROFILE:
            if ([[ProfileModel sharedInstance] bookmarkWithGuid:_parameter]) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"New Tab with \"%@\" Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: new tab with profile"), GetProfileName(_parameter)];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"New Tab with unavailable Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: New Tab with unavailable Profile");
            }
            break;
        case KEY_ACTION_SPLIT_HORIZONTALLY_WITH_PROFILE:
            if ([[ProfileModel sharedInstance] bookmarkWithGuid:_parameter]) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Split Horizontally with \"%@\" Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: split horizontally with profile"), GetProfileName(_parameter)];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Split Horizontally with unavailable Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Split Horizontally with unavailable Profile");
            }
            break;
        case KEY_ACTION_SPLIT_VERTICALLY_WITH_PROFILE:
            if ([[ProfileModel sharedInstance] bookmarkWithGuid:_parameter]) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Split Vertically with \"%@\" Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: split vertically with profile"), GetProfileName(_parameter)];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Split Vertically with unavailable Profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Split Vertically with unavailable Profile");
            }
            break;
        case KEY_ACTION_SET_PROFILE:
            if ([[ProfileModel sharedInstance] bookmarkWithGuid:_parameter]) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Change Profile to \"%@\"", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: change profile"), GetProfileName(_parameter)];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Change Profile to unavailable profile", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Change Profile to unavailable profile");
            }
            break;
        case KEY_ACTION_LOAD_COLOR_PRESET:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Load Color Preset \"%@\"", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: load color preset"), _parameter];
            break;
        case KEY_ACTION_SEND_C_H_BACKSPACE:
            actionString = NSLocalizedStringFromTableInBundle(@"Send ^H Backspace", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Send ^H Backspace");
            break;
        case KEY_ACTION_SEND_C_QM_BACKSPACE:
            actionString = NSLocalizedStringFromTableInBundle(@"Send ^? Backspace", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Send ^? Backspace");
            break;
        case KEY_ACTION_IGNORE:
            actionString = NSLocalizedStringFromTableInBundle(@"Ignore", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Ignore");
            break;
        case KEY_ACTION_BYPASS:
            actionString = NSLocalizedStringFromTableInBundle(@"Bypass Terminal", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Bypass Terminal");
            break;
        case KEY_ACTION_IR_FORWARD:
            actionString = NSLocalizedStringFromTableInBundle(@"Unsupported Command", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Unsupported Command");
            break;
        case KEY_ACTION_IR_BACKWARD:
            actionString = NSLocalizedStringFromTableInBundle(@"Start Instant Replay", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Start Instant Replay");
            break;
        case KEY_ACTION_SELECT_PANE_LEFT:
            actionString = NSLocalizedStringFromTableInBundle(@"Select Split Pane on Left", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Select Split Pane on Left");
            break;
        case KEY_ACTION_SELECT_PANE_RIGHT:
            actionString = NSLocalizedStringFromTableInBundle(@"Select Split Pane on Right", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Select Split Pane on Right");
            break;
        case KEY_ACTION_SELECT_PANE_ABOVE:
            actionString = NSLocalizedStringFromTableInBundle(@"Select Split Pane Above", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Select Split Pane Above");
            break;
        case KEY_ACTION_SELECT_PANE_BELOW:
            actionString = NSLocalizedStringFromTableInBundle(@"Select Split Pane Below", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Select Split Pane Below");
            break;
        case KEY_ACTION_DO_NOT_REMAP_MODIFIERS:
            actionString = NSLocalizedStringFromTableInBundle(@"Do Not Remap Modifiers", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Do Not Remap Modifiers");
            break;
        case KEY_ACTION_REMAP_LOCALLY:
            actionString = NSLocalizedStringFromTableInBundle(@"Remap Modifiers in iTerm2 Only", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Remap Modifiers in iTerm2 Only");
            break;
        case KEY_ACTION_TOGGLE_FULLSCREEN:
            actionString = NSLocalizedStringFromTableInBundle(@"Toggle Fullscreen", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Toggle Fullscreen");
            break;
        case KEY_ACTION_TOGGLE_HOTKEY_WINDOW_PINNING:
            actionString = NSLocalizedStringFromTableInBundle(@"Toggle Pin Hotkey Window", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Toggle Pin Hotkey Window");
            break;
        case KEY_ACTION_UNDO:
            actionString = NSLocalizedStringFromTableInBundle(@"Undo", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Undo");
            break;
        case KEY_ACTION_FIND_REGEX:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Find Regex “%@”", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: find regex"), _parameter];
            break;
        case KEY_FIND_AGAIN_DOWN:
            actionString = NSLocalizedStringFromTableInBundle(@"Find Again Down", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Find Again Down");
            break;
        case KEY_FIND_AGAIN_UP:
            actionString = NSLocalizedStringFromTableInBundle(@"Find Again Up", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Find Again Up");
            break;
        case KEY_ACTION_PASTE_SPECIAL_FROM_SELECTION: {
            NSString *pasteDetails =
                [iTermPasteSpecialViewController descriptionForCodedSettings:_parameter];
            if (pasteDetails.length) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Paste from Selection: %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: paste from selection"), pasteDetails];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Paste from Selection", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Paste from Selection");
            }
            break;
        }
        case KEY_ACTION_PASTE_SPECIAL: {
            NSString *pasteDetails =
                [iTermPasteSpecialViewController descriptionForCodedSettings:_parameter];
            if (pasteDetails.length) {
                actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Paste: %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: paste"), pasteDetails];
            } else {
                actionString = NSLocalizedStringFromTableInBundle(@"Paste", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Paste");
            }
            break;
        }
        case KEY_ACTION_MOVE_END_OF_SELECTION_LEFT:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Move End of Selection Left %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: move end of selection left"),
                            [self.class stringForSelectionMovementUnit:_parameter.integerValue]];
            break;
        case KEY_ACTION_MOVE_END_OF_SELECTION_RIGHT:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Move End of Selection Right %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: move end of selection right"),
                            [self.class stringForSelectionMovementUnit:_parameter.integerValue]];
            break;
        case KEY_ACTION_MOVE_START_OF_SELECTION_LEFT:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Move Start of Selection Left %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: move start of selection left"),
                            [self.class stringForSelectionMovementUnit:_parameter.integerValue]];
            break;
        case KEY_ACTION_MOVE_START_OF_SELECTION_RIGHT:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Move Start of Selection Right %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: move start of selection right"),
                            [self.class stringForSelectionMovementUnit:_parameter.integerValue]];
            break;

        case KEY_ACTION_DECREASE_HEIGHT:
            actionString = NSLocalizedStringFromTableInBundle(@"Decrease Height", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Decrease Height");
            break;
        case KEY_ACTION_INCREASE_HEIGHT:
            actionString = NSLocalizedStringFromTableInBundle(@"Increase Height", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Increase Height");
            break;

        case KEY_ACTION_DECREASE_WIDTH:
            actionString = NSLocalizedStringFromTableInBundle(@"Decrease Width", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Decrease Width");
            break;
        case KEY_ACTION_INCREASE_WIDTH:
            actionString = NSLocalizedStringFromTableInBundle(@"Increase Width", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Increase Width");
            break;

        case KEY_ACTION_SWAP_PANE_LEFT:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap With Split Pane on Left", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap With Split Pane on Left");
            break;
        case KEY_ACTION_SWAP_PANE_RIGHT:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap With Split Pane on Right", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap With Split Pane on Right");
            break;
        case KEY_ACTION_SWAP_PANE_ABOVE:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap With Split Pane Above", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap With Split Pane Above");
            break;
        case KEY_ACTION_SWAP_PANE_BELOW:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap With Split Pane Below", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap With Split Pane Below");
            break;
        case KEY_ACTION_TOGGLE_MOUSE_REPORTING:
            actionString = NSLocalizedStringFromTableInBundle(@"Toggle Mouse Reporting", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Toggle Mouse Reporting");
            break;
        case KEY_ACTION_INVOKE_SCRIPT_FUNCTION:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Call %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: call script function"), _parameter];
            break;
        case KEY_ACTION_DUPLICATE_TAB:
            actionString = NSLocalizedStringFromTableInBundle(@"Duplicate Tab", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Duplicate Tab");
            break;
        case KEY_ACTION_SEQUENCE: {
            NSArray<NSString *> *names = [[_parameter keyBindingActionsFromSequenceParameter] mapWithBlock:^id _Nullable(iTermKeyBindingAction * _Nonnull action) {
                return [action displayName];
            }];
            return [names componentsJoinedByString:NSLocalizedStringFromTableInBundle(@", then ", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: sequence join")];
        }
        default:
            actionString = [NSString stringWithFormat: @"%@ %d", NSLocalizedStringFromTableInBundle(@"Unknown Action ID", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: unknown action"), _keyAction];
            break;
        case KEY_ACTION_MOVE_TO_SPLIT_PANE:
            actionString = NSLocalizedStringFromTableInBundle(@"Move to Split Pane", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Move to Split Pane");
            break;
        case KEY_ACTION_SWAP_WITH_NEXT_PANE:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap with Next Pane", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap with Next Pane");
            break;
        case KEY_ACTION_SWAP_WITH_PREVIOUS_PANE:
            actionString = NSLocalizedStringFromTableInBundle(@"Swap with Previous Pane", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Swap with Previous Pane");
            break;
        case KEY_ACTION_COPY_OR_SEND:
            actionString = NSLocalizedStringFromTableInBundle(@"Copy Selection or Send ^C", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Copy Selection or Send ^C");
            break;
        case KEY_ACTION_PASTE_OR_SEND:
            actionString = NSLocalizedStringFromTableInBundle(@"Paste or Send ^V", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Paste or Send ^V");
            break;
        case KEY_ACTION_ALERT_ON_NEXT_MARK:
            actionString = NSLocalizedStringFromTableInBundle(@"Alert on Next Mark", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: Alert on Next Mark");
            break;
        case KEY_ACTION_COPY_INTERPOLATED_STRING:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Copy Interpolated String “%@”", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: copy interpolated string"), _parameter];
            break;
        case KEY_ACTION_COPY_MODE:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Copy mode: %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: copy mode"), _parameter];
            break;
        case KEY_ACTION_TOGGLE_SETTING:
            actionString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Toggle %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding action: toggle setting"), self.toggleSettingLabel];
            break;
    }

    switch (self.applyMode) {
        case iTermActionApplyModeCurrentSession:
            return actionString;
        case iTermActionApplyModeAllSessions:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"In all sessions, %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding apply mode: all sessions"), actionString];
        case iTermActionApplyModeUnfocusedSessions:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"In unfocused sessions, %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding apply mode: unfocused sessions"), actionString];
        case iTermActionApplyModeAllInWindow:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"In all sessions in the window, %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding apply mode: all in window"), actionString];
        case iTermActionApplyModeAllInTab:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"In all sessions in the tab, %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding apply mode: all in tab"), actionString];
        case iTermActionApplyModeBroadcasting:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"In all broadcasted-to sessions, %@", @"Keyboard", [NSBundle bundleForClass:[self class]], @"Key binding apply mode: broadcasting"), actionString];
    }
    return actionString;
}

- (BOOL)sendsText {
    switch (self.keyAction) {
        case KEY_ACTION_ESCAPE_SEQUENCE:
        case KEY_ACTION_HEX_CODE:
        case KEY_ACTION_TEXT:
        case KEY_ACTION_SEND_SNIPPET:
        case KEY_ACTION_COMPOSE:
        case KEY_ACTION_SEND_TMUX_COMMAND:
        case KEY_ACTION_VIM_TEXT:
        case KEY_ACTION_VIM_TEXT_NO_BROADCAST:
        case KEY_ACTION_RUN_COPROCESS:
        case KEY_ACTION_SEND_C_H_BACKSPACE:
        case KEY_ACTION_SEND_C_QM_BACKSPACE:
        case KEY_ACTION_PASTE_SPECIAL:
        case KEY_ACTION_PASTE_SPECIAL_FROM_SELECTION:
        case KEY_ACTION_COPY_OR_SEND:
        case KEY_ACTION_PASTE_OR_SEND:
            return YES;
            
        case KEY_ACTION_IGNORE:
        case KEY_ACTION_BYPASS:
        case KEY_ACTION_INVALID:
        case KEY_ACTION_NEXT_SESSION:
        case KEY_ACTION_NEXT_WINDOW:
        case KEY_ACTION_PREVIOUS_SESSION:
        case KEY_ACTION_PREVIOUS_WINDOW:
        case KEY_ACTION_SCROLL_END:
        case KEY_ACTION_SCROLL_HOME:
        case KEY_ACTION_SCROLL_LINE_DOWN:
        case KEY_ACTION_SCROLL_LINE_UP:
        case KEY_ACTION_SCROLL_PAGE_DOWN:
        case KEY_ACTION_SCROLL_PAGE_UP:
        case KEY_ACTION_IR_FORWARD:
        case KEY_ACTION_IR_BACKWARD:
        case KEY_ACTION_SELECT_PANE_LEFT:
        case KEY_ACTION_SELECT_PANE_RIGHT:
        case KEY_ACTION_SELECT_PANE_ABOVE:
        case KEY_ACTION_SELECT_PANE_BELOW:
        case KEY_ACTION_DO_NOT_REMAP_MODIFIERS:
        case KEY_ACTION_TOGGLE_FULLSCREEN:
        case KEY_ACTION_REMAP_LOCALLY:
        case KEY_ACTION_SELECT_MENU_ITEM:
        case KEY_ACTION_NEW_WINDOW_WITH_PROFILE:
        case KEY_ACTION_NEW_TAB_WITH_PROFILE:
        case KEY_ACTION_SPLIT_HORIZONTALLY_WITH_PROFILE:
        case KEY_ACTION_SPLIT_VERTICALLY_WITH_PROFILE:
        case KEY_ACTION_NEXT_PANE:
        case KEY_ACTION_PREVIOUS_PANE:
        case KEY_ACTION_NEXT_MRU_TAB:
        case KEY_ACTION_MOVE_TAB_LEFT:
        case KEY_ACTION_MOVE_TAB_RIGHT:
        case KEY_ACTION_FIND_REGEX:
        case KEY_ACTION_SET_PROFILE:
        case KEY_ACTION_PREVIOUS_MRU_TAB:
        case KEY_ACTION_LOAD_COLOR_PRESET:
        case KEY_ACTION_TOGGLE_HOTKEY_WINDOW_PINNING:
        case KEY_ACTION_UNDO:
        case KEY_ACTION_MOVE_END_OF_SELECTION_LEFT:
        case KEY_ACTION_MOVE_END_OF_SELECTION_RIGHT:
        case KEY_ACTION_MOVE_START_OF_SELECTION_LEFT:
        case KEY_ACTION_MOVE_START_OF_SELECTION_RIGHT:
        case KEY_ACTION_DECREASE_HEIGHT:
        case KEY_ACTION_INCREASE_HEIGHT:
        case KEY_ACTION_DECREASE_WIDTH:
        case KEY_ACTION_INCREASE_WIDTH:
        case KEY_ACTION_SWAP_PANE_LEFT:
        case KEY_ACTION_SWAP_PANE_RIGHT:
        case KEY_ACTION_SWAP_PANE_ABOVE:
        case KEY_ACTION_SWAP_PANE_BELOW:
        case KEY_FIND_AGAIN_DOWN:
        case KEY_FIND_AGAIN_UP:
        case KEY_ACTION_TOGGLE_MOUSE_REPORTING:
        case KEY_ACTION_INVOKE_SCRIPT_FUNCTION:
        case KEY_ACTION_DUPLICATE_TAB:
        case KEY_ACTION_MOVE_TO_SPLIT_PANE:
        case KEY_ACTION_SWAP_WITH_NEXT_PANE:
        case KEY_ACTION_SWAP_WITH_PREVIOUS_PANE:
        case KEY_ACTION_ALERT_ON_NEXT_MARK:
        case KEY_ACTION_COPY_INTERPOLATED_STRING:
        case KEY_ACTION_COPY_MODE:
        case KEY_ACTION_TOGGLE_SETTING:
            break;

        case KEY_ACTION_SEQUENCE:
            return [[self.parameter keyBindingActionsFromSequenceParameter] anyWithBlock:^BOOL(iTermKeyBindingAction *action) {
                return action.sendsText;
            }];
    }
    return NO;
}

- (BOOL)isActionable {
    switch (self.keyAction) {
        case KEY_ACTION_DO_NOT_REMAP_MODIFIERS:
        case KEY_ACTION_REMAP_LOCALLY:
        case KEY_ACTION_BYPASS:
            return NO;

        case KEY_ACTION_IGNORE:
        case KEY_ACTION_ESCAPE_SEQUENCE:
        case KEY_ACTION_HEX_CODE:
        case KEY_ACTION_TEXT:
        case KEY_ACTION_VIM_TEXT:
        case KEY_ACTION_VIM_TEXT_NO_BROADCAST:
        case KEY_ACTION_SEND_SNIPPET:
        case KEY_ACTION_COMPOSE:
        case KEY_ACTION_SEND_TMUX_COMMAND:
        case KEY_ACTION_RUN_COPROCESS:
        case KEY_ACTION_SEND_C_H_BACKSPACE:
        case KEY_ACTION_SEND_C_QM_BACKSPACE:
        case KEY_ACTION_INVALID:
        case KEY_ACTION_NEXT_SESSION:
        case KEY_ACTION_NEXT_WINDOW:
        case KEY_ACTION_PREVIOUS_SESSION:
        case KEY_ACTION_PREVIOUS_WINDOW:
        case KEY_ACTION_SCROLL_END:
        case KEY_ACTION_SCROLL_HOME:
        case KEY_ACTION_SCROLL_LINE_DOWN:
        case KEY_ACTION_SCROLL_LINE_UP:
        case KEY_ACTION_SCROLL_PAGE_DOWN:
        case KEY_ACTION_SCROLL_PAGE_UP:
        case KEY_ACTION_IR_FORWARD:
        case KEY_ACTION_IR_BACKWARD:
        case KEY_ACTION_SELECT_PANE_LEFT:
        case KEY_ACTION_SELECT_PANE_RIGHT:
        case KEY_ACTION_SELECT_PANE_ABOVE:
        case KEY_ACTION_SELECT_PANE_BELOW:
        case KEY_ACTION_TOGGLE_FULLSCREEN:
        case KEY_ACTION_SELECT_MENU_ITEM:
        case KEY_ACTION_NEW_WINDOW_WITH_PROFILE:
        case KEY_ACTION_NEW_TAB_WITH_PROFILE:
        case KEY_ACTION_SPLIT_HORIZONTALLY_WITH_PROFILE:
        case KEY_ACTION_SPLIT_VERTICALLY_WITH_PROFILE:
        case KEY_ACTION_NEXT_PANE:
        case KEY_ACTION_PREVIOUS_PANE:
        case KEY_ACTION_NEXT_MRU_TAB:
        case KEY_ACTION_MOVE_TAB_LEFT:
        case KEY_ACTION_MOVE_TAB_RIGHT:
        case KEY_ACTION_FIND_REGEX:
        case KEY_ACTION_SET_PROFILE:
        case KEY_ACTION_PREVIOUS_MRU_TAB:
        case KEY_ACTION_LOAD_COLOR_PRESET:
        case KEY_ACTION_PASTE_SPECIAL:
        case KEY_ACTION_PASTE_SPECIAL_FROM_SELECTION:
        case KEY_ACTION_TOGGLE_HOTKEY_WINDOW_PINNING:
        case KEY_ACTION_UNDO:
        case KEY_ACTION_MOVE_END_OF_SELECTION_LEFT:
        case KEY_ACTION_MOVE_END_OF_SELECTION_RIGHT:
        case KEY_ACTION_MOVE_START_OF_SELECTION_LEFT:
        case KEY_ACTION_MOVE_START_OF_SELECTION_RIGHT:
        case KEY_ACTION_DECREASE_HEIGHT:
        case KEY_ACTION_INCREASE_HEIGHT:
        case KEY_ACTION_DECREASE_WIDTH:
        case KEY_ACTION_INCREASE_WIDTH:
        case KEY_ACTION_SWAP_PANE_LEFT:
        case KEY_ACTION_SWAP_PANE_RIGHT:
        case KEY_ACTION_SWAP_PANE_ABOVE:
        case KEY_ACTION_SWAP_PANE_BELOW:
        case KEY_FIND_AGAIN_DOWN:
        case KEY_FIND_AGAIN_UP:
        case KEY_ACTION_TOGGLE_MOUSE_REPORTING:
        case KEY_ACTION_INVOKE_SCRIPT_FUNCTION:
        case KEY_ACTION_DUPLICATE_TAB:
        case KEY_ACTION_MOVE_TO_SPLIT_PANE:
        case KEY_ACTION_SWAP_WITH_NEXT_PANE:
        case KEY_ACTION_SWAP_WITH_PREVIOUS_PANE:
        case KEY_ACTION_COPY_OR_SEND:
        case KEY_ACTION_PASTE_OR_SEND:
        case KEY_ACTION_ALERT_ON_NEXT_MARK:
        case KEY_ACTION_COPY_INTERPOLATED_STRING:
        case KEY_ACTION_COPY_MODE:
        case KEY_ACTION_TOGGLE_SETTING:
            break;

        case KEY_ACTION_SEQUENCE:
            return [[self.parameter keyBindingActionsFromSequenceParameter] anyWithBlock:^BOOL(iTermKeyBindingAction *action) {
                return action.isActionable;
            }];
    }
    return YES;
}

@end

@implementation NSString(iTermKeyBindingAction)

+ (instancetype)parameterForKeyBindingActionSequence:(NSArray<iTermKeyBindingAction *> *)actions {
    NSArray<NSDictionary *> *dicts = [actions mapWithBlock:^id _Nullable(iTermKeyBindingAction * _Nonnull action) {
        return action.dictionaryValue;
    }];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dicts options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

- (NSArray<iTermKeyBindingAction *> *)keyBindingActionsFromSequenceParameter {
    NSArray<NSDictionary *> *dicts = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (![dicts isKindOfClass:[NSArray class]]) {
        return @[];
    }
    return [dicts mapWithBlock:^id _Nullable(NSDictionary * _Nonnull dict) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        return [iTermKeyBindingAction withDictionary:dict];
    }];
}

@end

@implementation iTermKeyBindingAction(ParameterHelper)

- (NSDictionary *)toggleSettingDict {
    NSData *data = [self.parameter dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    NSDictionary *dict = [NSDictionary castFrom:[NSJSONSerialization JSONObjectWithData:data
                                                                                options:0
                                                                                  error:nil]];
    if (!dict) {
        return nil;
    }
    return dict;
}

- (NSString *)toggleSettingKey {
    return [NSString castFrom:self.toggleSettingDict[@"key"]];
}

- (NSString *)toggleSettingLabel {
    return [NSString castFrom:self.toggleSettingDict[@"label"]];
}

- (BOOL)toggleSettingIsProfile {
    return [[NSNumber castFrom:self.toggleSettingDict[@"isProfile"]] boolValue];
}

+ (NSString *)toggleSettingParameterForKey:(NSString *)key
                                 isProfile:(BOOL)isProfile
                                     label:(NSString *)label {
    NSDictionary *dict = @{ @"key": key,
                            @"isProfile": @(isProfile),
                            @"label": label };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    if (!data) {
        return @"";
    }
    return [data stringWithEncoding:NSUTF8StringEncoding] ?: @"";
}

@end
