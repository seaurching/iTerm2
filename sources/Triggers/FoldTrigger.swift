//
//  FoldTrigger.swift
//  iTerm2
//
//  Created by George Nachman on 12/31/24.
//

@objc(iTermFoldTrigger)
class FoldTrigger: Trigger {
    override var description: String {
        return String(format: NSLocalizedString("Fold to %@", tableName: "Triggers", comment: "折叠触发器描述"), String(describing: self.param ?? ""))
    }

    override static var title: String {
        return NSLocalizedString("Fold to Named Mark", tableName: "Triggers", comment: "折叠触发器标题")
    }

    override func takesParameter() -> Bool {
        return true
    }

    override var allowedMatchTypes: Set<NSNumber> {
        var set: Set<NSNumber> = [NSNumber(value: iTermTriggerMatchType.regex.rawValue)]
        set.formUnion(EventTriggerMatchTypeHelper.allEventTypesSet)
        return set
    }

    override func triggerOptionalParameterPlaceholder(withInterpolation interpolation: Bool) -> String? {
        return NSLocalizedString("Name of Mark", tableName: "Triggers", comment: "占位符：标记名称")
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
                                        useInterpolation: useInterpolation).then { [weak self] message in
            scheduler.scheduleTriggerCallback {
                if let self {
                    session.triggerSession(self,
                                           foldFromNamedMark: message as String,
                                           toAbsoluteLine: lineNumber)
                }
            }
        }
        return true
    }
}
