在此页面中，你可以编辑各项 AI 功能所使用的提示词。

## 编辑 > 启用人工智能

当你调用菜单项**编辑 > 启用人工智能**（⌘Y）时会使用此提示词。它会取当前正在编辑的文本，并将其替换为一条终端命令。这段文本可能位于 shell 提示符（前提是你已安装 Shell 集成）、编写器（Composer）中，或应用内各处的文本框中。

例如，你可以打开编写器（⇧⌘.）并输入 `Remove files whose name contains a vowel`，然后选择“启用人工智能”，它会把你的表述改写为 `rm *[aeiou]*`。

其语法遵循[插值字符串](https://iterm2.com/documentation-scripting-fundamentals.html#:~:text=References%2C%20below.-,Interpolated%20Strings,-Another%20way%20that)。`shell` 和 `uname` 变量始终有定义，它们基于对当前会话中这些设置的最佳推测。如果你使用了 SSH 集成，它们对远程主机也应当是正确的。这样做是为了让回答能针对你正在使用的系统量身定制。提示词的形式是一段 shell 脚本，这是说服 ChatGPT 编写命令的好方法。`\(ai.prompt)` 仅在 AI 上下文中求值插值字符串时可用，它的值就是你在编写器中输入的内容。

## AI 对话

AI 对话针对不同功能组合提供了大量提示词。

AI 对话可以与终端会话及网页浏览器会话关联，前提是 AI 服务商支持函数调用（function calling）。如果服务商不支持函数调用（也称为“工具使用”），则只有 `AI Chat (no function calling)` 会生效。

如果你把 `Act in Web Browser`（在网页浏览器中操作）对话权限设为 `Never Allow`（从不允许），则包含 `Browser Access`（浏览器访问）的提示词不会被使用。

如果 `Run Commands`（运行命令）和 `Control Terminal`（控制终端）都设为 `Never`（从不），则包含 `Full Terminal`（完全终端）的提示词不会被使用。

如果所有与终端相关的权限都设为 `Never`（从不），则 `Full Terminal` 和 `Read-Only Terminal`（只读终端）提示词都不会被使用。

通过逐一排除，你可以确定哪种提示词适用于你的情况。

## 代码审查系统提示词

当工作区中有一个具有“代码审查”角色的成员时，此提示词会放入系统消息中，告诉智能体如何把它的发现更新到 iTerm2 中。

## 对话列表图标

此提示词让 AI 在为某个对话选定标题后立即为其绘制一个 SVG 图标。该图标会被栅格化并显示在对话列表中对话名称的旁边。语法遵循插值字符串，其中 `\(ai.subject)` 的值为对话的标题。响应必须包含一个 SVG 文档；其周围的内容会被忽略，如果找不到可渲染的 SVG，对话将保留默认图标。
