//
//  InjectTrigger.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 6/26/21.
//

import Foundation

@objc(iTermInjectTrigger)
class InjectTrigger: Trigger {
    override var description: String {
        return String(format: NSLocalizedString("Inject Data “%@”", tableName: "Triggers", comment: "注入数据触发器描述"), String(describing: self.param ?? ""))
    }

    override static var title: String {
        return NSLocalizedString("Inject Data…", tableName: "Triggers", comment: "注入数据触发器标题")
    }

    override func takesParameter() -> Bool {
        return true
    }

    // Requires a live session to inject data
    override var allowedMatchTypes: Set<NSNumber> {
        var set: Set<NSNumber> = [NSNumber(value: iTermTriggerMatchType.regex.rawValue)]
        set.formUnion(EventTriggerMatchTypeHelper.allEventTypesExceptSessionEndedSet)
        return set
    }

    override func triggerOptionalParameterPlaceholder(withInterpolation interpolation: Bool) -> String? {
        return NSLocalizedString("Use \\e for esc, \\a for ^G.", tableName: "Triggers", comment: "占位符：使用转义说明")
    }

    override func performAction(withCapturedStrings strings: [String],
                                capturedRanges: UnsafePointer<NSRange>,
                                in session: iTermTriggerSession,
                                onString s: iTermStringLine,
                                atAbsoluteLineNumber lineNumber: Int64,
                                useInterpolation: Bool,
                                stop: UnsafeMutablePointer<ObjCBool>) -> Bool {
        let scopeProvider = session.triggerSessionVariableScopeProvider(self)
        let scheduler = scopeProvider.triggerCallbackScheduler()
        paramWithBackreferencesReplaced(withValues: strings,
                                        absLine: lineNumber,
                                        scope: scopeProvider,
                                        useInterpolation: useInterpolation).then { message in
            if let data = (message as String).data(using: .utf8) {
                scheduler.scheduleTriggerCallback {
                    session.triggerSession(self, inject: data);
                }
            }
        }
        return false
    }
}
