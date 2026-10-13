//
//  AIExplanationRequest.swift
//  iTerm2
//
//  Created by George Nachman on 2/9/25.
//
//  NOTE: This file is also compiled into the iTerm2 Companion iOS app. Keep it
//  platform-neutral (Foundation only); Mac-only code (terminal-content
//  extraction) lives in AIExplanationRequest+Mac.swift. On the phone,
//  iTermCodableLocatedString is a wire-compatible stand-in.
//

import Foundation

struct AIExplanationRequest: Codable {
    struct Context: Codable {
        var sessionID: String
        var baseOffset: Int64
    }
    var command: String?
    var truncated: Bool
    var originalString: iTermCodableLocatedString
    var question: String
    var subjectMatter: String
    var url: URL?
    var context: Context
    private var _boxedUserInfo: NSDictionaryCodableBox?
    var userInfo: NSDictionary? {
        get { _boxedUserInfo?.dictionary }
        set { _boxedUserInfo = newValue.map { NSDictionaryCodableBox(dictionary: $0) } }
    }
    var snippetText: String {
        if let command {
            return String(format: NSLocalizedString("Explain %@", tableName: "AITermXC", comment: "解释 %@"), command)
        }
        if !question.isEmpty {
            return question
        }
        return String(format: NSLocalizedString("Explain %@", tableName: "AITermXC", comment: "解释 %@"), subjectMatter)
    }
    
    private static func escapedContent(_ original: String) -> String {
        return original
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .components(separatedBy: "\n")
            .enumerated()
            .map { (i, line) in
                "<line n=\"\(i)\">\(line)</line>\n"
            }
            .joined(separator: "\n")
    }

    private static func prompt(_ command: String?,
                               text: String,
                               truncated: Bool,
                               question: String) -> String {
        var instructions = [String]()
        if let command {
            instructions.append(String(format: NSLocalizedString("After this paragraph I will attach the output of %@, which the user needs help understanding.", tableName: "AITermXC", comment: "在此段落之后，我将附加 %@ 的输出，用户需要帮助理解。"), command))
        } else {
            instructions.append(NSLocalizedString("After this paragraph I will attach some text from a terminal emulator that the user needs help understanding.", tableName: "AITermXC", comment: "在此段落之后，我将附加来自终端模拟器的一些文本，用户需要帮助理解。"))
        }
        if truncated {
            instructions.append(NSLocalizedString("The beginning of the command output is not included because it was extremely long. What you see is just the latter part of it.", tableName: "AITermXC", comment: "命令输出的开头未包含在内，因为它非常长。您看到的只是它的后半部分。"))
        }
        let annotationsPurpose = NSLocalizedString("Annotations should explain parts of the output that the user likely wants to know more about, such as error messages, abstruse terms of art, tersely formatted messages, or anything non-obvious.", tableName: "AITermXC", comment: "注释应解释用户可能想了解更多关于输出的部分，例如错误消息、深奥的术语、简洁格式的消息或任何不明显的内容。")

        if question.isEmpty {
            instructions += [
                NSLocalizedString("Respond with a sequence of annotations.", tableName: "AITermXC", comment: "用一系列注释来回复。"),
                annotationsPurpose,
                NSLocalizedString("Since the user asked for this to be explained, you should always add at least one annotation.", tableName: "AITermXC", comment: "由于用户要求解释此内容，您应始终添加至少一个注释。"),
            ]
        } else {
            instructions += [
                String(format: NSLocalizedString("The user has asked this question about it: \u{201c}%@\u{201d}", tableName: "AITermXC", comment: "用户提出了以下问题：\u{201c}%@\u{201d}"), question),
                NSLocalizedString("You should respond to their question with a main response and, if needed, annotations of the text provided below.", tableName: "AITermXC", comment: "您应该用主要回复来回答他们的问题，如果需要，还可以对下面提供的文本进行注释。"),
                NSLocalizedString("The entirety of the main response should be wrapped in <response>…</response> tags.", tableName: "AITermXC", comment: "主要回复的全部内容应包裹在 <response>…</response> 标签中。"),
                NSLocalizedString("The main response should be markdown. < and & must be ampersand encoded.", tableName: "AITermXC", comment: "主要回复应为 markdown 格式。< 和 & 必须使用 & 编码。"),
                NSLocalizedString("You may also choose to include annotations that are relevant to the question.", tableName: "AITermXC", comment: "您也可以选择包含与问题相关的注释。"),
                annotationsPurpose
            ]
        }
        instructions += [
            NSLocalizedString("Annotations will be displayed to the user next to the parts of the terminal emulator's content.", tableName: "AITermXC", comment: "注释将在终端模拟器内容的部分旁边显示给用户。"),
            NSLocalizedString("Don't annotate anything obvious, like self-explanatory comments in code.", tableName: "AITermXC", comment: "不要注释任何明显的内容，如代码中不言自明的注释。"),
            NSLocalizedString("Never use a substring as its own annotation.", tableName: "AITermXC", comment: "永远不要使用子字符串作为自己的注释。"),
            NSLocalizedString("An example of a good annotation: `Error: text file busy` might be annotated as `This usually happens when you try to modify or delete an executable that is currently running`.", tableName: "AITermXC", comment: "一个好注释的例子：`Error: text file busy` 可以注释为 `当您尝试修改或删除当前正在运行的可执行文件时，通常会发生这种情况`。"),
            NSLocalizedString("Each annotation you write should look like this: <annotation line=\"N\" text=\"A useful explanation of the annotated substring\" substring=\"text that occurs on line N that you wish to annotate\"/>.", tableName: "AITermXC", comment: "您编写的每个注释应如下所示：<annotation line=\"N\" text=\"对注释子字符串的有用解释\" substring=\"您希望注释的第 N 行文本\"/>。"),
            NSLocalizedString("Use ampersand escaping like HTML if you need to use a quotation mark or an ampersand.", tableName: "AITermXC", comment: "如果您需要使用引号或 & 符号，请使用类似 HTML 的 & 转义。"),
            NSLocalizedString("You may provide more than one annotation per line of input if needed.", tableName: "AITermXC", comment: "如果需要，您可以为每行输入提供多个注释。"),
            NSLocalizedString("Avoid overlapping annotations because they lead to a confusing user interface.", tableName: "AITermXC", comment: "避免重叠注释，因为它们会导致混乱的用户界面。"),
            NSLocalizedString("I have added markup to help identify line numbers.", tableName: "AITermXC", comment: "我已添加标记以帮助识别行号。"),
            NSLocalizedString("Each line is wrapped in <line n=\"number\">…</line>.", tableName: "AITermXC", comment: "每行都包裹在 <line n=\"number\">…</line> 中。"),
            NSLocalizedString("The text to annotate follows:", tableName: "AITermXC", comment: "要注释的文本如下："),
        ]
        return instructions.joined(separator: " ") + "\n" + text

    }

    func prompt() -> String {
        let markedUpString = Self.escapedContent(originalString.string)
        return Self.prompt(command,
                           text: markedUpString,
                           truncated: truncated,
                           question: question)
    }

    static func conversationalPrompt(userPrompt: String) -> String {
        return NSLocalizedString("Stop using <annotation> and <response>. I am no longer parsing them. What follows will be a regular conversation. Here is the next prompt from the user: ", tableName: "AITermXC", comment: "停止使用 <annotation> 和 <response>。我不再解析它们。接下来将是普通对话。以下是用户的下一个提示：") + userPrompt
    }
}
