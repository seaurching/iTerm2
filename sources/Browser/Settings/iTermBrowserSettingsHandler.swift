//
//  iTermBrowserSettingsHandler.swift
//  iTerm2
//
//  Created by George Nachman on 6/18/25.
//

import Foundation
@preconcurrency import WebKit
import WebExtensionsFramework
import AppKit

@available(macOS 11.0, *)
protocol iTermBrowserSettingsHandlerDelegate: AnyObject {
    @MainActor func settingsHandlerDidUpdateAdblockSettings(_ handler: iTermBrowserSettingsHandler)
    @MainActor func settingsHandlerDidRequestAdblockUpdate(_ handler: iTermBrowserSettingsHandler)
    @MainActor func settingsHandlerWebView(_ handler: iTermBrowserSettingsHandler) -> iTermBrowserWebView?
    @MainActor func settingsHandlerExtensionManager(_ handler: iTermBrowserSettingsHandler) -> iTermBrowserExtensionManagerProtocol?
}

@available(macOS 11.0, *)
@objc(iTermBrowserSettingsHandler)
@MainActor
class iTermBrowserSettingsHandler: NSObject, iTermBrowserPageHandler {
    static let settingsURL = URL(string: "\(iTermBrowserSchemes.about):settings")!
    weak var delegate: iTermBrowserSettingsHandlerDelegate?
    private let secret: String
    private let user: iTermBrowserUser
    
    init(user: iTermBrowserUser) {
        self.user = user
        guard let secret = String.makeSecureHexString() else {
            it_fatalError("Failed to generate secure hex string for settings handler")
        }
        self.secret = secret
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    func generateSettingsHTML() -> String {
        let isDevNull = (user == .devNull)
        
        // Whether to show the extensions row. Only wired up in debug builds; in
        // release builds it is always hidden. Computing the style per config
        // (rather than a ternary on an always-false flag) avoids a
        // "will never be executed" warning on the dead branch in release builds.
#if ITERM_DEBUG
        var showExtensions = false
        if #available(macOS 14, *) {
            showExtensions = true
        }
        let showExtensionsStyle = showExtensions ? "" : "display: none;"
#else
        let showExtensionsStyle = "display: none;"
#endif
        
        let substitutions = ["ADBLOCK_ENABLED": iTermAdvancedSettingsModel.webKitAdblockEnabled() ? "checked" : "",
                             "ADBLOCK_URL": iTermAdvancedSettingsModel.adblockListURL().replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;"),
                             "SECRET": secret,
                             "DEV_NULL_NOTE": isDevNull ? "" : "display: none;",
                             "SHOW_EXTENSIONS": showExtensionsStyle]
        
        return iTermBrowserTemplateLoader.loadTemplate(named: "settings-page",
                                                       type: "html",
                                                       substitutions: substitutions)
    }
    
    func start(urlSchemeTask: WKURLSchemeTask, url: URL) {
        let htmlToServe = generateSettingsHTML()
        
        guard let data = htmlToServe.data(using: .utf8) else {
            urlSchemeTask.didFailWithError(NSError(domain: "iTermBrowserSettingsHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to encode HTML", tableName: "Browser", comment: "编码 HTML 失败")]))
            return
        }
        
        let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8")
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    
    func injectSettingsJavaScript(into webView: iTermBrowserWebView) {
        let confirmClearCookies = NSLocalizedString("This will remove all cookies from all websites. Continue?", tableName: "Browser", comment: "这将删除所有网站的 Cookie。是否继续？")
        let confirmClearAllData = NSLocalizedString("This will remove all browsing data including cookies, cache, and local storage. Continue?", tableName: "Browser", comment: "这将删除所有浏览数据，包括 Cookie、缓存和本地存储。是否继续？")

        // Escape single quotes for JavaScript strings
        let escapedClearCookies = confirmClearCookies.replacingOccurrences(of: "'", with: "\\'")
        let escapedClearAllData = confirmClearAllData.replacingOccurrences(of: "'", with: "\\'")

        let script = """
        // Direct functions that call Swift
        window.clearCookies = function() {
            if (confirm('\(escapedClearCookies)')) {
                window.webkit.messageHandlers['\(iTermBrowserSchemes.about):settings'].postMessage({action: 'clearCookies'});
            }
        };

        window.clearAllData = function() {
            if (confirm('\(escapedClearAllData)')) {
                window.webkit.messageHandlers['\(iTermBrowserSchemes.about):settings'].postMessage({action: 'clearAllData'});
            }
        };

        """

        Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
    }
    
    func handleSettingsMessage(_ message: [String: Any], webView: iTermBrowserWebView) {
        guard let action = message["action"] as? String,
              let sessionSecret = message["sessionSecret"] as? String,
              sessionSecret == secret else {
            RLog("Invalid or missing session secret for settings action")
            return
        }
        
        switch action {
        case "clearCookies":
            clearCookies(webView: webView)
        case "clearAllData":
            clearAllWebsiteData(webView: webView)
        case "setAdblockEnabled":  // webkit
            if let enabled = message["value"] as? Bool {
                setAdblockEnabled(enabled, webView: webView)
            }
        case "setAdblockURL":
            if let url = message["value"] as? String {
                setAdblockURL(url, webView: webView)
            }
        case "setSearchCommand":
            if let url = message["value"] as? String {
                setSearchCommand(url, webView: webView)
            }
        case "setSearchSuggestURL":
            if let url = message["value"] as? String {
                setSearchSuggestURL(url, webView: webView)
            }
        case "forceAdblockUpdate":
            forceAdblockUpdate(webView: webView)
        case "getAdblockSettings":
            sendAdblockSettings(to: webView)
        case "getSearchSettings":
            sendSearchSettings(to: webView)
        case "getAdblockStats":
            sendAdblockStats(to: webView)
        case "setProxyEnabled":
            if let enabled = message["value"] as? Bool {
                setProxyEnabled(enabled, webView: webView)
            }
        case "setProxyHost":
            if let host = message["value"] as? String {
                setProxyHost(host, webView: webView)
            }
        case "setProxyPort":
            if let port = message["value"] as? Int {
                setProxyPort(port, webView: webView)
            }
        case "getProxySettings":
            sendProxySettings(to: webView)
        case "getExtensions":
#if ITERM_DEBUG
            if #available(macOS 14, *) {
                sendExtensions(to: webView)
            }
#endif
        case "setExtensionEnabled":
#if ITERM_DEBUG
            if #available(macOS 14, *) {
                if let extensionId = message["extensionId"] as? String,
                   let enabled = message["enabled"] as? Bool {
                    setExtensionEnabled(extensionId, enabled: enabled, webView: webView)
                }
            }
#endif
        case "revealExtensionsDirectory":
#if ITERM_DEBUG
            if #available(macOS 14, *) {
                revealExtensionsDirectory(webView: webView)
            }
#endif
        case "setLinkOpeningPreference":
            if let preference = message["value"] as? String {
                setLinkOpeningPreference(preference, webView: webView)
            }
        case "getLinkOpeningPreference":
            sendLinkOpeningPreference(to: webView)
        default:
            break
        }
    }
    
    private func clearCookies(webView: iTermBrowserWebView) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookieStore.delete(cookie) {
                    DLog("Cookie deleted")
                }
            }
        }
    }
    
    private func clearAllWebsiteData(webView: iTermBrowserWebView) {
        let websiteDataStore = webView.configuration.websiteDataStore
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        websiteDataStore.removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            let user = self.user
            Task {
                let message: String
                if await BrowserDatabase.instance(for: user)?.erase() == true {
                    message = NSLocalizedString("All website data has been cleared successfully!", tableName: "Browser", comment: "所有网站数据已成功清除！")
                } else {
                    if let url = BrowserDatabaseCollection.url(for: user) {
                        message = String(format: NSLocalizedString("The browser database could not be deleted. It is in %@", tableName: "Browser", comment: "浏览器数据库无法删除。它位于 %@"), url.path)
                    } else {
                        message = NSLocalizedString("The browser database could not be deleted. Your application support folder could not be found.", tableName: "Browser", comment: "浏览器数据库无法删除。找不到您的应用程序支持文件夹。")
                    }
                }
                DispatchQueue.main.async {
                    Task { @MainActor in
                        _ = try? await webView.safelyEvaluateJavaScript(iife("alert('\(message)');"), contentWorld: .page)
                    }
                }
            }
        }
    }
    
    // MARK: - Adblock Settings

    // This is for webkit adblocking
    private func setAdblockEnabled(_ enabled: Bool, webView: iTermBrowserWebView) {
        iTermAdvancedSettingsModel.setWebKitAdblockEnabled(enabled)
        delegate?.settingsHandlerDidUpdateAdblockSettings(self)
        
        RLog("Ad blocking \(enabled ? "enabled" : "disabled")")
        
        let message = enabled ? NSLocalizedString("Ad blocking enabled", tableName: "Browser", comment: "广告拦截已启用") : NSLocalizedString("Ad blocking disabled", tableName: "Browser", comment: "广告拦截已禁用")
        showStatusMessage(message, type: "success", in: webView)
    }
    
    private func setAdblockURL(_ url: String, webView: iTermBrowserWebView) {
        guard !url.isEmpty else { return }
        
        iTermAdvancedSettingsModel.setAdblockListURL(url)
        delegate?.settingsHandlerDidUpdateAdblockSettings(self)
        
        DLog("Ad block URL updated to: \(url)")
        showStatusMessage(NSLocalizedString("Filter list URL updated", tableName: "Browser", comment: "过滤列表 URL 已更新"), type: "success", in: webView)
    }
    
    private func forceAdblockUpdate(webView: iTermBrowserWebView) {
        delegate?.settingsHandlerDidRequestAdblockUpdate(self)
        RLog("Force update of ad block rules requested")
    }
    
    private func sendAdblockSettings(to webView: iTermBrowserWebView) {
        let enabled = iTermAdvancedSettingsModel.webKitAdblockEnabled()
        let url = iTermAdvancedSettingsModel.adblockListURL() ?? ""
        
        let settings = [
            "enabled": enabled,
            "url": url
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            let script = "updateAdblockUI(\(jsonString));"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
        } catch {
            RLog("Failed to encode adblock settings: \(error)")
        }
    }
    
    private func sendAdblockStats(to webView: iTermBrowserWebView) {
        let ruleCount = iTermBrowserAdblockManager.shared.getRuleCount()
        let lastUpdate = iTermUserDefaults.userDefaults().object(forKey: "NoSyncAdblockLastUpdate") as? Date
        
        let stats = [
            "ruleCount": ruleCount,
            "lastUpdate": lastUpdate?.timeIntervalSince1970 ?? 0
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: stats)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            let script = "updateAdblockStats(\(jsonString));"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
        } catch {
            DLog("Failed to encode adblock stats: \(error)")
        }
    }
    
    private func showStatusMessage(_ message: String, type: String, in webView: iTermBrowserWebView) {
        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
        let script = "showStatus('\(escapedMessage)', '\(type)');"
        Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
    }
    
    @objc func showAdblockUpdateSuccess(in webView: iTermBrowserWebView) {
        showStatusMessage(NSLocalizedString("Ad block rules updated successfully", tableName: "Browser", comment: "广告拦截规则更新成功"), type: "success", in: webView)
    }

    @objc func showAdblockUpdateError(_ error: String, in webView: iTermBrowserWebView) {
        showStatusMessage(String(format: NSLocalizedString("Failed to update ad block rules: %@", tableName: "Browser", comment: "更新广告拦截规则失败：%@"), error), type: "error", in: webView)
    }
    
    // MARK: - Search Settings
    
    private func setSearchCommand(_ url: String, webView: iTermBrowserWebView) {
        guard !url.isEmpty, url.contains("%@") else {
            showStatusMessage(NSLocalizedString("Invalid search URL: must contain %@ placeholder", tableName: "Browser", comment: "无效的搜索 URL：必须包含 %@ 占位符"), type: "error", in: webView)
            return
        }

        iTermAdvancedSettingsModel.setSearchCommand(url)
        DLog("Search command updated to: \(url)")
        showStatusMessage(NSLocalizedString("Search engine updated", tableName: "Browser", comment: "搜索引擎已更新"), type: "success", in: webView)
    }

    private func setSearchSuggestURL(_ url: String, webView: iTermBrowserWebView) {
        if !url.isEmpty && !url.contains("%@") {
            showStatusMessage(NSLocalizedString("Invalid suggestion URL: must contain %@ placeholder", tableName: "Browser", comment: "无效的建议 URL：必须包含 %@ 占位符"), type: "error", in: webView)
            return
        }

        iTermAdvancedSettingsModel.setSearchSuggestURL(url)
        DLog("Search suggestion URL updated to: \(url.isEmpty ? "disabled" : url)")
        if url.isEmpty {
            showStatusMessage(NSLocalizedString("Search suggestions disabled", tableName: "Browser", comment: "搜索建议已禁用"), type: "success", in: webView)
        } else {
            showStatusMessage(NSLocalizedString("Search suggestions updated", tableName: "Browser", comment: "搜索建议已更新"), type: "success", in: webView)
        }
    }
    
    private func sendSearchSettings(to webView: iTermBrowserWebView) {
        let searchCommand = iTermAdvancedSettingsModel.searchCommand()!
        let searchSuggestURL = iTermAdvancedSettingsModel.searchSuggestURL()!
        
        let settings = [
            "searchCommand": searchCommand,
            "searchSuggestURL": searchSuggestURL
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            let script = "updateSearchEngineUI(\(jsonString));"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
        } catch {
            DLog("Failed to encode search settings: \(error)")
        }
    }
    
    // MARK: - Proxy Settings
    
    private func setProxyEnabled(_ enabled: Bool, webView: iTermBrowserWebView) {
        iTermAdvancedSettingsModel.setBrowserProxyEnabled(enabled)
        
        RLog("Browser proxy \(enabled ? "enabled" : "disabled")")
        
        let message = enabled ? NSLocalizedString("Proxy enabled", tableName: "Browser", comment: "代理已启用") : NSLocalizedString("Proxy disabled", tableName: "Browser", comment: "代理已禁用")
        showStatusMessage(message, type: "success", in: webView)
        
        // Notify delegate to reconfigure webview if needed
        delegate?.settingsHandlerDidUpdateAdblockSettings(self)
    }
    
    private func setProxyHost(_ host: String, webView: iTermBrowserWebView) {
        guard !host.isEmpty else { return }
        
        iTermAdvancedSettingsModel.setBrowserProxyHost(host)
        
        DLog("Browser proxy host updated to: \(host)")
        showStatusMessage(NSLocalizedString("Proxy host updated", tableName: "Browser", comment: "代理主机已更新"), type: "success", in: webView)
        
        // Notify delegate to reconfigure webview if needed
        delegate?.settingsHandlerDidUpdateAdblockSettings(self)
    }
    
    private func setProxyPort(_ port: Int, webView: iTermBrowserWebView) {
        guard port >= 1 && port <= 65535 else {
            showStatusMessage(NSLocalizedString("Invalid port number", tableName: "Browser", comment: "无效的端口号"), type: "error", in: webView)
            return
        }
        
        iTermAdvancedSettingsModel.setBrowserProxyPort(Int32(port))
        
        DLog("Browser proxy port updated to: \(port)")
        showStatusMessage(NSLocalizedString("Proxy port updated", tableName: "Browser", comment: "代理端口已更新"), type: "success", in: webView)
        
        // Notify delegate to reconfigure webview if needed
        delegate?.settingsHandlerDidUpdateAdblockSettings(self)
    }
    
    private func sendProxySettings(to webView: iTermBrowserWebView) {
        let enabled = iTermAdvancedSettingsModel.browserProxyEnabled()
        let host = iTermAdvancedSettingsModel.browserProxyHost() ?? "127.0.0.1"
        let port = iTermAdvancedSettingsModel.browserProxyPort()
        
        let settings = [
            "enabled": enabled,
            "host": host,
            "port": port
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            let script = "updateProxyUI(\(jsonString));"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
        } catch {
            DLog("Failed to encode proxy settings: \(error)")
        }
    }
    
    // MARK: - Extension Settings
    
    private func sendExtensions(to webView: iTermBrowserWebView) {
        if #available(macOS 14, *) {
            sendExtensionsForMacOS14(to: webView)
        } else {
            // Extensions not supported on macOS < 14
            let script = "updateExtensionsUI([]);"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
        }
    }
    
    @available(macOS 14, *)
    private func sendExtensionsForMacOS14(to webView: iTermBrowserWebView) {
        guard let extensionManager = delegate?.settingsHandlerExtensionManager(self) else {
            // Send empty array if extension manager is not available
            let script = "updateExtensionsUI([]);"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(iife(script), contentWorld: .page)
        }
            return
        }
        
        let availableExtensions = extensionManager.availableExtensions
        
        let extensionsData = availableExtensions.map { browserExtension in
            let manifest = browserExtension.manifest
            return [
                "id": browserExtension.id.stringValue,
                "name": manifest.name,
                "description": manifest.description ?? NSLocalizedString("No description available", tableName: "Browser", comment: "无可用描述"),
                "version": manifest.version,
                "permissions": manifest.permissions ?? [],
                "hostPermissions": manifest.hostPermissions ?? [],
                "enabled": extensionManager.extensionEnabled(id: browserExtension.id)
            ] as [String: Any]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: extensionsData)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            let script = "updateExtensionsUI(\(jsonString));"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(script, contentWorld: .page)
        }
        } catch {
            DLog("Failed to encode extensions data: \(error)")
            let script = "updateExtensionsUI([]);"
            Task { @MainActor in
            _ = try? await webView.safelyEvaluateJavaScript(script, contentWorld: .page)
        }
        }
    }
    
    private func setExtensionEnabled(_ extensionIdString: String, enabled: Bool, webView: iTermBrowserWebView) {
        if #available(macOS 14, *) {
            setExtensionEnabledForMacOS14(extensionIdString, enabled: enabled, webView: webView)
        } else {
            showStatusMessage(NSLocalizedString("Extensions not supported on this macOS version", tableName: "Browser", comment: "此 macOS 版本不支持扩展"), type: "error", in: webView)
        }
    }

    @available(macOS 14, *)
    private func setExtensionEnabledForMacOS14(_ extensionIdString: String, enabled: Bool, webView: iTermBrowserWebView) {
        guard let extensionManager = delegate?.settingsHandlerExtensionManager(self) else {
            showStatusMessage(NSLocalizedString("Extension management not available", tableName: "Browser", comment: "扩展管理不可用"), type: "error", in: webView)
            return
        }

        let extensionId = ExtensionID(stringValue: extensionIdString)
        extensionManager.set(id: extensionId, enabled: enabled)

        RLog("Extension \(extensionIdString) \(enabled ? "enabled" : "disabled")")

        let message = enabled ? NSLocalizedString("Extension enabled", tableName: "Browser", comment: "扩展已启用") : NSLocalizedString("Extension disabled", tableName: "Browser", comment: "扩展已禁用")
        showStatusMessage(message, type: "success", in: webView)

        // Note: Extensions list will be automatically refreshed via delegate callback
        // when the profile observer detects the change
    }

    private func revealExtensionsDirectory(webView: iTermBrowserWebView) {
        if #available(macOS 14, *) {
            revealExtensionsDirectoryForMacOS14(webView: webView)
        } else {
            showStatusMessage(NSLocalizedString("Extensions not supported on this macOS version", tableName: "Browser", comment: "此 macOS 版本不支持扩展"), type: "error", in: webView)
        }
    }

    @available(macOS 14, *)
    private func revealExtensionsDirectoryForMacOS14(webView: iTermBrowserWebView) {
        guard let extensionManager = delegate?.settingsHandlerExtensionManager(self) else {
            showStatusMessage(NSLocalizedString("Extension management not available", tableName: "Browser", comment: "扩展管理不可用"), type: "error", in: webView)
            return
        }

        // Get the extensions directory from the extension manager
        guard let extensionsURL = extensionManager.extensionsDirectory else {
            showStatusMessage(NSLocalizedString("Extensions directory not configured in profile preferences", tableName: "Browser", comment: "个人资料偏好设置中未配置扩展目录"), type: "error", in: webView)
            return
        }
        
        // Create the directory if it doesn't exist
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: extensionsURL, withIntermediateDirectories: true, attributes: nil)
            
            // Reveal in Finder
            NSWorkspace.shared.activateFileViewerSelecting([extensionsURL])
            
            DLog("Revealed extensions directory in Finder: \(extensionsURL.path)")
            showStatusMessage(NSLocalizedString("Extensions directory revealed in Finder", tableName: "Browser", comment: "已在 Finder 中显示扩展目录"), type: "success", in: webView)

        } catch {
            DLog("Failed to create or reveal extensions directory: \(error)")
            showStatusMessage(String(format: NSLocalizedString("Failed to create extensions directory: %@", tableName: "Browser", comment: "创建扩展目录失败：%@"), error.localizedDescription), type: "error", in: webView)
        }
    }
    
    // MARK: - Link Opening Preference

    private func setLinkOpeningPreference(_ preference: String, webView: iTermBrowserWebView) {
        let identifier = "NoSyncOpenLinksInApp"

        switch preference {
        case "ask":
            // Unsilence the warning to allow the prompt to show again
            iTermWarning.unsilenceIdentifier(identifier)
            showStatusMessage(NSLocalizedString("Link opening preference set to always ask", tableName: "Browser", comment: "链接打开首选项已设为始终询问"), type: "success", in: webView)

        case "builtin":
            // Set permanent selection to "Open in iTerm2" (selection 1)
            iTermWarning.setIdentifier(identifier, permanentSelection: .kiTermWarningSelection1)
            showStatusMessage(NSLocalizedString("Links will always open in built-in browser", tableName: "Browser", comment: "链接将始终在内置浏览器中打开"), type: "success", in: webView)

        case "default":
            // Set permanent selection to "Use Default Browser" (selection 0)
            iTermWarning.setIdentifier(identifier, permanentSelection: .kiTermWarningSelection0)
            showStatusMessage(NSLocalizedString("Links will always open in default browser", tableName: "Browser", comment: "链接将始终在默认浏览器中打开"), type: "success", in: webView)

        default:
            showStatusMessage(NSLocalizedString("Invalid link opening preference", tableName: "Browser", comment: "无效的链接打开首选项"), type: "error", in: webView)
            return
        }

        RLog("Link opening preference updated to: \(preference)")
    }

    private func sendLinkOpeningPreference(to webView: iTermBrowserWebView) {
        let identifier = "NoSyncOpenLinksInApp"

        var preference = "ask"
        if let savedSelection = iTermWarning.conditionalSavedSelection(forIdentifier: identifier) {
            switch iTermWarningSelection(rawValue: savedSelection.intValue) {
            case .kiTermWarningSelection0:
                preference = "default"
            case .kiTermWarningSelection1:
                preference = "builtin"
            default:
                preference = "ask"
            }
        }

        let settings = ["preference": preference]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: settings)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            let script = "updateLinkOpeningUI(\(jsonString));"
            Task { @MainActor in
                _ = try? await webView.safelyEvaluateJavaScript(script, contentWorld: .page)
            }
        } catch {
            DLog("Failed to encode link opening preference: \(error)")
        }
    }

    // MARK: - iTermBrowserPageHandler Protocol

    func injectJavaScript(into webView: iTermBrowserWebView) {
        injectSettingsJavaScript(into: webView)
    }

    func resetState() {
        // Settings handler doesn't maintain state that needs resetting
    }
}

// MARK: - iTermBrowserExtensionManagerDelegate

@available(macOS 11.0, *)
extension iTermBrowserSettingsHandler: iTermBrowserExtensionManagerDelegate {
    func extensionManagerDidUpdateExtensions(_ manager: iTermBrowserExtensionManagerProtocol) {
        // Refresh the extensions list in the settings UI
        guard let webView = delegate?.settingsHandlerWebView(self) else { return }
        sendExtensions(to: webView)
    }
}
