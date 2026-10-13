//
//  ChatWindowController.swift
//  iTerm2
//
//  Created by George Nachman on 2/10/25.
//

import AppKit

@objc public class ChatErrorObjc: NSObject {
    @objc static let domain = "com.iterm2.chat"
    @objc(iTermChatErrorType) public enum ErrorType: Int {
        case chatNotFound

        var localizedDescription: String {
            switch self {
            case .chatNotFound:
                NSLocalizedString("The messages for this chat could not be loaded.", tableName: "AITermXC", comment: "无法加载此对话的消息。")
            }
        }

        var error: ChatError {
            ChatError(self)
        }
    }
}

public typealias ChatErrorType = ChatErrorObjc.ErrorType

public struct ChatError: LocalizedError, CustomStringConvertible, CustomNSError {
    public internal(set) var type: ChatErrorType

    public init(_ type: ChatErrorType) {
        self.type = type
    }

    public var errorDescription: String? {
        type.localizedDescription
    }

    public var description: String {
        type.localizedDescription
    }

    var localizedDescription: String {
        type.localizedDescription
    }

    public static var errorDomain: String { ChatErrorObjc.domain }
    public var errorCode: Int { type.rawValue }
}

protocol DictionaryCodable: Codable {
    init?(dictionaryValue: NSDictionary)
    var dictionaryValue: NSDictionary { get }
}

extension DictionaryCodable {
    init?(dictionaryValue dictionary: NSDictionary) {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = decoded
    }

    var dictionaryValue: NSDictionary {
        guard let data = try? JSONEncoder().encode(self),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = jsonObject as? NSDictionary else {
            return [:]
        }
        return dictionary
    }
}

extension NSToolbarItem.Identifier {
    static let toggleChatList = NSToolbarItem.Identifier("ToggleChatList")
    static let providerSelector = NSToolbarItem.Identifier("ProviderSelector")
    static let modelSelector = NSToolbarItem.Identifier("ModelSelector")
    static let reasoningEffortSelector = NSToolbarItem.Identifier("ReasoningEffortSelector")
    static let serviceTierSelector = NSToolbarItem.Identifier("ServiceTierSelector")
    static let thinkingToggle = NSToolbarItem.Identifier("ThinkingToggle")
    static let webSearchToggle = NSToolbarItem.Identifier("WebSearchToggle")
    static let sessionButton = NSToolbarItem.Identifier("SessionButton")
}

@objc(iTermChatWindowController)
final class ChatWindowController: NSWindowController, DictionaryCodable {
    private static var _instance: ChatWindowController?
    @objc(instanceShowingErrors:) static func instance(showErrors: Bool) -> ChatWindowController? {
        if _instance == nil,
           let model = ChatListModel.instance,
           let client = ChatClient.instance {
            _instance = ChatWindowController(model: model,
                                             client: client)
        } else if showErrors && _instance == nil {
            iTermWarning.show(withTitle: NSLocalizedString("AI Chat could not open because of a problem loading the database. Verify there is only one instance of iTerm2 running.", tableName: "AITermXC", comment: "AI 对话无法打开"),
                              actions: [NSLocalizedString("OK", tableName: "AITermXC", comment: "好")],
                              accessory: nil,
                              identifier: nil,
                              silenceable: .kiTermWarningTypePersistent,
                              heading: NSLocalizedString("Error", tableName: "AITermXC", comment: "错误"),
                              window: nil)
        }
        return _instance
    }
    @objc static var instanceIfExists: ChatWindowController? {
        _instance
    }
    private let chatViewController: ChatViewController
    private let chatListViewController = ChatListViewController()
    private var splitViewController: ChatSplitViewController!
    private let model: ChatListModel
    private let client: ChatClient

    private enum CodingKeys: String, CodingKey {
        case chatID
    }

    init(model: ChatListModel, client: ChatClient) {
        chatViewController = ChatViewController(listModel: model,
                                                client: client)
        self.model = model
        self.client = client
        super.init(window: nil)
        chatListViewController.dataSource = model

        // The window's own delete flow clears the conversation view itself,
        // but a chat can also be deleted out from under us (the companion
        // phone today; anything else tomorrow). Without this the view keeps
        // showing, and interacting with, a chat that no longer exists.
        NotificationCenter.default.addObserver(
            forName: ChatListModel.chatWasDeleted,
            object: nil,
            queue: .main) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self,
                          let deletedID = notification.userInfo?[ChatListModel.chatIDUserInfoKey] as? String,
                          self.chatViewController.chatID == deletedID else {
                        return
                    }
                    RLog("Displayed chat \(deletedID) was deleted externally; clearing the view")
                    self.chatViewController.load(chatID: nil)
                }
            }
    }

    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chatID = try container.decode(String.self, forKey: .chatID)
        guard let model = ChatListModel.instance,
              let client = ChatClient.instance else {
            throw AIError(NSLocalizedString("There was a problem initializing the database", tableName: "AITermXC", comment: "初始化数据库时出现问题"))
        }
        self.init(model: model, client: client)

        select(chatID: chatID)
    }

    required init?(coder: NSCoder) {
        it_fatalError(NSLocalizedString("init(coder:) has not been implemented", tableName: "AITermXC", comment: "init(coder:) 未实现"))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatViewController.chatID, forKey: .chatID)
    }


    // MARK: - Public Interface

    @objc
    func showChatWindow() {
        if !iTermAITermGatekeeper.check() {
            return
        }
        let window = self.window ?? initialize()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        chatViewController.makeMessageInputFieldFirstResponder()
    }

    // True when `binding` (a chat's stored terminal reference, a stableID for
    // new bindings or a legacy guid otherwise) is one of `keys` (a session's
    // {guid, stableID} pair). Matches a binding stored in either form.
    private func terminalBinding(_ binding: String?, matchesReferenceKeys keys: Set<String>) -> Bool {
        guard let binding else {
            return false
        }
        return keys.contains(binding)
    }

    // Resolving convenience for the non-hot callers that only hold a guid.
    private func terminalBinding(_ binding: String?, matchesSessionGuid guid: String) -> Bool {
        return terminalBinding(binding, matchesReferenceKeys: iTermSessionReferenceKeys(forGuid: guid))
    }

    // Called from the draw path (textViewSessionIsStreamingToAIChat), so the
    // caller passes the session's stableID to avoid a session-tree walk here.
    @objc(isStreamingToGuid:stableID:)
    func isStreaming(toGuid guid: String, stableID: String) -> Bool {
        return chatViewController.streaming &&
            terminalBinding(chatViewController.terminalSessionGuid,
                            matchesReferenceKeys: [guid, stableID])
    }

    @objc(stopStreamingSession:)
    func stopStreaming(guid: String) {
        if terminalBinding(chatViewController.terminalSessionGuid, matchesSessionGuid: guid) &&
            chatViewController.streaming {
            chatViewController.stopStreaming()
        }
    }

    private var ageOfMostRecentChat: TimeInterval? {
        guard let chat = chatListViewController.mostRecentChat else {
            return nil
        }
        return -chat.lastModifiedDate.timeIntervalSinceNow
    }


    private var mostRecentChatIsEmpty: Bool {
        guard let chatID = chatListViewController.selectedChatID ?? chatListViewController.mostRecentChat?.id else {
            return false
        }
        guard let messages = model.messages(forChat: chatID, createIfNeeded: false) else {
            return false
        }
        let hasNontrivialMessage = messages.contains { message in
            switch message.content {
            case .plainText, .markdown, .explanationRequest, .explanationResponse,
                    .remoteCommandRequest, .remoteCommandResponse, .selectSessionRequest,
                    .clientLocal, .renameChat, .append, .appendAttachment, .commit,
                    .vectorStoreCreated, .terminalCommand, .multipart, .unsupported:
                true
            case .userCommand, .setPermissions, .watcherEvent:
                false
            }
        }
        return !hasNontrivialMessage
    }

    @objc
    func createNewChatIfNeeded(currentSession: PTYSession?) {
        if model.count == 0 {
            createNewChat(offerGuid: currentSession?.guid)
        } else if let currentSession {
            if chatListViewController.selectMostRecent(forGuid: currentSession.guid) {
                return
            } else {
                createNewChat(offerGuid: currentSession.guid)
            }
        } else if mostRecentChatIsEmpty {
            _ = chatListViewController.selectMostRecent(forGuid: nil)
        } else if let ageOfMostRecentChat, ageOfMostRecentChat < 60 * 5 {
            _ = chatListViewController.selectMostRecent(forGuid: nil)
        } else {
            createNewChat(offerGuid: nil)
        }
    }

    private func initialize() -> NSWindow {
        chatListViewController.dataSource = model
        splitViewController = ChatSplitViewController(chatListViewController: chatListViewController,
                                                      chatViewController: chatViewController)

        // Configure the window with full size content view for transparent toolbar
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Keep a window title for accessibility but hide it visually
        if let chatID = chatViewController.chatID,
           let model = model.chat(id: chatID) {
            window.title = model.title
        } else {
            window.title = NSLocalizedString("AI Chat", tableName: "AITermXC", comment: "AI 对话")
        }

        // Hide the native title
        if #available(macOS 26, *) {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }

        window.minSize = .init(width: 500, height: 500)
        window.isMovableByWindowBackground = true

        self.window = window

        window.contentViewController = splitViewController
        window.center()
        window.setFrameAutosaveName("ChatWindow")

        if #available(macOS 26, *) {
            // On macOS 26, no toolbar - we'll use floating controls
            window.titlebarSeparatorStyle = .none
        } else if #available(macOS 11.0, *) {
            // Use unified compact style for cleaner appearance
            window.toolbarStyle = .unifiedCompact
            // Remove the separator line for seamless blending
            window.titlebarSeparatorStyle = .none

            // Only create toolbar for pre-macOS 26
            let toolbar = NSToolbar(identifier: "MainToolbar")
            toolbar.delegate = self
            toolbar.displayMode = .iconOnly
            window.toolbar = toolbar
            window.toolbar?.isVisible = true
        } else {
            // macOS 10.x
            let toolbar = NSToolbar(identifier: "MainToolbar")
            toolbar.delegate = self
            toolbar.displayMode = .iconOnly
            window.toolbar = toolbar
            window.toolbar?.isVisible = true
        }

        window.minSize = NSSize(width: 400, height: 300)

        chatListViewController.delegate = self
        chatViewController.delegate = self
        window.delegate = self

        // Add floating controls on macOS 26
        if #available(macOS 26, *) {
            chatViewController.setupFloatingControls()
        }

        return window
    }

    func updateTitle(_ title: String) {
        // Update both the window title (for accessibility) and our custom label
        window?.title = title
        chatViewController.chatToolbar.titleLabel.stringValue = title
    }

    private func createNewChat(offerGuid guid: String?, enableOrchestration: Bool = false) {
        do {
            let chatID = try client.create(chatWithTitle: NSLocalizedString("New Chat", tableName: "AITermXC", comment: "新建对话"),
                                           terminalSessionGuid: nil,
                                           browserSessionGuid: nil,
                                           initialMessages: [],
                                           permissions: "")
            chatViewController.load(chatID: chatID)
            chatListViewController.select(chatID: chatID)
            if enableOrchestration {
                // The "try orchestration" entry point: don't just offer it,
                // turn it on so the user lands in an orchestration chat.
                chatViewController.enableOrchestration()
                return
            }
            if let guid, let session = iTermController.sharedInstance().anySession(forReference: guid) {
                let terminal = !session.isBrowserSession()
                let name = session.name
                chatViewController.offerLink(to: guid, terminal: terminal, name: name)
            } else {
                // No session to link to, so offer the alternative:
                // switch the chat into orchestration mode.
                chatViewController.offerOrchestration()
            }
        } catch {
            DLog("\(error)")
        }
    }

    // Open a brand-new chat with orchestration already enabled. The caller is
    // expected to have shown the window first (showChatWindow), which is gated
    // by iTermAITermGatekeeper; if AI is disabled the window never appeared, so
    // bail rather than silently creating a chat behind the warning.
    @objc
    func createNewOrchestrationChat() {
        guard window?.isVisible == true else {
            return
        }
        createNewChat(offerGuid: nil, enableOrchestration: true)
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(closeCurrentSession(_:)) {
            return true
        }
        return false
    }

    @objc(closeCurrentSession:)
    func closeCurrentSession(_ sender: Any) {
        chatViewController.stopStreaming()
        window?.performClose(sender)
    }

    @objc(selectChatWithID:)
    func select(chatID: String) {
        guard model.chat(id: chatID) != nil else {
            return
        }
        chatListViewController.select(chatID: chatID)
        chatViewController.load(chatID: chatID)
    }
}

extension ChatWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        chatViewController.stopStreaming()
    }
}

// MARK: - NSToolbarDelegate

extension ChatWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if #available(macOS 26, *) {
            return []
        } else {
            return [.providerSelector, .modelSelector, .reasoningEffortSelector, .serviceTierSelector,
                    .thinkingToggle, .webSearchToggle, .sessionButton, .toggleChatList]
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if #available(macOS 26, *) {
            return []
        } else {
            return [.providerSelector, .modelSelector, .reasoningEffortSelector, .serviceTierSelector,
                    .thinkingToggle, .webSearchToggle, .sessionButton, .toggleChatList]
        }
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier {
        case .toggleChatList:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = NSLocalizedString("Toggle Chat List", tableName: "AITermXC", comment: "切换对话列表")
            item.paletteLabel = NSLocalizedString("Toggle Chat List", tableName: "AITermXC", comment: "切换对话列表")
            item.toolTip = NSLocalizedString("Show or hide the chat list", tableName: "AITermXC", comment: "显示或隐藏对话列表")
            item.image = NSImage(systemSymbolName: SFSymbol.sidebarLeft.rawValue,
                                 accessibilityDescription: NSLocalizedString("Toggle Chat List", tableName: "AITermXC", comment: "切换对话列表"))
            item.target = self
            item.action = #selector(toggleChatList)
            // Standard toolbar buttons get automatic glass backing on macOS 26
            if #available(macOS 26, *) {
                item.isBordered = true  // Let the system handle the glass effect
            } else if #available(macOS 11.0, *) {
                item.isBordered = true
            }
            return item

        case .providerSelector:
            if let providerSelector = chatViewController.chatToolbar.providerSelectorButton,
               !providerSelector.isHidden {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Provider", tableName: "AITermXC", comment: "提供商")
                item.paletteLabel = NSLocalizedString("AI Provider", tableName: "AITermXC", comment: "AI 提供商")
                item.toolTip = NSLocalizedString("Select AI provider for new chats", tableName: "AITermXC", comment: "为新对话选择 AI 提供商")
                item.view = providerSelector
                return item
            }
            return nil

        case .modelSelector:
            // Only create if we have multiple models
            if let modelSelector = chatViewController.chatToolbar.modelSelectorButton {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Model", tableName: "AITermXC", comment: "模型")
                item.paletteLabel = NSLocalizedString("AI Model", tableName: "AITermXC", comment: "AI 模型")
                item.toolTip = NSLocalizedString("Select AI model", tableName: "AITermXC", comment: "选择 AI 模型")
                item.view = modelSelector
                return item
            }
            return nil

        case .thinkingToggle:
            if let button = chatViewController.chatToolbar.thinkingButton {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Thinking", tableName: "AITermXC", comment: "思考")
                item.paletteLabel = NSLocalizedString("Toggle Thinking", tableName: "AITermXC", comment: "切换思考模式")
                item.toolTip = NSLocalizedString("Enable or disable thinking/reasoning mode", tableName: "AITermXC", comment: "启用或禁用思考/推理模式")
                item.view = button
                return item
            }
            return nil

        case .reasoningEffortSelector:
            if let selector = chatViewController.chatToolbar.reasoningEffortButton,
               !selector.isHidden {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Effort", tableName: "AITermXC", comment: "推理力度")
                item.paletteLabel = NSLocalizedString("Reasoning Effort", tableName: "AITermXC", comment: "推理力度")
                item.toolTip = NSLocalizedString("Select reasoning effort", tableName: "AITermXC", comment: "选择推理力度")
                item.view = selector
                return item
            }
            return nil

        case .serviceTierSelector:
            if let selector = chatViewController.chatToolbar.serviceTierButton,
               !selector.isHidden {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Speed", tableName: "AITermXC", comment: "速度")
                item.paletteLabel = NSLocalizedString("AI Speed", tableName: "AITermXC", comment: "AI 速度")
                item.toolTip = NSLocalizedString("Select AI service tier", tableName: "AITermXC", comment: "选择 AI 服务等级")
                item.view = selector
                return item
            }
            return nil

        case .webSearchToggle:
            if let button = chatViewController.chatToolbar.webSearchButton {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Web Search", tableName: "AITermXC", comment: "网页搜索")
                item.paletteLabel = NSLocalizedString("Toggle Web Search", tableName: "AITermXC", comment: "切换网页搜索")
                item.toolTip = NSLocalizedString("Enable or disable web search", tableName: "AITermXC", comment: "启用或禁用网页搜索")
                item.view = button
                return item
            }
            return nil

        case .sessionButton:
            if let button = chatViewController.chatToolbar.sessionButton {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.label = NSLocalizedString("Session", tableName: "AITermXC", comment: "会话")
                item.paletteLabel = NSLocalizedString("Link Session", tableName: "AITermXC", comment: "链接会话")
                item.toolTip = NSLocalizedString("Link or unlink terminal/browser session", tableName: "AITermXC", comment: "链接或取消链接终端/浏览器会话")
                item.view = button
                return item
            }
            return nil

        default:
            return nil
        }
    }

    private var currentChat: Chat? {
        guard let chatID = chatViewController.chatID else {
            return nil
        }
        return model.chat(id: chatID)
    }

    @objc(setSelectionText:forSession:)
    func setSelectedText(_ text: String, forSession guid: String) {
        if terminalBinding(currentChat?.terminalSessionGuid, matchesSessionGuid: guid) {
            chatViewController.offerSelectedText(text)
        }
    }

    @objc(revealOrCreateChatAboutSessionGuid:name:isTerminal:)
    func revealOrCreateChat(aboutGuid guid: String, name: String, terminal: Bool) {
        if let chat = model.lastChat(guid: guid) {
            chatListViewController.select(chatID: chat.id)
        } else {
            do {
                let chatID = try client.create(chatWithTitle: String(format: NSLocalizedString("Chat about %@", tableName: "AITermXC", comment: "关于 %@ 的对话"), name),
                                               terminalSessionGuid: terminal ? guid : nil,
                                               browserSessionGuid: terminal ? nil : guid,
                                               initialMessages: [],
                                               permissions: "")
                chatViewController.load(chatID: chatID)
                chatListViewController.select(chatID: chatID)
            } catch {
                DLog("\(error)")
            }
        }
    }

    func createChat(name: String,
                    inject: String?,
                    linkToBrowserSessionGuid guid: String) {
        do {
            let chatID = try client.create(chatWithTitle: name,
                                           terminalSessionGuid: nil,
                                           browserSessionGuid: guid,
                                           initialMessages: [],
                                           permissions: "")
            chatViewController.load(chatID: chatID)
            chatListViewController.select(chatID: chatID)
            if let inject {
                chatViewController.attach(filename: name + ".txt",
                                          content: inject.lossyData,
                                          mimeType: "text/plain")
            }
        } catch {
            DLog("\(error)")
        }
    }

    // MARK: - Actions

    @objc func toggleChatList() {
        splitViewController.toggleChatList()
    }

    func updateToolbarItems() {
        guard let toolbar = window?.toolbar else {
            return
        }

        // Update visibility of toolbar items based on current state
        var visibleIdentifiers: [NSToolbarItem.Identifier] = [.toggleChatList, .flexibleSpace]

        if chatViewController.availableProviderOptions.count > 1 {
            visibleIdentifiers.append(.providerSelector)
        }

        // Add model selector if multiple models available
        if chatViewController.availableModels.count > 1 {
            visibleIdentifiers.append(.modelSelector)
        }

        if let provider = chatViewController.provider,
           !provider.model.reasoningEfforts.isEmpty {
            visibleIdentifiers.append(.reasoningEffortSelector)
        }

        if let provider = chatViewController.provider,
           !provider.model.serviceTiers.isEmpty {
            visibleIdentifiers.append(.serviceTierSelector)
        }

        // Add thinking button if supported
        if let provider = chatViewController.provider,
           provider.model.features.contains(.configurableThinking) {
            visibleIdentifiers.append(.thinkingToggle)
        }

        // Add web search if available
        if chatViewController.chatToolbar.webSearchButton != nil {
            visibleIdentifiers.append(.webSearchToggle)
        }

        // Always show session button
        visibleIdentifiers.append(.sessionButton)

        // Validate visible items to update the toolbar
        toolbar.validateVisibleItems()
    }
}

extension ChatWindowController: ChatListViewControllerDelegate {
    func chatListViewControllerDidTapNewChat(_ viewController: ChatListViewController) {
        createNewChat(offerGuid: nil)
    }

    func chatListViewController(_ chatListViewController: ChatListViewController,
                                didSelectChat chatID: String?) {
        chatViewController.load(chatID: chatID)
        // Update window title using our custom method
        updateTitle(chatViewController.chatTitle)
        // Update toolbar items in case model or features changed
        updateToolbarItems()
    }

    func chatListViewController(_ chatListViewController: ChatListViewController,
                                renameChat chatID: String) {
        renameChat(chatID: chatID)
    }

    func chatListViewController(_ chatListViewController: ChatListViewController,
                                deleteChats chatIDs: [String]) {
        let currentChatID = chatViewController.chatID
        deleteChats(chatIDs: chatIDs) { [weak self] in
            guard let self else {
                return
            }
            if let currentChatID,
               chatIDs.contains(currentChatID) {
                if model.count > 0 {
                    let nextChatID = model.chat(at: 0).id
                    chatViewController.load(chatID: nextChatID)
                    chatListViewController.select(chatID: nextChatID)
                } else {
                    chatViewController.load(chatID: nil)
                }
            }
            updateTitle(chatViewController.chatTitle)
            updateToolbarItems()
        }
    }

    private func renameChat(chatID: String) {
        guard let chat = model.chat(id: chatID) else {
            return
        }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Rename Chat", tableName: "AITermXC", comment: "重命名对话")
        alert.informativeText = NSLocalizedString("Choose a new name for this chat.", tableName: "AITermXC", comment: "为此对话选择一个新名称。")
        alert.addButton(withTitle: NSLocalizedString("Rename", tableName: "AITermXC", comment: "重命名"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", tableName: "AITermXC", comment: "取消"))

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = chat.title
        field.selectText(nil)
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        let newTitle = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTitle.isEmpty,
              newTitle != chat.title else {
            return
        }
        do {
            try client.publishMessageFromAgent(chatID: chatID,
                                               content: .renameChat(newTitle))
            if chatViewController.chatID == chatID {
                updateTitle(newTitle)
            }
        } catch {
            DLog("Failed to rename chat \(chatID): \(error)")
            iTermWarning.show(withTitle: NSLocalizedString("The chat could not be renamed.", tableName: "AITermXC", comment: "无法重命名对话。"),
                              actions: [NSLocalizedString("OK", tableName: "AITermXC", comment: "好")],
                              accessory: nil,
                              identifier: nil,
                              silenceable: .kiTermWarningTypePersistent,
                              heading: NSLocalizedString("Rename Failed", tableName: "AITermXC", comment: "重命名失败"),
                              window: window)
        }
    }
}

extension ChatWindowController: ChatSearchResultsViewControllerDelegate {
    func chatSearchResultsDidSelect(_ result: ChatSearchResult) {
        select(chatID: result.chatID)
        chatViewController.reveal(messageID: result.message.uniqueID)
    }
}

extension ChatWindowController: ChatViewControllerDelegate {
    func chatViewController(_ controller: ChatViewController, revealSessionWithGuid guid: String) -> Bool {
        if let session = iTermController.sharedInstance().anySession(forReference: guid) {
            session.reveal()
            return true
        }
        return false
    }

    func chatViewControllerDeleteSession(_ controller: ChatViewController) {
        guard let chatID = controller.chatID else {
            return
        }
        deleteChats(chatIDs: [chatID]) { [weak self] in
            self?.chatViewController.load(chatID: nil)
        }
    }

    fileprivate func deleteChats(chatIDs: [String], completion: (() -> Void)?) {
        let uniqueChatIDs = Array(Set(chatIDs))
        guard !uniqueChatIDs.isEmpty else {
            return
        }
        let warning = iTermWarning()
        let count = uniqueChatIDs.count
        warning.title = count == 1
            ? NSLocalizedString("Are you sure you want to delete this chat? This action cannot be undone.", tableName: "AITermXC", comment: "确定要删除此对话吗？此操作无法撤销。")
            : String(format: NSLocalizedString("Are you sure you want to delete %@ chats? This action cannot be undone.", tableName: "AITermXC", comment: "确定要删除 %@ 个对话吗？此操作无法撤销。"), "\(count)")
        warning.heading = count == 1
            ? NSLocalizedString("Delete Chat?", tableName: "AITermXC", comment: "删除对话？")
            : String(format: NSLocalizedString("Delete %@ Chats?", tableName: "AITermXC", comment: "删除 %@ 个对话？"), "\(count)")

        let action = iTermWarningAction(label: NSLocalizedString("Delete", tableName: "AITermXC", comment: "删除")) { [weak self] _ in
            guard let self else {
                return
            }
            for chatID in uniqueChatIDs {
                do {
                    try client.delete(chatID: chatID)
                } catch {
                    DLog("\(error)")
                }
            }
            completion?()
        }
        action.destructive = true
        warning.warningActions = [ iTermWarningAction(label: NSLocalizedString("Cancel", tableName: "AITermXC", comment: "取消")), action ]
        warning.warningType = .kiTermWarningTypePersistent
        warning.runModal()
    }

    func chatViewControllerDidUpdateToolbar(_ controller: ChatViewController) {
        updateToolbarItems()
    }

    func chatViewController(_ controller: ChatViewController,
                            forkAtMessageID: UUID,
                            ofChat originalChatID: String) {
        guard let listModel = ChatListModel.instance else {
            RLog("No chat list model")
            return
        }
        guard let chat = ChatListModel.instance?.chat(id: originalChatID) else {
            RLog("No chat with id \(originalChatID)")
            return
        }
        guard let index = listModel.index(ofMessageID: forkAtMessageID, inChat: chat.id) else {
            RLog("No such message \(forkAtMessageID) in \(originalChatID)")
            return
        }
        do {
            let allMessages = listModel.messages(forChat: originalChatID, createIfNeeded: false)
            let sourceMessages: [Message] =
                if let allMessages {
                    Array(allMessages[0..<index])
                } else {
                    []
                }
            var initialMessages = [Message]()
            var uuidMap = [UUID: UUID]()
            var messageMap = [UUID: Message]()
            for sourceMessage in sourceMessages {
                if case .renameChat = sourceMessage.content {
                    continue
                }
                let clone = sourceMessage.clone(&uuidMap, messages: messageMap)
                initialMessages.append(clone)
                messageMap[clone.uniqueID] = clone
            }
            let originalTitle = chat.title

            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short

            let now = Date()
            let nowString = formatter.string(from: now)

            var title = originalTitle
            let forkedAt = "(Forked at "
            let desiredSuffix = forkedAt + nowString + ")"
            if let range = title.range(of: forkedAt) {
                title = originalTitle[..<range.lowerBound] + desiredSuffix
            } else {
                title += " " + desiredSuffix
            }
            let chatID = try client.create(chatWithTitle: title,
                                           terminalSessionGuid: chat.terminalSessionGuid,
                                           browserSessionGuid: chat.browserSessionGuid,
                                           initialMessages: initialMessages,
                                           permissions: chat.permissions)
            // The fork inherits the source chat's icon: icon generation
            // only runs when the AI mints a title, and a forked chat is
            // never renamed (its title is set at creation and
            // .renameChat messages are stripped from the clones above),
            // so without this it would show the default icon forever
            // next to its near-identical sibling. setIcon is the single
            // funnel for icon writes; both this and create's insert post
            // their notifications in the same runloop turn, so no
            // default-icon flash is visible. Non-fatal: a failed icon
            // write must not abort loading the freshly forked chat.
            do {
                try listModel.setIcon(chat.icon, forChatID: chatID)
            } catch {
                RLog("Failed to copy icon to forked chat \(chatID): \(error)")
            }

            // Inherit the source chat's blobs for the retained prefix so the fork
            // keeps the prompt cache instead of re-migrating on its first turn. Only
            // when the retained prefix is FULLY linked: the retained messages'
            // firstBlobRefs must equal the source's blob prefix, in order. Any
            // migration-era unlinked round makes it copy nothing and fall back to
            // re-migration (safe) rather than risk a history that does not match the
            // copied blobs. Blobs are copied with fresh blobIDs and the clones'
            // firstBlobRefs are remapped to them (clone() cleared the stale source ref).
            let sourceBlobs = listModel.chatDatabase.blobs(inChat: originalChatID)
            let retainedRefs = sourceMessages.compactMap { $0.firstBlobRef }
            if let retainedBlobs = ChatBlobAssembler.forkBlobPrefix(sourceBlobs: sourceBlobs,
                                                                    retainedBlobRefs: retainedRefs) {
                var blobIDMap = [String: String]()
                for blob in retainedBlobs {
                    let newBlobID = UUID()
                    let copy = ChatBlob(blobID: newBlobID, chatID: chatID,
                                        blobProtocol: blob.blobProtocol, role: blob.role,
                                        payload: blob.payload, responseID: blob.responseID,
                                        tokenCount: blob.tokenCount)
                    if listModel.chatDatabase.appendBlob(copy) != nil {
                        blobIDMap[blob.blobID.uuidString] = newBlobID.uuidString
                    }
                }
                if let blobProtocol = chat.blobProtocol {
                    try? listModel.setBlobProtocol(blobProtocol, forChatID: chatID)
                }
                for sourceMessage in sourceMessages {
                    if let oldRef = sourceMessage.firstBlobRef,
                       let newRef = blobIDMap[oldRef],
                       let newMessageID = uuidMap[sourceMessage.uniqueID] {
                        listModel.setFirstBlobRef(newRef, forMessageID: newMessageID, inChat: chatID)
                    }
                }
            }

            chatViewController.load(chatID: chatID)
            chatListViewController.select(chatID: chatID)

            if let allMessages {
                let userMessage = allMessages[index]
                chatViewController.stage(userMessage)
            }
        } catch {
            DLog("\(error)")
        }
    }
}
