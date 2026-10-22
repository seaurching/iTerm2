//
//  OrchestratorError.swift
//  iTerm2SharedARC
//

import Foundation

// Errors thrown by the orchestrator dispatcher. Caught at the
// dispatch entrypoint and converted to OrchestratorResult.error so
// the LLM never sees a Swift exception. it always gets a
// well-formed tool_result with a code/message it can reason about.
enum OrchestratorError: Error {
    case unknownTool(String)
    case unknownWorkgroup(String)
    case unknownSession(guid: String)
    case ambiguousWorkgroup(name: String, candidateIDs: [String])
    case permissionDenied
    case targetNoLongerExists(sessionGuid: String)
    case malformedArgs(reason: String)
    case timeout
    case unsupported(reason: String)
    case notImplemented(String)
    case safetyBlocked(reason: String)

    var code: String {
        switch self {
        case .unknownTool: return "unknown_tool"
        case .unknownWorkgroup: return "unknown_workgroup"
        case .unknownSession: return "unknown_session"
        case .ambiguousWorkgroup: return "ambiguous_workgroup"
        case .permissionDenied: return "permission_denied"
        case .targetNoLongerExists: return "target_no_longer_exists"
        case .malformedArgs: return "malformed_args"
        case .timeout: return "timeout"
        case .unsupported: return "unsupported"
        case .notImplemented: return "not_implemented"
        case .safetyBlocked: return "safety_blocked"
        }
    }

    var message: String {
        switch self {
        case .unknownTool(let name):
            return String(format: NSLocalizedString("No such tool: %@", tableName: "ClaudeCodeXC", comment: "未知工具错误；%@ 为工具名，保留原文"), name)
        case .unknownWorkgroup(let id):
            return String(format: NSLocalizedString("No active workgroup matches \u{201C}%@\u{201D}", tableName: "ClaudeCodeXC", comment: "未知工作组错误；%@ 为工作组名"), id)
        case .unknownSession(let guid):
            return String(format: NSLocalizedString("No active session has GUID %@. Copy a session_guid verbatim from the <workgroups> snapshot.", tableName: "ClaudeCodeXC", comment: "未知会话错误；%@ 为 GUID；session_guid 与 <workgroups> 为字段名/标记，保留原文"), guid)
        case .ambiguousWorkgroup(let name, let candidateIDs):
            return String(format: NSLocalizedString("Workgroup name \u{201C}%1$@\u{201D} matches %2$ld active workgroups; use the workgroup_id instead. Candidates: %3$@", tableName: "ClaudeCodeXC", comment: "工作组名歧义错误；workgroup_id 为字段名保留原文；%1$@ 为工作组名，%2$ld 为数量，%3$@ 为候选 ID 列表"), name, candidateIDs.count, candidateIDs.joined(separator: ", "))
        case .permissionDenied:
            return NSLocalizedString("User denied permission for this action.", tableName: "ClaudeCodeXC", comment: "用户拒绝了对该操作的许可。")
        case .targetNoLongerExists(let sessionGuid):
            return String(format: NSLocalizedString("Target session no longer exists: session_guid=%@", tableName: "ClaudeCodeXC", comment: "目标会话不存在错误；session_guid 为字段名保留原文；%@ 为 GUID"), sessionGuid)
        case .malformedArgs(let reason):
            return String(format: NSLocalizedString("Malformed arguments: %@", tableName: "ClaudeCodeXC", comment: "参数格式错误；%@ 为具体原因"), reason)
        case .timeout:
            return NSLocalizedString("The operation timed out.", tableName: "ClaudeCodeXC", comment: "操作超时。")
        case .unsupported(let reason):
            return String(format: NSLocalizedString("Unsupported: %@", tableName: "ClaudeCodeXC", comment: "不支持的操作；%@ 为具体原因"), reason)
        case .notImplemented(let detail):
            return String(format: NSLocalizedString("Not implemented yet: %@", tableName: "ClaudeCodeXC", comment: "尚未实现；%@ 为具体说明"), detail)
        case .safetyBlocked(let reason):
            return String(format: NSLocalizedString("This command was not run automatically: %@", tableName: "ClaudeCodeXC", comment: "安全拦截；%@ 为拦截原因"), reason)
        }
    }

    var asResult: OrchestratorResult {
        return .error(code: code, message: message)
    }
}
