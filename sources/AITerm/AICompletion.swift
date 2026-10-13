//
//  AICompletion.swift
//  iTerm2
//
//  Created by George Nachman on 2/27/25.
//

fileprivate let filePlaceholder = "{{FILE}}"

class AICompletion {
    struct PreviouslyRunCommand {
        var command: String
        var workingDirectory: String?
        var date: Date
    }
    static func suggestionCompletions(_ request: SuggestionRequest,
                                      history: ArraySlice<PreviouslyRunCommand>,
                                      files: [CompletionItem],
                                      completion: @escaping ([CompletionItem]) -> ()) {
        DLog("Requesting AI completion")
        if !iTermAITermGatekeeper.check(silent: true) {
            DLog("Failed gatekeeper")
            completion(files)
            return
        }
        let (prompt, prefix) = request.aiPrompt(history: history,
                                                files: files.map { $0.value },
                                                prefix: request.prefix)
        let conversation =
        AIConversation(
            registrationProvider: nil,
            messages: [
                AITermController.Message(
                    role: .user,
                    content: prompt,
                    name: nil,
                    function_call: nil)])
        DLog("Completing…")
        AIConversation.completeOneShot(conversation) { result in
            DLog("Have completion")
            result.handle { updated in
                DLog("Handle success")
                guard let content = updated.messages.last?.body.content else {
                    DLog("No content")
                    completion(files)
                    return
                }
                var expandedFiles = false
                var completions = content
                    .components(separatedBy: "\n")
                    .compactMap { line -> CompletionItem? in
                        let parts = line.components(separatedBy: "\t")
                        guard parts.count == 2 else {
                            return nil
                        }
                        let description = parts[0]
                        let suggestion = parts[1]

                        if suggestion.hasPrefix(prefix) {
                            return CompletionItem(value: String(suggestion.removing(prefix: prefix)),
                                                  detail: description,
                                                  kind: .aiSuggestion)
                        } else {
                            let truncated = suggestion.removingPrefixThatIsLongestSuffix(of: prefix)
                            if !truncated.isEmpty {
                                return CompletionItem(value: String(truncated),
                                                      detail: description,
                                                      kind: .aiSuggestion)
                            }
                        }
                        return nil
                    }.flatMap { (completion: CompletionItem) -> [CompletionItem] in
                        if completion.value.contains(filePlaceholder) {
                            expandedFiles = true
                            return files
                                .sorted {
                                    $0.value < $1.value
                                }.map { (file: CompletionItem) -> CompletionItem in
                                    CompletionItem(value: file.value,
                                                   detail: completion.detail,
                                                   kind: .aiSuggestion)
                                }
                        } else if completion.value.contains("{{") {
                            // ChatGPT 4o likes to use {{DIRECTORY}} and {{MESSAGE}} even though I told it not to
                            let pattern = "\\{\\{([A-Z0-9_]+)\\}\\}"
                            let regex = try! NSRegularExpression(pattern: pattern)

                            let replacement = regex.stringByReplacingMatches(
                                in: completion.value,
                                options: [],
                                range: NSRange(completion.value.startIndex..., in: completion.value), withTemplate: "($1)")
                            return [CompletionItem(value: replacement,
                                                   detail: completion.detail,
                                                   kind: .aiSuggestion)]
                        } else {
                            return [completion]
                        }
                    }
                if !files.isEmpty && !expandedFiles {
                    completions.append(contentsOf: files)
                }
                DLog("Success")
                completion(completions.withoutDuplicates { $0.value })
            } failure: { error in
                DLog("Error: \(error.localizedDescription)")
                completion(files)
            }
        }
    }
}

fileprivate extension SuggestionRequest {
    func aiPrompt(history: ArraySlice<AICompletion.PreviouslyRunCommand>,
                  files: [String],
                  prefix: String) -> (String, String) {
        var lines = [NSLocalizedString("You are offering command line completion suggestions and descriptions.", tableName: "AITermXC", comment:"您正在提供命令行补全建议和描述。")]
        lines.append(NSLocalizedString("Respond with one description + suggestion per line.", tableName: "AITermXC", comment: "每行回复一个描述 + 建议。"))
        lines.append(NSLocalizedString("Each line should consist of a 2-5 word description, followed by a tab, followed by the suggestion.", tableName: "AITermXC", comment: "每行应包含 2-5 个词的描述，后跟一个制表符，再跟建议。"))
        lines.append(String(format: NSLocalizedString("Return no more than %@ lines. You may return fewer or none rather than poor quality suggestions.", tableName: "AITermXC", comment: "返回不超过 %@ 行。您可以返回更少或不返回，而不是返回低质量的建议。"), "\(4)"))
        lines.append(NSLocalizedString("For example, if the command so far was `git re` then you might suggest `Rewrite commit history\\tgit rebase`, `Rewrite commit history\\tgit revert`, and `Move branch pointer\\tgit reset`. ", tableName: "AITermXC", comment: "例如，如果到目前为止的命令是 `git re`，您可能会建议 `重写提交历史\\tgit rebase`、`重写提交历史\\tgit revert` 和 `移动分支指针\\tgit reset`。"))
        lines.append(NSLocalizedString("After the tab, the suggestion should begin with the literal text the user has entered so far.", tableName: "AITermXC", comment: "制表符之后，建议应以用户到目前为止输入的字面文本开头。"))
        lines.append(NSLocalizedString("You can suggest more than one additional word when you can tell from context that it would be a good suggestion. For example, if the user frequently runs `grep ERROR <file> | sort | uniq` and you see that the text so far is `grep ERROR myfile.txt` your response could include `Count unique errors\\tgrep ERROR myfile.txt | sort | uniq`", tableName: "AITermXC", comment: "当您从上下文中可以看出这是一个好建议时，您可以建议多个额外的单词。"))
        if let workingDirectory {
            lines.append(String(format: NSLocalizedString("The current working directory is %@", tableName: "AITermXC", comment: "当前工作目录是 %@"), workingDirectory))
        }
        if executable {
            lines.append(NSLocalizedString("The user appears to be entering the name of a command to execute, not one of its arguments, so completions should be for executable commands likely to be present on the system.", tableName: "AITermXC", comment: "用户似乎正在输入要执行的命令名称，而不是其参数，因此补全应该是系统上可能存在的可执行命令。"))
        }
        lines.append(NSLocalizedString("The suggestion in each line you respond with is a candidate to append after what has been typed so far.", tableName: "AITermXC", comment: "您回复的每一行中的建议都是在已输入内容之后追加的候选。"))
        if !history.isEmpty {
            lines.append(NSLocalizedString("Previously run commands in chronological order are:", tableName: "AITermXC", comment: "按时间顺序排列的先前运行的命令是："))
            for entry in history {
                lines.append(entry.command.replacingOccurrences(of: "\n", with: " "))
            }
            lines.append(NSLocalizedString("(end of command list)", tableName: "AITermXC", comment: "（命令列表结束）"))
            lines.append(NSLocalizedString("Your suggestions should take recently run commands into consideration: if possible, suggest a command that builds on what the user has begun.", tableName: "AITermXC", comment: "您的建议应考虑最近运行的命令：如果可能，建议一个基于用户已开始输入的命令。"))
            lines.append("")
        }
        lines.append(NSLocalizedString("Do not make up or invent file or directory names.", tableName: "AITermXC", comment: "不要编造或虚构文件或目录名称。"))
        lines.append(String(format: NSLocalizedString("If a suggestion would end with a filename, use %@ instead.", tableName: "AITermXC", comment: "如果建议以文件名结尾，请改用 %@。"), filePlaceholder))
        lines.append(NSLocalizedString("Do not invent other kinds of placeholders such as {{MESSAGE}} or {{DIRECTORY}}. Use plain English, like \"message\", instead.", tableName: "AITermXC", comment: "不要发明其他类型的占位符，如 {{MESSAGE}} 或 {{DIRECTORY}}。请使用普通英文，如 \"message\"。"))
        if files.lengthOfLongestCommonPrefix > 0 {
            let lcp = String(files.longestCommonPrefix)
            lines.append(String(format: NSLocalizedString("Instead, your suggestion may end with the longest common prefix of valid filename completions, which is: %@", tableName: "AITermXC", comment: "相反，您的建议可以以有效文件名补全的最长公共前缀结尾，即：%@"), lcp))
        }
        let sanitized = fullPrefix.replacingOccurrences(of: "\n", with: " ")
        lines.append(NSLocalizedString("The text the user has entered so far, which needs completion, is:", tableName: "AITermXC", comment: "用户到目前为止输入的需要补全的文本是："))
        lines.append(sanitized)

        if !fullSuffix.trimmingLeadingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("")
            lines.append(NSLocalizedString("Additionally, there is some text after the cursor. Use this to come up with better suggestions, assuming it will be used after what you suggest or that your suggestion will replace some of it. It is:", tableName: "AITermXC", comment: "此外，光标后面有一些文本。请利用这些文本提出更好的建议，假设它将在您建议的内容之后使用，或者您的建议将替换其中一部分。它是："))
            lines.append(fullSuffix.replacingOccurrences(of: "\n", with: " "))
        }
        return (lines.joined(separator: "\n"), sanitized)
    }
}

@objc(iTermCompletionItem)
class CompletionItem: NSObject {
    @objc let value: String
    @objc let detail: String?
    @objc let kind: Kind

    @objc(iTermCompletionItemKind) enum Kind: Int {
        case file
        case aiSuggestion
        case history
        case command
        case folder
        case webSearch
        case navigation
        case bookmark
    }

    @objc(initWithValue:detail:kind:)
    init(value: String, detail: String?, kind: Kind) {
        #if DEBUG
        it_assert(!(detail ?? "").contains("<iTermCompletionItem"))
        #endif
        self.value = value
        self.detail = detail
        self.kind = kind
    }

    @objc
    func mapValue(_ closure: (String) -> (String)) -> CompletionItem {
        return CompletionItem(value: closure(value), detail: detail, kind: kind)
    }
}
