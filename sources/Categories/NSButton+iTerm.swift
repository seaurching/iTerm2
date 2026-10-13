//
//  NSButton+iTerm.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 10/29/25.
//

import AppKit

@objc
extension NSButton {
    fileprivate static let hiddenFromActionsKey = { iTermMalloc(1) }()

    @objc
    var hiddenFromActions: Bool {
        get {
            if let obj = it_associatedObject(forKey: Self.hiddenFromActionsKey) as? NSNumber {
                return obj.boolValue
            } else {
                return false
            }
        }
        set {
            it_setAssociatedObject(NSNumber(value: newValue),
                                   forKey: Self.hiddenFromActionsKey)
        }
    }

    // The checkbox's localized title can be wider than the fixed-frame width
    // from the xib (sized for English). Grow the checkbox to fit and slide the
    // help button along, preserving the gap measured before any resizing and
    // clamping so everything stays inside the enclosing view. Any views to the
    // right of the help button (e.g. a warning label) slide by the same delta
    // so their gaps are preserved too. Only call this before the views get
    // repositioned (e.g. from awakeFromNib), since the gap is measured from
    // the current frames.
    @objc
    func it_fitBeforeHelpButton(_ helpButton: NSButton, trailingViews: [NSView]) {
        let helpGap = max(0, helpButton.frame.minX - frame.maxX)
        sizeToFit()
        var checkboxFrame = frame
        var helpFrame = helpButton.frame
        let trailingFrames = trailingViews.map { $0.frame }
        // Everything to the right of the checkbox: the help button plus any
        // trailing views, measured from the help button's left edge.
        let trailingExtent = trailingFrames.map { $0.maxX }.max()
            .map({ max(0, $0 - helpFrame.minX) }) ?? 0
        let maxWidth = (superview?.bounds.width ?? checkboxFrame.maxX)
            - checkboxFrame.minX - helpGap - helpFrame.width - trailingExtent
        checkboxFrame.size.width = min(checkboxFrame.width, max(0, maxWidth))
        frame = checkboxFrame
        let delta = (checkboxFrame.maxX + helpGap) - helpFrame.minX
        helpFrame.origin.x += delta
        helpButton.frame = helpFrame
        for (view, oldFrame) in zip(trailingViews, trailingFrames) {
            var newFrame = oldFrame
            newFrame.origin.x += delta
            view.frame = newFrame
        }
    }

    @objc
    func it_fitBeforeHelpButton(_ helpButton: NSButton) {
        it_fitBeforeHelpButton(helpButton, trailingViews: [])
    }
}
