# -*- coding: utf-8 -*-
"""Wrap SSH Swift files and generate 8 locale SSH.strings.

Convention (matches existing PasswordManager code): NSLocalizedString("key", tableName: "SSH", comment: "...")
— no bundle param (defaults to Bundle.main; all SSH files are in the main iTerm2 app target).
Interpolated strings convert to String(format: NSLocalizedString(...), args).

Excluded (NOT ADAPTED):
- SSHIdentity.swift: compactDescription/stringIdentifier used as UserDefaults key suffix; "My Mac" host id.
- protocolName "SSH Integration": feature/protocol name.
- it2DisplayName "ssh " + compactDescription: command prefix + identifier.
- currentOperationDescription: private, unused externally (debug status).
- "unknown_file": filename fallback.
"""
import os, sys

TABLE = 'SSH'
LOCALES = ['Base', 'en', 'zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']
SIMPLE = {'zh_CN', 'zh-Hans', 'zh-Hans-CN'}
TRAD   = {'zh_TW', 'zh-Hant', 'zh-Hant-TW'}
errs = []
total = 0

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def val(key, hans, hant, locale):
    if locale in ('Base', 'en'): return key
    if locale in SIMPLE: return hans
    if locale in TRAD: return hant
    return key

def NL(key, comment):
    # Swift string literal for the key: escape backslash and double-quote, real newlines -> \n
    k = key.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return f'NSLocalizedString("{k}", tableName: "{TABLE}", comment: "{comment}")'

def NLf(key, comment):
    return f'String(format: {NL(key, comment)}'

# ============================================================
# KEYS: (key, hans, hant)
# ============================================================
KEYS = [
    ('Connection closed', '连接已关闭', '連線已關閉'),
    ('File not found', '未找到文件', '找不到檔案'),
    ('Internal error', '内部错误', '內部錯誤'),
    ('File transfer canceled', '文件传输已取消', '檔案傳輸已取消'),
    ('Favorites', '收藏夹', '收藏夾'),
    ('Connected Hosts', '已连接的主机', '已連接的主機'),
    ('Desktop', '桌面', '桌面'),
    ('Documents', '文档', '文件'),
    ('Downloads', '下载', '下載'),
    ('Movies', '影片', '影片'),
    ('Music', '音乐', '音樂'),
    ('Pictures', '图片', '圖片'),
    ('Home', '主目录', '個人目錄'),
    ('Applications', '应用程序', '應用程式'),
    ('Folder', '文件夹', '資料夾'),
    ('Server', '服务器', '伺服器'),
    ('Connected host', '已连接的主机', '已連接的主機'),
    ('Disconnected host', '未连接的主机', '未連接的主機'),
    ('Star', '星标', '星號'),
    ('Go to the folder:', '前往文件夹：', '前往資料夾：'),
    ('Type a pathname or select from the pop-up menu', '输入路径名或从弹出式菜单中选择', '輸入路徑名稱或從彈出式選單中選擇'),
    ('Go', '前往', '前往'),
    ('Enter path (e.g., /usr/local/bin)', '输入路径（例如 /usr/local/bin）', '輸入路徑（例如 /usr/local/bin）'),
    ('Loading completions…', '正在加载补全…', '正在載入補全…'),
    ('Folder on %@', '%@ 上的文件夹', '%@ 上的資料夾'),
    ('Open', '打开', '打開'),
    ('Save As:', '另存为：', '儲存為：'),
    ('Enter filename', '输入文件名', '輸入檔案名稱'),
    ('Back', '返回', '返回'),
    ('Forward', '前进', '前進'),
    ('Search', '搜索', '搜尋'),
    ('Cancel', '取消', '取消'),
    ('Save', '保存', '儲存'),
    ('New Folder', '新建文件夹', '新增資料夾'),
    ('Use System Panel…', '使用系统面板…', '使用系統面板…'),
    ('OK', '确定', '確定'),
    ('Could not save file', '无法保存文件', '無法儲存檔案'),
    ('A file with the name “%@” on %@ already exists in this location. Do you want to replace it?',
     '此位置上已存在名为“%@”的文件（位于 %@）。要替换它吗？',
     '此位置上已存在名為「%@」的檔案（位於 %@）。要取代它嗎？'),
    ('Replacing it will overwrite its current contents.', '替换将覆盖其当前内容。', '取代將覆寫其目前的內容。'),
    ('Replace', '替换', '取代'),
    ('Go to Folder…', '前往文件夹…', '前往資料夾…'),
    ('Go to Home', '前往主目录', '前往個人目錄'),
    ('Go Up', '向上一级', '上一層'),
    ('Refresh', '刷新', '重新整理'),
    ('Show Hidden Files', '显示隐藏文件', '顯示隱藏檔案'),
    ('Name of new folder inside “%@”:',
     '在“%@”内新建文件夹的名称：',
     '在「%@」內新增資料夾的名稱：'),
    ('untitled folder', '未命名文件夹', '未命名資料夾'),
    ('Create', '创建', '建立'),
    ('Unable to create folder', '无法创建文件夹', '無法建立資料夾'),
    ('The connection to %@ was lost.', '与 %@ 的连接已丢失。', '與 %@ 的連線已中斷。'),
    ('iTerm2 SSH Integration Protocol\nUser name: %@")\nHost: %@\nFile: %@"',
     'iTerm2 SSH 集成协议\n用户名：%@")\n主机：%@\n文件：%@"',
     'iTerm2 SSH 整合協定\n使用者名稱：%@")\n主機：%@\n檔案：%@"'),
    ('(unknown)', '(未知)', '(未知)'),
    ('%@ via SSH Integration', '%@ 通过 SSH 集成', '%@ 透過 SSH 整合'),
    ('Unable to find Downloads folder', '无法找到下载文件夹', '找不到下載資料夾'),
    ('Failed to quarantine', '隔离失败', '隔離失敗'),
    ('Could not get attributes of %@', '无法获取 %@ 的属性', '無法取得 %@ 的屬性'),
    ('Could not get size of file: %@', '无法获取文件大小：%@', '無法取得檔案大小：%@'),
    ('No such file: %@', '无此文件：%@', '無此檔案：%@'),
    ('(In memory)', '(内存中)', '(記憶體中)'),
    ('No local path specified', '未指定本地路径', '未指定本機路徑'),
    ('Could not open %@', '无法打开 %@', '無法開啟 %@'),
    ('Streaming downloads do not support folders', '流式下载不支持文件夹', '串流下載不支援資料夾'),
    ('Transfer of directory at %@ not allowed', '不允许传输位于 %@ 的目录', '不允許傳輸位於 %@ 的目錄'),
    ('%@ on %@ is not a regular file', '%@（位于 %@）不是常规文件', '%@（位於 %@）不是一般檔案'),
    ('Canceled', '已取消', '已取消'),
    ('Download ended prematurely (received %@ of %@ byte%@)',
     '下载提前结束（已接收 %@ 字节，应为 %@ 字节%@）',
     '下載提前結束（已接收 %@ 字節，應為 %@ 字節%@）'),
    ('No local filename specified', '未指定本地文件名', '未指定本機檔案名稱'),
    ('Too many iterations to find a valid file name on remote host for upload',
     '上传时在远程主机上查找有效文件名的迭代次数过多',
     '上傳時在遠端主機上尋找有效檔案名稱的疊代次數過多'),
    ('Name', '名称', '名稱'),
    ('Date Created', '创建日期', '建立日期'),
    ('Size', '大小', '大小'),
    ('Kind', '种类', '種類'),
    ('Zero bytes', '零字节', '零位元組'),
    ('%@ image', '%@ 图像', '%@ 影像'),
    ('Text document', '文本文档', '文字文件'),
    ('PDF document', 'PDF 文档', 'PDF 文件'),
    ('Video', '视频', '視訊'),
    ('Audio', '音频', '音訊'),
    ('Archive', '归档', '壓縮檔'),
    ('Lua script', 'Lua 脚本', 'Lua 指令碼'),
    ('Neovim config', 'Neovim 配置', 'Neovim 設定'),
    ('Shell script', 'Shell 脚本', 'Shell 指令碼'),
    ('Objective-C source', 'Objective-C 源代码', 'Objective-C 原始碼'),
    ('Document', '文档', '文件'),
    ('Host', '主机', '主機'),
    ('Alias', '别名', '別名'),
    ('Missing file information', '缺少文件信息', '缺少檔案資訊'),
    ('it2: request too large (over %@ MiB over SSH integration); run it locally instead',
     'it2: 请求过大（超过 %@ MiB 的 SSH 集成）；请在本地运行',
     'it2: 請求過大（超過 %@ MiB 的 SSH 整合）；請在本機執行'),
    ('it2: malformed request', 'it2: 请求格式错误', 'it2: 請求格式錯誤'),
    ('it2: authorization failed', 'it2: 授权失败', 'it2: 授權失敗'),
    ('The iTerm2 Python API is not enabled (Settings > General > Magic).',
     '未启用 iTerm2 Python API（设置 > 通用 > Magic）。',
     '未啟用 iTerm2 Python API（設定 > 一般 > Magic）。'),
    ('Permission denied: iTerm2 API access was not granted for this session.',
     '权限被拒绝：此会话未授予 iTerm2 API 访问权限。',
     '權限被拒絕：此工作階段未授予 iTerm2 API 存取權限。'),
    ('Download %@ or view in browser?', '下载 %@ 还是在浏览器中查看？', '下載 %@ 或在瀏覽器中檢視？'),
    ('Download', '下载', '下載'),
    ('View', '查看', '檢視'),
    ('Download or View File?', '下载还是查看文件？', '下載或檢視檔案？'),
    ('%@: Unepected status %@', '%@：意外的状态 %@', '%@：未預期的狀態 %@'),
    ('Status %@ when running python code', '运行 python 代码时状态为 %@', '執行 python 程式碼時狀態為 %@'),
    ('Unexpected output from %@', '来自 %@ 的意外输出', '來自 %@ 的未預期輸出'),
    ('Invalid process ID from remote: %@', '来自远程的进程 ID 无效：%@', '來自遠端的行程 ID 無效：%@'),
]

# ============================================================
# Wrapping helpers
# ============================================================
def wrap_file(path, replacements):
    """replacements: list of (old, new, label). Applies to file at path."""
    global total
    s = open(path, encoding='utf-8').read()
    n = 0
    for old, new, label in replacements:
        c = s.count(old)
        if c == 0:
            errs.append(f'{path}: NOT FOUND: {label}'); continue
        if c > 1:
            errs.append(f'{path}: AMBIGUOUS ({c}): {label}'); continue
        s = s.replace(old, new)
        n += 1
    open(path, 'w', encoding='utf-8').write(s)
    print(f'{os.path.basename(path)}: {n} replacements')
    total += n

D = 'sources/SSH/'

# ---- SSHEndpointException.swift ----
wrap_file(D + 'SSHEndpointException.swift', [
    ('return "Connection closed"', f'return {NL("Connection closed", "SSH endpoint: connection closed error")}', 'connection closed'),
    ('return "File not found"', f'return {NL("File not found", "SSH endpoint: file not found error")}', 'file not found'),
    ('return "Internal error"', f'return {NL("Internal error", "SSH endpoint: internal error")}', 'internal error'),
    ('return "File transfer canceled"', f'return {NL("File transfer canceled", "SSH endpoint: transfer canceled error")}', 'transfer canceled'),
])

# ---- SSHFilePanelSidebarItem.swift ----
wrap_file(D + 'SSHFilePanelSidebarItem.swift', [
    ('accessibilityDescription: "Connected host",', f'accessibilityDescription: {NL("Connected host", "sidebar item: connected host accessibility")},', 'connected host'),
    ('accessibilityDescription: "Disconnected host",', f'accessibilityDescription: {NL("Disconnected host", "sidebar item: disconnected host accessibility")},', 'disconnected host'),
    ('accessibilityDescription: "Star",', f'accessibilityDescription: {NL("Star", "sidebar item: star accessibility")},', 'star'),
])

# ---- SSHFolderDialog.swift ----
wrap_file(D + 'SSHFolderDialog.swift', [
    ('alert.messageText = "Go to the folder:"', f'alert.messageText = {NL("Go to the folder:", "folder dialog: go to folder message")}', 'go to folder'),
    ('alert.informativeText = "Type a pathname or select from the pop-up menu"', f'alert.informativeText = {NL("Type a pathname or select from the pop-up menu", "folder dialog: informative text")}', 'informative text'),
    ('alert.addButton(withTitle: "Go")', f'alert.addButton(withTitle: {NL("Go", "folder dialog: go button")})', 'go button'),
    ('alert.addButton(withTitle: "Cancel")', f'alert.addButton(withTitle: {NL("Cancel", "folder dialog: cancel button")})', 'cancel button'),
    ('textField.placeholderString = "Enter path (e.g., /usr/local/bin)"', f'textField.placeholderString = {NL("Enter path (e.g., /usr/local/bin)", "folder dialog: path placeholder")}', 'path placeholder'),
    ('placeholder: "Loading completions…",', f'placeholder: {NL("Loading completions…", "folder dialog: loading completions placeholder")},', 'loading completions'),
    ('let detail = "Folder on " + hostname', f'let detail = {NLf("Folder on %@", "folder dialog: completion detail")}, hostname)', 'folder on'),
])

# ---- SSHFilePanelSidebar.swift ----
wrap_file(D + 'SSHFilePanelSidebar.swift', [
    ('return "Favorites"', f'return {NL("Favorites", "sidebar: favorites section title")}', 'favorites'),
    ('return "Connected Hosts"', f'return {NL("Connected Hosts", "sidebar: connected hosts section title")}', 'connected hosts'),
    ('(.desktopDirectory, "Desktop"),', f'(.desktopDirectory, {NL("Desktop", "sidebar: desktop favorite")}),', 'desktop'),
    ('(.documentDirectory, "Documents"),', f'(.documentDirectory, {NL("Documents", "sidebar: documents favorite")}),', 'documents'),
    ('(.downloadsDirectory, "Downloads"),', f'(.downloadsDirectory, {NL("Downloads", "sidebar: downloads favorite")}),', 'downloads'),
    ('(.moviesDirectory, "Movies"),', f'(.moviesDirectory, {NL("Movies", "sidebar: movies favorite")}),', 'movies'),
    ('(.musicDirectory, "Music"),', f'(.musicDirectory, {NL("Music", "sidebar: music favorite")}),', 'music'),
    ('(.picturesDirectory, "Pictures"),', f'(.picturesDirectory, {NL("Pictures", "sidebar: pictures favorite")}),', 'pictures'),
    ('(.userDirectory, "Home")', f'(.userDirectory, {NL("Home", "sidebar: home favorite")})', 'home'),
    ('favorites.append((name: "Applications", url: appsURL))', f'favorites.append((name: {NL("Applications", "sidebar: applications favorite")}, url: appsURL))', 'applications'),
    ('accessibilityDescription: "Folder",\n                        fallbackImageName: "folder",\n                        for: SSHFilePanelSidebar.self)',
     f'accessibilityDescription: {NL("Folder", "sidebar: folder accessibility")},\n                        fallbackImageName: "folder",\n                        for: SSHFilePanelSidebar.self)', 'folder sidebar'),
    ('accessibilityDescription: "Folder",\n                        fallbackImageName: "folder",\n                        for: SSHFilePanel.self)',
     f'accessibilityDescription: {NL("Folder", "sidebar: folder accessibility")},\n                        fallbackImageName: "folder",\n                        for: SSHFilePanel.self)', 'folder panel'),
    ('accessibilityDescription: "Server",', f'accessibilityDescription: {NL("Server", "sidebar: server accessibility")},', 'server'),
])

# ---- SSHFilePanel.swift ----
wrap_file(D + 'SSHFilePanel.swift', [
    ('window?.title = "Open"', f'window?.title = {NL("Open", "file panel: open window title")}', 'window title open'),
    ('NSTextField(labelWithString: "Save As:")', f'NSTextField(labelWithString: {NL("Save As:", "file panel: save as label")})', 'save as label'),
    ('saveAsTextField.placeholderString = "Enter filename"', f'saveAsTextField.placeholderString = {NL("Enter filename", "file panel: filename placeholder")}', 'filename placeholder'),
    ('accessibilityDescription: "Back",\n                                            fallbackImageName: "chevron.left",\n                                            for: SSHFilePanel.self)',
     f'accessibilityDescription: {NL("Back", "file panel: back accessibility")},\n                                            fallbackImageName: "chevron.left",\n                                            for: SSHFilePanel.self)', 'back acc'),
    ('accessibilityDescription: "Forward",\n                                               fallbackImageName: "chevron.right",\n                                               for: SSHFilePanel.self)',
     f'accessibilityDescription: {NL("Forward", "file panel: forward accessibility")},\n                                               fallbackImageName: "chevron.right",\n                                               for: SSHFilePanel.self)', 'forward acc'),
    ('searchField.placeholderString = "Search"', f'searchField.placeholderString = {NL("Search", "file panel: search placeholder")}', 'search placeholder'),
    ('cancelButton.title = "Cancel"', f'cancelButton.title = {NL("Cancel", "file panel: cancel button")}', 'cancel button'),
    ('openButton.title = isSavePanel ? "Save" : "Open"',
     f'openButton.title = isSavePanel ? {NL("Save", "file panel: save button")} : {NL("Open", "file panel: open button")}', 'save/open button'),
    ('newFolderButton.title = "New Folder"', f'newFolderButton.title = {NL("New Folder", "file panel: new folder button")}', 'new folder button'),
    ('systemPanelButton.title = "Use System Panel…"', f'systemPanelButton.title = {NL("Use System Panel…", "file panel: use system panel button")}', 'system panel button'),
    ('actions: [ "OK" ],', f'actions: [ {NL("OK", "file panel: save error ok button")} ],', 'save error ok'),
    ('heading: "Could not save file"', f'heading: {NL("Could not save file", "file panel: save error heading")}', 'save error heading'),
    ('alert.messageText = "A file with the name “\\(descriptor.absolutePath.lastPathComponent)” on \\(descriptor.sshIdentity.displayName) already exists in this location. Do you want to replace it?"',
     f'alert.messageText = {NLf("A file with the name “%@” on %@ already exists in this location. Do you want to replace it?", "file panel: file exists alert message")}, descriptor.absolutePath.lastPathComponent, descriptor.sshIdentity.displayName)', 'file exists message'),
    ('alert.informativeText = "Replacing it will overwrite its current contents."',
     f'alert.informativeText = {NL("Replacing it will overwrite its current contents.", "file panel: file exists informative text")}', 'file exists informative'),
    ('let replaceButton = alert.addButton(withTitle: "Replace")',
     f'let replaceButton = alert.addButton(withTitle: {NL("Replace", "file panel: replace button")})', 'replace button'),
    ('alert.addButton(withTitle: "Cancel")', f'alert.addButton(withTitle: {NL("Cancel", "file panel: cancel alert button")})', 'cancel alert button'),
    ('let goToFolderItem = NSMenuItem(title: "Go to Folder…",', f'let goToFolderItem = NSMenuItem(title: {NL("Go to Folder…", "file panel: go to folder menu item")},', 'go to folder menu'),
    ('let goToHomeItem = NSMenuItem(title: "Go to Home",', f'let goToHomeItem = NSMenuItem(title: {NL("Go to Home", "file panel: go to home menu item")},', 'go to home menu'),
    ('let goUpItem = NSMenuItem(title: "Go Up",', f'let goUpItem = NSMenuItem(title: {NL("Go Up", "file panel: go up menu item")},', 'go up menu'),
    ('let backItem = NSMenuItem(title: "Back",', f'let backItem = NSMenuItem(title: {NL("Back", "file panel: back menu item")},', 'back menu'),
    ('let forwardItem = NSMenuItem(title: "Forward",', f'let forwardItem = NSMenuItem(title: {NL("Forward", "file panel: forward menu item")},', 'forward menu'),
    ('let refreshItem = NSMenuItem(title: "Refresh",', f'let refreshItem = NSMenuItem(title: {NL("Refresh", "file panel: refresh menu item")},', 'refresh menu'),
    ('let toggleShowHiddenFilesItem = NSMenuItem(title: "Show Hidden Files",', f'let toggleShowHiddenFilesItem = NSMenuItem(title: {NL("Show Hidden Files", "file panel: show hidden files menu item")},', 'show hidden menu'),
    ('let mainTitle = NSTextField(labelWithString: "New Folder")', f'let mainTitle = NSTextField(labelWithString: {NL("New Folder", "file panel: new folder sheet title")})', 'new folder sheet title'),
    ('let subtitleLabel = NSTextField(labelWithString: "Name of new folder inside “\\(currentPath.absolutePath.lastPathComponent)”:")',
     f'let subtitleLabel = NSTextField(labelWithString: {NLf("Name of new folder inside “%@”:", "file panel: new folder subtitle")}, currentPath.absolutePath.lastPathComponent)', 'new folder subtitle'),
    ('newFolderNameTextField.stringValue = "untitled folder"', f'newFolderNameTextField.stringValue = {NL("untitled folder", "file panel: untitled folder default name")}', 'untitled folder'),
    ('cancelSheetButton.title = "Cancel"', f'cancelSheetButton.title = {NL("Cancel", "file panel: new folder cancel button")}', 'new folder cancel'),
    ('createButton.title = "Create"', f'createButton.title = {NL("Create", "file panel: create button")}', 'create button'),
    ('alert.messageText = "Unable to create folder"', f'alert.messageText = {NL("Unable to create folder", "file panel: unable to create folder alert")}', 'unable to create folder'),
    ('alert.addButton(withTitle: "OK")', f'alert.addButton(withTitle: {NL("OK", "file panel: unable to create folder ok button")})', 'unable ok'),
    ('seal.reject(iTermFilePanelError("The connection to \\(file.sshIdentity.displayName) was lost."))',
     f'seal.reject(iTermFilePanelError({NLf("The connection to %@ was lost.", "file panel: connection lost error")}, file.sshIdentity.displayName))', 'connection lost'),
])

# ---- ConductorFileTransfer.swift ----
# displayName multiline (special: exact block match)
display_old = '        return """\n        iTerm2 SSH Integration Protocol\n        User name: \\(path.username ?? "(unknown)")")\n        Host: \\(path.hostname!)\n        File: \\(path.path!)"\n        """'
display_new = f'        return {NLf("iTerm2 SSH Integration Protocol\\nUser name: %@\\\")\\nHost: %@\\nFile: %@\\\"", "ConductorFileTransfer: display name")}, path.username ?? {NL("(unknown)", "ConductorFileTransfer: unknown username")}, path.hostname!, path.path!)'
wrap_file(D + 'ConductorFileTransfer.swift', [
    (display_old, display_new, 'displayName multiline'),
    ('path.hostname! + " via SSH Integration"', f'{NLf("%@ via SSH Integration", "ConductorFileTransfer: subheading")}, path.hostname!)', 'subheading'),
    ('throw ConductorFileTransferError("Unable to find Downloads folder")', f'throw ConductorFileTransferError({NL("Unable to find Downloads folder", "ConductorFileTransfer: downloads folder missing error")})', 'downloads folder'),
    ('_error = "Failed to quarantine"', f'_error = {NL("Failed to quarantine", "ConductorFileTransfer: quarantine failed error")}', 'quarantine failed'),
    ('_error = "Could not get attributes of \\(_localPath!)"', f'_error = {NLf("Could not get attributes of %@", "ConductorFileTransfer: attributes error")}, _localPath!)', 'attributes error'),
    ('_error = "Could not get size of file: \\(path)"', f'_error = {NLf("Could not get size of file: %@", "ConductorFileTransfer: size error")}, path)', 'size error'),
    ('_error = "No such file: \\(path)"', f'_error = {NLf("No such file: %@", "ConductorFileTransfer: no such file error")}, path)', 'no such file'),
    ('return "(In memory)"', f'return {NL("(In memory)", "ConductorFileTransfer: in memory path")}', 'in memory'),
])

# ---- Conductor+ConductorFileTransferDelegate.swift ----
wrap_file(D + 'Conductor+ConductorFileTransferDelegate.swift', [
    ('fileTransfer.fail(reason: "No local path specified")', f'fileTransfer.fail(reason: {NL("No local path specified", "conductor delegate: no local path error")})', 'no local path'),
    ('fileTransfer.fail(reason: "Could not open \\(path)")', f'fileTransfer.fail(reason: {NLf("Could not open %@", "conductor delegate: could not open error")}, path)', 'could not open'),
    ('"Streaming downloads do not support folders"', f'{NL("Streaming downloads do not support folders", "conductor delegate: streaming folders error")}', 'streaming folders'),
    ('fileTransfer.fail(reason: "Transfer of directory at \\(remotePath) not allowed")', f'fileTransfer.fail(reason: {NLf("Transfer of directory at %@ not allowed", "conductor delegate: directory transfer not allowed")}, remotePath)', 'directory not allowed'),
    ('throw ConductorFileTransfer.ConductorFileTransferError("\\(remoteFile.absolutePath) on \\(sshIdentity.displayName) is not a regular file")',
     f'throw ConductorFileTransfer.ConductorFileTransferError({NLf("%@ on %@ is not a regular file", "conductor delegate: not regular file error")}, remoteFile.absolutePath, sshIdentity.displayName)', 'not regular file'),
    ('throw ConductorFileTransfer.ConductorFileTransferError("Canceled")', f'throw ConductorFileTransfer.ConductorFileTransferError({NL("Canceled", "conductor delegate: canceled error")})', 'canceled'),
    ('"Download ended prematurely (received \\(content.count) of \\(remoteFile.size!) byte\\(remoteFile.size! == 1 ? "" : "s")")',
     f'{NLf("Download ended prematurely (received %@ of %@ byte%@)", "conductor delegate: download premature error")}, content.count, remoteFile.size!, remoteFile.size! == 1 ? "" : "s")', 'download premature'),
    ('fileTransfer.fail(reason: "No local filename specified")', f'fileTransfer.fail(reason: {NL("No local filename specified", "conductor delegate: no local filename error")})', 'no local filename'),
    ('throw ConductorFileTransfer.ConductorFileTransferError("Too many iterations to find a valid file name on remote host for upload")',
     f'throw ConductorFileTransfer.ConductorFileTransferError({NL("Too many iterations to find a valid file name on remote host for upload", "conductor delegate: too many iterations error")})', 'too many iterations'),
])

# ---- SSHFilePanelFileList.swift ----
wrap_file(D + 'SSHFilePanelFileList.swift', [
    ('case .name: return "Name"', f'case .name: return {NL("Name", "file list: name column title")}', 'name col'),
    ('case .dateModified: return "Date Created"', f'case .dateModified: return {NL("Date Created", "file list: date column title")}', 'date col'),
    ('case .size: return "Size"', f'case .size: return {NL("Size", "file list: size column title")}', 'size col'),
    ('case .kind: return "Kind"', f'case .kind: return {NL("Kind", "file list: kind column title")}', 'kind col'),
    ('return "Zero bytes"', f'return {NL("Zero bytes", "file list: zero bytes")}', 'zero bytes'),
    ('return "\\(pathExtension.uppercased()) image"', f'return {NLf("%@ image", "file list: image kind")}, pathExtension.uppercased())', 'image kind'),
    ('return "Text document"', f'return {NL("Text document", "file list: text document kind")}', 'text doc'),
    ('return "PDF document"', f'return {NL("PDF document", "file list: pdf document kind")}', 'pdf doc'),
    ('return "Video"', f'return {NL("Video", "file list: video kind")}', 'video'),
    ('return "Audio"', f'return {NL("Audio", "file list: audio kind")}', 'audio'),
    ('return "Archive"', f'return {NL("Archive", "file list: archive kind")}', 'archive'),
    ('return "Lua script"', f'return {NL("Lua script", "file list: lua script kind")}', 'lua script'),
    ('return "Neovim config"', f'return {NL("Neovim config", "file list: neovim config kind")}', 'neovim config'),
    ('return "Shell script"', f'return {NL("Shell script", "file list: shell script kind")}', 'shell script'),
    ('return "Objective-C source"', f'return {NL("Objective-C source", "file list: objc source kind")}', 'objc source'),
    ('case "":\n                return "Document"', f'case "":\n                return {NL("Document", "file list: document kind")}', 'document empty'),
    ('default:\n                return "Document"', f'default:\n                return {NL("Document", "file list: document kind default")}', 'document default'),
    ('return "Folder"', f'return {NL("Folder", "file list: folder kind")}', 'folder kind'),
    ('return "Host"', f'return {NL("Host", "file list: host kind")}', 'host kind'),
    ('return "Alias"', f'return {NL("Alias", "file list: alias kind")}', 'alias kind'),
    ('let error = NSError(domain: "SSHFilePanelError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing file information"])',
     f'let error = NSError(domain: "SSHFilePanelError", code: 1, userInfo: [NSLocalizedDescriptionKey: {NL("Missing file information", "file list: missing file info error")}])', 'missing file info'),
])

# ---- Conductor+IT2.swift ----
wrap_file(D + 'Conductor+IT2.swift', [
    ('"it2: request too large (over \\(Self.maxFrameLength / (1 << 20)) MiB over SSH integration); run it locally instead"',
     f'{NLf("it2: request too large (over %@ MiB over SSH integration); run it locally instead", "conductor it2: request too large stderr")}, Self.maxFrameLength / (1 << 20))', 'request too large'),
    ('sendLine(connid, IT2FrameType.stderr, "it2: malformed request")', f'sendLine(connid, IT2FrameType.stderr, {NL("it2: malformed request", "conductor it2: malformed request stderr")})', 'malformed request'),
    ('sendLine(connid, IT2FrameType.stderr, "it2: authorization failed")', f'sendLine(connid, IT2FrameType.stderr, {NL("it2: authorization failed", "conductor it2: authorization failed stderr")})', 'authorization failed'),
    ('emitStderr("The iTerm2 Python API is not enabled (Settings > General > Magic).")', f'emitStderr({NL("The iTerm2 Python API is not enabled (Settings > General > Magic).", "conductor it2: api not enabled stderr")})', 'api not enabled'),
    ('emitStderr("Permission denied: iTerm2 API access was not granted for this session.")', f'emitStderr({NL("Permission denied: iTerm2 API access was not granted for this session.", "conductor it2: permission denied stderr")})', 'permission denied'),
])

# ---- Conductor.swift ----
wrap_file(D + 'Conductor.swift', [
    ('warning.title = "Download \\(path.path.lastPathComponent) or view in browser?"', f'warning.title = {NLf("Download %@ or view in browser?", "conductor: download or view warning title")}, path.path.lastPathComponent)', 'download or view title'),
    ('warning.actionLabels = ["Download", "View", "Cancel"]', f'warning.actionLabels = [{NL("Download", "conductor: download action label")}, {NL("View", "conductor: view action label")}, {NL("Cancel", "conductor: cancel action label")}]', 'action labels'),
    ('warning.heading = "Download or View File?"', f'warning.heading = {NL("Download or View File?", "conductor: download or view heading")}', 'download or view heading'),
    ('warning.doNotRememberLabels = ["Download", "Cancel"]', f'warning.doNotRememberLabels = [{NL("Download", "conductor: download do not remember label")}, {NL("Cancel", "conductor: cancel do not remember label")}]', 'do not remember labels'),
    ('fail("\\(executionContext.command.stringValue): Unepected status \\(status)")', f'fail({NLf("%@: Unepected status %@", "conductor: unexpected status error")}, executionContext.command.stringValue, status)', 'unexpected status 1'),
    ('fail("Status \\(status) when running python code")', f'fail({NLf("Status %@ when running python code", "conductor: python status error")}, status)', 'python status'),
    ('fail("Unexpected output from \\(executionContext.command.stringValue)")', f'fail({NLf("Unexpected output from %@", "conductor: unexpected output error")}, executionContext.command.stringValue)', 'unexpected output'),
    ('fail("Invalid process ID from remote: \\(lines.string)")', f'fail({NLf("Invalid process ID from remote: %@", "conductor: invalid pid error")}, lines.string)', 'invalid pid'),
])

if errs:
    print('ERRORS:')
    for e in errs: print(f'  {e}')
    sys.exit(1)

# ============================================================
# Generate 8 locale SSH.strings
# ============================================================
for loc in LOCALES:
    d = f'{D}{loc}.lproj'
    os.makedirs(d, exist_ok=True)
    lines = []
    for key, hans, hant in KEYS:
        v = val(key, hans, hant, loc)
        lines.append(f'"{esc(key)}" = "{esc(v)}";')
    fp = f'{d}/SSH.strings'
    open(fp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(f'{fp}: {len(lines)} keys')

print(f'\nTotal applied: {total}')
print('All OK')
