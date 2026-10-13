import AppKit
import Foundation

@objc(iTermArrangementTrustGate)
final class iTermArrangementTrustGate: NSObject {
    @objc(shouldOpenUntrustedArrangementAtPath:)
    static func shouldOpenUntrustedArrangement(atPath path: String) -> Bool {
        // Files the user created locally (no quarantine xattr) are treated as
        // trusted. Only prompt when the file was received from an untrusted
        // source — a browser download, AirDrop, a sandboxed app dispatching
        // via LaunchServices, etc.
        guard isQuarantined(path: path) else {
            return true
        }
        let summary: RiskSummary
        if let windows = NSArray(contentsOfFile: path) as? [[String: Any]] {
            summary = RiskAnalyzer.analyze(windows: windows)
        } else {
            summary = RiskSummary()
        }

        let filename = (path as NSString).lastPathComponent
        let heading = String(format: NSLocalizedString("Open the arrangement “%@”?", tableName: "iTermController", comment: "Alert heading: open untrusted arrangement"), filename)
        let body = buildBody(summary: summary)

        let selection = iTermWarning.show(withTitle: body,
                                          actions: ["Cancel", NSLocalizedString("Open", tableName: "iTermController", comment: "Alert button: open the arrangement")],
                                          accessory: nil,
                                          identifier: nil,
                                          silenceable: .kiTermWarningTypePersistent,
                                          heading: heading,
                                          window: nil)
        if selection == .kiTermWarningSelection1 {
            clearQuarantine(at: path)
            return true
        }
        return false
    }

    private static func buildBody(summary: RiskSummary) -> String {
        var parts: [String] = []
        parts.append(NSLocalizedString("Window arrangements embed session profiles, which can run commands, connect to remote hosts, and configure triggers or smart-selection actions that execute when the terminal sees matching output. Opening an arrangement from an untrusted source is equivalent to running a program they gave you.", tableName: "iTermController", comment: "Trust gate body: explanation of arrangement risks"))
        if !summary.findings.isEmpty {
            parts.append("")
            parts.append(NSLocalizedString("This arrangement contains:", tableName: "iTermController", comment: "Trust gate body: list header"))
            for finding in summary.findings {
                parts.append("  • " + finding)
            }
        }
        parts.append("")
        parts.append(NSLocalizedString("Open it only if you trust where it came from.", tableName: "iTermController", comment: "Trust gate body: trust warning"))
        return parts.joined(separator: "\n")
    }

    private static func isQuarantined(path: String) -> Bool {
        let url = NSURL(fileURLWithPath: path)
        var value: AnyObject?
        do {
            try url.getResourceValue(&value, forKey: .quarantinePropertiesKey)
        } catch {
            return false
        }
        return value != nil
    }

    private static func clearQuarantine(at path: String) {
        let url = NSURL(fileURLWithPath: path)
        do {
            try url.setResourceValue(nil, forKey: .quarantinePropertiesKey)
        } catch {
            RLog("Failed to clear quarantine on \(path): \(error)")
        }
    }
}

struct RiskSummary {
    var findings: [String] = []
}

enum RiskAnalyzer {
    static func analyze(windows: [[String: Any]]) -> RiskSummary {
        var sessionCount = 0
        var customCommandCount = 0
        var sshCount = 0
        var programCount = 0
        var initialTextCount = 0
        var triggerCount = 0
        var smartRuleCount = 0

        for window in windows {
            guard let tabs = window[TERMINAL_ARRANGEMENT_TABS] as? [[String: Any]] else { continue }
            for tab in tabs {
                guard let root = tab[TAB_ARRANGEMENT_ROOT] as? [String: Any] else { continue }
                walk(root) { session in
                    sessionCount += 1
                    if let program = session[SESSION_ARRANGEMENT_PROGRAM] as? [String: Any],
                       let type = program[kProgramType] as? String,
                       type == kProgramTypeCommand,
                       let command = program[kProgramCommand] as? String,
                       !command.isEmpty {
                        programCount += 1
                    }
                    if let bookmark = session[SESSION_ARRANGEMENT_BOOKMARK] as? [String: Any] {
                        analyze(bookmark: bookmark,
                                customCommandCount: &customCommandCount,
                                sshCount: &sshCount,
                                initialTextCount: &initialTextCount,
                                triggerCount: &triggerCount,
                                smartRuleCount: &smartRuleCount)
                    }
                }
            }
        }

        var findings: [String] = []
        if sessionCount > 0 {
            findings.append(plural(sessionCount, NSLocalizedString("embedded session profile", tableName: "iTermController", comment: "Trust gate finding: embedded session profile")))
        }
        let commandTotal = customCommandCount + programCount
        if commandTotal > 0 {
            findings.append(plural(commandTotal, NSLocalizedString("custom command", tableName: "iTermController", comment: "Trust gate finding: custom command")) + NSLocalizedString(" that will run when the arrangement opens", tableName: "iTermController", comment: "Trust gate finding suffix: custom command"))
        }
        if sshCount > 0 {
            findings.append(plural(sshCount, NSLocalizedString("SSH connection", tableName: "iTermController", comment: "Trust gate finding: SSH connection")) + NSLocalizedString(" that will be opened automatically", tableName: "iTermController", comment: "Trust gate finding suffix: SSH connection"))
        }
        if initialTextCount > 0 {
            findings.append(plural(initialTextCount, NSLocalizedString("session", tableName: "iTermController", comment: "Trust gate finding: session")) + NSLocalizedString(" with text that will be typed into the terminal on startup", tableName: "iTermController", comment: "Trust gate finding suffix: session initial text"))
        }
        if triggerCount > 0 {
            findings.append(plural(triggerCount, NSLocalizedString("trigger", tableName: "iTermController", comment: "Trust gate finding: trigger")) + NSLocalizedString(" that runs actions when matching output appears", tableName: "iTermController", comment: "Trust gate finding suffix: trigger"))
        }
        if smartRuleCount > 0 {
            findings.append(plural(smartRuleCount, NSLocalizedString("smart-selection rule", tableName: "iTermController", comment: "Trust gate finding: smart-selection rule")) + NSLocalizedString(" with custom actions", tableName: "iTermController", comment: "Trust gate finding suffix: smart-selection rule"))
        }
        return RiskSummary(findings: findings)
    }

    private static func analyze(bookmark: [String: Any],
                                customCommandCount: inout Int,
                                sshCount: inout Int,
                                initialTextCount: inout Int,
                                triggerCount: inout Int,
                                smartRuleCount: inout Int) {
        if let custom = bookmark[KEY_CUSTOM_COMMAND] as? String {
            switch custom {
            case kProfilePreferenceCommandTypeCustomValue:
                customCommandCount += 1
            case kProfilePreferenceCommandTypeSSHValue:
                sshCount += 1
            default:
                break
            }
        }
        if let initialText = bookmark[KEY_INITIAL_TEXT] as? String, !initialText.isEmpty {
            initialTextCount += 1
        }
        if let triggers = bookmark[KEY_TRIGGERS] as? [Any] {
            triggerCount += triggers.count
        }
        if let rules = bookmark[KEY_SMART_SELECTION_RULES] as? [[String: Any]] {
            for rule in rules {
                if let actions = rule[kActionsKey] as? [Any], !actions.isEmpty {
                    smartRuleCount += 1
                }
            }
        }
    }

    private static func walk(_ node: [String: Any], sessionHandler: ([String: Any]) -> Void) {
        guard let viewType = node[TAB_ARRANGEMENT_VIEW_TYPE] as? String else { return }
        switch viewType {
        case VIEW_TYPE_SESSIONVIEW:
            if let session = node[TAB_ARRANGEMENT_SESSION] as? [String: Any] {
                sessionHandler(session)
            }
        case VIEW_TYPE_SPLITTER:
            if let subviews = node[SUBVIEWS] as? [[String: Any]] {
                for subview in subviews {
                    walk(subview, sessionHandler: sessionHandler)
                }
            }
        default:
            break
        }
    }

    private static func plural(_ count: Int, _ noun: String) -> String {
        let fmt = (count == 1)
            ? NSLocalizedString("%d %@", tableName: "iTermController", comment: "Trust gate: count + noun (singular)")
            : NSLocalizedString("%d %@s", tableName: "iTermController", comment: "Trust gate: count + noun (plural)");
        return String(format: fmt, count, noun)
    }
}
