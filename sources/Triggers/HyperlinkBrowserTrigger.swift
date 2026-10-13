//
//  HyperlinkBrowserTrigger.swift
//  iTerm2
//
//  Created by George Nachman on 8/3/25.
//

class HyperlinkBrowserTrigger: Trigger {
    override var description: String {
        String(format: NSLocalizedString("Make Hyperlink with URL “%@”", tableName: "Triggers", comment: "创建超链接触发器描述"), param as? String ?? NSLocalizedString("(nil)", tableName: "Triggers", comment: "超链接：无URL值"))
    }
    override static var title: String {
        NSLocalizedString("Make Hyperlink…", tableName: "Triggers", comment: "创建超链接触发器标题")
    }
    override func takesParameter() -> Bool {
        true
    }
    override var isIdempotent: Bool {
        true
    }
    override func triggerOptionalParameterPlaceholder(withInterpolation interpolation: Bool) -> String? {
        return triggerOptionalDefaultParameterValue(withInterpolation: interpolation)
    }
    override func triggerOptionalDefaultParameterValue(withInterpolation interpolation: Bool) -> String? {
        if interpolation {
            "https://\\(match0)"
        } else {
            "https://\\0"
        }
    }
    override var allowedMatchTypes: Set<NSNumber> {
        return Set([ NSNumber(value: iTermTriggerMatchType.pageContentRegex.rawValue )])
    }
    override var matchType: iTermTriggerMatchType {
        .pageContentRegex
    }
    override var isBrowserTrigger: Bool {
        true
    }
}

extension HyperlinkBrowserTrigger: BrowserTrigger {
    func performBrowserAction(matchID: String?,
                              urlCaptures: [String],
                              contentCaptures: [String]?,
                              in client: any BrowserTriggerClient) async -> [BrowserTriggerAction] {
        guard let matchID else {
            DLog("No match id")
            return []
        }
        let scheduler = client.scopeProvider.triggerCallbackScheduler()
        paramWithBackreferencesReplaced(withValues: urlCaptures + (contentCaptures ?? []),
                                        absLine: -1,
                                        scope: client.scopeProvider,
                                        useInterpolation: client.useInterpolation).then { message in
            scheduler.scheduleTriggerCallback {
                client.triggerDelegate?.browserTriggerMakeHyperlink(matchID: matchID,
                                                                    url: message as String)
            }
        }
        return []
    }
}
