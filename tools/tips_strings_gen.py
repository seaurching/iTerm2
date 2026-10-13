# -*- coding: utf-8 -*-
"""Generate Tips.strings for 8 locales.

Keys come from 5 wrapped source files in sources/Tips/ (266 unique keys total):
  - 21 fixed UI keys (buttons, labels, alert text)
  - 124 tip titles + 124 tip bodies (tips 000, 0000-0123 skipping 0075)

Locales: Base, en, zh_CN, zh-Hans, zh-Hans-CN (share simplified)
         zh_TW, zh-Hant, zh-Hant-TW (share traditional)
Base/en use the key itself as value.
"""
import os, sys

LOCALES = ['Base', 'en', 'zh_CN', 'zh-Hans', 'zh-Hans-CN', 'zh_TW', 'zh-Hant', 'zh-Hant-TW']
SIMPLE = {'zh_CN', 'zh-Hans', 'zh-Hans-CN'}
TRAD   = {'zh_TW', 'zh-Hant', 'zh-Hant-TW'}
T = 'Tips'

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\t', '\\t')

def val(key, hans, hant, locale):
    if locale in ('Base', 'en'): return key
    if locale in SIMPLE: return hans
    if locale in TRAD: return hant
    return key

# (key, simplified, traditional)
KEYS = [
    # ===== Fixed UI keys (21) =====
    ("Learn More", "了解更多", "瞭解更多"),
    ("Tip title", "提示标题", "提示標題"),
    ("Tip content", "提示内容", "提示內容"),
    ("iTerm2 tip of the day", "iTerm2 每日提示", "iTerm2 每日提示"),
    ("See Tips of the Day?", "查看每日提示？", "查看每日提示？"),
    ("iTerm2 can show you a Tip of the Day message to help you learn about its many features. Are you interested?",
     "iTerm2 可向你显示每日提示消息，帮助你了解其众多功能。你感兴趣吗？",
     "iTerm2 可向您顯示每日提示訊息，協助您瞭解其眾多功能。您感興趣嗎？"),
    ("Yes", "是", "是"),
    ("No", "否", "否"),
    ("Dismiss Tip", "关闭提示", "關閉提示"),
    ("Fewer Options", "更少选项", "更少選項"),
    ("More Options", "更多选项", "更多選項"),
    ("Show This Later", "稍后显示", "稍後顯示"),
    ("Disable Tips", "禁用提示", "停用提示"),
    ("Enable Tips", "启用提示", "啟用提示"),
    ("Show Next Tip", "显示下一条提示", "顯示下一條提示"),
    ("Show Previous Tip", "显示上一条提示", "顯示上一條提示"),
    ("Show Tips Weekly", "每周显示提示", "每週顯示提示"),
    ("Show Tips Daily", "每天显示提示", "每天顯示提示"),
    ("Share", "分享", "分享"),
    ("iTerm2 Tip of the Day", "iTerm2 每日提示", "iTerm2 每日提示"),
    ("Tip of the Day", "每日提示", "每日提示"),
    # ===== Tip 000 =====
    ("This window shows the iTerm2 tip of the day. It’ll appear every 24 hours to let you know about new features and hidden secrets. Hit “More Options” to view more tips or to stop getting them altogether.",
     "此窗口显示 iTerm2 每日提示。它每 24 小时出现一次，让你了解新功能和隐藏技巧。点击“更多选项”可查看更多提示或完全停止接收。",
     "此視窗顯示 iTerm2 每日提示。它每 24 小時出現一次，讓您瞭解新功能和隱藏技巧。點擊「更多選項」可查看更多提示或完全停止接收。"),
    # ===== Tip 0000 Shell Integration =====
    ("Shell Integration", "Shell 集成", "Shell 整合"),
    ("The big new feature of iTerm2 version 3 is Shell Integration. Click “Learn More” for all the details.",
     "iTerm2 版本 3 的重大新功能是 Shell 集成。点击“了解更多”获取所有详情。",
     "iTerm2 版本 3 的重大新功能是 Shell 整合。點擊「瞭解更多」取得所有詳情。"),
    # ===== Tip 0001 Timestamps =====
    ("Timestamps", "时间戳", "時間戳"),
    ("“View > Show Timestamps” shows the time (and date, if appropriate) when each line was last modified.",
     "“视图 > 显示时间戳”会显示每行最后修改的时间（及日期，如适用）。",
     "「檢視 > 顯示時間戳」會顯示每行最後修改的時間（及日期，如適用）。"),
    # ===== Tip 0002 Password Manager =====
    ("Password Manager", "密码管理器", "密碼管理器"),
    ("Did you know iTerm2 has a password manager? Open it with “Window > Password Manager.” You can define a Trigger to open it for you at a password prompt in “Settings > Profiles > Advanced > Triggers.”",
     "你知道 iTerm2 有密码管理器吗？用“窗口 > 密码管理器”打开它。你可以在“设置 > 配置文件 > 高级 > 触发器”中定义一个触发器，在密码提示处自动打开它。",
     "您知道 iTerm2 有密碼管理器嗎？用「視窗 > 密碼管理器」開啟它。您可以在「設定 > 設定檔 > 進階 > 觸發器」中定義一個觸發器，在密碼提示處自動開啟它。"),
    # ===== Tip 0003 Open Quickly =====
    ("Open Quickly", "快速打开", "快速開啟"),
    ("You can quickly search through your sessions with “View > Open Quickly”\xa0(⇧⌘O). You can type a query and sessions whose name, badge, current hostname, current user name, recent commands, and recent working directories match will be surfaced. It works best with Shell Integration so the user name, hostname, command, and directories can be known even while sshed.",
     "你可以用“视图 > 快速打开”（⇧⌘O）快速搜索会话。输入查询后，名称、徽章、当前主机名、当前用户名、最近命令和最近工作目录匹配的会话将会显示。配合 Shell 集成效果最佳，这样即使在 ssh 连接中也能知道用户名、主机名、命令和目录。",
     "您可以用「檢視 > 快速開啟」（⇧⌘O）快速搜尋工作階段。輸入查詢後，名稱、徽章、目前主機名稱、目前使用者名稱、最近指令和最近工作目錄相符的工作階段將會顯示。配合 Shell 整合效果最佳，這樣即使在 ssh 連線中也能知道使用者名稱、主機名稱、指令和目錄。"),
    # ===== Tip 0004 Undo Close =====
    ("Undo Close", "撤销关闭", "還原關閉"),
    ("If you close a session, tab, or window by accident you can undo it with “Edit > Undo”\xa0(⌘Z). By default you have five seconds to undo, but you can adjust that timeout in “Settings > Profiles > Session.”",
     "如果你不小心关闭了会话、标签页或窗口，可以用“编辑 > 撤销”（⌘Z）撤销。默认有五秒钟可以撤销，但你可以在“设置 > 配置文件 > 会话”中调整该超时时间。",
     "如果您不小心關閉了工作階段、分頁或視窗，可以用「編輯 > 還原」（⌘Z）還原。預設有五秒鐘可以還原，但您可以在「設定 > 設定檔 > 工作階段」中調整該逾時時間。"),
    # ===== Tip 0005 Annotations =====
    ("Annotations", "注释", "註解"),
    ("Want to mark up your scrollback history? Right click on a selection and choose “Annotate Selection” to add a personal note to it. Use “View > Show Annotations” to show or hide them, and look in “Edit > Marks and Annotations” for more things you can do.",
     "想在回滚历史中做标记吗？右键点击选区并选择“为选区添加注释”即可为其添加个人备注。用“视图 > 显示注释”来显示或隐藏它们，并在“编辑 > 标记和注释”中查看更多可用操作。",
     "想在回捲歷史中做標記嗎？右鍵點擊選取範圍並選擇「為選取範圍新增註解」即可為其新增個人備註。用「檢視 > 顯示註解」來顯示或隱藏它們，並在「編輯 > 標記和註解」中查看更多可用操作。"),
    # ===== Tip 0006 Copy with Styles =====
    ("Copy with Styles", "带样式复制", "帶樣式複製"),
    ("Copy a selection with ⌥⌘C to include styles such as colors and fonts. You can make this the default action for Copy in “Settings > Advanced.”",
     "用 ⌥⌘C 复制选区可包含颜色和字体等样式。你可以在“设置 > 高级”中将此设为复制的默认行为。",
     "用 ⌥⌘C 複製選取範圍可包含顏色和字型等樣式。您可以在「設定 > 進階」中將此設為複製的預設行為。"),
    # ===== Tip 0007 Inline Images =====
    ("Inline Images", "内联图片", "內嵌圖片"),
    ("iTerm2 can display images (even animated GIFs) inline.",
     "iTerm2 可以内联显示图片（甚至是动态 GIF）。",
     "iTerm2 可以內嵌顯示圖片（甚至是動態 GIF）。"),
    # ===== Tip 0008 Automatic Profile Switching =====
    ("Automatic Profile Switching", "自动切换配置文件", "自動切換設定檔"),
    ("Automatic Profile Switching changes the current profile when the username, hostname, or directory changes. Set it up in “Settings > Profiles > Advanced.” It requires Shell Integration to be installed.",
     "自动切换配置文件会在用户名、主机名或目录变化时切换当前配置文件。在“设置 > 配置文件 > 高级”中设置。它需要安装 Shell 集成。",
     "自動切換設定檔會在使用者名稱、主機名稱或目錄變化時切換目前設定檔。在「設定 > 設定檔 > 進階」中設定。它需要安裝 Shell 整合。"),
    # ===== Tip 0009 Captured Output =====
    ("Captured Output", "捕获的输出", "擷取的輸出"),
    ("iTerm2 can act like an IDE using the Captured Output feature. When it sees text matching a regular expression you define, like compiler errors, it shows the matching lines in the Toolbelt. You can click to jump to the line in your terminal and double-click to perform an action like opening an editor to the line with the error.",
     "iTerm2 可通过捕获的输出功能像 IDE 一样工作。当它看到与你定义的正则表达式匹配的文本（如编译器错误）时，会在工具栏中显示匹配行。你可以点击跳转到终端中的该行，双击可执行操作（如在编辑器中打开出错行）。",
     "iTerm2 可透過擷取的輸出功能像 IDE 一樣運作。當它看到與您定義的正規表示式匹配的文字（如編譯器錯誤）時，會在工具列中顯示匹配行。您可以點擊跳轉到終端機中的該行，雙擊可執行動作（如在編輯器中開啟出錯行）。"),
    # ===== Tip 0010 Badges =====
    ("Badges", "徽章", "徽章"),
    ("You can display a status message in the top right of your session in the background. It’s called a “Badge.” If you install Shell Integration you can include info like user name, hostname, current directory, and more.",
     "你可以在会话右上角后台显示一条状态消息。它叫做“徽章”。如果安装了 Shell 集成，你可以包含用户名、主机名、当前目录等信息。",
     "您可以在工作階段右上角背景顯示一條狀態訊息。它叫做「徽章」。如果安裝了 Shell 整合，您可以包含使用者名稱、主機名稱、目前目錄等資訊。"),
    # ===== Tip 0011 Dynamic Profiles =====
    ("Dynamic Profiles", "动态配置文件", "動態設定檔"),
    ("Dynamic Profiles let you store your profiles as one or more JSON files. It’s great for batch creating and editing profiles.",
     "动态配置文件让你将配置文件存储为一个或多个 JSON 文件。它非常适合批量创建和编辑配置文件。",
     "動態設定檔讓您將設定檔儲存為一個或多個 JSON 檔案。它非常適合批量建立和編輯設定檔。"),
    # ===== Tip 0012 Advanced Paste =====
    ("Advanced Paste", "高级粘贴", "進階貼上"),
    ("“Edit > Paste Special > Advanced Paste” lets you preview and edit text before you paste. You get to tweak options, like how to handle control codes, or even to base-64 encode before pasting.",
     "“编辑 > 特殊粘贴 > 高级粘贴”让你在粘贴前预览和编辑文本。你可以调整选项，比如如何处理控制字符，甚至在粘贴前进行 base-64 编码。",
     "「編輯 > 特殊貼上 > 進階貼上」讓您在貼上前預覽和編輯文字。您可以調整選項，比如如何處理控制字元，甚至在貼上前進行 base-64 編碼。"),
    # ===== Tip 0013 Zoom =====
    ("Zoom", "缩放", "縮放"),
    ("Ever wanted to focus on a block of lines without distraction, or limit Find to a single command’s output? Select the lines and choose “View > Zoom In on Selection.” The session’s contents will be temporarily replaced with the selection. Press “esc” to unzoom.",
     "是否想专注于一组行而不受干扰，或将查找限制在单个命令的输出中？选中这些行并选择“视图 > 放大选区”。会话内容将被临时替换为选区。按“esc”退出缩放。",
     "是否想專注於一組行而不受干擾，或將尋找限制在單一指令的輸出中？選取這些行並選擇「檢視 > 放大選取範圍」。工作階段內容將被臨時替換為選取範圍。按「esc」退出縮放。"),
    # ===== Tip 0014 Semantic History =====
    ("Semantic History", "语义历史", "語意歷史"),
    ("The “Semantic History” feature allows you to ⌘-click on a file or URL to open it.",
     "“语义历史”功能允许你按住 ⌘ 点击文件或 URL 来打开它。",
     "「語意歷史」功能允許您按住 ⌘ 點擊檔案或 URL 來開啟它。"),
    # ===== Tip 0015 Tmux Integration =====
    ("Tmux Integration", "Tmux 集成", "Tmux 整合"),
    ("If you use tmux, try running “tmux -CC” to get iTerm2’s tmux integration mode. The tmux windows show up as native iTerm2 windows, and you can use iTerm2’s keyboard shortcuts. It even works over ssh!",
     "如果你使用 tmux，试试运行“tmux -CC”来获得 iTerm2 的 tmux 集成模式。tmux 窗口会显示为原生 iTerm2 窗口，你可以使用 iTerm2 的键盘快捷键。它甚至可以通过 ssh 使用！",
     "如果您使用 tmux，試試執行「tmux -CC」來取得 iTerm2 的 tmux 整合模式。tmux 視窗會顯示為原生 iTerm2 視窗，您可以使用 iTerm2 的鍵盤快速鍵。它甚至可以透過 ssh 使用！"),
    # ===== Tip 0016 Triggers =====
    ("Triggers", "触发器", "觸發器"),
    ("iTerm2 can automatically perform actions you define when text matching a regular expression is received. For example, you can highlight text or show an alert box. Set it up in “Settings > Profiles > Advanced > Triggers.”",
     "iTerm2 可在收到与你定义的正则表达式匹配的文本时自动执行操作。例如，你可以高亮文本或显示警告框。在“设置 > 配置文件 > 高级 > 触发器”中设置。",
     "iTerm2 可在收到與您定義的正規表示式匹配的文字時自動執行動作。例如，您可以高亮文字或顯示警告框。在「設定 > 設定檔 > 進階 > 觸發器」中設定。"),
    # ===== Tip 0017 Smart Selection =====
    ("Smart Selection", "智能选择", "智慧選取"),
    ("Quadruple click to perform Smart Selection. It figures out if you’re selecting a URL, filename, email address, etc. based on prioritized regular expressions.",
     "四连击可执行智能选择。它会根据优先级正则表达式判断你选择的是 URL、文件名、电子邮件地址等。",
     "四連擊可執行智慧選取。它會根據優先順序正規表示式判斷您選取的是 URL、檔名、電子郵件地址等。"),
    # ===== Tip 0018 Instant Replay =====
    ("Instant Replay", "即时回放", "即時回放"),
    ("Press ⌥⌘B to step back in time in a terminal window. Use arrow keys to go frame by frame. Hold ⇧ and press arrow keys to go faster.",
     "按 ⌥⌘B 可在终端窗口中回溯时间。用方向键逐帧前进。按住 ⇧ 再按方向键可加快速度。",
     "按 ⌥⌘B 可在終端機視窗中回溯時間。用方向鍵逐幀前進。按住 ⇧ 再按方向鍵可加快速度。"),
    # ===== Tip 0019 Hotkey Window =====
    ("Hotkey Window", "热键窗口", "熱鍵視窗"),
    ("You can have a terminal window open with a keystroke, even while in other apps. Click “Create a Dedicated Hotkey Window” in “Settings > Keys.”",
     "你可以用快捷键打开终端窗口，即使在其他应用中也可以。在“设置 > 键”中点击“创建专用热键窗口”。",
     "您可以用快速鍵開啟終端機視窗，即使在其他應用程式中也可以。在「設定 > 鍵」中點擊「建立專屬熱鍵視窗」。"),
    ("Hotkey windows can stay open after losing focus. Turn it on in “Window > Pin Hotkey Window.”",
     "热键窗口在失去焦点后可以保持打开。在“窗口 > 固定热键窗口”中开启。",
     "熱鍵視窗在失去焦點後可以保持開啟。在「視窗 > 固定熱鍵視窗」中開啟。"),
    # ===== Tip 0020 Cursor Guide =====
    ("Cursor Guide", "光标引导线", "游標引導線"),
    ("The cursor guide is a horizontal line that follows your cursor. You can turn it on in “Settings > Profiles > Colors” or toggle it with the ⌥⌘; shortcut.",
     "光标引导线是跟随光标的水平线。你可以在“设置 > 配置文件 > 颜色”中开启，或用 ⌥⌘; 快捷键切换。",
     "游標引導線是跟隨游標的水平線。您可以在「設定 > 設定檔 > 顏色」中開啟，或用 ⌥⌘; 快速鍵切換。"),
    # ===== Tip 0021 Shell Integration: Alerts =====
    ("Shell Integration: Alerts", "Shell 集成：提醒", "Shell 整合：提醒"),
    ("The Shell Integration feature lets you ask to be alerted (⌥⌘A) when a long-running command completes.",
     "Shell 集成功能可让你在长时间运行的命令完成时收到提醒（⌥⌘A）。",
     "Shell 整合功能可讓您在長時間執行的指令完成時收到提醒（⌥⌘A）。"),
    # ===== Tip 0022 Cursor Blink Rate =====
    ("Cursor Blink Rate", "光标闪烁频率", "游標閃爍頻率"),
    ("You can configure how quickly the cursor blinks in “Settings > Advanced.”",
     "你可以在“设置 > 高级”中配置光标闪烁的速度。",
     "您可以在「設定 > 進階」中設定游標閃爍的速度。"),
    # ===== Tip 0023 Shell Integration: Navigation =====
    ("Shell Integration: Navigation", "Shell 集成：导航", "Shell 整合：導覽"),
    ("The Shell Integration feature lets you navigate among shell prompts with ⇧⌘↑ and ⇧⌘↓.",
     "Shell 集成功能可让你用 ⇧⌘↑ 和 ⇧⌘↓ 在 shell 提示符之间导航。",
     "Shell 整合功能可讓您用 ⇧⌘↑ 和 ⇧⌘↓ 在 shell 提示符之間導覽。"),
    # ===== Tip 0024 Shell Integration: Status =====
    ("Shell Integration: Status", "Shell 集成：状态", "Shell 整合：狀態"),
    ("The Shell Integration feature puts a blue arrow next to your shell prompt. If you run a command that fails, it turns red. Right click on it to get the running time and status.",
     "Shell 集成功能会在 shell 提示符旁放一个蓝色箭头。如果你运行的命令失败，它会变红。右键点击它可查看运行时间和状态。",
     "Shell 整合功能會在 shell 提示符旁放一個藍色箭頭。如果您執行的指令失敗，它會變紅。右鍵點擊它可查看執行時間和狀態。"),
    # ===== Tip 0025 Shell Integration: Selection =====
    ("Shell Integration: Selection", "Shell 集成：选择", "Shell 整合：選取"),
    ("With Shell Integration installed, you can select the output of the last command with ⇧⌘A.",
     "安装 Shell 集成后，你可以用 ⇧⌘A 选择上一条命令的输出。",
     "安裝 Shell 整合後，您可以用 ⇧⌘A 選取上一條指令的輸出。"),
    # ===== Tip 0026 Bells =====
    ("Bells", "响铃", "響鈴"),
    ("The dock icon shows a count of the number of bells rung and notifications posted since the app was last active.",
     "Dock 图标会显示自应用上次活动以来响铃和发布通知的次数。",
     "Dock 圖示會顯示自應用程式上次活動以來響鈴和發布通知的次數。"),
    # ===== Tip 0027 Shell Integration: Downloads =====
    ("Shell Integration: Downloads", "Shell 集成：下载", "Shell 整合：下載"),
    ("If you install Shell Integration on a machine you ssh to, you can right click on a filename (for example, in the output of “ls”) and choose “Download with scp” to download the file.",
     "如果你在 ssh 连接的机器上安装了 Shell 集成，可以右键点击文件名（例如在“ls”的输出中）并选择“用 scp 下载”来下载文件。",
     "如果您在 ssh 連線的機器上安裝了 Shell 整合，可以右鍵點擊檔名（例如在「ls」的輸出中）並選擇「用 scp 下載」來下載檔案。"),
    # ===== Tip 0028 Find Your Cursor =====
    ("Find Your Cursor", "找到你的光标", "找到您的游標"),
    ("Press ⌘/ to locate your cursor. It’s fun!",
     "按 ⌘/ 定位你的光标。很有趣！",
     "按 ⌘/ 定位您的游標。很有趣！"),
    # ===== Tip 0029 Customize Smart Selection =====
    ("Customize Smart Selection", "自定义智能选择", "自訂智慧選取"),
    ("You can edit Smart Selection regular expressions in “Settings > Profiles > Advanced > Smart Selection.”",
     "你可以在“设置 > 配置文件 > 高级 > 智能选择”中编辑智能选择正则表达式。",
     "您可以在「設定 > 設定檔 > 進階 > 智慧選取」中編輯智慧選取正規表示式。"),
    # ===== Tip 0030 Smart Selection Actions =====
    ("Smart Selection Actions", "智能选择操作", "智慧選取動作"),
    ("Assign an action to a Smart Selection rule in “Settings > Profiles > Advanced > Smart Selection > Edit Actions.” They go in the context menu and override semantic history on ⌘-click.",
     "在“设置 > 配置文件 > 高级 > 智能选择 > 编辑操作”中为智能选择规则分配操作。它们会出现在上下文菜单中，并在 ⌘ 点击时覆盖语义历史。",
     "在「設定 > 設定檔 > 進階 > 智慧選取 > 編輯動作」中為智慧選取規則分配動作。它們會出現在快顯功能表中，並在 ⌘ 點擊時覆蓋語意歷史。"),
    # ===== Tip 0031 Visual Bell =====
    ("Visual Bell", "视觉响铃", "視覺響鈴"),
    ("If you want the visual bell to flash the whole screen instead of show a bell icon, you can turn that on in “Settings > Advanced.”",
     "如果你想让视觉响铃闪烁整个屏幕而不是显示铃铛图标，可以在“设置 > 高级”中开启。",
     "如果您想讓視覺響鈴閃爍整個螢幕而不是顯示鈴鐺圖示，可以在「設定 > 進階」中開啟。"),
    # ===== Tip 0032 Tab Menu =====
    ("Tab Menu", "标签页菜单", "分頁選單"),
    ("Right click on a tab to change its color, close tabs after it, or to close all other tabs.",
     "右键点击标签页可更改其颜色、关闭其后的标签页或关闭所有其他标签页。",
     "右鍵點擊分頁可更改其顏色、關閉其後的分頁或關閉所有其他分頁。"),
    # ===== Tip 0033 Tags =====
    ("Tags", "标签", "標籤"),
    ("You can assign tags to your profiles, and by clicking “Tags>” anywhere you see a list of profiles you can browse those tags.",
     "你可以为配置文件分配标签，在任何配置文件列表中点击“标签>”即可浏览这些标签。",
     "您可以為設定檔分配標籤，在任何設定檔列表中點擊「標籤>」即可瀏覽這些標籤。"),
    # ===== Tip 0034 Tag Hierarchy =====
    ("Tag Hierarchy", "标签层级", "標籤階層"),
    ("If you put a slash in a profile’s tag, that implicitly defines a hierarchy. You can see it in the Profiles menu as nested submenus.",
     "如果在配置文件的标签中加斜杠，会隐式定义一个层级。你可以在“配置文件”菜单中看到它作为嵌套子菜单。",
     "如果在設定檔的標籤中加斜線，會隱式定義一個階層。您可以在「設定檔」選單中看到它作為巢狀子選單。"),
    # ===== Tip 0035 Downloads =====
    ("Downloads", "下载", "下載"),
    ("iTerm2 can download files by base-64 encoding them. Click “Learn More” to download a shell script that makes it easy.",
     "iTerm2 可通过 base-64 编码下载文件。点击“了解更多”下载一个简化此操作的 shell 脚本。",
     "iTerm2 可透過 base-64 編碼下載檔案。點擊「瞭解更多」下載一個簡化此操作的 shell 指令稿。"),
    # ===== Tip 0036 Command Completion =====
    ("Command Completion", "命令补全", "指令補全"),
    ("If you install Shell Integration, ⇧⌘; helps you complete commands. It remembers the commands you’ve run on each host that has Shell Integration installed. It knows how often that command was run and how recently to help make the best suggestions.",
     "如果安装了 Shell 集成，⇧⌘; 可帮你补全命令。它会记住你在每个安装了 Shell 集成的主机上运行过的命令，并根据运行频率和近期程度给出最佳建议。",
     "如果安裝了 Shell 整合，⇧⌘; 可幫您補全指令。它會記住您在每個安裝了 Shell 整合的主機上執行過的指令，並根據執行頻率和近期程度給出最佳建議。"),
    # ===== Tip 0037 Recent Directories =====
    ("Recent Directories", "最近目录", "最近目錄"),
    ("iTerm2 remembers which directories you use the most on each host that has Shell Integration installed. There’s a Toolbelt tool to browse them, and ⌥⌘/ gives you a popup sorted by frequency and recency of use.",
     "iTerm2 会记住你在每个安装了 Shell 集成的主机上最常用的目录。工具栏中有一个工具可浏览它们，⌥⌘/ 会弹出一个按使用频率和近期程度排序的列表。",
     "iTerm2 會記住您在每個安裝了 Shell 整合的主機上最常用的目錄。工具列中有一個工具可瀏覽它們，⌥⌘/ 會彈出一個按使用頻率和近期程度排序的列表。"),
    # ===== Tip 0038 Favorite Directories =====
    ("Favorite Directories", "收藏目录", "收藏目錄"),
    ("If you have Shell Integration installed, you can “star” a directory to keep it always at the bottom of the Recent Directories tool in the Toolbelt. Right click and choose “Toggle Star.”",
     "如果安装了 Shell 集成，你可以给目录加“星标”，使其始终显示在工具栏的最近目录工具底部。右键点击并选择“切换星标”。",
     "如果安裝了 Shell 整合，您可以給目錄加「星標」，使其始終顯示在工具列的最近目錄工具底部。右鍵點擊並選擇「切換星標」。"),
    # ===== Tip 0039 Shell Integration History =====
    ("Shell Integration History", "Shell 集成历史", "Shell 整合歷史"),
    ("Install Shell Integration and turn on “Settings > General > Save copy/paste and command history to disk” to remember command history per host across restarts of iTerm2.",
     "安装 Shell 集成并开启“设置 > 通用 > 将复制/粘贴和命令历史保存到磁盘”，即可在 iTerm2 重启后按主机记住命令历史。",
     "安裝 Shell 整合並開啟「設定 > 一般 > 將複製/貼上和指令歷史儲存到磁碟」，即可在 iTerm2 重啟後按主機記住指令歷史。"),
    # ===== Tip 0040 Paste File as Base64 =====
    ("Paste File as Base64", "将文件粘贴为 Base64", "將檔案貼上為 Base64"),
    ("Copy a file to the pasteboard in Finder and then use “Edit > Paste Special > Paste File Base64-Encoded” for easy uploads of binary files. Use ”base64 -D” (or -d on Linux) on the remote host to decode it.",
     "在 Finder 中将文件拷贝到剪贴板，然后用“编辑 > 特殊粘贴 > 粘贴 Base64 编码的文件”即可轻松上传二进制文件。在远程主机上用“base64 -D”（Linux 上用 -d）解码。",
     "在 Finder 中將檔案拷貝到剪貼簿，然後用「編輯 > 特殊貼上 > 貼上 Base64 編碼的檔案」即可輕鬆上傳二進位檔案。在遠端主機上用「base64 -D」（Linux 上用 -d）解碼。"),
    # ===== Tip 0041 Split Panes =====
    ("Split Panes", "分屏面板", "分割窗格"),
    ("You can split a tab into multiple panes with ⌘D and ⇧⌘D.",
     "你可以用 ⌘D 和 ⇧⌘D 将标签页拆分为多个分屏面板。",
     "您可以用 ⌘D 和 ⇧⌘D 將分頁拆分為多個分割窗格。"),
    # ===== Tip 0042 Adjust Split Panes =====
    ("Adjust Split Panes", "调整分屏面板", "調整分割窗格"),
    ("Resize split panes with the keyboard using ^⌘-Arrow Key.",
     "用键盘 ^⌘-方向键调整分屏面板大小。",
     "用鍵盤 ^⌘-方向鍵調整分割窗格大小。"),
    # ===== Tip 0043 Move Cursor =====
    ("Move Cursor", "移动光标", "移動游標"),
    ("Hold ⌥ and click to move your cursor. It works best with Shell Integration installed (to avoid sending up/down arrow keys to your shell).",
     "按住 ⌥ 并点击可移动光标。安装 Shell 集成后效果最佳（可避免向 shell 发送上下方向键）。",
     "按住 ⌥ 並點擊可移動游標。安裝 Shell 整合後效果最佳（可避免向 shell 發送上下方向鍵）。"),
    # ===== Tip 0044 Edge Windows =====
    ("Edge Windows", "边缘窗口", "邊緣視窗"),
    ("You can tell your profile to create windows that are attached to one edge of the screen in “Settings > Profiles > Window.” You can resize them by dragging the edges.",
     "你可以在“设置 > 配置文件 > 窗口”中让配置文件创建附着在屏幕一侧的窗口。你可以通过拖动边缘调整大小。",
     "您可以在「設定 > 設定檔 > 視窗」中讓設定檔建立附著在螢幕一側的視窗。您可以透過拖動邊緣調整大小。"),
    # ===== Tip 0045 Tab Color =====
    ("Tab Color", "标签页颜色", "分頁顏色"),
    ("You can assign colors to tabs in “Settings > Profiles > Colors,” or in the View menu.",
     "你可以在“设置 > 配置文件 > 颜色”或视图菜单中为标签页分配颜色。",
     "您可以在「設定 > 設定檔 > 顏色」或檢視選單中為分頁分配顏色。"),
    # ===== Tip 0046 Rectangular Selection =====
    ("Rectangular Selection", "矩形选择", "矩形選取"),
    ("Hold ⌥⌘ while dragging to make a rectangular selection.",
     "拖动时按住 ⌥⌘ 可进行矩形选择。",
     "拖動時按住 ⌥⌘ 可進行矩形選取。"),
    # ===== Tip 0047 Multiple Selection =====
    ("Multiple Selection", "多重选择", "多重選取"),
    ("Hold ⌘ while dragging to make multiple discontinuous selections.",
     "拖动时按住 ⌘ 可进行多个不连续的选择。",
     "拖動時按住 ⌘ 可進行多個不連續的選取。"),
    # ===== Tip 0048 Dragging Panes =====
    ("Dragging Panes", "拖动分屏面板", "拖動分割窗格"),
    ("Hold ⇧⌥⌘ and drag a session into another session to create or change split panes.",
     "按住 ⇧⌥⌘ 将一个会话拖入另一个会话可创建或更改分屏面板。",
     "按住 ⇧⌥⌘ 將一個工作階段拖入另一個工作階段可建立或更改分割窗格。"),
    # ===== Tip 0049 Cursor Boost =====
    ("Cursor Boost", "光标增强", "游標增強"),
    ("Adjust Cursor Boost in “Settings > Profiles > Colors” to make all colors more muted, except the cursor. Use a bright white cursor and it pops!",
     "在“设置 > 配置文件 > 颜色”中调整光标增强，可使除光标外的所有颜色更柔和。使用亮白色光标，它会非常醒目！",
     "在「設定 > 設定檔 > 顏色」中調整游標增強，可使除游標外的所有顏色更柔和。使用亮白色游標，它會非常醒目！"),
    # ===== Tip 0050 Minimum Contrast =====
    ("Minimum Contrast", "最低对比度", "最低對比度"),
    ("Adjust “Minimum Contrast” in “Settings > Profiles > Colors” to ensure text is always legible regardless of text/background color combination.",
     "在“设置 > 配置文件 > 颜色”中调整“最低对比度”，可确保无论文本/背景颜色如何组合，文本始终清晰可读。",
     "在「設定 > 設定檔 > 顏色」中調整「最低對比度」，可確保無論文字/背景顏色如何組合，文字始終清晰可讀。"),
    # ===== Tip 0051 Tabs =====
    ("Tabs", "标签页", "分頁"),
    ("Normally, new tabs appear at the end of the tab bar. There’s a setting in “Settings > Advanced” to place them next to your current tab.",
     "通常新标签页出现在标签栏末尾。在“设置 > 高级”中有一项设置可将它们放在当前标签页旁边。",
     "通常新分頁出現在分頁列末尾。在「設定 > 進階」中有一項設定可將它們放在目前分頁旁邊。"),
    # ===== Tip 0052 Base Conversion =====
    ("Base Conversion", "进制转换", "進位轉換"),
    ("Right-click on a number and the context menu shows it converted to hex or decimal as appropriate.",
     "右键点击数字，上下文菜单会显示其转换为十六进制或十进制的结果。",
     "右鍵點擊數字，快顯功能表會顯示其轉換為十六進位或十進位的結果。"),
    # ===== Tip 0053 Saved Searches =====
    ("Saved Searches", "保存的搜索", "儲存的搜尋"),
    ("In “Settings > Keys” you can assign a keystroke to a search for a regular expression with the “Find Regular Expression…” action.",
     "在“设置 > 键”中，你可以用“查找正则表达式…”操作将快捷键分配给正则表达式搜索。",
     "在「設定 > 鍵」中，您可以用「尋找正規表示式…」動作將快速鍵分配給正規表示式搜尋。"),
    # ===== Tip 0054 Find URLs =====
    ("Find URLs", "查找 URL", "尋找 URL"),
    ("Search for URLs using “Edit > Find > Find URLs.” Navigate search results with ⌘G and ⇧⌘G. Open the current selection with ⌥⌘O.",
     "用“编辑 > 查找 > 查找 URL”搜索 URL。用 ⌘G 和 ⇧⌘G 导航搜索结果。用 ⌥⌘O 打开当前选择。",
     "用「編輯 > 尋找 > 尋找 URL」搜尋 URL。用 ⌘G 和 ⇧⌘G 導覽搜尋結果。用 ⌥⌘O 開啟目前選取範圍。"),
    # ===== Tip 0055 (instant checkbox) =====
    ("The “instant” checkbox in a Trigger allows it to fire while the cursor is on the same line as the text that matches your regular expression.",
     "触发器中的“即时”复选框允许它在光标与匹配正则表达式的文本位于同一行时触发。",
     "觸發器中的「即時」核取方塊允許它在游標與匹配正規表示式的文字位於同一行時觸發。"),
    # ===== Tip 0056 Soft Boundaries =====
    ("Soft Boundaries", "软边界", "軟邊界"),
    ("Turn on “Edit > Selection Respects Soft Boundaries” to recognize split pane dividers in programs like vi, emacs, and tmux so you can select multiple lines of text.",
     "开启“编辑 > 选区遵守软边界”可识别 vi、emacs 和 tmux 等程序中的分屏面板分隔符，从而选择多行文本。",
     "開啟「編輯 > 選取範圍遵守軟邊界」可識別 vi、emacs 和 tmux 等程式中的分割窗格分隔符，從而選取多行文字。"),
    # ===== Tip 0057 Select Without Dragging =====
    ("Select Without Dragging", "无需拖动即可选择", "無需拖動即可選取"),
    ("Single click where you want to start a selection and ⇧-click where you want it to end to select text without dragging.",
     "在想要开始选区的位置单击，在想要结束的位置按住 ⇧ 点击，即可无需拖动选择文本。",
     "在想要開始選取範圍的位置單擊，在想要結束的位置按住 ⇧ 點擊，即可無需拖動選取文字。"),
    # ===== Tip 0058 Smooth Window Resizing =====
    ("Smooth Window Resizing", "平滑调整窗口大小", "平滑調整視窗大小"),
    ("Hold ^ while resizing a window and it won’t snap to the character grid: you can make it any size you want.",
     "调整窗口大小时按住 ^，它不会对齐到字符网格：你可以调整为任意大小。",
     "調整視窗大小時按住 ^，它不會對齊到字元格線：您可以調整為任意大小。"),
    # ===== Tip 0059 Pasting Tabs =====
    ("Pasting Tabs", "粘贴制表符", "貼上定位字元"),
    ("If you paste text containing tabs, you’ll be asked if you want to convert them to spaces. It’s handy at the shell prompt to avoid triggering filename completion.",
     "如果你粘贴包含制表符的文本，系统会询问你是否将它们转换为空格。这在 shell 提示符处很方便，可避免触发文件名补全。",
     "如果您貼上包含定位字元的文字，系統會詢問您是否將它們轉換為空格。這在 shell 提示符處很方便，可避免觸發檔名補全。"),
    # ===== Tip 0060 Bell Silencing =====
    ("Bell Silencing", "响铃静音", "響鈴靜音"),
    ("Did you know? If the bell rings too often, you’ll be asked if you’d like to silence it temporarily. iTerm2 cares about your comfort.",
     "你知道吗？如果响铃过于频繁，系统会询问你是否暂时静音。iTerm2 关心你的舒适体验。",
     "您知道嗎？如果響鈴過於頻繁，系統會詢問您是否暫時靜音。iTerm2 關心您的舒適體驗。"),
    # ===== Tip 0061 Profile Search =====
    ("Profile Search", "配置文件搜索", "設定檔搜尋"),
    ("Every list of profiles has a search field (e.g., in ”Settings > Profiles.”) You can use various operators to restrict your search query. Click “Learn More” for all the details.",
     "每个配置文件列表都有搜索框（例如在“设置 > 配置文件”中）。你可以使用各种运算符来限制搜索查询。点击“了解更多”获取所有详情。",
     "每個設定檔列表都有搜尋框（例如在「設定 > 設定檔」中）。您可以使用各種運算子來限制搜尋查詢。點擊「瞭解更多」取得所有詳情。"),
    # ===== Tip 0062 Color Schemes =====
    ("Color Schemes", "配色方案", "配色方案"),
    ("The online color gallery features over one hundred beautiful color schemes you can download.",
     "在线配色库提供了一百多种可供下载的精美配色方案。",
     "線上配色庫提供了一百多種可供下載的精美配色方案。"),
    # ===== Tip 0063 ASCII/Non-Ascii Fonts =====
    ("ASCII/Non-Ascii Fonts", "ASCII/非 ASCII 字体", "ASCII/非 ASCII 字型"),
    ("You can have a separate font for ASCII versus non-ASCII text. Enable it in “Settings > Profiles > Text.”",
     "你可以为 ASCII 和非 ASCII 文本分别使用不同字体。在“设置 > 配置文件 > 文本”中启用。",
     "您可以為 ASCII 和非 ASCII 文字分別使用不同字型。在「設定 > 設定檔 > 文字」中啟用。"),
    # ===== Tip 0064 Coprocesses =====
    ("Coprocesses", "协处理", "協同處理"),
    ("A coprocess is a job, such as a shell script, that has a special relationship with a particular iTerm2 session. All output in a terminal window (that is, what you see on the screen) is also input to the coprocess. All output from the coprocess acts like text that the user is typing at the keyboard.",
     "协处理是一个任务（如 shell 脚本），与特定 iTerm2 会话有特殊关系。终端窗口中的所有输出（即你在屏幕上看到的内容）也是协处理的输入。协处理的所有输出就像用户在键盘上输入的文本。",
     "協同處理是一個任務（如 shell 指令稿），與特定 iTerm2 工作階段有特殊關係。終端機視窗中的所有輸出（即您在螢幕上看到的內容）也是協同處理的輸入。協同處理的所有輸出就像使用者在鍵盤上輸入的文字。"),
    # ===== Tip 0065 Touch Bar Customization =====
    ("Touch Bar Customization", "触控栏自定义", "觸控列自訂"),
    ("You can customize the touch bar by selecting “View > Customize Touch Bar.” You can add a tab bar for full-screen mode, a user-customizable status button, and you can even define your own touch bar buttons in Settings > Keys. There’s also a new shell integration tool to customize touch bar function key labels.",
     "你可以通过选择“视图 > 自定义触控栏”来自定义触控栏。你可以为全屏模式添加标签栏、用户可自定义的状态按钮，甚至可以在“设置 > 键”中定义自己的触控栏按钮。还有一个新的 shell 集成工具可自定义触控栏功能键标签。",
     "您可以透過選擇「檢視 > 自訂觸控列」來自訂觸控列。您可以為全螢幕模式新增分頁列、使用者可自訂的狀態按鈕，甚至可以在「設定 > 鍵」中定義自己的觸控列按鈕。還有一個新的 Shell 整合工具可自訂觸控列功能鍵標籤。"),
    # ===== Tip 0066 Ligatures =====
    ("Ligatures", "连字", "連字"),
    ("If you use a font that supports ligatures, you can enable ligature support in Settings > Profiles > Text.",
     "如果你使用支持连字的字体，可以在“设置 > 配置文件 > 文本”中启用连字支持。",
     "如果您使用支援連字的字型，可以在「設定 > 設定檔 > 文字」中啟用連字支援。"),
    # ===== Tip 0067 Floating Hotkey Window =====
    ("Floating Hotkey Window", "浮动热键窗口", "浮動熱鍵視窗"),
    ("New in 3.1: You can configure your hotkey window to appear over other apps’ full screen windows. Turn on “Floating Window” in “Settings > Profiles > Keys > Customize Hotkey Window.”",
     "3.1 新功能：你可以将热键窗口配置为显示在其他应用的全屏窗口之上。在“设置 > 配置文件 > 键 > 自定义热键窗口”中开启“浮动窗口”。",
     "3.1 新功能：您可以將熱鍵視窗設定為顯示在其他應用程式的全螢幕視窗之上。在「設定 > 設定檔 > 鍵 > 自訂熱鍵視窗」中開啟「浮動視窗」。"),
    # ===== Tip 0068 Multiple Hotkey Windows =====
    ("Multiple Hotkey Windows", "多个热键窗口", "多個熱鍵視窗"),
    ("New in 3.1: You can have multiple hotkey windows. Each profile can have one or more hotkeys.",
     "3.1 新功能：你可以拥有多个热键窗口。每个配置文件可以有一个或多个热键。",
     "3.1 新功能：您可以擁有多個熱鍵視窗。每個設定檔可以有一個或多個熱鍵。"),
    # ===== Tip 0069 Double-Tap Hotkey =====
    ("Double-Tap Hotkey", "双击热键", "雙擊熱鍵"),
    ("New in 3.1: You can configure a hotkey window to open on double-tap of a modifier in “Settings > Profiles > Keys > Customize Hotkey Window.”",
     "3.1 新功能：你可以在“设置 > 配置文件 > 键 > 自定义热键窗口”中配置热键窗口在双击修饰键时打开。",
     "3.1 新功能：您可以在「設定 > 設定檔 > 鍵 > 自訂熱鍵視窗」中設定熱鍵視窗在雙擊修飾鍵時開啟。"),
    # ===== Tip 0070 Buried Sessions =====
    ("Buried Sessions", "隐藏的会话", "隱藏的工作階段"),
    ("You can “bury” a session with “Session > Bury Session.” It remains hidden until you restore it by selecting it from “Session > Buried Sessions > Your session.”",
     "你可以用“会话 > 隐藏会话”来“隐藏”一个会话。它会保持隐藏，直到你从“会话 > 已隐藏的会话 > 你的会话”中选择恢复。",
     "您可以用「工作階段 > 隱藏工作階段」來「隱藏」一個工作階段。它會保持隱藏，直到您從「工作階段 > 已隱藏的工作階段 > 您的工作階段」中選擇還原。"),
    # ===== Tip 0071 Python API =====
    ("Python API", "Python API", "Python API"),
    ("You can add custom behavior to iTerm2 using the Python API.",
     "你可以使用 Python API 为 iTerm2 添加自定义行为。",
     "您可以使用 Python API 為 iTerm2 新增自訂行為。"),
    # ===== Tip 0072 Status Bar =====
    ("Status Bar", "状态栏", "狀態列"),
    ("You can add a configurable status bar to your terminal windows.",
     "你可以为终端窗口添加可配置的状态栏。",
     "您可以為終端機視窗新增可設定的狀態列。"),
    # ===== Tip 0073 Minimal Theme =====
    ("Minimal Theme", "极简主题", "極簡主題"),
    ("Try the “Minimal” and “Compact” themes to reduce visual clutter. You can set it in “Settings > Appearance > General.”",
     "试试“极简”和“紧凑”主题以减少视觉杂乱。你可以在“设置 > 外观 > 通用”中设置。",
     "試試「極簡」和「緊湊」主題以減少視覺雜亂。您可以在「設定 > 外觀 > 一般」中設定。"),
    # ===== Tip 0074 Session Titles =====
    ("Session Titles", "会话标题", "工作階段標題"),
    ("You can configure which elements are present in session titles in “Settings > Profiles > General > Title.”",
     "你可以在“设置 > 配置文件 > 通用 > 标题”中配置会话标题中包含哪些元素。",
     "您可以在「設定 > 設定檔 > 一般 > 標題」中設定工作階段標題中包含哪些元素。"),
    # ===== Tip 0076 Tab Icons =====
    ("Tab Icons", "标签页图标", "分頁圖示"),
    ("Tabs can show an icon indicating the current application. Configure it in “Settings > Profiles > General > Icon.”",
     "标签页可显示指示当前应用的图标。在“设置 > 配置文件 > 通用 > 图标”中配置。",
     "分頁可顯示指示目前應用程式的圖示。在「設定 > 設定檔 > 一般 > 圖示」中設定。"),
    # ===== Tip 0077 Drag Window by Tab =====
    ("Drag Window by Tab", "通过标签页拖动窗口", "透過分頁拖動視窗"),
    ("Hold ⌥ while dragging a tab to move the window. This is useful in the Compact and Minimal themes, which have a very small area for dragging the window.",
     "拖动标签页时按住 ⌥ 可移动窗口。这在紧凑和极简主题中很有用，因为它们用于拖动窗口的区域很小。",
     "拖動分頁時按住 ⌥ 可移動視窗。這在緊湊和極簡主題中很有用，因為它們用於拖動視窗的區域很小。"),
    # ===== Tip 0078 Composer =====
    ("Composer", "编辑器", "編輯器"),
    ("Press ⇧⌘. to open the Composer. It gives you a scratchpad to edit a command before sending it to the shell.",
     "按 ⇧⌘. 打开编辑器。它提供一个临时编辑区，让你在将命令发送到 shell 前先编辑。",
     "按 ⇧⌘. 開啟編輯器。它提供一個臨時編輯區，讓您在將指令傳送到 shell 前先編輯。"),
    # ===== Tip 0079 Shell Integration: Uploads =====
    ("Shell Integration: Uploads", "Shell 集成：上传", "Shell 整合：上傳"),
    ("If you install Shell Integration on a machine you ssh to, you can drag-drop from Finder into the remote host by holding ⌥ while dragging. The destination directory is determined by where you drop the file in the terminal window: run cd foo, then drop the file below the cd command, and the file will go into the foo directory.",
     "如果你在 ssh 连接的机器上安装了 Shell 集成，可以按住 ⌥ 从 Finder 拖放文件到远程主机。目标目录由你在终端窗口中放置文件的位置决定：运行 cd foo，然后将文件放在 cd 命令下方，文件就会进入 foo 目录。",
     "如果您在 ssh 連線的機器上安裝了 Shell 整合，可以按住 ⌥ 從 Finder 拖放檔案到遠端主機。目標目錄由您在終端機視窗中放置檔案的位置決定：執行 cd foo，然後將檔案放在 cd 指令下方，檔案就會進入 foo 目錄。"),
    # ===== Tip 0080 Composer Power Features =====
    ("Composer Power Features", "编辑器高级功能", "編輯器進階功能"),
    ("The composer supports multiple cursors. It also has the ability to send just one command out of a list, making it easy to walk through a list of commands one-by-one. Click the help button in the composer for details.",
     "编辑器支持多光标。它还能从列表中仅发送一条命令，便于逐条执行命令列表。点击编辑器中的帮助按钮了解详情。",
     "編輯器支援多游標。它還能從列表中僅傳送一條指令，便於逐條執行指令列表。點擊編輯器中的說明按鈕瞭解詳情。"),
    # ===== Tip 0081 Render Selection =====
    ("Render Selection", "渲染选区", "算繪選取範圍"),
    ("Transform selected text into a prettified, syntax-highlighted view with the “Render Selection” command, ideal for JSON, Markdown, or source code. This feature includes horizontal scrolling for easy log navigation.",
     "用“渲染选区”命令将选中文本转换为美化、语法高亮的视图，非常适合 JSON、Markdown 或源代码。此功能包含水平滚动，便于日志导航。",
     "用「算繪選取範圍」指令將選取文字轉換為美化、語法高亮的視圖，非常適合 JSON、Markdown 或原始碼。此功能包含水平捲動，便於日誌導覽。"),
    # ===== Tip 0082 SSH Integration =====
    ("SSH Integration", "SSH 集成", "SSH 整合"),
    ("Export environment variables and copy files to remote hosts seamlessly with SSH integration. Either configure a profile to use ssh or use it2ssh in place of ssh.",
     "通过 SSH 集成无缝导出环境变量和拷贝文件到远程主机。可以配置配置文件使用 ssh，或用 it2ssh 代替 ssh。",
     "透過 SSH 整合無縫匯出環境變數和拷貝檔案到遠端主機。可以設定設定檔使用 ssh，或用 it2ssh 代替 ssh。"),
    # ===== Tip 0083 Auto Composer =====
    ("Auto Composer", "自动编辑器", "自動編輯器"),
    ("Improve your command line with the “auto composer”, which replaces the command line with a native control for ease of use. Requires shell integration.",
     "用“自动编辑器”改进你的命令行，它用原生控件替换命令行以方便使用。需要 Shell 集成。",
     "用「自動編輯器」改進您的命令列，它用原生控制項替換命令列以方便使用。需要 Shell 整合。"),
    # ===== Tip 0084 AI Command Writing =====
    ("AI Command Writing", "AI 命令编写", "AI 指令撰寫"),
    ("Generate commands using AI by entering a prompt in the composer and selecting “Edit > Engage Artificial Intelligence”. An OpenAI API key is required for this functionality.",
     "在编辑器中输入提示并选择“编辑 > 启用人工智能”，即可用 AI 生成命令。此功能需要 OpenAI API 密钥。",
     "在編輯器中輸入提示並選擇「編輯 > 啟用人工智慧」，即可用 AI 產生指令。此功能需要 OpenAI API 金鑰。"),
    # ===== Tip 0085 Codecierge Tool =====
    ("Codecierge Tool", "Codecierge 工具", "Codecierge 工具"),
    ("Set and achieve terminal goals with “Codecierge”, a Toolbelt feature that guides you step-by-step based on your terminal activity. An OpenAI API key is necessary for this feature.",
     "用“Codecierge”设定并实现终端目标，这是一个工具栏功能，会根据你的终端活动逐步引导你。此功能需要 OpenAI API 密钥。",
     "用「Codecierge」設定並實現終端目標，這是一個工具列功能，會根據您的終端活動逐步引導您。此功能需要 OpenAI API 金鑰。"),
    # ===== Tip 0086 Named Marks =====
    ("Named Marks", "命名标记", "具名標記"),
    ("Navigate your command history effortlessly with “named marks” by assigning names to lines in the terminal.",
     "用“命名标记”为终端中的行分配名称，轻松导航你的命令历史。",
     "用「具名標記」為終端機中的行分配名稱，輕鬆導覽您的指令歷史。"),
    # ===== Tip 0087 Font Assignments =====
    ("Font Assignments", "字体分配", "字型分配"),
    ("You can assign specific fonts to Unicode ranges. Use 'Settings > Profiles > Text > Manage Special Exceptions' to manage it and to install a huge set of Powerline symbols.",
     "你可以为 Unicode 区段分配特定字体。用“设置 > 配置文件 > 文本 > 管理特殊例外”来管理，并安装大量 Powerline 符号。",
     "您可以為 Unicode 區段分配特定字型。用「設定 > 設定檔 > 文字 > 管理特殊例外」來管理，並安裝大量 Powerline 符號。"),
    # ===== Tip 0088 Disable Transparency =====
    ("Disable Transparency", "禁用透明度", "停用透明度"),
    ("Maintain clarity in your active window while enjoying transparency in background windows by using 'View > Disable transparency in key window'.",
     "用“视图 > 在关键窗口中禁用透明度”，可在活动窗口中保持清晰，同时在背景窗口中享受透明效果。",
     "用「檢視 > 在關鍵視窗中停用透明度」，可在活動視窗中保持清晰，同時在背景視窗中享受透明效果。"),
    # ===== Tip 0089 Leader Shortcut =====
    ("Leader Shortcut", "前导键快捷键", "前導鍵快速鍵"),
    ("Create two-keystroke shortcuts with a “leader”: a special keystroke that precedes a custom key binding.",
     "用“前导键”创建双键快捷键：一种在自定义按键绑定之前的特殊按键。",
     "用「前導鍵」建立雙鍵快速鍵：一種在自訂按鍵綁定之前的特殊按鍵。"),
    # ===== Tip 0090 Sequence Binding =====
    ("Sequence Binding", "序列绑定", "序列綁定"),
    ("Execute a series of actions in order with a single shortcut using “sequence” key bindings.",
     "用“序列”按键绑定，通过单个快捷键按顺序执行一系列操作。",
     "用「序列」按鍵綁定，透過單一快速鍵按順序執行一系列動作。"),
    # ===== Tip 0091 Export/Import Settings =====
    ("Export/Import Settings", "导出/导入设置", "匯出/匯入設定"),
    ("Easily backup or transfer your iTerm2 settings using the Export/Import feature in “Settings > General > Settings”.",
     "用“设置 > 通用 > 设置”中的导出/导入功能，轻松备份或传输你的 iTerm2 设置。",
     "用「設定 > 一般 > 設定」中的匯出/匯入功能，輕鬆備份或傳輸您的 iTerm2 設定。"),
    # ===== Tip 0092 Multi-Session Bindings =====
    ("Multi-Session Bindings", "多会话绑定", "多工作階段綁定"),
    ("Apply key bindings uniformly across multiple sessions for consistent control in different tabs or windows.",
     "在多个会话中统一应用按键绑定，以便在不同标签页或窗口中保持一致的控制。",
     "在多個工作階段中統一套用按鍵綁定，以便在不同分頁或視窗中保持一致的控制。"),
    # ===== Tip 0093 Inject Trigger =====
    ("Inject Trigger", "注入触发器", "注入觸發器"),
    ("Simulate terminal input as if it were output from a running app with the “Inject” trigger.",
     "用“注入”触发器模拟终端输入，就像来自运行中应用的输出一样。",
     "用「注入」觸發器模擬終端機輸入，就像來自執行中應用程式的輸出一樣。"),
    # ===== Tip 0094 Trigger Status Bar =====
    ("Trigger Status Bar", "触发器状态栏", "觸發器狀態列"),
    ("Easily manage your triggers using the new Triggers status bar component.",
     "使用新的触发器状态栏组件轻松管理你的触发器。",
     "使用新的觸發器狀態列元件輕鬆管理您的觸發器。"),
    # ===== Tip 0095 Session Size in Tab =====
    ("Session Size in Tab", "标签页中显示会话大小", "分頁中顯示工作階段大小"),
    ("Display session size directly in tab titles for convenient at-a-glance information.",
     "在标签页标题中直接显示会话大小，方便一目了然。",
     "在分頁標題中直接顯示工作階段大小，方便一目了然。"),
    # ===== Tip 0096 Advanced Snippet Editing =====
    ("Advanced Snippet Editing", "高级代码片段编辑", "進階程式碼片段編輯"),
    ("Edit snippets in Advanced Paste by holding the ⌥ key, or open them in the composer with ⇧.",
     "在高级粘贴中按住 ⌥ 键编辑代码片段，或用 ⇧ 在编辑器中打开它们。",
     "在進階貼上中按住 ⌥ 鍵編輯程式碼片段，或用 ⇧ 在編輯器中開啟它們。"),
    # ===== Tip 0097 HTML Logs =====
    ("HTML Logs", "HTML 日志", "HTML 日誌"),
    ("Save your terminal logs in HTML format for enhanced readability and sharing capabilities.",
     "以 HTML 格式保存终端日志，增强可读性和分享能力。",
     "以 HTML 格式儲存終端機日誌，增強可讀性和分享能力。"),
    # ===== Tip 0098 ASCIICast Logs =====
    ("ASCIICast Logs", "ASCIICast 日志", "ASCIICast 日誌"),
    ("Create and play back terminal recordings with ASCIICast logs, compatible with asciinema.",
     "用 ASCIICast 日志创建和回放终端录制，兼容 asciinema。",
     "用 ASCIICast 日誌建立和回放終端機錄製，相容於 asciinema。"),
    # ===== Tip 0099 Timestamped Logs =====
    ("Timestamped Logs", "带时间戳的日志", "帶時間戳的日誌"),
    ("Include timestamps in your logs for better tracking and event correlation.",
     "在日志中包含时间戳，便于跟踪和事件关联。",
     "在日誌中包含時間戳，便於追蹤和事件關聯。"),
    # ===== Tip 0100 LastPass & 1Password =====
    ("LastPass & 1Password", "LastPass 和 1Password", "LastPass 和 1Password"),
    ("Utilize LastPass or 1Password with the password manager by configuring it in the menu next to the search field.",
     "通过搜索框旁边的菜单配置，可在密码管理器中使用 LastPass 或 1Password。",
     "透過搜尋框旁的選單設定，可在密碼管理器中使用 LastPass 或 1Password。"),
    # ===== Tip 0101 Password Manager Access =====
    ("Password Manager Access", "密码管理器访问", "密碼管理器存取"),
    ("Access your password manager without authentication by adjusting the settings via the menu next to its search field.",
     "通过搜索框旁边的菜单调整设置，无需认证即可访问密码管理器。",
     "透過搜尋框旁的選單調整設定，無需認證即可存取密碼管理器。"),
    # ===== Tip 0102 Password Generation =====
    ("Password Generation", "密码生成", "密碼產生"),
    ("Generate strong, secure passwords using the password manager’s new password generation feature.",
     "使用密码管理器的新密码生成功能生成强健、安全的密码。",
     "使用密碼管理器的新密碼產生功能產生強健、安全的密碼。"),
    # ===== Tip 0103 it2tip Utility =====
    ("it2tip Utility", "it2tip 工具", "it2tip 工具"),
    ("Access tips of the day with the it2tip utility, a command line app. Enable it by installing shell integration and utilities.",
     "用 it2tip 工具（一个命令行应用）访问每日提示。通过安装 Shell 集成和工具来启用它。",
     "用 it2tip 工具（一個命令列應用程式）存取每日提示。透過安裝 Shell 整合和工具來啟用它。"),
    # ===== Tip 0104 Auto Shell Integration =====
    ("Auto Shell Integration", "自动 Shell 集成", "自動 Shell 整合"),
    ("Experience automatic shell integration when creating a login shell, removing the need for explicit setup on your Mac.",
     "创建登录 shell 时体验自动 Shell 集成，无需在 Mac 上手动设置。",
     "建立登入 shell 時體驗自動 Shell 整合，無需在 Mac 上手動設定。"),
    # ===== Tip 0105 Command Prompt Info =====
    ("Command Prompt Info", "命令提示信息", "指令提示資訊"),
    ("Get detailed information about commands by ⌘-clicking on the command prompt.",
     "按住 ⌘ 点击命令提示符可获取命令的详细信息。",
     "按住 ⌘ 點擊指令提示符可取得指令的詳細資訊。"),
    # ===== Tip 0106 tmux Integration =====
    ("tmux Integration", "tmux 集成", "tmux 整合"),
    ("Use tmux integration for automatic key bindings that emulate tmux’s shortcuts, configurable via the Leader settings.",
     "使用 tmux 集成可获得模拟 tmux 快捷键的自动按键绑定，可通过前导键设置配置。",
     "使用 tmux 整合可獲得模擬 tmux 快速鍵的自動按鍵綁定，可透過前導鍵設定配置。"),
    # ===== Tip 0107 tmux Clipboard Mirroring =====
    ("tmux Clipboard Mirroring", "tmux 剪贴板镜像", "tmux 剪貼簿鏡像"),
    ("Sync your tmux paste buffer with the local clipboard for seamless integration (requires tmux 3.4).",
     "将 tmux 粘贴缓冲区与本地剪贴板同步以实现无缝集成（需要 tmux 3.4）。",
     "將 tmux 貼上緩衝區與本地剪貼簿同步以實現無縫整合（需要 tmux 3.4）。"),
    # ===== Tip 0108 Multi-Cursor in Composer =====
    ("Multi-Cursor in Composer", "编辑器中的多光标", "編輯器中的多游標"),
    ("Enhance your editing in the Composer with multiple cursors, created using ^⇧-up/down or ⌥-drag.",
     "在编辑器中用多光标增强编辑，通过 ^⇧-上/下或 ⌥-拖动创建。",
     "在編輯器中用多游標增強編輯，透過 ^⇧-上/下或 ⌥-拖動建立。"),
    # ===== Tip 0109 Advanced Paste from Composer =====
    ("Advanced Paste from Composer", "从编辑器高级粘贴", "從編輯器進階貼上"),
    ("Move content from the Composer to the Advanced Paste window with ⌥⌘V for additional editing options.",
     "用 ⌥⌘V 将内容从编辑器移到高级粘贴窗口，以获得更多编辑选项。",
     "用 ⌥⌘V 將內容從編輯器移到進階貼上視窗，以獲得更多編輯選項。"),
    # ===== Tip 0110 Composer Search =====
    ("Composer Search", "编辑器搜索", "編輯器搜尋"),
    ("Search within the Composer using ⌘F to quickly find specific text.",
     "在编辑器中用 ⌘F 快速查找特定文本。",
     "在編輯器中用 ⌘F 快速尋找特定文字。"),
    # ===== Tip 0111 Resize Composer =====
    ("Resize Composer", "调整编辑器大小", "調整編輯器大小"),
    ("Adjust the Composer’s height to suit your needs by dragging its bottom edge.",
     "拖动编辑器底边可调整其高度以适应你的需求。",
     "拖動編輯器底邊可調整其高度以適應您的需求。"),
    # ===== Tip 0112 Explain Command =====
    ("Explain Command", "解释命令", "解釋指令"),
    ("Learn more about your commands by ⌘-clicking in the Composer to open them in explainshell.com.",
     "在编辑器中按住 ⌘ 点击命令可在 explainshell.com 中打开，了解更多信息。",
     "在編輯器中按住 ⌘ 點擊指令可在 explainshell.com 中開啟，瞭解更多資訊。"),
    # ===== Tip 0113 Quick Command Send =====
    ("Quick Command Send", "快速发送命令", "快速傳送指令"),
    ("Quickly send and remove commands in the Composer using ⌥⇧-enter.",
     "在编辑器中用 ⌥⇧-enter 快速发送并移除命令。",
     "在編輯器中用 ⌥⇧-enter 快速傳送並移除指令。"),
    # ===== Tip 0114 Queue Commands =====
    ("Queue Commands", "排队命令", "排隊指令"),
    ("Queue up a command in the Composer to be sent after the current command finishes with ⌥-Enter.",
     "在编辑器中用 ⌥-Enter 将命令排队，在当前命令完成后发送。",
     "在編輯器中用 ⌥-Enter 將指令排隊，在目前指令完成後傳送。"),
    # ===== Tip 0115 Draggable Tip Window =====
    ("Draggable Tip Window", "可拖动的提示窗口", "可拖動的提示視窗"),
    ("Reposition the Tip of the Day window conveniently on your screen, as it is now draggable.",
     "现在可以拖动每日提示窗口，方便地在屏幕上重新定位。",
     "現在可以拖動每日提示視窗，方便地在螢幕上重新定位。"),
    # ===== Tip 0116 AI Chat =====
    ("AI Chat", "AI 对话", "AI 對話"),
    ("iTerm2 now has an AI Chat feature! Use “Window > AI Chats” or “Edit > Explain Output with AI”. The assistant can interact with your terminal (with your permission) and explain command output, adding annotations right in the terminal.",
     "iTerm2 现在有 AI 对话功能！用“窗口 > AI 对话”或“编辑 > 用 AI 解释输出”。助手可以（经你许可）与终端交互并解释命令输出，直接在终端中添加注释。",
     "iTerm2 現在有 AI 對話功能！用「視窗 > AI 對話」或「編輯 > 用 AI 解釋輸出」。助手可以（經您許可）與終端機互動並解釋指令輸出，直接在終端機中新增註解。"),
    # ===== Tip 0117 Web Browser Profiles =====
    ("Web Browser Profiles", "浏览器配置文件", "瀏覽器設定檔"),
    ("You can configure a profile to be a web browser! In “Settings > Profiles > General”, set “Profile Type” to “Web Browser”. Key bindings, smart selection, and the password manager all work in browser sessions.",
     "你可以将配置文件配置为浏览器！在“设置 > 配置文件 > 通用”中，将“配置文件类型”设为“浏览器”。按键绑定、智能选择和密码管理器都能在浏览器会话中使用。",
     "您可以將設定檔設定為瀏覽器！在「設定 > 設定檔 > 一般」中，將「設定檔類型」設為「瀏覽器」。按鍵綁定、智慧選取和密碼管理器都能在瀏覽器工作階段中使用。"),
    # ===== Tip 0118 Adjacent Timestamps =====
    ("Adjacent Timestamps", "相邻时间戳", "相鄰時間戳"),
    ("Timestamps can now be shown next to terminal content instead of overlapping. Configure it in “Settings > Profiles > Session > Timestamps”. Right-click on any line and select “Set Baseline for Relative Timestamps” to see time elapsed between lines.",
     "时间戳现在可以显示在终端内容旁边而不是重叠。在“设置 > 配置文件 > 会话 > 时间戳”中配置。右键点击任意行并选择“为相对时间戳设置基准”可查看行之间的时间差。",
     "時間戳現在可以顯示在終端機內容旁邊而不是重疊。在「設定 > 設定檔 > 工作階段 > 時間戳」中設定。右鍵點擊任意行並選擇「為相對時間戳設定基準」可查看行之間的時間差。"),
    # ===== Tip 0119 Pretty-Print JSON =====
    ("Pretty-Print JSON", "格式化 JSON", "格式化 JSON"),
    ("Select a block of JSON text and choose “Edit > Replace Selection > Replace with Pretty-Printed JSON” to make it readable. Perfect for debugging API responses and log files.",
     "选择一块 JSON 文本并选择“编辑 > 替换选区 > 替换为格式化的 JSON”使其可读。非常适合调试 API 响应和日志文件。",
     "選取一塊 JSON 文字並選擇「編輯 > 替換選取範圍 > 替換為格式化的 JSON」使其可讀。非常適合除錯 API 回應和日誌檔案。"),
    # ===== Tip 0120 Command Palette =====
    ("Command Palette", "命令面板", "指令面板"),
    ("Open Quickly (⇧⌘O) is now a command palette! Just type the name of a menu item to activate it.",
     "快速打开（⇧⌘O）现在是一个命令面板！只需输入菜单项名称即可激活它。",
     "快速開啟（⇧⌘O）現在是一個指令面板！只需輸入選單項目名稱即可啟用它。"),
    # ===== Tip 0121 Click Paths in Shell Prompts =====
    ("Click Paths in Shell Prompts", "点击 shell 提示符中的路径", "點擊 shell 提示符中的路徑"),
    ("Enable “Settings > Profiles > Terminal > Click on a path in a shell prompt to open Navigator” to navigate your filesystem by clicking on paths in your prompt. Requires Shell Integration.",
     "启用“设置 > 配置文件 > 终端 > 点击 shell 提示符中的路径以打开导航器”，即可通过点击提示符中的路径来导航文件系统。需要 Shell 集成。",
     "啟用「設定 > 設定檔 > 終端機 > 點擊 shell 提示符中的路徑以開啟導航器」，即可透過點擊提示符中的路徑來導覽檔案系統。需要 Shell 整合。"),
    # ===== Tip 0122 SSH File Browser =====
    ("SSH File Browser", "SSH 文件浏览器", "SSH 檔案瀏覽器"),
    ("When connected via SSH Integration, use “Shell > ssh > Download Files” to browse and download files from the remote host without opening a new connection. Files on SSH hosts also appear in file open/save dialogs!",
     "通过 SSH 集成连接时，用“Shell > ssh > 下载文件”可浏览和下载远程主机上的文件，无需打开新连接。SSH 主机上的文件也会出现在文件打开/保存对话框中！",
     "透過 SSH 整合連線時，用「Shell > ssh > 下載檔案」可瀏覽和下載遠端主機上的檔案，無需開啟新連線。SSH 主機上的檔案也會出現在檔案開啟/儲存對話框中！"),
]

# Deduplicate by key (preserve first occurrence)
seen = set()
UNIQ = []
for k, h, t in KEYS:
    if k in seen:
        continue
    seen.add(k)
    UNIQ.append((k, h, t))
print(f'Total unique keys: {len(UNIQ)} (deduped from {len(KEYS)})')

root = 'sources/Tips'
for loc in LOCALES:
    d = f'{root}/{loc}.lproj'
    os.makedirs(d, exist_ok=True)
    lines = [f'"{esc(k)}" = "{esc(val(k, h, t, loc))}";' for k, h, t in UNIQ]
    fp = f'{d}/{T}.strings'
    open(fp, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(f'{fp}: {len(lines)} keys')

print('\nAll OK')
