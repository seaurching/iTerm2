//
//  iTermBrowserErrorHandler.swift
//  iTerm2
//
//  Created by George Nachman on 6/18/25.
//

import Foundation
@preconcurrency import WebKit

@available(macOS 11.0, *)
@objc(iTermBrowserErrorHandler)
class iTermBrowserErrorHandler: NSObject, iTermBrowserPageHandler {
    private var pendingErrorHTML: String?
    
    static let errorURL = URL(string: "\(iTermBrowserSchemes.about):error")!
    
    // MARK: - Public Interface
    
    func generateErrorPageHTML(for error: Error, failedURL: URL?) -> String {
        let (title, message) = errorTitleAndMessage(for: error)
        return generateErrorHTML(title: title, message: message, originalURL: failedURL?.absoluteString)
    }
    
    func setPendingErrorHTML(_ html: String) {
        pendingErrorHTML = html
    }
    
    func consumePendingErrorHTML() -> String? {
        let html = pendingErrorHTML
        pendingErrorHTML = nil
        return html
    }
    
    func hasPendingError() -> Bool {
        return pendingErrorHTML != nil
    }
    
    func clearPendingError() {
        pendingErrorHTML = nil
    }
    
    // MARK: - iTermBrowserPageHandler Protocol
    
    func injectJavaScript(into webView: iTermBrowserWebView) {
        // Error pages don't need JavaScript injection
    }
    
    func resetState() {
        clearPendingError()
    }

    func start(urlSchemeTask: WKURLSchemeTask, url: URL) {
        // Serve our error page HTML
        let htmlToServe = consumePendingErrorHTML() ?? generateErrorPageHTML(
            for: NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Page Not Available", tableName: "Browser", comment: "页面不可用")]),
            failedURL: nil
        )

        guard let data = htmlToServe.data(using: .utf8) else {
            urlSchemeTask.didFailWithError(NSError(domain: "iTermBrowserManager", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to encode HTML", tableName: "Browser", comment: "编码 HTML 失败")]))
            return
        }

        let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: "utf-8")
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    // MARK: - Error Page Generation
    
    private func generateErrorHTML(title: String, message: String, originalURL: String?) -> String {
        let urlDisplay = originalURL ?? ""
        let urlDisplayHTML = urlDisplay.isEmpty ? "" : "<div class=\"error-url\">\(urlDisplay)</div>"
        
        let substitutions = [
            "TITLE": title,
            "MESSAGE": message,
            "URL_DISPLAY": urlDisplayHTML,
            "ORIGINAL_URL": originalURL ?? ""
        ]
        
        return iTermBrowserTemplateLoader.loadTemplate(named: "error-page",
                                                       type: "html",
                                                       substitutions: substitutions)
    }
    
    private func errorTitleAndMessage(for error: Error) -> (title: String, message: String) {
        let nsError = error as NSError

        let tuple: (String, String, String?) = {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return (NSLocalizedString("No Internet Connection", tableName: "Browser", comment: "无网络连接"), NSLocalizedString("Your computer appears to be offline. Check your internet connection and try again.", tableName: "Browser", comment: "您的计算机似乎已离线。请检查您的网络连接，然后重试。"), nil)

            case NSURLErrorCannotFindHost:
                return (NSLocalizedString("Server Not Found", tableName: "Browser", comment: "找不到服务器"), NSLocalizedString("iTerm2 can’t find the server. Check that the web address is correct and try again.", tableName: "Browser", comment: "iTerm2 无法找到服务器。请检查网址是否正确，然后重试。"), nil)

            case NSURLErrorTimedOut:
                return (NSLocalizedString("The Connection Timed Out", tableName: "Browser", comment: "连接超时"), NSLocalizedString("The server didn’t respond in time. The site may be temporarily unavailable or overloaded.", tableName: "Browser", comment: "服务器未及时响应。该站点可能暂时不可用或过载。"), nil)

            case NSURLErrorCannotConnectToHost:
                return (NSLocalizedString("Can’t Connect to Server", tableName: "Browser", comment: "无法连接到服务器"), NSLocalizedString("iTerm2 can’t establish a secure connection to the server. The server may be down or unreachable.", tableName: "Browser", comment: "iTerm2 无法与服务器建立安全连接。服务器可能已关闭或无法访问。"), nil)

            case NSURLErrorNetworkConnectionLost:
                return (NSLocalizedString("Network Connection Lost", tableName: "Browser", comment: "网络连接已断开"), NSLocalizedString("The network connection was lost. Check your internet connection and try again.", tableName: "Browser", comment: "网络连接已断开。请检查您的网络连接，然后重试。"), nil)

            case NSURLErrorDNSLookupFailed:
                return (NSLocalizedString("Server Not Found", tableName: "Browser", comment: "找不到服务器"), NSLocalizedString("The server’s DNS address could not be found. Check that the web address is correct.", tableName: "Browser", comment: "无法找到服务器的 DNS 地址。请检查网址是否正确。"), nil)

            case NSURLErrorHTTPTooManyRedirects:
                return (NSLocalizedString("Too Many Redirects", tableName: "Browser", comment: "重定向次数过多"), NSLocalizedString("iTerm2 can’t open the page because the server redirected too many times.", tableName: "Browser", comment: "iTerm2 无法打开该页面，因为服务器重定向次数过多。"), nil)

            case NSURLErrorResourceUnavailable:
                return (NSLocalizedString("Page Unavailable", tableName: "Browser", comment: "页面不可用"), NSLocalizedString("The requested page is currently unavailable. Try again later.", tableName: "Browser", comment: "请求的页面目前不可用。请稍后重试。"), nil)

            case NSURLErrorNotConnectedToInternet:
                return (NSLocalizedString("No Internet Connection", tableName: "Browser", comment: "无网络连接"), NSLocalizedString("Your computer is not connected to the internet. Check your connection and try again.", tableName: "Browser", comment: "您的计算机未连接到互联网。请检查您的连接，然后重试。"), nil)

            case NSURLErrorServerCertificateUntrusted, NSURLErrorSecureConnectionFailed:
                return (NSLocalizedString("Secure Connection Failed", tableName: "Browser", comment: "安全连接失败"), NSLocalizedString("iTerm2 can’t verify the identity of the website. The connection may not be secure.", tableName: "Browser", comment: "iTerm2 无法验证网站的身份。连接可能不安全。"), sslErrorDetails(from: error))

            case NSURLErrorFileDoesNotExist:
                return (NSLocalizedString("File Not Found", tableName: "Browser", comment: "文件未找到"), NSLocalizedString("The requested file does not exist.", tableName: "Browser", comment: "请求的文件不存在。"), nil)

            default:
                return (NSLocalizedString("Page Can’t Be Loaded", tableName: "Browser", comment: "无法加载页面"), String(format: NSLocalizedString("An error occurred while loading this page. %@", tableName: "Browser", comment: "加载此页面时发生错误。%@"), error.localizedDescription), nil)
            }
        }()
        return (title: tuple.0,
                message: "<strong>" + tuple.1 + "</strong><br/><br/>" + (tuple.2 ?? error.localizedDescription))
    }
}

/// Returns a detailed TLS/SSL error message if `error` is an SSL-related NSURLError.
func sslErrorDetails(from error: Error) -> String? {
    let ns = error as NSError
    if ns.domain != NSURLErrorDomain {
        return nil
    }
    // Common TLS/SSL URL error codes
    let sslURLCodes: Set<Int> = [
        URLError.serverCertificateUntrusted.rawValue,
        URLError.serverCertificateHasBadDate.rawValue,
        URLError.serverCertificateHasUnknownRoot.rawValue,
        URLError.serverCertificateNotYetValid.rawValue,
        URLError.clientCertificateRejected.rawValue,
        URLError.clientCertificateRequired.rawValue
    ]
    if !sslURLCodes.contains(ns.code) {
        return nil
    }

    var lines: [String] = []

    if let os = ns.userInfo["_kCFStreamErrorCodeKey"] as? Int,
       let description = sslErrorDescription(for: os) {
        lines.append(description.escapedForHTML)
    }

    // Extract SecTrust safely from userInfo (NSURLErrorFailingURLPeerTrustErrorKey)
    if let trust = secTrust(fromUserInfo: ns.userInfo) {
        // Certificate chain subjects
        let subjects = certificateSubjects(from: trust)
        if !subjects.isEmpty {
            lines.append(NSLocalizedString("Certificate chain:", tableName: "Browser", comment: "证书链："))
            for (idx, s) in subjects.enumerated() {
                lines.append("  [\(idx)] \(s.escapedForHTML)")
            }
        }
    }

    return lines.joined(separator: "<br/>\n")
}

/// Robustly extract SecTrust from NSError.userInfo, handling CF bridging.
private func secTrust(fromUserInfo ui: [String: Any]) -> SecTrust? {
    guard let any = ui[NSURLErrorFailingURLPeerTrustErrorKey] else {
        return nil
    }
    // Work through CFTypeRef to avoid “AnyObject is not convertible to SecTrust”
    let cf = any as CFTypeRef
    if CFGetTypeID(cf) == SecTrustGetTypeID() {
        return (cf as! SecTrust)
    }
    return nil
}

/// Map SecureTransport OSStatus to a readable name and a short hint.
private func sslErrorDescription(for status: Int) -> String? {
    // Subset of the most useful SSL codes you’ll actually see.
    switch OSStatus(status) {
    case errSSLXCertChainInvalid:        return NSLocalizedString("The presented chain is not valid (e.g., self-signed without trust).", tableName: "Browser", comment: "所提供的证书链无效（例如未经信任的自签名证书）。")
    case errSSLUnknownRootCert:          return NSLocalizedString("The root CA is unknown (not in trust store).", tableName: "Browser", comment: "根证书颁发机构未知（不在信任存储中）。")
    case errSSLNoRootCert:               return NSLocalizedString("No root certificate found to anchor the chain.", tableName: "Browser", comment: "未找到可用于锚定证书链的根证书。")
    case errSSLBadCert:                  return NSLocalizedString("The certificate is malformed or otherwise bad.", tableName: "Browser", comment: "证书格式错误或已损坏。")
    case errSSLCertExpired:              return NSLocalizedString("The certificate is expired.", tableName: "Browser", comment: "证书已过期。")
    case errSSLCertNotYetValid:          return NSLocalizedString("The certificate is not yet valid.", tableName: "Browser", comment: "证书尚未生效。")
    case errSSLHostNameMismatch:         return NSLocalizedString("The hostname does not match the certificate.", tableName: "Browser", comment: "主机名与证书不匹配。")
    default:                             return SecCopyErrorMessageString(OSStatus(status), nil) as? String
    }
}

/// Get human-friendly subject summaries for the chain.
private func certificateSubjects(from trust: SecTrust) -> [String] {
    if #available(macOS 10.15, *) {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            return []
        }
        return chain.compactMap { SecCertificateCopySubjectSummary($0) as String? }
    } else {
        var out: [String] = []
        let count = SecTrustGetCertificateCount(trust)
        if count <= 0 {
            return out
        }
        for i in 0..<count {
            if let cert = SecTrustGetCertificateAtIndex(trust, i) {
                if let s = SecCertificateCopySubjectSummary(cert) as String? {
                    out.append(s)
                } else {
                    out.append("(no subject summary)")
                }
            }
        }
        return out
    }
}
