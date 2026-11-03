//
//  iTermApplicationDelegate.swift
//  iTerm2
//
//  Created by George Nachman on 3/28/25.
//

@objc
extension iTermApplicationDelegate {
    @objc
    func registerMenuTips() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        struct Tip {
            var identifier: String
            var imageName: String?
            var text: String
        }

        let toolbeltText = NSLocalizedString("""
        The **Toolbelt** provides a versatile, dockable sidebar that offers quick access to frequently used features and information. It supports multiple panels that can be displayed simultaneously, including clipboard history, recently opened directories, command history, a scratchpad for notes, and more.
        """, tableName: "AppKit", comment: "工具带提供了一个多功能的可停靠侧边栏，可以快速访问常用功能和信息。它支持同时显示多个面板，包括剪贴板历史、最近打开的目录、命令历史、用于笔记的便签本等。")

        let tips = [
            Tip(identifier: "Toolbelt",
                imageName: "Toolbelt-Screenshot",
                text: toolbeltText),
            Tip(identifier: "Show Toolbelt",
                imageName: "Toolbelt-Screenshot",
                text: toolbeltText),
            Tip(identifier: "Split Vertically with Current Profile",
                imageName: "VerticalSplit",
                text: NSLocalizedString("Splits the current session vertically, placing a new session in the right half. The new session inherits the profile of the current session, including any changes made in `Session > Edit Session`.", tableName: "AppKit", comment: "垂直分割当前会话，将新会话放置在右半部分。新会话继承当前会话的配置文件，包括在「会话 > 编辑会话」中所做的任何更改。")),
            Tip(identifier: "Split Horizontally with Current Profile",
                imageName: "HorizontalSplit",
                text: NSLocalizedString("Splits the current session horizontally, placing a new session in the bottom half. The new session inherits the profile of the current session, including any changes made in `Session > Edit Session`.", tableName: "AppKit", comment: "水平分割当前会话，将新会话放置在下半部分。新会话继承当前会话的配置文件，包括在「会话 > 编辑会话」中所做的任何更改。")),
            Tip(identifier: "Split Vertically…",
                imageName: "VerticalSplit",
                text: NSLocalizedString("Prompts you to select a profile and then splits the current session vertically, placing the new session in the right half.", tableName: "AppKit", comment: "提示您选择一个配置文件，然后垂直分割当前会话，将新会话放置在右半部分。")),
            Tip(identifier: "Split Horizontally…",
                imageName: "HorizontalSplit",
                text: NSLocalizedString("Prompts you to select a profile and then splits the current session horizontally, placing the new session in the bottom half.", tableName: "AppKit", comment: "提示您选择一个配置文件，然后水平分割当前会话，将新会话放置在下半部分。")),
            Tip(identifier: "tmux.Dashboard",
                imageName: "TmuxDashboard",
                text: NSLocalizedString("The **tmux Dashboard** helps you switch between tmux sessions, show and hide windows, and administer other features of tmux without needing to use tmux’s commands.", tableName: "AppKit", comment: "tmux 仪表板帮助您在 tmux 会话之间切换、显示和隐藏窗口，以及管理 tmux 的其他功能，而无需使用 tmux 的命令。")),
            Tip(identifier: "Paste Special.Advanced Paste…",
                imageName: "AdvancedPaste",
                text: NSLocalizedString("**Advanced Paste** lets you edit text before pasting, remove control characters, convert tabs, base64-encode, and perform regular expression substitutions. It also lets you fine-tune how quickly pasted text is sent.", tableName: "AppKit", comment: "高级粘贴允许您在粘贴前编辑文本、删除控制字符、转换制表符、进行 base64 编码以及执行正则表达式替换。它还允许您微调粘贴文本的发送速度。")),
            Tip(identifier: "Render Selection Natively",
                imageName: "RenderNatively",
                text: NSLocalizedString("**Render Natively** shows a nicely formatted, syntax-highlighted rendition of a document. For example, Markdown renders beautifully. It also allows for horizontal scrolling, making it a convenient way to view log files.", tableName: "AppKit", comment: "原生渲染显示格式优美、语法高亮的文档渲染。例如，Markdown 渲染效果非常好。它还支持水平滚动，使其成为查看日志文件的便捷方式。")),
            Tip(identifier: "Paste Special.Warn Before Multi-Line Paste",
                text: NSLocalizedString("You’ll be prompted any time you paste text containing a newline. See also **Limit Multi-Line Paste Warning to Shell Prompt**.", tableName: "AppKit", comment: "每当您粘贴包含换行符的文本时，系统都会提示您。另请参阅「将多行粘贴警告限制在 Shell 提示符」。")),
            Tip(identifier: "Paste Special.Limit Multi-Line Paste Warning to Shell Prompt",
                text: NSLocalizedString("This is effective only when **Warn Before Multi-Line Paste** is enabled. It also requires Shell Integration. When enabled, it suppresses confirmation when pasting text containing a newline if you are not at a shell prompt.", tableName: "AppKit", comment: "此选项仅在启用「多行粘贴前警告」时有效。它还需要 Shell 集成。启用后，如果您不在 shell 提示符下，粘贴包含换行符的文本时将不再需要确认。")),
            Tip(identifier: "Paste Special.Warn Before Pasting One Line Ending in a Newline at Shell Prompt",
                text: NSLocalizedString("If enabled, you’ll be prompted to confirm that you wish to send a newline when pasting a single line of text ending in a newline. Shell Integration is required.", tableName: "AppKit", comment: "启用后，当您粘贴以换行符结尾的单行文本时，系统会提示您确认是否要发送换行符。需要 Shell 集成。")),
            Tip(identifier: "Engage Artificial Intelligence",
                imageName: "AIMenuTip",
                text: NSLocalizedString("When selected at a shell prompt (provided Shell Integration is installed) or in the Composer, it sends the current command to the configured AI system along with a prompt for it to generate a command. If no input is provided, you’ll be asked to give instructions. The generated command goes into the Composer.", tableName: "AppKit", comment: "在 shell 提示符下（前提是已安装 Shell 集成）或在编辑器中选择时，它会将当前命令与提示一起发送到配置的 AI 系统以生成命令。如果未提供输入，系统会要求您提供指令。生成的命令将进入编辑器。")),
            Tip(identifier: "Explain Output with AI",
                imageName: "AIExplainTip",
                text: NSLocalizedString("This is meant to be used at the shell prompt after executing a command. It requires Shell Integration. The output of the preceding (or selected) command is sent to AI, which annotates the output and opens a chat window for further discussion.", tableName: "AppKit", comment: "此功能旨在在 shell 提示符下执行命令后使用。它需要 Shell 集成。前一个（或选定）命令的输出被发送到 AI，AI 会对输出进行注释并打开对话窗口以供进一步讨论。")),
            Tip(identifier: "Edit.Snippets",
                imageName: "SnippetsTip",
                text: NSLocalizedString("Snippets are pieces of text that you save to reuse later. They’re great for frequently used commands, hard-to-remember directories, and much more.", tableName: "AppKit", comment: "代码片段是您保存以供日后重复使用的文本片段。它们非常适合用于常用命令、难以记住的目录等等。")),
            Tip(identifier: "Edit.Actions",
                imageName: "ActionsMenuTip",
                text: NSLocalizedString("Actions are saved instructions for iTerm2. For example, you could create an action that opens a new window and then creates a split pane.", tableName: "AppKit", comment: "操作是为 iTerm2 保存的指令。例如，您可以创建一个操作来打开一个新窗口，然后创建一个分割窗格。")),
            Tip(identifier: "Set Default Width",
                text: NSLocalizedString("Records the current width of the toolbelt for use in newly created windows.", tableName: "AppKit", comment: "记录工具带的当前宽度，以便在新创建的窗口中使用。")),
            Tip(identifier: "Toolbelt.Actions",
                imageName: "ActionsMenuTip",
                text: NSLocalizedString("Actions are saved instructions for iTerm2. For example, you could create an action that opens a new window and then creates a split pane.", tableName: "AppKit", comment: "操作是为 iTerm2 保存的指令。例如，您可以创建一个操作来打开一个新窗口，然后创建一个分割窗格。")),
            Tip(identifier: "Selection Respects Soft Boundaries",
                imageName: "SelectionRespectsSoftBoundariesMenuTip",
                text: NSLocalizedString("When enabled, dividers rendered by programs like vim or emacs are detected, and text selection wraps around them.", tableName: "AppKit", comment: "启用后，可以检测到 vim 或 emacs 等程序渲染的分隔线，文本选择会围绕它们自动换行。")),
            Tip(identifier: "Find.Filter",
                imageName: "FilterMenuTip",
                text: NSLocalizedString("**Filter** allows you to hide any lines that do not match a search query, which can be a substring or regular expression. It updates live as new text arrives.", tableName: "AppKit", comment: "过滤器允许您隐藏与搜索查询不匹配的行，搜索查询可以是子字符串或正则表达式。当新文本到达时，它会实时更新。")),
            Tip(identifier: "Marks and Annotations.Set Mark",
                text: NSLocalizedString("A **Mark** appears as a blue triangle in the left margin. You can easily navigate among marks using **Jump to Mark**, **Next Mark**, and **Previous Mark**. If Shell Integration is enabled, a Mark is automatically added at each shell prompt.", tableName: "AppKit", comment: "标记以蓝色三角形出现在左边距中。您可以使用「跳转到标记」、「下一个标记」和「上一个标记」轻松在标记之间导航。如果启用了 Shell 集成，则每个 shell 提示符处会自动添加标记。")),
            Tip(identifier: "Set Named Mark",
                text: NSLocalizedString("A **Named Mark** appears as a blue triangle in the left margin. In addition to being easy to navigate with **Next Mark** and **Previous Mark**, you can also find Named Marks in the Toolbelt’s **Named Marks** tool.", tableName: "AppKit", comment: "命名标记以蓝色三角形出现在左边距中。除了可以使用「下一个标记」和「上一个标记」轻松导航外，您还可以在工具带的「命名标记」工具中找到命名标记。")),
            Tip(identifier: "Toolbelt.Named Marks",
                text: NSLocalizedString("A **Named Mark** appears as a blue triangle in the left margin. In addition to being easy to navigate with **Next Mark** and **Previous Mark**, you can also find Named Marks in this Toolbelt tool.", tableName: "AppKit", comment: "命名标记以蓝色三角形出现在左边距中。除了可以使用「下一个标记」和「上一个标记」轻松导航外，您还可以在此工具带工具中找到命名标记。")),
            Tip(identifier: "Fold Selected Lines",
                imageName: "FoldMenuTip",
                text: NSLocalizedString("**Fold** lets you collapse multiple lines into a single line to hide distracting text. You can always unfold it by clicking the arrow in the margin, selecting the text and using **Edit > Unfold in Selection**, or right-clicking and choosing **Unfold**.", tableName: "AppKit", comment: "折叠允许您将多行合并为一行以隐藏干扰文本。您始终可以通过单击边距中的箭头、选择文本并使用「编辑 > 在选择中展开」，或右键单击并选择「展开」来展开它。")),
            Tip(identifier: "Toolbelt.Captured Output",
                imageName: "CapturedOutputMenuTip",
                text: NSLocalizedString("**Captured Output** works in conjunction with a Trigger to detect interesting text in the terminal and make it easy to find. The Toolbelt tool shows a list of captured text. You can click to navigate to it or double-click to enter a programmable command. This is useful for finding errors in the output of a build command, for example. It requires Shell Integration.", tableName: "AppKit", comment: "捕获输出与触发器配合使用，可以检测终端中的有趣文本并使其易于查找。工具带工具显示捕获文本的列表。您可以单击以导航到它，或双击以输入可编程命令。这对于查找构建命令输出中的错误很有用。它需要 Shell 集成。")),
            Tip(identifier: "Toolbelt.Codecierge",
                imageName: "CodeciergeMenuTip",
                text: NSLocalizedString("**Codecierge** uses AI to help you achieve a goal. Tell it what you want to do, and it can watch your terminal to interpret output and suggest commands. Shell Integration is required.", tableName: "AppKit", comment: "Codecierge 使用 AI 帮助您实现目标。告诉它您想做什么，它可以监视您的终端以解释输出并建议命令。需要 Shell 集成。")),
            Tip(identifier: "Toolbelt.Command History",
                text: NSLocalizedString("If Shell Integration is installed, **Command History** shows a searchable list of recently run commands on the current host.", tableName: "AppKit", comment: "如果安装了 Shell 集成，命令历史记录会显示当前主机上最近运行的命令的可搜索列表。")),
            Tip(identifier: "Toolbelt.Notes",
                imageName: "NotesMenuTip",
                text: NSLocalizedString("**Notes** is a single, persistent notepad in your Toolbelt. It’s useful for keeping track of what you’re doing or composing messages.", tableName: "AppKit", comment: "笔记是您工具带中的单个持久记事本。它对于跟踪您正在做的事情或撰写消息很有用。")),
            Tip(identifier: "Toolbelt.Paste History",
                text: NSLocalizedString("**Paste History** shows text that you have copied and pasted in iTerm2. You can configure it to be saved long term.", tableName: "AppKit", comment: "粘贴历史记录显示您在 iTerm2 中复制和粘贴的文本。您可以将其配置为长期保存。")),
            Tip(identifier: "Toolbelt.Profiles",
                text: NSLocalizedString("Shows a list of your profiles so you can create new sessions easily.", tableName: "AppKit", comment: "显示您的配置文件列表，以便您可以轻松创建新会话。")),
            Tip(identifier: "Toolbelt.Recent Directories",
                text: NSLocalizedString("Shows your most used directories, sorted by a combination of frequency and recency of use. Requires Shell Integration.", tableName: "AppKit", comment: "显示您最常用的目录，按使用频率和最近使用时间的组合排序。需要 Shell 集成。")),
            Tip(identifier: "Toolbelt.Snippets",
                imageName: "SnippetsTip",
                text: NSLocalizedString("Snippets are pieces of text that you save to reuse later. They’re great for frequently used commands, hard-to-remember directories, and much more.", tableName: "AppKit", comment: "代码片段是您保存以供日后重复使用的文本片段。它们非常适合用于常用命令、难以记住的目录等等。")),
            Tip(identifier: "Zoom In on Selection",
                text: NSLocalizedString("Hides everything except the lines of selected text to remove distractions.", tableName: "AppKit", comment: "隐藏除选定文本行之外的所有内容以消除干扰。")),
            Tip(identifier: "Find Cursor",
                imageName: "FindCursorMenuTip",
                text: NSLocalizedString("Highlights the location of the cursor and unhides it if it is currently hidden.", tableName: "AppKit", comment: "高亮显示光标的位置，如果当前隐藏则取消隐藏。")),
            Tip(identifier: "Show Annotations",
                imageName: "AnnotationsMenuTip",
                text: NSLocalizedString("Annotations are inline markup. When closed, they appear as a yellow underline; when open, they look like yellow stickies where you can write memos about content in the terminal window.", tableName: "AppKit", comment: "注释是内联标记。关闭时，它们显示为黄色下划线；打开时，它们看起来像黄色便签，您可以在其中撰写有关终端窗口内容的备忘录。")),
            Tip(identifier: "Composer",
                imageName: "ComposerMenuTip",
                text: NSLocalizedString("The Composer is a window within the terminal where you can edit text using macOS-native controls. It does syntax highlighting, command and filename completion—even over SSH (provided you use SSH Integration). If AI features are enabled, you can also get AI-powered suggestions. You can even have multiple cursors! When you’re ready, you can send the whole buffer or just a line at a time to your shell.", tableName: "AppKit", comment: "编辑器是终端内的一个窗口，您可以在其中使用 macOS 原生控件编辑文本。它支持语法高亮、命令和文件名补全——甚至可以通过 SSH（前提是您使用 SSH 集成）。如果启用了 AI 功能，您还可以获得 AI 驱动的建议。您甚至可以有多个光标！当您准备好时，您可以将整个缓冲区或一次一行地发送到您的 shell。")),
            Tip(identifier: "Auto Composer",
                imageName: "AutoComposerMenuTip",
                text: NSLocalizedString("**Auto Composer** replaces your shell prompt with a macOS-native text field. It does syntax highlighting and command and filename completion. You can also enable AI-powered suggestions. Shell Integration is required.", tableName: "AppKit", comment: "自动编辑器用 macOS 原生文本字段替换您的 shell 提示符。它支持语法高亮以及命令和文件名补全。您还可以启用 AI 驱动的建议。需要 Shell 集成。")),
            Tip(identifier: "Open Quickly",
                imageName: "OpenQuicklyMenuTip",
                text: NSLocalizedString("**Open Quickly** provides quick access to many common actions. You can use it to find a session by typing its name, directory, hostname, or recent command. You can also use it to switch profiles or create a new window by typing the name of a profile. Restore an arrangement by entering its name. Press `/` to get tips for quick commands.", tableName: "AppKit", comment: "快速打开提供了对许多常见操作的快速访问。您可以通过输入会话名称、目录、主机名或最近的命令来查找会话。您还可以通过输入配置文件名称来切换配置文件或创建新窗口。通过输入名称来恢复排列。按 `/` 获取快速命令提示。")),
            Tip(identifier: "Start Instant Replay",
                imageName: "InstantReplayMenuTip",
                text: NSLocalizedString("**Instant Replay** lets you review recent terminal history. It’s handy if something just disappeared from the screen and it isn’t in scrollback history.", tableName: "AppKit", comment: "即时回放让您查看最近的终端历史记录。如果某些内容刚刚从屏幕上消失且不在滚动历史记录中，它会非常方便。")),
            Tip(identifier: "Run Coprocess…",
                imageName: "CoprocessMenuTip",
                text: NSLocalizedString("A **Coprocess** is a program that automates interactions in the terminal. Input to the terminal is redirected to stdin of the coprocess, and its output is sent back to the terminal as though the coprocess were typing.", tableName: "AppKit", comment: "协进程是一个自动执行终端交互的程序。终端的输入被重定向到协进程的标准输入，其输出被发送回终端，就像协进程在输入一样。")),
            Tip(identifier: "Stop Coprocess",
                imageName: "CoprocessMenuTip",
                text: NSLocalizedString("Stops the active coprocess. Input to the terminal is no longer redirected to the coprocess, and its output ceases.", tableName: "AppKit", comment: "停止活动的协进程。终端的输入不再重定向到协进程，其输出也会停止。")),
            Tip(identifier: "Triggers",
                imageName: "TriggersMenuTip",
                text: NSLocalizedString("**Triggers** are actions the terminal performs automatically when text matching a regular expression is received. For example, you can highlight text or display an alert.", tableName: "AppKit", comment: "触发器是终端在接收到与正则表达式匹配的文本时自动执行的操作。例如，您可以高亮显示文本或显示警报。")),
            Tip(identifier: "Terminal State.Literal Mode",
                text: NSLocalizedString("When enabled, control characters are displayed visually rather than being interpreted as usual.", tableName: "AppKit", comment: "启用后，控制字符以视觉方式显示，而不是按常规方式解释。")),
            Tip(identifier: "Terminal State.Report Modifiers with CSI u",
                text: NSLocalizedString("This mode is generally not recommended. **Disambiguate Escape** is a more modern approach.", tableName: "AppKit", comment: "通常不建议使用此模式。**消除歧义转义**是一种更现代的方法。")),
            Tip(identifier: "Bury Session",
                imageName: "BurySessionMenuTip",
                text: NSLocalizedString("Buried sessions are hidden in the **Buried Sessions** menu below and do not appear in any window. These are particularly useful for the session where you initiate tmux integration by running `tmux -CC`.", tableName: "AppKit", comment: "已隐藏的会话隐藏在下方的「已隐藏会话」菜单中，不会出现在任何窗口中。这些对于您通过运行 `tmux -CC` 启动 tmux 集成的会话特别有用。")),
            Tip(identifier: "Open Interactive Window",
                text: NSLocalizedString("The Python REPL opens a window running a special Python interpreter that lets you experiment with iTerm2’s Python API. You can use `await` at the top level of the interpreter.", tableName: "AppKit", comment: "Python REPL 打开一个运行特殊 Python 解释器的窗口，让您可以尝试 iTerm2 的 Python API。您可以在解释器的顶层使用 `await`。")),
            Tip(identifier: "Manage Dependencies",
                text: NSLocalizedString("Opens a UI where you can add, update, or remove pip dependencies of a Python API script.", tableName: "AppKit", comment: "打开一个界面，您可以在其中添加、更新或删除 Python API 脚本的 pip 依赖项。")),
            Tip(identifier: "Install Python Runtime",
                text: NSLocalizedString("iTerm2’s Python Runtime is a large binary package (hundreds of MBs) that enables the Python API by installing a pre-built Python environment that scripts can use.", tableName: "AppKit", comment: "iTerm2 的 Python 运行时是一个大型二进制包（数百 MB），通过安装脚本可以使用的预构建 Python 环境来启用 Python API。")),
            Tip(identifier: "Import Script",
                text: NSLocalizedString("Use **Import** to install scripts others have shared with you. These scripts have the `.its` extension.", tableName: "AppKit", comment: "使用「导入」来安装他人与您共享的脚本。这些脚本具有 `.its` 扩展名。")),
            Tip(identifier: "Export Script",
                text: NSLocalizedString("If you want to share Python API scripts, you can export them to an `.its` file. If you have a code signing certificate and private key in your Keychain, you can also sign the `.its` file.", tableName: "AppKit", comment: "如果您想共享 Python API 脚本，可以将它们导出为 `.its` 文件。如果您的钥匙串中有代码签名证书和私钥，您还可以对 `.its` 文件进行签名。")),
            Tip(identifier: "Script Console",
                text: NSLocalizedString("View errors and low-level communication between Python API scripts and iTerm2 here.\n\nThe Inspector can be accessed from the Console. It allows you to browse variables in sessions, tabs, and windows.", tableName: "AppKit", comment: "在此处查看 Python API 脚本与 iTerm2 之间的错误和低级通信。\n\n检查器可以从控制台访问。它允许您浏览会话、选项卡和窗口中的变量。")),
            Tip(identifier: "Arrangements",
                imageName: "ArrangementsMenuTip",
                text: NSLocalizedString("**Window Arrangements** are a saved record of one or more windows, their tabs, and split panes, including how each pane is configured. They do not include content. They’re a quick way to create a working environment with multiple sessions in various configurations.", tableName: "AppKit", comment: "窗口排列是一个或多个窗口、其选项卡和分割窗格的保存记录，包括每个窗格的配置方式。它们不包括内容。它们是创建具有各种配置的多个会话的工作环境的快速方式。")),
            Tip(identifier: "Password Manager",
                imageName: "PasswordManagerMenuTip",
                text: NSLocalizedString("The **Password Manager** helps you keep track of your passwords securely. By default, it stores them in the macOS Keychain, but it can also use 1Password or LastPass.", tableName: "AppKit", comment: "密码管理器帮助您安全地跟踪密码。默认情况下，它将密码存储在 macOS 钥匙串中，但也可以使用 1Password 或 LastPass。")),
            Tip(identifier: "AI Chats",
                imageName: "AIChatMenuTip",
                text: NSLocalizedString("**AI Chats** opens a chat window where you can interact with AI. It can optionally view and control the terminal if you grant it permission.", tableName: "AppKit", comment: "AI 对话打开一个对话窗口，您可以在其中与 AI 交互。如果您授予权限，它可以选择性地查看和控制终端。")),
            Tip(identifier: "Pin Hotkey Window",
                text: NSLocalizedString("A **pinned** Hotkey Window does not close automatically when it loses keyboard focus.", tableName: "AppKit", comment: "固定的快捷键窗口在失去键盘焦点时不会自动关闭。")),
            Tip(identifier: "GPU Renderer Availability",
                text: NSLocalizedString("Checks whether the GPU Renderer is currently being used in the active session. This is sometimes useful for debugging.", tableName: "AppKit", comment: "检查活动会话中是否正在使用 GPU 渲染器。这有时对调试很有用。")),
            Tip(identifier: "Secure Keyboard Entry",
                text: NSLocalizedString("**Secure Keyboard Entry** prevents other programs from intercepting your keystrokes in the terminal. However, it also breaks some functionality: other programs cannot activate their windows while this is enabled. For example, the `open` command will still open an app, but it won’t be activated.", tableName: "AppKit", comment: "安全键盘输入可以防止其他程序拦截您在终端中的击键。但是，它也会破坏一些功能：启用此功能后，其他程序无法激活其窗口。例如，`open` 命令仍然会打开应用程序，但不会被激活。")),
            Tip(identifier: "Install Shell Integration",
                text: NSLocalizedString("**Shell Integration** consists of shell scripts that run when you log in. They inform iTerm2 of where your shell prompt is. This enables dozens of useful features such as command history, directory history, AI features, and more.", tableName: "AppKit", comment: "Shell 集成由登录时运行的 shell 脚本组成。它们通知 iTerm2 您的 shell 提示符在哪里。这启用了许多有用的功能，如命令历史记录、目录历史记录、AI 功能等。")),
            Tip(identifier: "Toggle Debug Logging",
                text: NSLocalizedString("Debug logs are saved in memory while this setting is enabled and written to `/tmp/debuglog.txt` when you turn it off. Memory use is capped at about 200MB; if the log grows past that, the oldest entries are discarded so the most recent activity is always kept.", tableName: "AppKit", comment: "启用此设置后，调试日志保存在内存中，关闭时写入 `/tmp/debuglog.txt`。内存使用上限约为 200MB；如果日志超过此大小，最旧的条目将被丢弃，以便始终保留最近的活动。")),
            Tip(identifier: "Broadcast Input.Broadcast Input to All Panes in All Tabs",
                text: NSLocalizedString("When enabled, anything you type in this window is sent to all sessions in this window.", tableName: "AppKit", comment: "启用后，您在此窗口中键入的任何内容都会发送到此窗口中的所有会话。")),
            Tip(identifier: "Broadcast Input.Broadcast Input to All Panes in Current Tab",
                text: NSLocalizedString("When enabled, anything you type in this tab is sent to all sessions in this tab.", tableName: "AppKit", comment: "启用后，您在此选项卡中键入的任何内容都会发送到此选项卡中的所有会话。")),
            Tip(identifier: "Broadcast Input.Toggle Broadcast Input to Current Session",
                text: NSLocalizedString("Adds or removes this session from the set of sessions in this window that have broadcast enabled. When you type in a session with broadcast enabled, the keystrokes are sent to all other sessions in the same window that have broadcast enabled.", tableName: "AppKit", comment: "从此窗口中已启用广播的会话集中添加或删除此会话。当您在已启用广播的会话中键入内容时，击键将发送到同一窗口中已启用广播的所有其他会话。")),
            Tip(identifier: "Broadcast Input.Show Background Pattern Indicator",
                imageName: "BroadcastStripesMenuTip",
                text: NSLocalizedString("When enabled, prominent red lines are drawn in the background to indicate that text you type is being broadcast to other sessions.", tableName: "AppKit", comment: "启用后，背景中会绘制醒目的红线，表示您键入的文本正在广播到其他会话。")),
            Tip(identifier: "Broadcast Input.Current Session is Broadcast Source",
                text: NSLocalizedString("When enabled, typing in this session is broadcast to other sessions in the same broadcast domain. Typing in other sessions sends input only to those sessions.", tableName: "AppKit", comment: "启用后，在此会话中键入的内容将广播到同一广播域中的其他会话。在其他会话中键入的内容仅发送到这些会话。")),
            Tip(identifier: "Lock Size",
                text: NSLocalizedString("Locked windows resist being resized. This can be useful when macOS screws up your windows when connecting or disconnecting displays.", tableName: "AppKit", comment: "锁定的窗口不会被调整大小。当 macOS 在连接或断开显示器时搞乱您的窗口时，这很有用。")),
            Tip(identifier: "Lock Layout",
                text: NSLocalizedString("When a window’s layout is locked, its tabs and panes can’t be added, closed, reordered, dragged, or moved to another window, so a stray click or drag can’t rearrange it. Resizing panes, opening new windows, and closing the window still work. This is an alternative to Lock Size; turning one on turns the other off.", tableName: "AppKit", comment: "当窗口的布局被锁定时，其选项卡和窗格无法添加、关闭、重新排序、拖动或移动到另一个窗口，因此误点击或拖动不会重新排列它。调整窗格大小、打开新窗口和关闭窗口仍然有效。这是锁定大小的替代方案；打开一个会关闭另一个。")),
            Tip(identifier: "Notify on Status Change",
                text: NSLocalizedString("When enabled, the next time any session in this window changes its status (such as waiting, idle, or busy) an alert is shown and this setting turns itself back off. This is the same toggle as the bell button in the **Session Status** toolbelt tool, which must be open for this to be available.", tableName: "AppKit", comment: "启用后，下次此窗口中的任何会话更改其状态（如等待、空闲或忙碌）时，会显示警报，此设置会自动关闭。这与会话状态工具带工具中的钟形按钮是同一个开关，该工具必须打开才能使用此功能。")),
            Tip(identifier: "Toggle Buffer Input", text: NSLocalizedString("While Buffer Input is turned on, keyboard input is stored in a buffer. It will be sent when Buffer Input is turned off. You can also configure a trigger to change the Buffer Input setting.", tableName: "AppKit", comment: "当缓冲输入开启时，键盘输入存储在缓冲区中。当缓冲输入关闭时，它将被发送。您还可以配置触发器来更改缓冲输入设置。")),
            Tip(identifier: "Toolbelt.Session Status",
                imageName: "TabStatus",
                text: NSLocalizedString("The **Session Status** tool shows the status of sessions across all tabs. Statuses can be set by the **Set Tab Status** trigger or by programs using a control sequence. Each entry shows the session name, a colored indicator dot, status text, and a keyboard shortcut to jump to that session.", tableName: "AppKit", comment: "会话状态工具显示所有选项卡中会话的状态。状态可以通过「设置选项卡状态」触发器或使用控制序列的程序来设置。每个条目显示会话名称、彩色指示点、状态文本和跳转到该会话的键盘快捷键。")),
        ]
        var index = [String: NSMenuItem]()
        func makeIndex(menu: NSMenu) {
            for item in menu.items {
                if let identifier = item.identifier?.rawValue, !identifier.isEmpty {
                    index[identifier] = item
                }
                if let sub = item.submenu {
                    makeIndex(menu: sub)
                }
            }
        }
        makeIndex(menu: mainMenu)
        let controller = MenuItemTipController.instance
        for tip in tips {
            if let item = index[tip.identifier] {
                controller.registerTip(forMenuItem: item,
                                       image: tip.imageName.compactMap { NSImage.it_imageNamed($0, for: Self.self) },
                                       attributedString: NSAttributedString.attributedString(markdown: tip.text,
                                                                                             font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                                                                                             paragraphStyle: NSParagraphStyle.default)!)
            } else {
                #if(DEBUG)
                it_fatalError("Index missing \(tip.identifier)")
                #endif
            }
        }
    }
}

@objc
extension iTermApplicationDelegate {
    @IBAction func restoreArchive(_ sender: Any?) {
        ArchivesMenuBuilder.shared?.restoreArchive(nil)
    }
}

@objc
extension iTermApplicationDelegate {
    @IBAction func revealCockpit(_ sender: Any?) {
        CockpitWindowController.shared.showAndFocusSearch()
    }
}
