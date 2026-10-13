# -*- coding: utf-8 -*-
"""Fixup: wrap remaining 2 SSH items + generate SSH.strings (re-run safe)."""
import os, sys

TABLE = 'SSH'
LOCALES = ['Base', 'en', 'zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']
SIMPLE = {'zh_CN', 'zh-Hans', 'zh-Hans-CN'}
TRAD   = {'zh_TW', 'zh-Hant', 'zh-Hant-TW'}
errs = []

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def val(key, hans, hant, locale):
    if locale in ('Base', 'en'): return key
    if locale in SIMPLE: return hans
    if locale in TRAD: return hant
    return key

def NL(key, comment):
    k = key.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return f'NSLocalizedString("{k}", tableName: "{TABLE}", comment: "{comment}")'

def NLf(key, comment):
    return f'String(format: {NL(key, comment)}'

D = 'sources/SSH/'

# 1. Sidebar second Folder block (20-space indent, for: SSHFilePanel.self)
f = D + 'SSHFilePanelSidebar.swift'
s = open(f, encoding='utf-8').read()
old = 'accessibilityDescription: "Folder",\n                    fallbackImageName: "folder",\n                    for: SSHFilePanel.self)'
new = f'accessibilityDescription: {NL("Folder", "sidebar: folder accessibility")},\n                    fallbackImageName: "folder",\n                    for: SSHFilePanel.self)'
c = s.count(old)
if c != 1:
    errs.append(f'Sidebar folder panel: count {c}')
else:
    s = s.replace(old, new)
    open(f, 'w', encoding='utf-8').write(s)
    print('Sidebar folder panel: 1 replacement')

# 2. Conductor unexpected status (2 identical occurrences)
f = D + 'Conductor.swift'
s = open(f, encoding='utf-8').read()
old = 'fail("\\(executionContext.command.stringValue): Unepected status \\(status)")'
new = f'fail({NLf("%@: Unepected status %@", "conductor: unexpected status error")}, executionContext.command.stringValue, status)'
c = s.count(old)
if c != 2:
    errs.append(f'Conductor unexpected status: count {c} (expected 2)')
else:
    s = s.replace(old, new)
    open(f, 'w', encoding='utf-8').write(s)
    print(f'Conductor unexpected status: 2 replacements')

if errs:
    print('ERRORS:')
    for e in errs: print(' ', e)
    sys.exit(1)

# Generate strings (same KEYS as main script — inline)
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

print('\nAll OK')
