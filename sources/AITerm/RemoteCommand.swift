//
//  RemoteCommand.swift
//  iTerm2
//
//  Created by George Nachman on 8/18/25.
//
//  NOTE: This file is also compiled into the iTerm2 Companion iOS app. Keep it
//  platform-neutral (Foundation only); Mac-only code (safety checks,
//  preferences) lives in RemoteCommand+Mac.swift.
//

import Foundation

// Generic wrapper around "a remote command the LLM wants to run".
// Two flavors:
//   - .classic: session-bound mode's typed RemoteCommand. Its Content
//     enum drives permission checks, safety classification, markdown
//     rendering, and the per-tool argument shape known at compile time.
//   - .external: any other stack's tool call (today: the orchestration
//     mode's tool surface). Args travel as opaque JSON. Renders via
//     the wrapper's markdownDescription.
//
// Codable shape:
//   - .classic encodes as a bare RemoteCommand (no envelope) so existing
//     chat databases round-trip without migration.
//   - .external encodes with a "kind": "external" discriminator on the
//     same object level; init(from:) checks for it and routes
//     accordingly, falling back to the legacy classic shape.
enum RemoteCommandPayload {
    case classic(RemoteCommand)
    case external(ExternalRemoteCommand)

    var llmMessage: LLM.Message {
        switch self {
        case .classic(let rc): rc.llmMessage
        case .external(let ext): ext.llmMessage
        }
    }

    // Tool name as the LLM sees it. For .classic this is the typed
    // Content's functionName; for .external it's whatever the
    // orchestrator's tool definition registered.
    var name: String {
        switch self {
        case .classic(let rc): rc.content.functionName
        case .external(let ext): ext.name
        }
    }

    var markdownDescription: String {
        switch self {
        case .classic(let rc): rc.markdownDescription
        case .external(let ext): ext.markdownDescription
        }
    }

    // Convenience for AITerm-side readers that need typed Content
    // access (safety check, permission category, etc.). Returns nil
    // for external payloads — readers that don't have a sensible
    // fallback should treat that as "skip this message".
    var classic: RemoteCommand? {
        if case .classic(let rc) = self { return rc }
        return nil
    }
}

struct ExternalRemoteCommand: Codable {
    // Discriminator. Always "external"; used by RemoteCommandPayload's
    // custom decoder to tell this shape apart from a bare RemoteCommand.
    var kind: String = "external"
    var llmMessage: LLM.Message
    var name: String
    var argsJSON: String
    var markdownDescription: String
}

extension RemoteCommandPayload: Codable {
    private enum DiscriminatorKey: String, CodingKey {
        case kind
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: DiscriminatorKey.self),
           let kind = try? container.decode(String.self, forKey: .kind),
           kind == "external" {
            let ext = try ExternalRemoteCommand(from: decoder)
            self = .external(ext)
            return
        }
        let rc = try RemoteCommand(from: decoder)
        self = .classic(rc)
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .classic(let rc):
            try rc.encode(to: encoder)
        case .external(let ext):
            try ext.encode(to: encoder)
        }
    }
}

struct RemoteCommand: Codable {
    struct IsAtPrompt: Codable {}
    struct ExecuteCommand: Codable { var command: String = "" }
    struct GetLastExitStatus: Codable {}

    struct GetCommandHistory: Codable { var limit: Int = 100 }
    struct GetLastCommand: Codable {}
    struct GetCommandBeforeCursor: Codable {}
    struct SearchCommandHistory: Codable { var query: String = "" }
    struct GetCommandOutput: Codable { var id: String = "" }
    struct GetScreenContents: Codable { var lines: Int = 0 }

    struct GetTerminalSize: Codable {}
    struct GetShellType: Codable {}
    struct DetectSSHSession: Codable {}
    struct GetRemoteHostname: Codable {}
    struct GetUserIdentity: Codable {}
    struct GetCurrentDirectory: Codable {}

    struct SetClipboard: Codable { var text: String = "" }
    struct InsertTextAtCursor: Codable { var text: String = "" }
    struct DeleteCurrentLine: Codable {}
    struct GetManPage: Codable { var cmd: String = "" }
    struct CreateFile: Codable {
        var filename: String=""
        var content: String=""
    }
    struct SearchBrowser: Codable { var query: String = "" }
    struct LoadURL: Codable { var url: String = "" }
    struct WebSearch: Codable { var query: String = "" }
    struct GetURL: Codable {}
    struct ReadWebPage: Codable {
        var startingLineNumber: Int = 0
        var numberOfLines: Int = 0
    }
    struct RestartSession: Codable {}
    enum Content: Codable, CaseIterable {
        static var allCases: [RemoteCommand.Content] {
            return [.isAtPrompt(IsAtPrompt()),
                    .executeCommand(ExecuteCommand()),
                    .getLastExitStatus(GetLastExitStatus()),
                    .getCommandHistory(GetCommandHistory()),
                    .getLastCommand(GetLastCommand()),
                    .getCommandBeforeCursor(GetCommandBeforeCursor()),
                    .searchCommandHistory(SearchCommandHistory()),
                    .getCommandOutput(GetCommandOutput()),
                    .getScreenContents(GetScreenContents()),
                    .getTerminalSize(GetTerminalSize()),
                    .getShellType(GetShellType()),
                    .detectSSHSession(DetectSSHSession()),
                    .getRemoteHostname(GetRemoteHostname()),
                    .getUserIdentity(GetUserIdentity()),
                    .getCurrentDirectory(GetCurrentDirectory()),
                    .setClipboard(SetClipboard()),
                    .insertTextAtCursor(InsertTextAtCursor()),
                    .deleteCurrentLine(DeleteCurrentLine()),
                    .getManPage(GetManPage()),
                    .createFile(CreateFile()),
                    .searchBrowser(SearchBrowser()),
                    .loadURL(LoadURL()),
                    .webSearch(WebSearch()),
                    .getURL(GetURL()),
                    .readWebPage(ReadWebPage()),
                    .restartSession(RestartSession())
            ]
        }

        case isAtPrompt(IsAtPrompt)
        case executeCommand(ExecuteCommand)
        case getLastExitStatus(GetLastExitStatus)
        case getCommandHistory(GetCommandHistory)
        case getLastCommand(GetLastCommand)
        case getCommandBeforeCursor(GetCommandBeforeCursor)
        case searchCommandHistory(SearchCommandHistory)
        case getCommandOutput(GetCommandOutput)
        case getScreenContents(GetScreenContents)
        case getTerminalSize(GetTerminalSize)
        case getShellType(GetShellType)
        case detectSSHSession(DetectSSHSession)
        case getRemoteHostname(GetRemoteHostname)
        case getUserIdentity(GetUserIdentity)
        case getCurrentDirectory(GetCurrentDirectory)
        case setClipboard(SetClipboard)
        case insertTextAtCursor(InsertTextAtCursor)
        case deleteCurrentLine(DeleteCurrentLine)
        case getManPage(GetManPage)
        case createFile(CreateFile)
        case searchBrowser(SearchBrowser)
        case loadURL(LoadURL)
        case webSearch(WebSearch)
        case getURL(GetURL)
        case readWebPage(ReadWebPage)
        case restartSession(RestartSession)
        // When adding a new command be sure to update allCases.

        enum PermissionCategory: String, Codable, CaseIterable {
            case checkTerminalState = "Check Terminal State"
            case runCommands = "Run Commands"
            case viewContents = "View Contents"
            case writeToClipboard = "Write to the Clipboard"
            case controlTerminal = "Control Terminal"
            case viewManpages = "View Manpages"
            case writeToFilesystem = "Write to the File System"
            case actInWebBrowser = "Act in Web Browser"

            // Persisted per-chat permissions encode the category by rawValue, and the
            // whole [Key: Permission] blob fails to decode if any single category is
            // unknown (losing every category's grant for that chat). "View History"
            // was renamed to "View Contents"; accept the legacy string so existing
            // grants survive the rename.
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try container.decode(String.self)
                if raw == "View History" {
                    self = .viewContents
                    return
                }
                // "Type for You" was renamed to "Control Terminal"; accept the
                // legacy string so existing per-chat grants survive the rename.
                if raw == "Type for You" {
                    self = .controlTerminal
                    return
                }
                guard let value = PermissionCategory(rawValue: raw) else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Unknown permission category \(raw)")
                }
                self = value
            }

            // Localized name for display only. The rawValue doubles as the
            // persisted (Codable) representation, so it must never change;
            // UI code should show displayName instead of rawValue.
            var displayName: String {
                switch self {
                case .checkTerminalState:
                    NSLocalizedString("Check Terminal State", tableName: "AITermXC", comment: "检查终端状态")
                case .runCommands:
                    NSLocalizedString("Run Commands", tableName: "AITermXC", comment: "运行命令")
                case .viewContents:
                    NSLocalizedString("View Contents", tableName: "AITermXC", comment: "查看内容")
                case .writeToClipboard:
                    NSLocalizedString("Write to the Clipboard", tableName: "AITermXC", comment: "写入剪贴板")
                case .controlTerminal:
                    NSLocalizedString("Control Terminal", tableName: "AITermXC", comment: "控制终端")
                case .viewManpages:
                    NSLocalizedString("View Manpages", tableName: "AITermXC", comment: "查看 manpage")
                case .writeToFilesystem:
                    NSLocalizedString("Write to the File System", tableName: "AITermXC", comment: "写入文件系统")
                case .actInWebBrowser:
                    NSLocalizedString("Act in Web Browser", tableName: "AITermXC", comment: "在 Web 浏览器中操作")
                }
            }

            var isBrowserSpecific: Bool {
                switch self {
                case .checkTerminalState, .runCommands, .viewContents, .writeToClipboard,
                        .controlTerminal, .viewManpages, .writeToFilesystem:
                    false
                case .actInWebBrowser:
                    true
                }
            }

            var autopopulationTitle: String? {
                switch self {
                case .checkTerminalState:
                    NSLocalizedString("Provide Terminal State Automatically", tableName: "AITermXC", comment: "自动提供终端状态")
                case .viewContents:
                    NSLocalizedString("Provide Screen Contents Automatically", tableName: "AITermXC", comment: "自动提供屏幕内容")
                case .runCommands, .writeToClipboard, .controlTerminal, .viewManpages,
                        .writeToFilesystem, .actInWebBrowser:
                    nil
                }
            }

            var autopopulationWarningText: String? {
                switch self {
                case .checkTerminalState:
                    NSLocalizedString("By setting this permission to “Always Allow”, terminal state will be sent automatically on every message you send in this chat.\nThis includes:\n • The current or last command and its exit status\n •The window size\n • Your shell\n • The current working directory, username, and hostname.", tableName: "AITermXC", comment: "将此权限设为「始终允许」后，在此对话中你发送的每条消息都会自动发送终端状态\n这包括：\n • 当前或最后一条命令及其退出状态\n •窗口大小\n • 你的 shell\n • 当前工作目录、用户名和主机名")
                case .viewContents:
                    NSLocalizedString("By setting this permission to “Always Allow”, the current visible screen of your terminal session will be sent automatically on every message you send in this chat.", tableName: "AITermXC", comment: "将此权限设为「始终允许」后，在此对话中你发送的每条消息都会自动发送终端会话当前可见的屏幕内容")
                case .runCommands, .writeToClipboard, .controlTerminal, .viewManpages,
                        .writeToFilesystem, .actInWebBrowser:
                    nil
                }
            }

            var regularTitle: String {
                String(format: NSLocalizedString("AI can %@", tableName: "AITermXC", comment: "AI 可以 %@"), displayName)
            }

            var autopopulatedWhenAlways: Bool {
                switch self {
                case .checkTerminalState, .viewContents:
                    true
                case .runCommands, .writeToClipboard, .controlTerminal, .viewManpages,
                        .writeToFilesystem, .actInWebBrowser:
                    false
                }
            }

            // Whether "Provided automatically" also hides the on-request tools. Check
            // Terminal State does: its autopopulated state fully replaces the state
            // queries. View Contents does NOT: the autopopulated visible screen only
            // covers the current grid, while the history tools reach off-screen
            // content (command history, an earlier command's full output, the
            // partially-typed command), so they stay available on request.
            var suppressesOnRequestToolsWhenAlways: Bool {
                switch self {
                case .checkTerminalState:
                    true
                case .viewContents, .runCommands, .writeToClipboard, .controlTerminal,
                        .viewManpages, .writeToFilesystem, .actInWebBrowser:
                    false
                }
            }
        }

        var permissionCategory: PermissionCategory {
            switch self {
            case .isAtPrompt, .getLastExitStatus, .getTerminalSize, .getShellType,
                    .detectSSHSession, .getRemoteHostname, .getUserIdentity, .getCurrentDirectory:
                    .checkTerminalState
            case .executeCommand:
                    .runCommands
            case .getCommandHistory, .getLastCommand, .getCommandBeforeCursor,
                    .searchCommandHistory, .getCommandOutput, .getScreenContents:
                    .viewContents
            case .setClipboard:
                    .writeToClipboard
            case .insertTextAtCursor, .deleteCurrentLine, .restartSession:
                    .controlTerminal
            case .getManPage:
                    .viewManpages
            case .createFile:
                    .writeToFilesystem
            case .searchBrowser, .loadURL, .webSearch, .getURL, .readWebPage:
                    .actInWebBrowser
            }
        }

        var args: Any {
            switch self {
            case .isAtPrompt(let args): args
            case .executeCommand(let args): args
            case .getLastExitStatus(let args): args
            case .getCommandHistory(let args): args
            case .getLastCommand(let args): args
            case .getCommandBeforeCursor(let args): args
            case .searchCommandHistory(let args): args
            case .getCommandOutput(let args): args
            case .getScreenContents(let args): args
            case .getTerminalSize(let args): args
            case .getShellType(let args): args
            case .detectSSHSession(let args): args
            case .getRemoteHostname(let args): args
            case .getUserIdentity(let args): args
            case .getCurrentDirectory(let args): args
            case .setClipboard(let args): args
            case .insertTextAtCursor(let args): args
            case .deleteCurrentLine(let args): args
            case .getManPage(let args): args
            case .createFile(let args): args
            case .searchBrowser(let args): args
            case .loadURL(let args): args
            case .webSearch(let args): args
            case .getURL(let args): args
            case .readWebPage(let args): args
            case .restartSession(let args): args
            }
        }
    }


    var llmMessage: LLM.Message
    var content: Content

    var needsSafetyCheck: Bool {
        // NOTE: .createFile is deliberately NOT checked here. A session-bound
        // file write surfaces in the chat UI where the user sees it before it
        // lands. The ORCHESTRATOR, which runs autonomously, does classify its
        // own create_file (OrchestratorDispatcher.handleSessionToolCall). Don't
        // "fix" this asymmetry by flipping .createFile without also revisiting
        // that autonomy distinction.
        switch content {
        case .isAtPrompt, .getLastExitStatus, .getCommandHistory, .getLastCommand,
                .getCommandBeforeCursor, .searchCommandHistory, .getCommandOutput,
                .getScreenContents,
                .getTerminalSize, .getShellType, .detectSSHSession, .getRemoteHostname,
                .getUserIdentity, .getCurrentDirectory, .setClipboard,
                .deleteCurrentLine, .getManPage, .createFile, .searchBrowser,
                .loadURL, .webSearch, .getURL, .readWebPage, .insertTextAtCursor,
                .restartSession:
            return false
        case .executeCommand:
            return true
        }
    }

    var markdownDescription: String {
        switch content {
        case .isAtPrompt:
            NSLocalizedString("Checking if you're at a shell prompt", tableName: "AITermXC", comment: "正在检查是否处于 shell 提示符")
        case let .executeCommand(args):
            String(format: NSLocalizedString("Executing `%@`", tableName: "AITermXC", comment: "正在执行 `%@`"), args.command.escapedForMarkdownCode.truncatedWithTrailingEllipsis(to: 32))
        case .getLastExitStatus:
            NSLocalizedString("Checking the exit status of the last command", tableName: "AITermXC", comment: "正在检查上一条命令的退出状态")
        case .getCommandHistory:
            NSLocalizedString("Reviewing the history of commands you have run in this session", tableName: "AITermXC", comment: "正在查看本会话中你运行过的命令历史")
        case .getLastCommand:
            NSLocalizedString("Viewing the last command you ran in this session", tableName: "AITermXC", comment: "正在查看本会话中你运行的最后一条命令")
        case .getCommandBeforeCursor:
            NSLocalizedString("Reading your current command prompt", tableName: "AITermXC", comment: "正在读取当前命令提示符")
        case .searchCommandHistory:
            NSLocalizedString("Searching the history of commands you have run in this session", tableName: "AITermXC", comment: "正在搜索本会话中你运行过的命令历史")
        case .getCommandOutput:
            NSLocalizedString("Fetching the output of a previously run command", tableName: "AITermXC", comment: "正在获取之前运行的命令输出")
        case .getScreenContents:
            NSLocalizedString("Reading the visible screen", tableName: "AITermXC", comment: "正在读取可见屏幕")
        case .getTerminalSize:
            NSLocalizedString("Querying the size of your terminal window", tableName: "AITermXC", comment: "正在查询终端窗口大小")
        case .getShellType:
            NSLocalizedString("Determining which shell you use", tableName: "AITermXC", comment: "正在确定你使用的 shell")
        case .detectSSHSession:
            NSLocalizedString("Checking if you are using SSH", tableName: "AITermXC", comment: "正在检查是否在使用 SSH")
        case .getRemoteHostname:
            NSLocalizedString("Getting the current host name of this terminal session", tableName: "AITermXC", comment: "正在获取本终端会话的当前主机名")
        case .getUserIdentity:
            NSLocalizedString("Checking your username", tableName: "AITermXC", comment: "正在检查你的用户名")
        case .getCurrentDirectory:
            NSLocalizedString("Discovering your current directory", tableName: "AITermXC", comment: "正在发现你的当前目录")
        case .setClipboard:
            NSLocalizedString("Pasting to the clipboard", tableName: "AITermXC", comment: "正在粘贴到剪贴板")
        case let .insertTextAtCursor(args):
            String(format: NSLocalizedString("Typing `%@` into the current session", tableName: "AITermXC", comment: "正在向当前会话输入 `%@`"), args.text.escapedForMarkdownCode.truncatedWithTrailingEllipsis(to: 32))
        case .deleteCurrentLine:
            NSLocalizedString("Erasing the current command line", tableName: "AITermXC", comment: "正在清除当前命令行")
        case let .getManPage(args):
            String(format: NSLocalizedString("Checking the manpage for `%@`", tableName: "AITermXC", comment: "正在查看 `%@` 的 manpage"), args.cmd.escapedForMarkdownCode.truncatedWithTrailingEllipsis(to: 32))
        case let .createFile(args):
            String(format: NSLocalizedString("Creating %@", tableName: "AITermXC", comment: "正在创建 %@"), args.filename)
        case let .searchBrowser(args):
            String(format: NSLocalizedString("Search in browser for %@", tableName: "AITermXC", comment: "在浏览器中搜索 %@"), args.query)
        case let .loadURL(args):
            String(format: NSLocalizedString("Navigate to %@", tableName: "AITermXC", comment: "导航到 %@"), args.url)
        case let .webSearch(args):
            String(format: NSLocalizedString("Search the web for “%@”", tableName: "AITermXC", comment: "在网上搜索“%@”"), args.query)
        case .getURL:
            NSLocalizedString("Get the current URL", tableName: "AITermXC", comment: "获取当前 URL")
        case .readWebPage:
            NSLocalizedString("View the current web page", tableName: "AITermXC", comment: "查看当前网页")
        case .restartSession:
            NSLocalizedString("Restarting this session", tableName: "AITermXC", comment: "正在重启本会话")
        }
    }

    var permissionDescription: String {
        switch content {
        case .isAtPrompt:
            NSLocalizedString("The AI Agent would like to check if you're at a shell prompt", tableName: "AITermXC", comment: "AI 代理想检查你是否处于 shell 提示符")
        case let .executeCommand(args):
            String(format: NSLocalizedString("The AI Agent would like to execute `%@`", tableName: "AITermXC", comment: "AI 代理想执行 `%@`"), args.command.escapedForMarkdownCode)
        case .getLastExitStatus:
            NSLocalizedString("The AI Agent would like to check the exit status of the last command", tableName: "AITermXC", comment: "AI 代理想检查上一条命令的退出状态")
        case .getCommandHistory:
            NSLocalizedString("The AI Agent would like to review the history of commands you have run in this session", tableName: "AITermXC", comment: "AI 代理想查看你在本会话中运行过的命令历史")
        case .getLastCommand:
            NSLocalizedString("The AI Agent would like to view the last command you ran in this session", tableName: "AITermXC", comment: "AI 代理想查看你在本会话中运行的最后一条命令")
        case .getCommandBeforeCursor:
            NSLocalizedString("The AI Agent would like to read your current command prompt", tableName: "AITermXC", comment: "AI 代理想读取你当前的命令提示符")
        case .searchCommandHistory:
            NSLocalizedString("The AI Agent would like to search the history of commands you have run in this session", tableName: "AITermXC", comment: "AI 代理想搜索你在本会话中运行过的命令历史")
        case .getCommandOutput:
            NSLocalizedString("The AI Agent would like to fetch the output of a previously run command", tableName: "AITermXC", comment: "AI 代理想获取之前运行的命令的输出")
        case .getScreenContents:
            NSLocalizedString("The AI Agent would like to read the visible screen of your terminal session", tableName: "AITermXC", comment: "AI 代理想读取你终端会话的可见屏幕内容")
        case .getTerminalSize:
            NSLocalizedString("The AI Agent would like to query the size of your terminal window", tableName: "AITermXC", comment: "AI 代理想查询你终端窗口的大小")
        case .getShellType:
            NSLocalizedString("The AI Agent would like to determine which shell you use", tableName: "AITermXC", comment: "AI 代理想确定你使用的是哪种 shell")
        case .detectSSHSession:
            NSLocalizedString("The AI Agent would like to check if you are using SSH", tableName: "AITermXC", comment: "AI 代理想检查你是否正在使用 SSH")
        case .getRemoteHostname:
            NSLocalizedString("The AI Agent would like to get the current host name of this terminal session", tableName: "AITermXC", comment: "AI 代理想获取本终端会话的当前主机名")
        case .getUserIdentity:
            NSLocalizedString("The AI Agent would like to check your username", tableName: "AITermXC", comment: "AI 代理想检查你的用户名")
        case .getCurrentDirectory:
            NSLocalizedString("The AI Agent would like to know your current directory", tableName: "AITermXC", comment: "AI 代理想知道你当前所在的目录")
        case .setClipboard:
            NSLocalizedString("The AI Agent would like to paste to the clipboard", tableName: "AITermXC", comment: "AI 代理想粘贴到剪贴板")
        case let .insertTextAtCursor(args):
            String(format: NSLocalizedString("The AI Agent would like to type `%@` into the current session", tableName: "AITermXC", comment: "AI 代理想在当前会话中输入 `%@`"), args.text.escapedForMarkdownCode.truncatedWithTrailingEllipsis(to: 32))
        case .deleteCurrentLine:
            NSLocalizedString("The AI Agent would like to erase the current command line", tableName: "AITermXC", comment: "AI 代理想清除当前命令行")
        case let .getManPage(args):
            String(format: NSLocalizedString("The AI Agent would like to check the manpage for `%@`", tableName: "AITermXC", comment: "AI 代理想查看 `%@` 的 manpage"), args.cmd.escapedForMarkdownCode)
        case let .createFile(args):
            String(format: NSLocalizedString("The AI Agent would like to create a file named `%@`", tableName: "AITermXC", comment: "AI 代理想创建名为 `%@` 的文件"), args.filename)
        case let .searchBrowser(args):
            String(format: NSLocalizedString("The AI agent would like to search the current web page for “%@”", tableName: "AITermXC", comment: "AI 代理想在当前网页中搜索 “%@”"), args.query)
        case let .loadURL(args):
            String(format: NSLocalizedString("The AI agent would like to navigate to %@", tableName: "AITermXC", comment: "AI 代理想导航到 %@"), args.url)
        case let .webSearch(args):
            String(format: NSLocalizedString("The AI agent would like to search the web for “%@”", tableName: "AITermXC", comment: "AI 代理想在网上搜索 “%@”"), args.query)
        case .getURL:
            NSLocalizedString("The AI agent would like to get the current URL", tableName: "AITermXC", comment: "AI 代理想获取当前 URL")
        case .readWebPage:
            NSLocalizedString("The AI agent would like to view the current web page", tableName: "AITermXC", comment: "AI 代理想查看当前网页")
        case .restartSession:
            NSLocalizedString("The AI Agent would like to restart this session, which kills any running jobs", tableName: "AITermXC", comment: "AI 代理想重启本会话，这会终止所有正在运行的作业")
        }
    }

    var shouldPublishNotice: Bool {
        switch content {
        case .executeCommand:
            false
        case .isAtPrompt, .getLastExitStatus, .getCommandHistory, .getLastCommand,
                .getCommandBeforeCursor, .searchCommandHistory, .getCommandOutput,
                .getScreenContents, .getTerminalSize,
                .getShellType, .detectSSHSession, .getRemoteHostname, .getUserIdentity,
                .getCurrentDirectory, .setClipboard, .insertTextAtCursor, .deleteCurrentLine,
                .getManPage, .createFile, .searchBrowser, .loadURL,
                .webSearch, .getURL, .readWebPage, .restartSession:
            true
        }
    }
}

extension RemoteCommand.Content {
    var functionName: String {
        switch self {
        case .isAtPrompt:
            "is_at_prompt"
        case .executeCommand:
            "execute_command"
        case .getLastExitStatus:
            "get_last_exit_status"
        case .getCommandHistory:
            "get_command_history"
        case .getLastCommand:
            "get_last_command"
        case .getCommandBeforeCursor:
            "get_command_before_cursor"
        case .searchCommandHistory:
            "search_command_history"
        case .getCommandOutput:
            "get_command_output"
        case .getScreenContents:
            "get_screen_contents"
        case .getTerminalSize:
            "get_terminal_size"
        case .getShellType:
            "get_shell_type"
        case .detectSSHSession:
            "detect_ssh_session"
        case .getRemoteHostname:
            "get_remote_hostname"
        case .getUserIdentity:
            "get_user_identity"
        case .getCurrentDirectory:
            "get_current_directory"
        case .setClipboard:
            "set_clipboard"
        case .insertTextAtCursor:
            "insert_text_at_cursor"
        case .deleteCurrentLine:
            "delete_current_line"
        case .getManPage:
            "get_man_page"
        case .createFile:
            "create_file"
        case .searchBrowser:
            "find_on_page"
        case .loadURL:
            "load_url"
        case .webSearch:
            "web_search_in_browser"
        case .getURL:
            "get_current_url"
        case .readWebPage:
            "read_web_page_section"
        case .restartSession:
            "restart_session"
        }
    }

    var argDescriptions: [String: String] {
        return switch self {
        case .isAtPrompt(_):
            [:]
        case .executeCommand(_):
            ["command": "The command to run"]
        case .getLastExitStatus(_):
            [:]
        case .getCommandHistory(_):
            ["limit": "Maximum number of history items to return."]
        case .getLastCommand(_):
            [:]
        case .getCommandBeforeCursor(_):
            [:]
        case .searchCommandHistory(_):
            ["query": "Search query for filtering command history."]
        case .getCommandOutput(_):
            ["id": "Unique identifier of the command whose output is requested."]
        case .getScreenContents(_):
            ["lines": "Number of trailing lines to return when the visible screen is a normal shell (the primary screen). Use 0 for the default of 100. Ignored for a full-screen application, where only the current screen is available."]
        case .getTerminalSize(_):
            [:]
        case .getShellType(_):
            [:]
        case .detectSSHSession(_):
            [:]
        case .getRemoteHostname(_):
            [:]
        case .getUserIdentity(_):
            [:]
        case .getCurrentDirectory(_):
            [:]
        case .setClipboard(_):
            ["text": "The text to copy to the clipboard."]
        case .insertTextAtCursor(_):
            ["text": "The text to insert at the cursor position. Supports a small backslash-escape vocabulary so you can send control keys and special characters: \\\\ for a literal backslash, \\n for newline, \\r for carriage return, \\t for tab, and \\uXXXX (four hex digits, JSON-style) for any Unicode scalar. Examples: \\u0004 for Ctrl-D / EOF, \\u001a for Ctrl-Z, \\u000c for Ctrl-L, \\u001b for Escape. Consider whether execute_command would be a better choice, especially when running a command at the shell prompt since insert_text_at_cursor does not return the output to you."]
        case .deleteCurrentLine(_):
            [:]
        case .getManPage(_):
            ["cmd": "The command whose man page content is requested."]
        case .createFile:
            ["filename": "The name of the file you wish to create. It will be replaced if it already exists.",
             "content": "The content that will be written to the file."]
        case .searchBrowser(_):
            ["query": "The text to search for on the current page. Ensure you know which web page is currently loaded before using this."]
        case .loadURL(_):
            ["url": "The URL to load. Must use https scheme."]
        case .webSearch(_):
            ["query": "The web search query"]
        case .getURL(_):
            [:]
        case .readWebPage(_):
            ["startingLineNumber": "The line number to start reading at.",
             "numberOfLines": "The number of lines to return."]
        case .restartSession(_):
            [:]
        }
    }

    var functionDescription: String {
        switch self {
        case .isAtPrompt(_):
            "Returns true if the terminal is at the command prompt, allowing safe command injection."
        case .executeCommand(_):
            "Runs a shell command and returns its output once the command finishes. "
            + "Do NOT use it for interactive or full-screen (TUI) programs (for example "
            + "vim, less, top, an ssh session, a REPL, or claude): it blocks until the "
            + "command exits, so an interactive or long-running program never returns. To "
            + "launch or drive a TUI from the command line, use insert_text_at_cursor instead."
        case .getLastExitStatus(_):
            "Retrieves the exit status of the last executed command."
        case .getCommandHistory(_):
            "Returns the recent command history."
        case .getLastCommand(_):
            "Retrieves the most recent command."
        case .getCommandBeforeCursor(_):
            "Returns the current partially typed command before the cursor."
        case .searchCommandHistory(_):
            "Searches history for commands matching a query."
        case .getCommandOutput(_):
            "Returns the output of a previous command by its unique identifier."
        case .getScreenContents(_):
            "Returns the visible contents of this terminal session. For a normal shell the text is linear scrollback (real history; ask for more `lines` to see further back). For a full-screen application (vim, less, htop, a REPL, etc.) the text is only the current rendered screen: there is no scrollback or history beyond what is displayed. The result reports a `kind` field and an `is_snapshot` flag (true means do not assume any history is present) alongside the raw `text`. The text uses a few markup tokens (the angle brackets are U+27E8/U+27E9 and effectively never occur in real terminal output): \u{27E8}dim\u{27E9}\u{2026}\u{27E8}/dim\u{27E9} wraps faint/dimmed text (how shells and TUIs render inline suggestions and ghost completions); \u{27E8}cursor\u{27E9} marks the text cursor's position; \u{27E8}image\u{27E9} stands in for an inline image. These tokens are inserted by iTerm2 and are not literally present on the screen."
        case .getTerminalSize(_):
            "Returns (columns, rows) of the terminal window."
        case .getShellType(_):
            "Detects the shell in use (e.g., bash, fish, xonsh, zsh)."
        case .detectSSHSession(_):
            "Returns true if the user is SSH’ed into a remote host."
        case .getRemoteHostname(_):
            "Returns the remote hostname if in an SSH session."
        case .getUserIdentity(_):
            "Returns the logged-in user’s username."
        case .getCurrentDirectory(_):
            "Returns the current directory."
        case .setClipboard(_):
            "Copies text to the clipboard."
        case .insertTextAtCursor(_):
            "Inserts text into the terminal input at the cursor position, as if typed; "
            + "end with a newline to submit it. Use this to launch and interact with "
            + "interactive or full-screen (TUI) programs - start one from the command "
            + "prompt (type the command plus a newline), choose a menu option, or send "
            + "keystrokes to a running app - since unlike execute_command it does not wait "
            + "for the program to finish."
        case .deleteCurrentLine(_):
            "Clears the current command line input (only at the prompt)."
        case .getManPage(_):
            "Returns the content of a command's man page."
        case .createFile:
            "Creates a file containing a specified string on the user's computer and then reveals it in Finder."
        case .loadURL:
            "Loads the specified URL in the associated web browser"
        case .webSearch:
            "Performs a web search using the currently configured search engine in the associated web browser"
        case .getURL:
            "Returns the current URL of the associated web browser"
        case .readWebPage:
            "Returns some of the content (in markdown format) of the page visible in the associated web browser."
        case .searchBrowser(_):
            "Searches the current web page in the associated web browser (after converting to markdown format) for a substring."
        case .restartSession(_):
            "Restarts this terminal session: terminates any running jobs and relaunches the session’s command, equivalent to the Session > Restart Session menu item. Use this to recover a hung or misconfigured session. This is disruptive - every running process in the session is killed - so only use it when the user has asked to restart or when the session is unusable."
        }
    }

    func withValue(_ value: Any) -> RemoteCommand.Content {
        switch self {
        case .isAtPrompt: .isAtPrompt(value as! RemoteCommand.IsAtPrompt)
        case .executeCommand: .executeCommand(value as! RemoteCommand.ExecuteCommand)
        case .getLastExitStatus: .getLastExitStatus(value as! RemoteCommand.GetLastExitStatus)
        case .getCommandHistory: .getCommandHistory(value as! RemoteCommand.GetCommandHistory)
        case .getLastCommand: .getLastCommand(value as! RemoteCommand.GetLastCommand)
        case .getCommandBeforeCursor: .getCommandBeforeCursor(value as! RemoteCommand.GetCommandBeforeCursor)
        case .searchCommandHistory: .searchCommandHistory(value as! RemoteCommand.SearchCommandHistory)
        case .getCommandOutput: .getCommandOutput(value as! RemoteCommand.GetCommandOutput)
        case .getScreenContents: .getScreenContents(value as! RemoteCommand.GetScreenContents)
        case .getTerminalSize: .getTerminalSize(value as! RemoteCommand.GetTerminalSize)
        case .getShellType: .getShellType(value as! RemoteCommand.GetShellType)
        case .detectSSHSession: .detectSSHSession(value as! RemoteCommand.DetectSSHSession)
        case .getRemoteHostname: .getRemoteHostname(value as! RemoteCommand.GetRemoteHostname)
        case .getUserIdentity: .getUserIdentity(value as! RemoteCommand.GetUserIdentity)
        case .getCurrentDirectory: .getCurrentDirectory(value as! RemoteCommand.GetCurrentDirectory)
        case .setClipboard: .setClipboard(value as! RemoteCommand.SetClipboard)
        case .insertTextAtCursor: .insertTextAtCursor(value as! RemoteCommand.InsertTextAtCursor)
        case .deleteCurrentLine: .deleteCurrentLine(value as! RemoteCommand.DeleteCurrentLine)
        case .getManPage: .getManPage(value as! RemoteCommand.GetManPage)
        case .createFile: .createFile(value as! RemoteCommand.CreateFile)
        case .searchBrowser: .searchBrowser(value as! RemoteCommand.SearchBrowser)
        case .loadURL: .loadURL(value as! RemoteCommand.LoadURL)
        case .webSearch: .webSearch(value as! RemoteCommand.WebSearch)
        case .getURL: .getURL(value as! RemoteCommand.GetURL)
        case .readWebPage: .readWebPage(value as! RemoteCommand.ReadWebPage)
        case .restartSession: .restartSession(value as! RemoteCommand.RestartSession)
        }
    }
}
