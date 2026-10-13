//
//  PopoverHelpButton.swift
//  iTerm2
//
//  Created by George Nachman on 12/18/24.
//

import AppKit

@objc(iTermPopoverHelpButton)
@IBDesignable
class PopoverHelpButton: NSButton {
    @IBInspectable var helpText: String = ""

    @objc
    init(helpText: String) {
        self.helpText = helpText
        super.init(frame: .zero)
        bezelStyle = .helpButton
        setButtonType(.momentaryPushIn)
        isBordered = true
        target = self
        action = #selector(clicked(_:))
        title = ""
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(clicked(_:))
        title = ""
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc
    private func clicked(_ sender: Any?) {
    }

    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        // The NIB injects helpText as the English source string (userDefinedRuntimeAttributes
        // are not extracted into String Catalogs). Look it up in the Settings table so help
        // popovers localize; falls back to the input when no translation exists.
        let localized = NSLocalizedString(helpText,
                                          tableName: "Settings",
                                          bundle: Bundle(for: PopoverHelpButton.self),
                                          comment: "help popover text")
        it_showWarning(withMarkdown: localized)
        return super.sendAction(action, to: target)
    }
}
