//
//  iTermMetalUnavailableReason.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 12/15/21.
//

#import "iTermMetalUnavailableReason.h"
#import <Foundation/Foundation.h>

NSString *iTermMetalUnavailableReasonDescription(iTermMetalUnavailableReason reason) {
    switch (reason) {
        case iTermMetalUnavailableReasonNone:
            return nil;
        case iTermMetalUnavailableReasonNoGPU:
            return NSLocalizedStringFromTableInBundle(@"no usable GPU found on this machine.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: no GPU");
        case iTermMetalUnavailableReasonDisabled:
            return NSLocalizedStringFromTableInBundle(@"GPU Renderer is disabled in Settings > General.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: disabled in settings");
        case iTermMetalUnavailableReasonNotATerminal:
            return NSLocalizedStringFromTableInBundle(@"the current session is not a terminal.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: not a terminal");
        case iTermMetalUnavailableReasonLigatures:
            return NSLocalizedStringFromTableInBundle(@"ligatures are enabled. You can disable them in Settings > Profiles > Text > Use ligatures.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: ligatures enabled");
        case iTermMetalUnavailableReasonInitializing:
            return NSLocalizedStringFromTableInBundle(@"the GPU renderer is initializing. It should be ready soon.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: initializing");
        case iTermMetalUnavailableReasonInvalidSize:
            return NSLocalizedStringFromTableInBundle(@"the session is too large or too small.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: invalid size");
        case iTermMetalUnavailableReasonSessionInitializing:
            return NSLocalizedStringFromTableInBundle(@"the session is initializing.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: session initializing");
        case iTermMetalUnavailableReasonTransparency:
            return NSLocalizedStringFromTableInBundle(@"transparent windows are not supported. They can be disabled in Settings > Profiles > Window > Transparency.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: transparency not supported");
        case iTermMetalUnavailableReasonVerticalSpacing:
            return NSLocalizedStringFromTableInBundle(@"the font's vertical spacing set to less than 100%. You can change it in Settings > Profiles > Text > Change Font.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: vertical spacing");
        case iTermMetalUnavailableReasonMarginSize:
            return NSLocalizedStringFromTableInBundle(@"terminal window margins are too small. You can edit them in Settings > Advanced.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: margins too small");
        case iTermMetalUnavailableReasonAnnotations:
            return NSLocalizedStringFromTableInBundle(@"annotations or URL shortcuts are open.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: annotations open");
        case iTermMetalUnavailableReasonPortholes:
            return NSLocalizedStringFromTableInBundle(@"this session has natively rendered items.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: natively rendered items");
        case iTermMetalUnavailableReasonFindPanel:
            return NSLocalizedStringFromTableInBundle(@"the find panel is open.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: find panel open");
        case iTermMetalUnavailableReasonPasteIndicator:
            return NSLocalizedStringFromTableInBundle(@"the paste progress indicator is open.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: paste indicator open");
        case iTermMetalUnavailableReasonAnnouncement:
            return NSLocalizedStringFromTableInBundle(@"an announcement (yellow bar) is visible.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: announcement visible");
        case iTermMetalUnavailableReasonURLPreview:
            return NSLocalizedStringFromTableInBundle(@"a URL preview is visible.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: URL preview visible");
        case iTermMetalUnavailableReasonWindowResizing:
            return NSLocalizedStringFromTableInBundle(@"the window is being resized.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: window resizing");
        case iTermMetalUnavailableReasonDisconnectedFromPower:
            return NSLocalizedStringFromTableInBundle(@"the computer is not connected to power. You can enable GPU rendering while disconnected from power in Settings > General > Advanced GPU Settings.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: not on power");
        case iTermMetalUnavailableReasonIdle:
            return NSLocalizedStringFromTableInBundle(@"the session is idle. You can enable Metal while idle in Settings > Advanced.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: session idle");
        case iTermMetalUnavailableReasonTooManyPanesReason:
            return NSLocalizedStringFromTableInBundle(@"This tab has too many split panes", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: too many panes");
        case iTermMetalUnavailableReasonNoFocus:
            return NSLocalizedStringFromTableInBundle(@"the window does not have keyboard focus.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: no keyboard focus");
        case iTermMetalUnavailableReasonTabInactive:
            return NSLocalizedStringFromTableInBundle(@"this tab is not active.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: tab inactive");
        case iTermMetalUnavailableReasonTabBarTemporarilyVisible:
            return NSLocalizedStringFromTableInBundle(@"the tab bar is temporarily visible.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: tab bar visible");
        case iTermMetalUnavailableReasonScreensChanging:
            return NSLocalizedStringFromTableInBundle(@"the screen configuration has just changed.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: screen config changed");
        case iTermMetalUnavailableReasonContextAllocationFailure:
            return NSLocalizedStringFromTableInBundle(@"of a temporary failure to allocate a graphics context.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: context alloc failure");
        case iTermMetalUnavailableReasonTabDragInProgress:
            return NSLocalizedStringFromTableInBundle(@"a tab is being dragged.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: tab being dragged");
        case iTermMetalUnavailableReasonSessionHasNoWindow:
            return NSLocalizedStringFromTableInBundle(@"the current session has no window (this shouldn't happen).", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: no window");
        case iTermMetalUnavailableReasonDropTargetsVisible:
            return NSLocalizedStringFromTableInBundle(@"secure copy drop targets are visible.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: scp drop targets");
        case iTermMetalUnavailableReasonSwipingBetweenTabs:
            return NSLocalizedStringFromTableInBundle(@"swiping between tabs", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: swiping tabs");
        case iTermMetalUnavailableReasonSplitPaneBeingDragged:
            return NSLocalizedStringFromTableInBundle(@"a split pane is being dragged.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: split pane dragged");
        case iTermMetalUnavailableReasonWindowObscured:
            return NSLocalizedStringFromTableInBundle(@"the window is mostly under another window.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: window obscured");
        case iTermMetalUnavailableReasonLowerPowerMode:
            return NSLocalizedStringFromTableInBundle(@"macOS is in low power mode.", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: low power mode");
    }

    return NSLocalizedStringFromTableInBundle(@"of an internal error. Please file a bug report!", @"MetalRenderer", [NSBundle mainBundle], @"Metal unavailable: internal error");
}
