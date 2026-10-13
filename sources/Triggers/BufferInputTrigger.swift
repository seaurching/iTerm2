//
//  BufferInputTrigger.swift
//  iTerm2
//
//  Created by George Nachman on 12/12/25.
//


@objc(iTermBufferInputTrigger)
class BufferInputTrigger: Trigger {
    private enum Tag: Int {
        case start = 0
        case stop = 1
    }

    @objc var shouldBuffer: Bool {
        switch Tag(rawValue: (self.param as? NSNumber)?.intValue ?? 0) {
        case .none, .start:
            return true
        case .stop:
            return false
        }
    }
    override var description: String {
        if shouldBuffer {
            return NSLocalizedString("Buffer Input", tableName: "Triggers", comment: "缓冲输入触发器描述：开始")
        } else {
            return NSLocalizedString("Stop Buffering Input", tableName: "Triggers", comment: "缓冲输入触发器描述：停止")
        }
    }

    override static var title: String {
        return NSLocalizedString("Buffer Input…", tableName: "Triggers", comment: "缓冲输入触发器标题")
    }

    override func takesParameter() -> Bool {
        return true
    }

    // Requires a live session to buffer input
    override var allowedMatchTypes: Set<NSNumber> {
        var set: Set<NSNumber> = [NSNumber(value: iTermTriggerMatchType.regex.rawValue)]
        set.formUnion(EventTriggerMatchTypeHelper.allEventTypesExceptSessionEndedSet)
        return set
    }

    override func paramIsPopupButton() -> Bool {
        true
    }

    override var isIdempotent: Bool {
        return true
    }

    override func index(for object: Any?) -> Int {
        return objectsSortedByValue(inDict: menuItemsForPoupupButton()!).firstIndex { obj in
            (obj as? NSNumber) == (object as? NSNumber)
        } ?? -1
    }

    override func object(at index: Int) -> Any? {
        let sorted = objectsSortedByValue(inDict: menuItemsForPoupupButton()!)
        return sorted[index]
    }

    override func menuItemsForPoupupButton() -> [AnyHashable : Any]? {
        [ NSNumber(value: Tag.start.rawValue): NSLocalizedString("Start Buffering Input", tableName: "Triggers", comment: "弹出菜单：开始缓冲输入"),
          NSNumber(value: Tag.stop.rawValue): NSLocalizedString("Stop Buffering Input", tableName: "Triggers", comment: "弹出菜单：停止缓冲输入") ]
    }

    override func performAction(withCapturedStrings strings: [String],
                                capturedRanges: UnsafePointer<NSRange>,
                                in session: iTermTriggerSession,
                                onString s: iTermStringLine,
                                atAbsoluteLineNumber lineNumber: Int64,
                                useInterpolation: Bool,
                                stop: UnsafeMutablePointer<ObjCBool>) -> Bool {
        session.triggerSetBufferInput(self, shouldBuffer: shouldBuffer)
        return false
    }

    override func paramAttributedString() -> NSAttributedString? {
        NSAttributedString(string: shouldBuffer ? NSLocalizedString("Start buffering", tableName: "Triggers", comment: "参数：开始缓冲") : NSLocalizedString("Stop buffering", tableName: "Triggers", comment: "参数：停止缓冲"),
                           attributes: regularAttributes())
    }
}
