//
//  MessageToPromptStateMachine.swift
//  iTerm2
//
//  Created by George Nachman on 8/18/25.
//

struct MessageToPromptStateMachine {
    private enum Mode {
        case regular
        case initialExplanation
    }
    private var mode = Mode.regular

    mutating func body(message: Message) -> LLM.Message.Body {
        switch message.author {
        case .agent:
            body(agentMessage: message)
        case .user:
            body(userMessage: message)
        }
    }

    private mutating func body(agentMessage: Message) -> LLM.Message.Body {
        switch agentMessage.content {
        case .plainText(let value, context: _), .markdown(let value):
            return .text(value)
        case .explanationResponse(let annotations, _, _):
            return .text(annotations.rawResponse)
        case .remoteCommandRequest(let request, safe: _):
            if let call = request.llmMessage.function_call {
                return .functionCall(call,
                                     id: request.llmMessage.functionCallID)
            } else {
                return .uninitialized
            }
        case .remoteCommandResponse, .selectSessionRequest, .clientLocal, .renameChat, .append,
                .commit, .setPermissions, .vectorStoreCreated, .terminalCommand, .appendAttachment,
                .explanationRequest, .userCommand, .watcherEvent:
            it_fatalError()
        case .unsupported:
            // Forward-compat placeholder; upstream transcript builders
            // skip it before reaching here, so this is purely defensive
            // (don't crash a release build on a never-actually-sent path).
            return .uninitialized
        case .multipart(let subparts, _):
            return .multipart(subparts.compactMap { subpart -> LLM.Message.Body? in
                switch subpart {
                case .attachment(let attachment):
                    switch attachment.type {
                    case .code(let code):
                        return .text(code)
                    case .statusUpdate:
                        return nil
                    case .file, .fileID:
                        return .attachment(attachment)
                    }
                case .markdown(let string), .plainText(let string):
                    return .text(string)
                case .context:
                    it_fatalError()
                }
            })
        }
    }

    private func prompt(terminalCommand: TerminalCommand) -> String {
        var lines = [String]()
        lines.append(NSLocalizedString("iTerm2 is sending you this message automatically because the user enabled sending terminal commands to AI for assistance. If you can provide useful non-obvious insights, respond with those. Do not restate information that is obvious from the output. If there is nothing important to say, just respond with \"Got it.\"", tableName: "AITermXC", comment: "iTerm2 自动发送此消息，因为用户启用了将终端命令发送给 AI 以获取帮助。如果您能提供有用的非明显见解，请回复。不要重复输出中明显的信息。如果没有重要内容，请回复\"明白了。\""))
        lines.append(NSLocalizedString("I executed the following command line:", tableName: "AITermXC", comment: "我执行了以下命令行："))
        lines.append(terminalCommand.command)
        if let directory = terminalCommand.directory {
            lines.append(NSLocalizedString("My current directory was:", tableName: "AITermXC", comment: "我当时的目录是："))
            lines.append(directory)
        }
        if let hostname = terminalCommand.hostname {
            if let username = terminalCommand.username {
                lines.append(String(format: NSLocalizedString("I am logged in as %@@%@", tableName: "AITermXC", comment: "我以 %@@%@ 登录"), username, hostname))
            } else {
                lines.append(String(format: NSLocalizedString("The current hostname is %@", tableName: "AITermXC", comment: "当前主机名是 %@"), hostname))
            }
        }
        lines.append(String(format: NSLocalizedString("The exit status of the command was %@", tableName: "AITermXC", comment: "命令的退出状态是 %@"), "\(terminalCommand.exitCode)"))
        lines.append(NSLocalizedString("It produced this output:", tableName: "AITermXC", comment: "它产生了以下输出："))
        lines.append(terminalCommand.output)
        return lines.joined(separator: "\n")
    }

    private mutating func body(userMessage: Message) -> LLM.Message.Body {
        switch userMessage.content {
        case .plainText(let value, context: let context):
            defer {
                mode = .regular
            }
            switch mode {
            case .regular:
                return .text(value + (context.map { "\n" + $0 } ?? ""))
            case .initialExplanation:
                return .text(AIExplanationRequest.conversationalPrompt(userPrompt: value))
            }
        case .markdown(let text):
            // A user-author markdown message comes from the orchestrator
            // turn path (the agent's translator wraps the body with a
            // <workgroups> snapshot before adding; on history reload
            // we just want the raw text).
            return .text(text)
        case .watcherEvent(let payload):
            // Orchestration watcher events are routed like user messages so
            // ChatService kicks off an agent turn; they're rendered to
            // the LLM as a tagged <status_update> block both on the
            // initial firing and on history reload.
            return .text(Self.llmText(forWatcherEvent: payload))
        case .explanationRequest(let request):
            mode = .initialExplanation
            return .text(request.prompt())
        case .multipart(let subparts, _):
            var parts = subparts.compactMap { subpart -> LLM.Message.Body? in
                switch subpart {
                case .attachment(let attachment):
                    switch attachment.type {
                    case .code(let code):
                        return .text(code)
                    case .statusUpdate:
                        return nil
                    case .file, .fileID:
                        return .attachment(attachment)
                    }
                case .markdown(let string), .plainText(let string), .context(let string):
                    return .text(string)
                }
            }
            if parts.contains(where: { $0.isAttachment}),
               let i = parts.firstIndex(where: { $0.isText }) {
                parts[i].prepend(NSLocalizedString("I have attached files for you to use.\n", tableName: "AITermXC", comment: "我已附上文件供你使用。\n"))
            }
            return .multipart(parts)
        case .remoteCommandResponse(let result, _, let functionName, let functionCallID):
            let output = result.map { value in
                value
            } failure: { error in
                NSLocalizedString("I was unable to complete the function call: ", tableName: "AITermXC", comment: "我未能完成此函数调用：") + error.localizedDescription
            }
            return .functionOutput(name: functionName,
                                   output: output,
                                   id: functionCallID)
        case .terminalCommand(let cmd):
            return .text(prompt(terminalCommand: cmd))
        case .explanationResponse, .append, .appendAttachment, .remoteCommandRequest,
                .selectSessionRequest, .clientLocal, .renameChat, .commit, .setPermissions,
                .vectorStoreCreated, .userCommand:
            it_fatalError()
        case .unsupported:
            // Forward-compat placeholder; upstream transcript builders
            // skip it before reaching here, so this is purely defensive.
            return .uninitialized
        }
    }

    // LLM-visible rendering of a watcher event. Wrapped in an XML-ish
    // tag so the system prompt can teach the model to recognize these
    // as iTerm2-generated events, not user requests.
    //
    // Every interpolated value passes through xmlEscape* helpers. Detail
    // in particular is free-form text from watcher output and can legally
    // contain markup; without escaping a detail string containing
    // "</status_update>" would close the tag early and the rest of the
    // payload would be parsed by the LLM as a higher-trust system frame.
    private static func llmText(forWatcherEvent payload: StatusUpdate) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let at = iso.string(from: payload.timestamp)
        var lines: [String] = []
        lines.append("<status_update reason=\"\(xmlEscapeAttribute(payload.reason.rawValue))\" "
                     + "watcher_id=\"\(xmlEscapeAttribute(payload.watcherID))\" "
                     + "at=\"\(xmlEscapeAttribute(at))\">")
        lines.append(String(format: NSLocalizedString("Workgroup: %@", tableName: "AITermXC", comment: "工作组：%%@"), xmlEscapeText(payload.workgroupName)))
        lines.append(String(format: NSLocalizedString("Role: %@", tableName: "AITermXC", comment: "角色：%%@"), xmlEscapeText(payload.roleName)))
        if !payload.stateReached.isEmpty {
            lines.append(String(format: NSLocalizedString("Reached state: %@", tableName: "AITermXC", comment: "到达状态：%%@"), xmlEscapeText(payload.stateReached)))
        }
        if let screenLastChanged = payload.screenLastChanged {
            lines.append(String(format: NSLocalizedString("Screen last changed: %@", tableName: "AITermXC", comment: "屏幕最后更改：%%@"), xmlEscapeText(screenLastChanged)))
        }
        if !payload.detail.isEmpty {
            lines.append(String(format: NSLocalizedString("Detail: %@", tableName: "AITermXC", comment: "详情：%%@"), xmlEscapeText(payload.detail)))
        }
        if payload.pushed == true {
            lines.append(NSLocalizedString("Note: iTerm2 already sent a push notification to the user's iPhone for this event. Do not send another.", tableName: "AITermXC", comment: "注意：iTerm2 已为此事件向用户的 iPhone 发送了推送通知。请勿再发送。"))
        } else if payload.pushed == false {
            lines.append(NSLocalizedString("Note: the user asked for a push notification but notifications are unavailable right now, so make sure they see this in chat.", tableName: "AITermXC", comment: "注意：用户请求了推送通知，但通知目前不可用，请确保他们在对话中看到此消息。"))
        } else if CompanionPushRegistry.canNotify {
            lines.append(NSLocalizedString("Note: the user may be away from their Mac. If they asked to be told when this happened, also send a push notification with the notify tool.", tableName: "AITermXC", comment: "注意：用户可能不在 Mac 旁边。如果他们要求在此情况发生时通知，请同时使用通知工具发送推送通知。"))
        }
        lines.append("</status_update>")
        return lines.joined(separator: "\n")
    }

    // & must be replaced first so subsequent replacements don't
    // double-encode the ampersands they introduce.
    private static func xmlEscapeText(_ s: String) -> String {
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func xmlEscapeAttribute(_ s: String) -> String {
        return xmlEscapeText(s)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: "&#10;")
    }
}

extension Message.Subpart {
    var isFileAttachment: Bool {
        switch self {
        case .attachment(let attachment):
            switch attachment.type {
            case .file, .fileID:
                true
            case .code, .statusUpdate:
                false
            }
        case .plainText, .markdown, .context:
            false
        }
    }
}

extension LLM.Message.Body {
    var isAttachment: Bool {
        switch self {
        case .attachment: true
        case .uninitialized, .text, .functionCall, .functionOutput, .multipart: false
        }
    }
    var isText: Bool {
        switch self {
        case .text: true
        case .attachment, .uninitialized, .functionCall, .functionOutput, .multipart: false
        }
    }
    mutating func prepend(_ string: String)  {
        it_assert(isText)
        if case .text(let text) = self {
            self = .text(string + text)
        }
    }
}
