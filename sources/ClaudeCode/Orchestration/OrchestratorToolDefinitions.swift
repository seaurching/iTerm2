//
//  OrchestratorToolDefinitions.swift
//  iTerm2SharedARC
//

import Foundation

// JSON-Schema definitions for the 12 orchestrator tools. Passed to
// AIConversation in the tools array of each LLM request so the model
// knows what it can call.
//
// Schemas use plain dictionaries because the destination is JSON
// (the LLM API serializes them) and writing a typed schema layer for
// 12 tools would be more code than the schemas themselves. Keep
// descriptions tunable here. they're what the LLM sees and how it
// decides which tool to use.
struct ToolDefinition {
    let name: String
    let description: String
    let inputSchema: [String: Any]
}

// MARK: - Schema helpers

private let stringSchema: [String: Any] = ["type": "string"]
private let integerSchema: [String: Any] = ["type": "integer"]
private let booleanSchema: [String: Any] = ["type": "boolean"]

private func string(_ description: String, enumValues: [String]? = nil) -> [String: Any] {
    var result: [String: Any] = ["type": "string", "description": description]
    if let enumValues {
        result["enum"] = enumValues
    }
    return result
}

private func integer(_ description: String) -> [String: Any] {
    return ["type": "integer", "description": description]
}

private func boolean(_ description: String) -> [String: Any] {
    return ["type": "boolean", "description": description]
}

private func nullableString(_ description: String, enumValues: [String]? = nil) -> [String: Any] {
    var result: [String: Any] = ["type": ["string", "null"], "description": description]
    if let enumValues {
        result["enum"] = enumValues.map { $0 as Any } + [NSNull()]
    }
    return result
}

private func nullableInteger(_ description: String) -> [String: Any] {
    return ["type": ["integer", "null"], "description": description]
}

private func nullableBoolean(_ description: String) -> [String: Any] {
    return ["type": ["boolean", "null"], "description": description]
}

private func object(_ properties: [(String, [String: Any])],
                    required: [String]) -> [String: Any] {
    var props = [String: Any]()
    for (k, v) in properties { props[k] = v }
    return [
        "type": "object",
        "properties": props,
        "required": required,
        "additionalProperties": false,
    ]
}

private let emptyObjectSchema: [String: Any] = [
    "type": "object",
    "properties": [String: Any](),
    "required": [String](),
    "additionalProperties": false,
]

// Every session-acting tool addresses its target with this one field.
// The agent copies a session_guid verbatim from the <workgroups>
// snapshot (each role carries a session_guid); the app resolves it to
// the owning workgroup and role. The id is globally unique, so no
// separate role/workgroup disambiguation is needed.
private let sessionGuidSchema: [String: Any] =
    string(NSLocalizedString("The session_guid of the target session, copied verbatim from a role in the <workgroups> snapshot (its session_guid field).",
                             tableName: "ClaudeCodeXC",
                             comment: "session_guid 参数的 schema 描述；session_guid、<workgroups> 保留原文"))

// MARK: - Tool list

extension OrchestratorCommand {
    // The register_watch notify_user paragraph, shared by both surfaces so it
    // can't drift. Empty when no companion phone is paired.
    private static var registerWatchNotifyClause: String {
        CompanionPushRegistry.devicePaired
            ? NSLocalizedString(" When the user asked to be told or alerted when this happens, set notify_user=true: iTerm2 then sends a push notification to their iPhone automatically when the watch fires (a chat reply alone won't reach a user who is away from the Mac). If notifications aren't enabled yet, call request_notification_permission before registering.",
                                tableName: "ClaudeCodeXC",
                                comment: "register_watch 工具描述的 notify_user 段落（配对手机时拼接）；notify_user=true、request_notification_permission 保留原文；key 以空格开头，用于与上文拼接")
            : ""
    }

    // Builds a register_watch description from the shared spine (the
    // <status_update> paragraph, the notify clause, the dedup/already-satisfied
    // sentence) plus the four parts that differ between the orchestration and
    // session-bound surfaces. Keeping the spine here means the two surfaces can't
    // drift on it (they had already diverged in punctuation before this).
    private static func registerWatchDescription(target: String,
                                                 blocking: String,
                                                 formChoice: String,
                                                 persistence: String) -> String {
        return String(format: NSLocalizedString("Register an async watcher on %1$@. Supply exactly ONE of target_state or condition. %2$@ When the watch fires, iTerm2 delivers a `<status_update>...</status_update>` message into the chat as a separate turn; treat that as a system event from iTerm2 (not a new user request) and act on it directly, messaging the user only when a step advances, a task finishes, or you need a decision (not on every event).%3$@ %4$@ Watchers are de-duplicated on (session, target_state, condition): registering the same watch twice returns the existing watcher_id. If the goal is already satisfied at registration time, the watcher fires immediately. %5$@",
                                                tableName: "ClaudeCodeXC",
                                                comment: "register_watch 工具描述主干；target_state、condition、watcher_id、<status_update> 等标记保留原文；%1$@ 为目标，%2$@ 为阻塞说明，%3$@ 为 notify 段落（可为空，其自带前导空格），%4$@ 为形式选择段落，%5$@ 为持久化段落"),
                       target, blocking, registerWatchNotifyClause, formChoice, persistence)
    }

    // Computed (not a stored let) because parts of the text depend on
    // runtime state: push-related guidance only appears when a companion
    // device is paired. Evaluated at agent creation, like the tool list
    // itself.
    static var allToolDefinitions: [ToolDefinition] { [

        // -------- Discovery --------

        ToolDefinition(
            name: ToolName.listWorkgroups.rawValue,
            description: NSLocalizedString("List all active workgroups and their member sessions. Each session reports its role within the workgroup, current status (idle/working/waiting), status_source, and kind (claude-code/shell/tui/other). status_source says how much to trust `status`: \u{201C}reported\u{201D} means the program announces its own status (accurate, and state watchers fire on exact transitions); \u{201C}inferred\u{201D} means iTerm2 is guessing from indicators, so `status` is unreliable (e.g. a program waiting at a splash screen looks \u{201C}idle\u{201D}). screen_last_changed says how long ago the session's screen last changed; use it to tell stale output from fresh activity. provenance (on workgroups and sessions) says who created them, e.g. a workgroup entered by a trigger in some session, or a session created by an agent in another chat; a workgroup whose provenance traces to a different chat belongs to that chat's work, so don't drive it unless asked. Standalone sessions appear as single-session workgroups with a synthetic ID prefixed \u{201C}session:\u{201D}.",
                            tableName: "ClaudeCodeXC",
                            comment: "list_workgroups 工具描述；status_source、screen_last_changed、provenance、kind 取值及 \"reported\"/\"inferred\"/\"session:\" 等取值保留原文"),
            inputSchema: emptyObjectSchema),

        ToolDefinition(
            name: ToolName.getState.rawValue,
            description: NSLocalizedString("Get rich state for a single session, including the last cc-status detail message for Claude Code sessions. The status_source field says whether `status` is announced by the program itself (\u{201C}reported\u{201D}, trustworthy) or guessed from indicators (\u{201C}inferred\u{201D}, unreliable). screen_last_changed says how long ago the screen last changed, and provenance says who created the session when it wasn't the user.",
                            tableName: "ClaudeCodeXC",
                            comment: "get_state 工具描述；status_source、screen_last_changed、provenance 及 \"reported\"/\"inferred\" 保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
            ], required: ["session_guid"])),

        ToolDefinition(
            name: ToolName.getScreenContents.rawValue,
            description: NSLocalizedString("Get the visible contents of a session. For Claude Code sessions, returns a synthesized view of recent hook events (assistant messages, tool calls). For shell sessions, returns scrollback. For TUI sessions, returns a snapshot of the rendered screen with is_snapshot=true; there is no history beyond what's currently displayed. The result includes a kind field so you know how to read the text.\n\nThe result also reports `screen` (\u{201C}primary\u{201D} or \u{201C}alternate\u{201D}) and `mouse_reporting` (bool). On the primary screen the returned text is linear scrollback (real history; ask for more `lines` to see more). On the alternate screen (full-screen apps like vim/less/htop, and Claude Code) ONLY the current grid is returned and is_snapshot is true: older content isn't in scrollback. To view content that scrolled off, if `screen` is \u{201C}alternate\u{201D} and `mouse_reporting` is true, use the scroll_wheel tool (direction=\u{201C}up\u{201D}) and then call get_screen_contents again.\n\nThe text uses a few markup tokens (the angle brackets are U+27E8/U+27E9 and effectively never occur in real terminal output):\n\u{27E8}dim\u{27E9}\u{2026}\u{27E8}/dim\u{27E9} wraps faint/dimmed text. This is how shells and TUIs render inline suggestions and ghost completions (zsh-autosuggestions, fish autosuggest, Claude Code's suggested reply, etc.). \n\u{27E8}cursor\u{27E9} marks the text cursor's position. \n\u{27E8}image\u{27E9} stands in for an inline image. These tokens are inserted by iTerm2 and are not literally present on the screen.",
                            tableName: "ClaudeCodeXC",
                            comment: "get_screen_contents 工具描述；kind、screen 取值（\"primary\"/\"alternate\"）、mouse_reporting、is_snapshot、scroll_wheel、⟨dim⟩/⟨cursor⟩/⟨image⟩（U+27E8/27E9）标记保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
                ("lines", nullableInteger(NSLocalizedString("Number of trailing lines to return for shell sessions. Use null for the default 100. Ignored for tui/claude-code kinds.", tableName: "ClaudeCodeXC", comment: "lines 参数描述；null 及 kind 取值保留原文"))),
            ], required: ["session_guid", "lines"])),

        ToolDefinition(
            name: ToolName.scrollWheel.rawValue,
            description: NSLocalizedString("Send mouse scroll-wheel events to a session to reveal content that's off-screen. This is only useful when get_screen_contents reports screen=\u{201C}alternate\u{201D} (a full-screen app like Claude Code, vim, less, htop): on the alternate screen only the current grid is returned, and older content isn't in scrollback, so scrolling the app's own viewport is the only way to see it. REQUIRES the session to have mouse reporting enabled (get_screen_contents reports mouse_reporting=true); if it's off, this tool errors and does nothing. Workflow: call get_screen_contents, and if you need to see earlier content and screen=\u{201C}alternate\u{201D} with mouse_reporting=true, call scroll_wheel with direction=\u{201C}up\u{201D}, then call get_screen_contents again to read the now-revealed lines. Repeat to page further. Not every alternate-screen app honors the scroll wheel (some ignore it, some scroll a pane you didn't intend); if the screen doesn't change after scrolling, stop and tell the user rather than scrolling blindly. On the primary screen (screen=\u{201C}primary\u{201D}) you don't need this at all: just ask get_screen_contents for more lines.",
                            tableName: "ClaudeCodeXC",
                            comment: "scroll_wheel 工具描述；get_screen_contents、screen/mouse_reporting/direction 取值保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
                ("lines", integer(NSLocalizedString("Number of scroll-wheel notches to send. Each notch is one wheel event; how many text lines that moves depends on the app (often 1 or 3). Start small (e.g. 3) and re-read.", tableName: "ClaudeCodeXC", comment: "scroll_wheel lines 参数描述"))),
                ("direction", nullableString(NSLocalizedString("\u{201C}up\u{201D} reveals OLDER content (the usual choice for paging back through history); \u{201C}down\u{201D} reveals NEWER content. Use null for the default \u{201C}up\u{201D}.", tableName: "ClaudeCodeXC", comment: "direction 参数描述；取值 \"up\"/\"down\" 与 null 保留原文"), enumValues: ["up", "down"])),
            ], required: ["session_guid", "lines", "direction"])),

        ToolDefinition(
            name: ToolName.listWorkgroupClippings.rawValue,
            description: NSLocalizedString("List the clippings posted to a workgroup. Clippings are structured snippets (type, title, detail) that the user or other agents have posted to the workgroup leader for shared reference. Optional type_filter limits to clippings of a particular type (e.g. \u{201C}Code Review Comment\u{201D}).",
                            tableName: "ClaudeCodeXC",
                            comment: "list_workgroup_clippings 工具描述；type_filter 及示例类型值保留原文"),
            inputSchema: object([
                ("workgroup_id", stringSchema),
                ("type_filter", nullableString(NSLocalizedString("Optional. Only return clippings whose type matches this string exactly. Use null for all types.", tableName: "ClaudeCodeXC", comment: "type_filter 参数描述；null 保留原文"))),
            ], required: ["workgroup_id", "type_filter"])),

        // -------- Action (claim required) --------

        ToolDefinition(
            name: ToolName.sendText.rawValue,
            description: NSLocalizedString("Type text into a session as if the user typed it. By default appends a newline. The text supports a small backslash-escape vocabulary so you can send control keys and special characters: \\\\ for a literal backslash, \\n for newline, \\r for carriage return, \\t for tab, and \\uXXXX (four hex digits, JSON-style) for any Unicode scalar. Use this to drive control keys: \\u0003 for Ctrl-C (prefer the dedicated interrupt tool), \\u0004 for Ctrl-D / EOF, \\u001a for Ctrl-Z, \\u000c for Ctrl-L, \\u001b for Escape, etc. When sending a standalone control key, pass append_newline=false so you don't tack an Enter onto it. You may combine control bytes with text and a trailing newline in a single call (e.g. \\u001b:q\\n to quit vim). iTerm2 detects embedded control bytes and sends the payload as a raw keystroke stream rather than a bracketed paste, so the control bytes are interpreted by the target program rather than inserted as literal data. The return value `{\"ack\":{}}` only confirms that the bytes were transmitted; it does NOT confirm the program behaved as you expected. For interactive TUIs (vim, emacs, less, htop, fzf, etc.) always follow up with `get_screen_contents` to verify the effect before telling the user it worked. Requires the user to have approved this chat to control the workgroup; the user is prompted inline on the first send to an unclaimed workgroup.",
                            tableName: "ClaudeCodeXC",
                            comment: "send_text 工具描述；反斜杠转义词汇表（\\\\、\\n、\\uXXXX 等）、append_newline、{\"ack\":{}} 返回值、get_screen_contents 保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
                ("text", stringSchema),
                ("append_newline", nullableBoolean(NSLocalizedString("Whether to append a newline to the text. Use null for the default true. Set to false when sending control keys (e.g. \\u001b for Escape) by themselves.", tableName: "ClaudeCodeXC", comment: "append_newline 参数描述；null/true/false 与 \\uXXXX 转义保留原文"))),
            ], required: ["session_guid", "text", "append_newline"])),

        ToolDefinition(
            name: ToolName.interrupt.rawValue,
            description: NSLocalizedString("Send SIGINT to the foreground process of a session, equivalent to the user pressing Ctrl-C. Requires workgroup claim.",
                            tableName: "ClaudeCodeXC",
                            comment: "interrupt 工具描述；SIGINT 保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
            ], required: ["session_guid"])),

        ToolDefinition(
            name: ToolName.addWorkgroupClipping.rawValue,
            description: NSLocalizedString("Post a clipping to a workgroup so it appears alongside any user-posted clippings. Useful for surfacing structured findings (e.g. distilled code-review comments) for the user or other agents to consume. Requires workgroup claim.",
                            tableName: "ClaudeCodeXC",
                            comment: "add_workgroup_clipping 工具描述"),
            inputSchema: object([
                ("workgroup_id", stringSchema),
                ("type", string(NSLocalizedString("Short tag describing the clipping kind, e.g. \u{201C}Code Review Comment\u{201D} or \u{201C}Build Error\u{201D}.", tableName: "ClaudeCodeXC", comment: "type 参数描述；示例类型值保留原文"))),
                ("title", string(NSLocalizedString("One-line headline.", tableName: "ClaudeCodeXC", comment: "title 参数描述"))),
                ("detail", string(NSLocalizedString("Full description. Markdown is supported.", tableName: "ClaudeCodeXC", comment: "detail 参数描述"))),
            ], required: ["workgroup_id", "type", "title", "detail"])),

        // -------- Code Review (convenience) --------

        ToolDefinition(
            name: ToolName.startCodeReview.rawValue,
            description: NSLocalizedString("Run a Code Review in one call. The session_guid must name the Code Review role's session. The session can be in either of two ready states: (a) the prompt overlay is up (pending_action mentions \u{201C}Code Review prompt overlay\u{201D}), in which case the overlay is populated and the review program launches; or (b) the Code Review session already ran and is idle at its chat prompt, in which case the session is reloaded (killed and relaunched) to run a fresh review. Either way the call auto-registers a watcher for the session reaching idle, so you'll receive a status_update when the review completes. The call errors only if the session isn't the Code Review role, its program is busy, or it can't be reloaded. Pick the prompt by name from the saved prompts (see the system message for the list) via prompt_name, OR pass custom_prompt with free-form text, OR leave both nil to use the user's default prompt. Prefer this over send_text + register_watch for code reviews.",
                            tableName: "ClaudeCodeXC",
                            comment: "start_code_review 工具描述；session_guid、pending_action、prompt_name、custom_prompt、status_update、send_text、register_watch 保留原文"),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
                ("prompt_name", nullableString(NSLocalizedString("Optional. Name of a saved prompt from the user's prompt list. Use null when not using a saved prompt.", tableName: "ClaudeCodeXC", comment: "prompt_name 参数描述；null 保留原文"))),
                ("custom_prompt", nullableString(NSLocalizedString("Optional. Free-form prompt text when no saved prompt fits. Use null to use the default prompt.", tableName: "ClaudeCodeXC", comment: "custom_prompt 参数描述；null 保留原文"))),
            ], required: ["session_guid", "prompt_name", "custom_prompt"])),

        // -------- Spawn (always prompts) --------

        ToolDefinition(
            name: ToolName.startSession.rawValue,
            description: NSLocalizedString("Spawn a new terminal session. Use window=\u{201C}new\u{201D} to open a new window, \u{201C}tab\u{201D} (default) to add a tab to the current window, or \u{201C}current\u{201D} to split the current pane vertically. The user is always prompted to approve the spawn (and the command being run, if any). Returns the session_guid of the new session so you can immediately drive it with the other tools (send_text, get_screen_contents, etc.).",
                            tableName: "ClaudeCodeXC",
                            comment: "start_session 工具描述；window 取值（\"new\"/\"tab\"/\"current\"）、session_guid、send_text、get_screen_contents 保留原文"),
            inputSchema: object([
                ("profile", nullableString(NSLocalizedString("Optional profile name. Use null to fall back to the default profile.", tableName: "ClaudeCodeXC", comment: "profile 参数描述；null 保留原文"))),
                ("command", nullableString(NSLocalizedString("Optional command to run in the new session. Use null for the profile's default shell.", tableName: "ClaudeCodeXC", comment: "command 参数描述；null 保留原文"))),
                ("cwd", nullableString(NSLocalizedString("Optional working directory. Use null for the default.", tableName: "ClaudeCodeXC", comment: "cwd 参数描述；null 保留原文"))),
                ("window", nullableString(NSLocalizedString("Where to put the new session. \u{201C}new\u{201D} for a new window, \u{201C}current\u{201D} to split the current pane, \u{201C}tab\u{201D} (default) for a new tab in the current window. Use null for tab.",
                                          tableName: "ClaudeCodeXC",
                                          comment: "window 参数描述；取值 \"new\"/\"current\"/\"tab\" 与 null 保留原文"),
                                          enumValues: ["new", "current", "tab"])),
            ], required: ["profile", "command", "cwd", "window"])),

        // -------- Watchers (async; non-blocking) --------

        ToolDefinition(
            name: ToolName.registerWatch.rawValue,
            description: registerWatchDescription(
                target: NSLocalizedString("a session", tableName: "ClaudeCodeXC", comment: "register_watch 目标（orchestration 表面）"),
                blocking: NSLocalizedString("This call returns immediately and does NOT block your turn.", tableName: "ClaudeCodeXC", comment: "register_watch 阻塞说明（orchestration 表面）"),
                formChoice: NSLocalizedString("Choosing the form: use target_state (idle/working/waiting) when the session's status_source is \u{201C}reported\u{201D} (see list_workgroups / get_state) — the watch then fires on the program's own exact status transitions. When status_source is \u{201C}inferred\u{201D}, or when what you're waiting for isn't really an idle/working/waiting transition (e.g. \u{201C}emacs has exited and a shell prompt is showing\u{201D}, \u{201C}the build printed a success or failure line\u{201D}, \u{201C}a password prompt appeared\u{201D}), prefer condition: a plain-English description that an AI judge evaluates by periodically reading the session's screen. Inferred idle/busy is ambiguous (a program parked at a splash screen counts as \u{201C}idle\u{201D}), so a specific condition is far more accurate there. Screen-judged watches (all condition watches, and target_state watches on \u{201C}inferred\u{201D} sessions) keep watching on their own, polling less often the longer they run, and only time out (reason=\u{201C}watchTimedOut\u{201D}) after several hours; re-register then if you still need to wait.",
                              tableName: "ClaudeCodeXC",
                              comment: "register_watch 形式选择段落（orchestration 表面）；target_state、condition、status_source、list_workgroups、get_state、reason=\"watchTimedOut\" 及取值/示例保留原文"),
                persistence: NSLocalizedString("Watchers persist across iTerm2 restarts; if a watched session can't be restored, you get a status_update with reason=\u{201C}watcherDropped\u{201D}. Either way, do NOT poll yourself.",
                              tableName: "ClaudeCodeXC",
                              comment: "register_watch 持久化段落（orchestration 表面）；status_update、reason=\"watcherDropped\" 保留原文")),
            inputSchema: object([
                ("session_guid", sessionGuidSchema),
                // "unknown" is included in the enum so the schema matches
                // the runtime SessionState type (which can appear in
                // get_state output), but it isn't a transition target;
                // the dispatcher rejects watch registrations for
                // "unknown" with a clear error.
                ("target_state", nullableString(NSLocalizedString("State to watch for. Must be a transition target: \u{201C}idle\u{201D}, \u{201C}working\u{201D}, or \u{201C}waiting\u{201D}. \u{201C}unknown\u{201D} is shown by get_state when a session has no tab status yet, but it is not a watchable transition. Mutually exclusive with condition: set exactly one and null the other.", tableName: "ClaudeCodeXC", comment: "target_state 参数描述（orchestration 表面）；取值 \"idle\"/\"working\"/\"waiting\"/\"unknown\"、get_state、condition 与 null 保留原文"), enumValues: ["idle", "working", "waiting", "unknown"])),
                ("condition", nullableString(NSLocalizedString("Plain-English condition to watch for, judged by an AI reading the session's screen, e.g. \u{201C}emacs has exited and a shell prompt is showing\u{201D}. Describe what will be VISIBLE on screen when the condition holds. Mutually exclusive with target_state: set exactly one and null the other.", tableName: "ClaudeCodeXC", comment: "condition 参数描述（两表面共用）；示例条件与 target_state、null 保留原文"))),
            ] + (CompanionPushRegistry.devicePaired ? [
                ("notify_user", nullableBoolean(NSLocalizedString("Set true when the user asked to be told/alerted when this happens. iTerm2 sends a push notification to their iPhone automatically when the watch fires; you do not need to call notify yourself. Use null when not requested.", tableName: "ClaudeCodeXC", comment: "notify_user 参数描述（两表面共用）；null 与 notify 保留原文"))),
            ] : []), required: ["session_guid", "target_state", "condition"] + (CompanionPushRegistry.devicePaired ? ["notify_user"] : []))),

        // unregister_watch / list_watches are identical across the orchestration
        // and session-bound surfaces, so they live in one place and are reused by
        // both (see sessionBoundWatchToolDefinitions).
        unregisterWatchDefinition,
        listWatchesDefinition,

        // -------- Companion phone --------

        // The push tools are conditionally offered (see
        // OrchestrationToolProvider's filter): notify whenever a companion
        // phone is paired, request_notification_permission only while a
        // phone is connected but cannot yet receive pushes.
        ToolDefinition(
            name: ToolName.notify.rawValue,
            description: NSLocalizedString("Send a push notification to the user's iPhone (their paired iTerm2 companion device). Use it to alert the user to something that needs their attention when they may be away from the Mac: a long-running task finished, a session is waiting on input, or an error needs their decision. Keep it brief; it renders as a standard iOS notification. Do not use it for routine progress updates. If it fails because notifications aren't enabled, call request_notification_permission first.",
                            tableName: "ClaudeCodeXC",
                            comment: "notify 工具描述；request_notification_permission 保留原文"),
            inputSchema: object([
                ("title", string(NSLocalizedString("Short notification title, a few words.", tableName: "ClaudeCodeXC", comment: "notify title 参数描述"))),
                ("body", string(NSLocalizedString("Notification body, one or two sentences.", tableName: "ClaudeCodeXC", comment: "notify body 参数描述"))),
            ], required: ["title", "body"])),

        ToolDefinition(
            name: ToolName.requestNotificationPermission.rawValue,
            description: NSLocalizedString("Ask the user, on their paired iPhone, for permission to receive notifications. Call this before the first notify when the user asks to be alerted about something (e.g. \u{201C}let me know when my job finishes\u{201D}) and notifications aren't enabled yet. iOS shows its standard permission dialog on the phone; this returns the outcome. If the user previously declined, the dialog cannot be shown again and they must enable notifications in iOS Settings, which the result will say. This is a valuable feature that users won't discover on their own, so offer this when they ask to be notified (for example, if you create a watcher, you should probably request notification permission). If the result is a decline, accept it: do not call this again or lobby the user about Settings unless they bring it up.",
                            tableName: "ClaudeCodeXC",
                            comment: "request_notification_permission 工具描述；notify、iOS Settings 保留原文"),
            inputSchema: emptyObjectSchema),
    ] }

    // The unregister_watch / list_watches definitions, shared verbatim by the
    // orchestration surface (allToolDefinitions) and the session-bound surface
    // (sessionBoundWatchToolDefinitions) so the two can't drift.
    static var unregisterWatchDefinition: ToolDefinition {
        ToolDefinition(
            name: ToolName.unregisterWatch.rawValue,
            description: NSLocalizedString("Cancel a registered watcher by its watcher_id (from register_watch or list_watches). No-op if the watcher has already fired or doesn't exist.",
                            tableName: "ClaudeCodeXC",
                            comment: "unregister_watch 工具描述；watcher_id、register_watch、list_watches 保留原文"),
            inputSchema: object([
                ("watcher_id", stringSchema),
            ], required: ["watcher_id"]))
    }

    static var listWatchesDefinition: ToolDefinition {
        ToolDefinition(
            name: ToolName.listWatches.rawValue,
            description: NSLocalizedString("List every async watcher currently registered for this chat.",
                            tableName: "ClaudeCodeXC",
                            comment: "list_watches 工具描述"),
            inputSchema: emptyObjectSchema)
    }

    // The watch tools offered to a session-bound chat (one linked terminal
    // session). unregister_watch / list_watches are the shared definitions; the
    // register_watch description is built from the shared spine
    // (registerWatchDescription) with four session-bound parts: it takes NO
    // session_guid (the target is the chat's linked session, filled in by the
    // dispatcher), its blocking clause notes the one-time Ask consent wait, its
    // form-choice paragraph drops the orchestration-only vocabulary
    // (list_workgroups, status_source), and its persistence clause matches the
    // lazy re-arm. request_notification_permission is offered separately by the
    // provider (it filters on companion state and reuses the shared definition).
    static var sessionBoundWatchToolDefinitions: [ToolDefinition] { [
        ToolDefinition(
            name: ToolName.registerWatch.rawValue,
            description: registerWatchDescription(
                target: NSLocalizedString("the terminal session this chat is linked to", tableName: "ClaudeCodeXC", comment: "register_watch 目标（session-bound 表面）"),
                blocking: NSLocalizedString("This normally returns immediately and does NOT block your turn; the one exception is a screen-reading watch on a session whose View Contents permission is set to Ask, where it first asks the user to approve repeated screen reads and waits for that answer before returning.",
                              tableName: "ClaudeCodeXC",
                              comment: "register_watch 阻塞说明（session-bound 表面）；View Contents 与 Ask 为权限名，保留原文"),
                formChoice: NSLocalizedString("Choosing the form: use target_state (idle/working/waiting) to fire when the running program reports that transition. Use condition, a plain-English description an AI judge evaluates by periodically reading the session's screen, when what you're waiting for isn't an idle/working/waiting transition (e.g. \u{201C}emacs has exited and a shell prompt is showing\u{201D}, \u{201C}the build printed a success or failure line\u{201D}, \u{201C}a password prompt appeared\u{201D}); a specific condition is more accurate for those. Screen-judged watches keep watching on their own, polling less often the longer they run, and only time out (reason=\u{201C}watchTimedOut\u{201D}) after several hours; re-register then if you still need to wait.",
                              tableName: "ClaudeCodeXC",
                              comment: "register_watch 形式选择段落（session-bound 表面）；target_state、condition、reason=\"watchTimedOut\" 及取值/示例保留原文"),
                persistence: NSLocalizedString("Watchers are saved across iTerm2 restarts and resume when you next return to this chat (if the linked session no longer exists then, you get a status_update with reason=\u{201C}watcherDropped\u{201D}). Do NOT poll yourself.",
                              tableName: "ClaudeCodeXC",
                              comment: "register_watch 持久化段落（session-bound 表面）；status_update、reason=\"watcherDropped\" 保留原文")),
            inputSchema: object([
                ("target_state", nullableString(NSLocalizedString("State to watch for. Must be a transition target: \u{201C}idle\u{201D}, \u{201C}working\u{201D}, or \u{201C}waiting\u{201D}. Mutually exclusive with condition: set exactly one and null the other.", tableName: "ClaudeCodeXC", comment: "target_state 参数描述（session-bound 表面）；取值 \"idle\"/\"working\"/\"waiting\"、condition 与 null 保留原文"), enumValues: ["idle", "working", "waiting"])),
                ("condition", nullableString(NSLocalizedString("Plain-English condition to watch for, judged by an AI reading the session's screen, e.g. \u{201C}emacs has exited and a shell prompt is showing\u{201D}. Describe what will be VISIBLE on screen when the condition holds. Mutually exclusive with target_state: set exactly one and null the other.", tableName: "ClaudeCodeXC", comment: "condition 参数描述（两表面共用）；示例条件与 target_state、null 保留原文"))),
            ] + (CompanionPushRegistry.devicePaired ? [
                ("notify_user", nullableBoolean(NSLocalizedString("Set true when the user asked to be told/alerted when this happens. iTerm2 sends a push notification to their iPhone automatically when the watch fires; you do not need to call notify yourself. Use null when not requested.", tableName: "ClaudeCodeXC", comment: "notify_user 参数描述（两表面共用）；null 与 notify 保留原文"))),
            ] : []), required: ["target_state", "condition"] + (CompanionPushRegistry.devicePaired ? ["notify_user"] : []))),

        unregisterWatchDefinition,
        listWatchesDefinition,
    ] }
}
