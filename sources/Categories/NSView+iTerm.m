//
//  NSView+iTerm.m
//  iTerm
//
//  Created by George Nachman on 3/15/14.
//
//

#import "NSView+iTerm.h"
#import "DebugLogging.h"
#import "iTerm2SharedARC-Swift.h"
#import "iTermApplication.h"
#import "iTermTextPopoverViewController.h"
#import "NSArray+iTerm.h"
#import "NSObject+iTerm.h"
#import "NSWindow+iTerm.h"

static NSInteger gTakingSnapshot;

NSString *CGAffineTransformDescription(CGAffineTransform tm) {
    return [NSString stringWithFormat:@"[%g %g 0; %g %g 0; %g %g 1]",
                                      tm.a,
                                      tm.b,
                                      tm.c,
                                      tm.d,
                                      tm.tx,
                                      tm.ty];
}


NSRect iTermRectCenteredHorizontallyWithinRect(NSRect frameToCenter, NSRect container) {
    CGFloat centerOfContainer = NSMidX(container);
    CGFloat centerOfFrame = NSMidX(frameToCenter);
    CGFloat diff = centerOfContainer - centerOfFrame;
    frameToCenter.origin.x += diff;
    return frameToCenter;
}

NSRect iTermRectCenteredVerticallyWithinRect(NSRect frameToCenter, NSRect container) {
    CGFloat centerOfContainer = NSMidY(container);
    CGFloat centerOfFrame = NSMidY(frameToCenter);
    CGFloat diff = centerOfContainer - centerOfFrame;
    frameToCenter.origin.y += diff;
    return frameToCenter;
}


@implementation NSView (iTerm)

+ (BOOL)iterm_takingSnapshot {
    return gTakingSnapshot > 0;
}

+ (NSView *)viewAtScreenCoordinate:(NSPoint)point {
    const NSRect mouseRect = {
        .origin = point,
        .size = NSZeroSize
    };
    NSArray<NSWindow *> *frontToBackWindows = [[iTermApplication sharedApplication] orderedWindowsPlusVisibleHotkeyPanels];
    for (NSWindow *window in frontToBackWindows) {
        if (!window.isOnActiveSpace) {
            continue;
        }
        if (!window.isVisible) {
            continue;
        }
        NSPoint pointInWindow = [window convertRectFromScreen:mouseRect].origin;
        if ([window isTerminalWindow]) {
            DLog(@"Consider window %@", window.title);
            NSView *view = [window.contentView hitTest:pointInWindow];
            if (view) {
                return view;
            } else {
                DLog(@"%@ failed hit test", window.title);
            }
        }
    }
    return nil;
}

- (NSImage *)snapshot {
    return [self snapshotOfRect:self.bounds];
}

- (NSImage *)snapshotOfRect:(NSRect)rect {
    gTakingSnapshot += 1;

    NSBitmapImageRep *rep = [self bitmapImageRepForCachingDisplayInRect:rect];
    [self cacheDisplayInRect:self.bounds toBitmapImageRep:rep];
    NSImage *image = [[NSImage alloc] initWithSize:rect.size];
    [image addRepresentation:rep];

    gTakingSnapshot -= 1;
    return image;
}

- (void)insertSubview:(NSView *)subview atIndex:(NSInteger)index {
    NSArray *subviews = [self subviews];
    if (subviews.count == 0) {
        [self addSubview:subview];
        return;
    }
    if (index == 0) {
        [self addSubview:subview positioned:NSWindowBelow relativeTo:subviews[0]];
    } else {
        [self addSubview:subview positioned:NSWindowAbove relativeTo:subviews[index - 1]];
    }
}

- (void)swapSubview:(NSView *)subview1 withSubview:(NSView *)subview2 {
    NSArray *subviews = [self subviews];
    NSUInteger index1 = [subviews indexOfObject:subview1];
    NSUInteger index2 = [subviews indexOfObject:subview2];
    assert(index1 != index2);
    assert(index1 != NSNotFound);
    assert(index2 != NSNotFound);

    NSRect frame1 = subview1.frame;
    NSRect frame2 = subview2.frame;

    NSView *filler1 = [[NSView alloc] initWithFrame:subview1.frame];
    NSView *filler2 = [[NSView alloc] initWithFrame:subview2.frame];

    [self replaceSubview:subview1 with:filler1];
    [self replaceSubview:subview2 with:filler2];

    subview1.frame = frame2;
    subview2.frame = frame1;

    [self replaceSubview:filler1 with:subview2];
    [self replaceSubview:filler2 with:subview1];
}

+ (iTermDelayedPerform *)animateWithDuration:(NSTimeInterval)duration
                                       delay:(NSTimeInterval)delay
                                  animations:(void (^)(void))animations
                                  completion:(void (^)(BOOL finished))completion {
    iTermDelayedPerform *delayedPerform = [[iTermDelayedPerform alloc] init];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       if (!delayedPerform.canceled) {
                           DLog(@"Run dp %@", delayedPerform);
                           [self animateWithDuration:duration
                                          animations:animations
                                          completion:^(BOOL finished) {
                                              delayedPerform.completed = YES;
                                              completion(finished);
                                          }];
                       } else {
                           completion(NO);
                       }
                   });
    return delayedPerform;
}

+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (NS_NOESCAPE ^)(void))animations
                 completion:(void (^)(BOOL finished))completion {
   NSAnimationContext *context = [NSAnimationContext currentContext];
   NSTimeInterval savedDuration = [context duration];
   if (duration > 0) {
       [context setDuration:duration];
   }
   animations();
   [context setDuration:savedDuration];

   if (completion) {
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
                          completion(YES);
                      });
   }
}

- (void)enumerateHierarchy:(void (NS_NOESCAPE ^)(NSView *))block {
    block(self);
    for (NSView *view in self.subviews) {
        [view enumerateHierarchy:block];
    }
}

- (CGFloat)retinaRound:(CGFloat)value {
    NSWindow *window = self.window;
    if (!window) {
        return round(value);
    }
    CGFloat scale = window.backingScaleFactor;
    if (!scale) {
        scale = [[NSScreen mainScreen] backingScaleFactor];
    }
    if (!scale) {
        scale = 1;
    }
    return round(scale * value) / scale;
}

- (CGFloat)retinaRoundUp:(CGFloat)value {
    NSWindow *window = self.window;
    if (!window) {
        return ceil(value);
    }
    CGFloat scale = window.backingScaleFactor;
    if (!scale) {
        scale = [[NSScreen mainScreen] backingScaleFactor];
    }
    if (!scale) {
        scale = 1;
    }
    return ceil(scale * value) / scale;
}

- (CGRect)retinaRoundRect:(CGRect)rect {
    NSRect result = NSMakeRect([self retinaRound:NSMinX(rect)],
                               [self retinaRound:NSMinY(rect)],
                               [self retinaRoundUp:NSWidth(rect)],
                               [self retinaRoundUp:NSHeight(rect)]);
    return result;
}

- (BOOL)containsDescendant:(NSView *)possibleDescendant {
    NSView *view = possibleDescendant;
    while (view) {
        if (view == self) {
            return YES;
        }
        view = view.superview;
    }
    return NO;
}

- (NSColor *)it_backgroundColorOfEnclosingTerminalIfBackgroundColorViewHidden {
    return [self.superview it_backgroundColorOfEnclosingTerminalIfBackgroundColorViewHidden];
}

- (void)it_showWarning:(NSString *)text {
    [self it_showWarning:text rect:self.bounds];
}

- (void)it_showWarning:(NSString *)text rect:(NSRect)rect {
    iTermTextPopoverViewController *popoverVC = [[iTermTextPopoverViewController alloc] initWithNibName:@"iTermTextPopoverViewController"
                                                                  bundle:[NSBundle bundleForClass:self.class]];
    popoverVC.popover.behavior = NSPopoverBehaviorTransient;
    [popoverVC view];
    popoverVC.textView.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    popoverVC.textView.drawsBackground = NO;
    [popoverVC appendString:text];
    [popoverVC sizeToFit];
    [popoverVC.view it_setAssociatedObject:@YES forKey:iTermDeclineFirstResponderAssociatedObjectKey];
    [popoverVC.popover showRelativeToRect:rect
                                    ofView:self
                             preferredEdge:NSRectEdgeMaxY];
    [self it_setAssociatedObject:popoverVC forKey:@"PopoverWarning"];
}

- (void)it_showInformativeMessageWithMarkdown:(NSString *)markdown {
    [self it_showWarningWithMarkdown:markdown];
}

- (void)it_showWarningWithMarkdown:(NSString *)markdown {
    NSAttributedString *attributedString = [NSAttributedString attributedStringWithMarkdown:markdown
                                                                                   font:[NSFont systemFontOfSize:[NSFont systemFontSize]]
                                                                         paragraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [self it_showWarningWithAttributedString:attributedString
                                        rect:self.bounds];
}

- (void)it_showWarningWithAttributedString:(NSAttributedString *)text rect:(NSRect)rect {
    iTermTextPopoverViewController *popoverVC = [[iTermTextPopoverViewController alloc] initWithNibName:@"iTermTextPopoverViewController"
                                                                  bundle:[NSBundle bundleForClass:self.class]];
    popoverVC.maxHeight = 500;
    popoverVC.popover.behavior = NSPopoverBehaviorTransient;
    [popoverVC view];
    popoverVC.textView.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    popoverVC.textView.drawsBackground = NO;
    [popoverVC appendAttributedString:text];
    [popoverVC sizeToFit];
    [popoverVC.view it_setAssociatedObject:@YES forKey:iTermDeclineFirstResponderAssociatedObjectKey];
    [popoverVC.popover showRelativeToRect:rect
                                    ofView:self
                             preferredEdge:NSRectEdgeMaxY];
    [self it_setAssociatedObject:popoverVC forKey:@"PopoverWarning"];
    [popoverVC.textView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)it_removeWarning {
    iTermTextPopoverViewController *vc = [self it_associatedObjectForKey:@"PopoverWarning"];
    if (!vc) {
        return;
    }
    [vc.popover close];
    [self it_setAssociatedObject:nil forKey:@"PopoverWarning"];
}

- (NSPoint)viewPointFromAccessibilityScreenPoint:(NSPoint)stupidScreenPoint {
    if (@available(macOS 15, *)) {
        const NSPoint windowPoint = [self.window convertPointFromScreen:stupidScreenPoint];
        const NSPoint viewPoint =  [self convertPoint:windowPoint fromView:nil];
        return viewPoint;
    }
    const CGFloat flippedY = NSMaxY([NSScreen mainScreen].frame) - stupidScreenPoint.y;
    const NSPoint regularScreenPoint = NSMakePoint(stupidScreenPoint.x, flippedY);
    const NSPoint windowPoint = [self.window convertPointFromScreen:regularScreenPoint];
    const NSPoint viewPoint = [self convertPoint:windowPoint fromView:nil];
    return viewPoint;
}

// My MTKView clone uses canDraw. I don't understand why the original code did so I'm not
// interested in changing it and adding weird edge cases. Eventually Apple will have to fix their
// own use of a deprecated API, at which point I can reverse MTKView and remove this.
- (BOOL)it_canDraw {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self canDraw];
#pragma clang diagnostic pop
}

- (iTermNonDefaultIndicator *)it_nonDefaultIndicator {
    return [[self subviews] objectPassingTest:^BOOL(__kindof NSView *view, NSUInteger index, BOOL *stop) {
        return [view isKindOfClass:[iTermNonDefaultIndicator class]];
    }];
}

- (void)setIt_showNonDefaultIndicator:(BOOL)shouldShow {
    NSView *ndv = [self it_nonDefaultIndicator];
    if (shouldShow && !ndv) {
        ndv = [[iTermNonDefaultIndicator alloc] init];
        [self addSubview:ndv];
    } else if (!shouldShow && ndv) {
        [ndv removeFromSuperview];
    }
}

- (BOOL)it_showNonDefaultIndicator {
    return [self it_nonDefaultIndicator] != nil;
}

#pragma mark - Localization layout adaptation

- (void)it_adaptInlineRowsForLocalization {
    NSString *language = [NSBundle mainBundle].preferredLocalizations.firstObject;
    if ([language isEqualToString:@"en"]) {
        return;
    }
    [self it_adaptInlineRowsOneLevel];
    // Rows can be nested in intermediate container views (e.g. group boxes inside a settings
    // tab), so recurse into non-leaf subviews to tighten every level.
    for (NSView *subview in self.subviews) {
        if ([subview isKindOfClass:[NSTextField class]] ||
            [subview isKindOfClass:[NSButton class]] ||
            [subview isKindOfClass:[NSPopUpButton class]] ||
            [subview isKindOfClass:[NSStepper class]]) {
            continue;
        }
        [subview it_adaptInlineRowsForLocalization];
    }
}

- (void)it_adaptInlineRowsOneLevel {
    const CGFloat kDesiredGap = 8;
    const CGFloat kMinimumExcessGap = 20;
    const CGFloat kRowCenterTolerance = 12;
    const CGFloat kFollowerMaxDistance = 24;

    NSMutableArray<NSView *> *views = [NSMutableArray array];
    for (NSView *view in self.subviews) {
        if (view.isHidden || view.frame.size.width >= 0.9 * self.frame.size.width) {
            // Skip hidden views and full-width background/enclosure views.
            continue;
        }
        [views addObject:view];
    }
    if (views.count < 2) {
        return;
    }

    // Controls sharing an x origin form a deliberate column; never move them.
    NSMutableDictionary<NSNumber *, NSMutableSet<NSView *> *> *viewsByX =
        [NSMutableDictionary dictionary];
    for (NSView *view in views) {
        if (![self it_isMovableControl:view]) {
            continue;
        }
        NSNumber *key = @(round(view.frame.origin.x));
        NSMutableSet<NSView *> *set = viewsByX[key];
        if (!set) {
            set = [NSMutableSet set];
            viewsByX[key] = set;
        }
        [set addObject:view];
    }
    NSMutableSet<NSView *> *columnControls = [NSMutableSet set];
    for (NSSet<NSView *> *set in viewsByX.allValues) {
        if (set.count >= 2) {
            [columnControls unionSet:set];
        }
    }

    // Group views into rows by vertical center.
    NSMutableArray<NSMutableArray<NSView *> *> *rows = [NSMutableArray array];
    for (NSView *view in [views sortedArrayUsingComparator:^NSComparisonResult(NSView *a, NSView *b) {
        CGFloat centerYA = NSMidY(a.frame);
        CGFloat centerYB = NSMidY(b.frame);
        return centerYA < centerYB ? NSOrderedAscending : (centerYA > centerYB ? NSOrderedDescending : NSOrderedSame);
    }]) {
        CGFloat centerY = NSMidY(view.frame);
        NSMutableArray<NSView *> *lastRow = rows.lastObject;
        if (lastRow && fabs(NSMidY(lastRow.firstObject.frame) - centerY) <= kRowCenterTolerance) {
            [lastRow addObject:view];
        } else {
            [rows addObject:[NSMutableArray arrayWithObject:view]];
        }
    }

    for (NSMutableArray<NSView *> *row in rows) {
        [row sortUsingComparator:^NSComparisonResult(NSView *a, NSView *b) {
            CGFloat xA = a.frame.origin.x;
            CGFloat xB = b.frame.origin.x;
            return xA < xB ? NSOrderedAscending : (xA > xB ? NSOrderedDescending : NSOrderedSame);
        }];
        // cursor is the right edge of the inline text run so far, or -1 when the previous view
        // anchors the layout (right-aligned label, custom view, ...). previousWasStaticText
        // records whether the cursor came from a static label, so caption labels don't pull
        // other labels toward themselves (controls are always allowed to move).
        CGFloat cursor = -1;
        BOOL previousWasStaticText = NO;
        CGFloat lastDelta = 0;
        CGFloat previousOriginalRightEdge = 0;
        for (NSView *view in row) {
            NSRect frame = view.frame;
            BOOL wasRightAfterPrevious = previousOriginalRightEdge > 0 &&
                frame.origin.x - previousOriginalRightEdge < kFollowerMaxDistance;
            previousOriginalRightEdge = NSMaxX(frame);

            if (lastDelta != 0 && wasRightAfterPrevious && [self it_isFollowerControl:view]) {
                frame.origin.x += lastDelta;
                view.frame = frame;
                continue;
            }
            lastDelta = 0;

            NSTextField *textField = [view isKindOfClass:[NSTextField class]] ? (NSTextField *)view : nil;
            BOOL isRightAlignedLabel = textField && !textField.isEditable &&
                textField.alignment == NSTextAlignmentRight;
            BOOL isCheckbox = [view isKindOfClass:[NSButton class]] &&
                [self it_isCheckboxOrRadioButton:(NSButton *)view];
            BOOL isSmallButton = [view isKindOfClass:[NSButton class]] && !isCheckbox &&
                frame.size.width < 40;
            if (isRightAlignedLabel || (isSmallButton && cursor < 0)) {
                // Right-aligned labels and leading small buttons (e.g. help buttons) anchor the
                // layout.
                cursor = -1;
                continue;
            }
            if (!textField && ![view isKindOfClass:[NSPopUpButton class]] &&
                ![view isKindOfClass:[NSButton class]]) {
                // Custom views (sliders, color wells, ...) anchor the layout.
                cursor = -1;
                continue;
            }

            BOOL isStaticText = textField && !textField.isEditable;
            CGFloat newX = frame.origin.x;
            if (cursor >= 0 && !(isStaticText && previousWasStaticText) &&
                ![columnControls containsObject:view]) {
                CGFloat desiredX = cursor + kDesiredGap;
                if (frame.origin.x - desiredX >= kMinimumExcessGap) {
                    newX = desiredX;
                }
            }
            lastDelta = newX - frame.origin.x;
            if (lastDelta != 0) {
                frame.origin.x = newX;
                view.frame = frame;
            }
            CGFloat advance = frame.size.width;
            if (isStaticText) {
                advance = [self it_renderedTextWidth:textField];
            } else if (isCheckbox) {
                advance = [self it_renderedTextWidthOfButton:(NSButton *)view];
            }
            cursor = newX + advance;
            previousWasStaticText = isStaticText;
        }

        // A small help button to the left of a right-aligned label was positioned next to the
        // English text. Shift it right to hug the localized text's leading edge. Only adjacent
        // pairs qualify; unrelated buttons further left stay where they are.
        for (NSUInteger i = 0; i + 1 < row.count; i++) {
            NSView *button = row[i];
            NSView *label = row[i + 1];
            if (![button isKindOfClass:[NSButton class]] ||
                [self it_isCheckboxOrRadioButton:(NSButton *)button] ||
                [columnControls containsObject:button]) {
                continue;
            }
            if (![label isKindOfClass:[NSTextField class]] ||
                ((NSTextField *)label).alignment != NSTextAlignmentRight) {
                continue;
            }
            if (label.frame.origin.x - NSMaxX(button.frame) >= kFollowerMaxDistance) {
                continue;
            }
            NSTextField *labelField = (NSTextField *)label;
            CGFloat textStart = NSMaxX(labelField.frame) - [self it_renderedTextWidth:labelField];
            NSRect frame = button.frame;
            CGFloat desiredX = textStart - frame.size.width - kDesiredGap;
            if (desiredX - frame.origin.x >= kMinimumExcessGap) {
                frame.origin.x = desiredX;
                button.frame = frame;
            }
        }
    }
}

// Kinds of views that participate in column detection. These are the views whose x position may
// be adjusted.
- (BOOL)it_isMovableControl:(NSView *)view {
    if ([view isKindOfClass:[NSPopUpButton class]] || [view isKindOfClass:[NSButton class]]) {
        return YES;
    }
    if (![view isKindOfClass:[NSTextField class]]) {
        return NO;
    }
    NSTextField *textField = (NSTextField *)view;
    return textField.isEditable || textField.alignment != NSTextAlignmentRight;
}

- (BOOL)it_isCheckboxOrRadioButton:(NSButton *)button {
    // NSButtonCell.type is declared as NSCellType but the switch/radio values come from
    // NSButtonType.
    NSInteger type = [(NSButtonCell *)button.cell type];
    return type == NSButtonTypeSwitch || type == NSButtonTypeRadio;
}

// Small controls that sit immediately to the right of another control and belong to it, e.g. the
// stepper paired with an input field. They move by the same delta as the control they follow.
- (BOOL)it_isFollowerControl:(NSView *)view {
    if ([view isKindOfClass:[NSStepper class]]) {
        return YES;
    }
    return ![view isKindOfClass:[NSControl class]] && view.frame.size.width < 40;
}

- (CGFloat)it_renderedTextWidth:(NSTextField *)textField {
    if (textField.stringValue.length == 0) {
        return 0;
    }
    CGFloat width = [textField.cell cellSize].width;
    return width > 0 ? width : textField.frame.size.width;
}

- (CGFloat)it_renderedTextWidthOfButton:(NSButton *)button {
    if (button.title.length == 0) {
        return 0;
    }
    CGFloat width = [button.cell cellSize].width;
    return width > 0 ? width : button.frame.size.width;
}

@end

