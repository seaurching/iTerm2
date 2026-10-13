//
//  ICURegexToRailroadConverter.swift
//  iTerm2
//
//  Created by George Nachman on 5/25/25.
//

import Foundation
import WebKit

/// Converts ICU style regular expressions into railroad DSL for visualization
class ICURegexToRailroadConverter {

    // MARK: - Types

    enum Token {
        case literal(String)
        case metachar(String)
        case charClass(String)
        case group(String)
        case quantifier(String)
        case anchor(String)
        case alternation
        case escaped(String)
    }

    // MARK: - Properties

    private var input: String
    private var position: String.Index

    // MARK: - Initialization

    init() {
        self.input = ""
        self.position = self.input.startIndex
    }

    // MARK: - Public Methods

    /// Converts an ICU regex pattern to railroad DSL
    func convert(_ pattern: String) -> String {
        self.input = pattern
        self.position = pattern.startIndex

        let result = parseAlternation()
        return result
    }

    // MARK: - Parsing Methods

    private func parseAlternation() -> String {
        var alternatives: [String] = []
        var current = parseSequence()

        while hasMore() && peek() == "|" {
            alternatives.append(current)
            advance() // consume |
            current = parseSequence()
        }

        if alternatives.isEmpty {
            return current
        } else {
            alternatives.append(current)
            // <...> is for choices/alternatives and uses commas
            return "<\(alternatives.joined(separator: ", "))>"
        }
    }

    private func parseSequence() -> String {
        var elements: [String] = []
        var currentLiteral = ""

        while hasMore() && peek() != "|" && peek() != ")" {
            let element = parseElement()

            if let elem = element {
                // Check if this element is a single unquoted character
                // (returned by parseElement when it's a literal without quantifier)
                if elem.count == 1 && !elem.contains("\"") && !elem.contains("'") && !elem.contains("`") {
                    // This is a raw character - accumulate it
                    currentLiteral.append(elem)
                } else if elem.count == 1 {
                    // This is a single character that needs escaping (like a quote)
                    // Flush any accumulated literals first
                    if !currentLiteral.isEmpty {
                        elements.append("\"\(escapeForTerminal(currentLiteral))\"")
                        currentLiteral = ""
                    }
                    // Add the single character as a properly escaped element
                    elements.append("\"\(escapeForTerminal(elem))\"")
                } else {
                    // This is a complete element (quoted, quantified, etc.)
                    // Flush any accumulated literals first
                    if !currentLiteral.isEmpty {
                        elements.append("\"\(escapeForTerminal(currentLiteral))\"")
                        currentLiteral = ""
                    }
                    elements.append(elem)
                }
            }
        }

        // Flush any remaining literals
        if !currentLiteral.isEmpty {
            elements.append("\"\(escapeForTerminal(currentLiteral))\"")
        }

        if elements.isEmpty {
            return "!"
        } else if elements.count == 1 {
            return elements[0]
        } else {
            return "{\(elements.joined(separator: ", "))}"
        }
    }

    private func parseElement() -> String? {
        guard hasMore() else { return nil }

        let char = peek()

        switch char {
        case "(":
            return parseGroup()
        case "[":
            return parseCharacterClass()
        case "\\":
            return parseEscape()
        case ".":
            advance()
            return applyQuantifier("\"\(NSLocalizedString("[any character]", tableName: "RegexVisualization", comment: "Regex visualization: any character label"))\"")
        case "^":
            advance()
            return "`\(NSLocalizedString("start of line", tableName: "RegexVisualization", comment: "Regex visualization: start of line anchor"))`"
        case "$":
            advance()
            return "`\(NSLocalizedString("end of line", tableName: "RegexVisualization", comment: "Regex visualization: end of line anchor"))`"
        case "*", "+", "?", "{":
            // Quantifier without preceding element - invalid regex
            advance()
            return nil
        case ")":
            // End of group - let parent handle
            return nil
        default:
            // Literal character - return it without quotes for now
            // The sequence parser will handle grouping literals together
            advance()

            // Check if there's a quantifier following this literal
            if hasMore() && isQuantifier(peek()) {
                return applyQuantifier("\"\(escapeForTerminal(String(char)))\"")
            }

            // Return the literal - parseSequence will handle grouping
            return String(char)
        }
    }

    private func isQuantifier(_ char: Character) -> Bool {
        return char == "*" || char == "+" || char == "?" || char == "{"
    }

    private func parseGroup() -> String {
        advance() // consume (

        var groupType = "capture"
        var groupName = ""
        var content = ""

        if hasMore() && peek() == "?" {
            advance() // consume ?
            if hasMore() {
                let next = peek()
                switch next {
                case ":":
                    advance()
                    groupType = "non-capture"
                case ">":
                    advance()
                    groupType = "atomic"
                case "=":
                    advance()
                    groupType = "lookahead"
                case "!":
                    advance()
                    groupType = "negative-lookahead"
                case "#":
                    // Comment group
                    advance()
                    while hasMore() && peek() != ")" {
                        advance()
                    }
                    if hasMore() { advance() } // consume )
                    return "`\(NSLocalizedString("comment", tableName: "RegexVisualization", comment: "Regex visualization: comment group label"))`"
                case "<":
                    advance()
                    if hasMore() {
                        let lookBehindType = peek()
                        if lookBehindType == "=" {
                            advance()
                            groupType = "lookbehind"
                        } else if lookBehindType == "!" {
                            advance()
                            groupType = "negative-lookbehind"
                        } else {
                            // Named capture group
                            var name = ""
                            while hasMore() && peek() != ">" {
                                name.append(peek())
                                advance()
                            }
                            if hasMore() { advance() } // consume >
                            groupType = "named"
                            groupName = name
                        }
                    }
                default:
                    // Flag settings
                    if isFlag(next) || next == "-" {
                        var flags = ""
                        while hasMore() && peek() != ":" && peek() != ")" {
                            flags.append(peek())
                            advance()
                        }
                        if hasMore() && peek() == ":" {
                            advance()
                            groupType = "flags"
                            groupName = flags
                        } else {
                            // Flag change without group
                            if hasMore() { advance() } // consume )
                            return "`\(String(format: NSLocalizedString("flags: %@", tableName: "RegexVisualization", comment: "Regex visualization: flags label"), flags))`"
                        }
                    }
                }
            }
        }

        // Parse group content
        content = parseAlternation()

        if hasMore() && peek() == ")" {
            advance() // consume )
        }

        // Apply annotations based on group type
        var result = content

        switch groupType {
        case "capture":
            // Regular capture group - add annotation for group number if needed
            // For now, just return the content
            break
        case "non-capture":
            // Non-capturing group - no annotation needed
            break
        case "named":
            // Named capture group - add the name as annotation
            result = "\(content)#`\(groupName)`"
        case "atomic":
            result = "\(content)#`\(NSLocalizedString("atomic", tableName: "RegexVisualization", comment: "Regex visualization: atomic group label"))`"
        case "lookahead":
            result = "\(content)#`\(NSLocalizedString("lookahead", tableName: "RegexVisualization", comment: "Regex visualization: lookahead label"))`"
        case "negative-lookahead":
            result = "\(content)#`\(NSLocalizedString("negative lookahead", tableName: "RegexVisualization", comment: "Regex visualization: negative lookahead label"))`"
        case "lookbehind":
            result = "\(content)#`\(NSLocalizedString("lookbehind", tableName: "RegexVisualization", comment: "Regex visualization: lookbehind label"))`"
        case "negative-lookbehind":
            result = "\(content)#`\(NSLocalizedString("negative lookbehind", tableName: "RegexVisualization", comment: "Regex visualization: negative lookbehind label"))`"
        case "flags":
            result = "\(content)#`\(String(format: NSLocalizedString("flags: %@", tableName: "RegexVisualization", comment: "Regex visualization: flags label"), groupName))`"
        default:
            break
        }

        return applyQuantifier(result)
    }

    private func parseCharacterClass() -> String {
        advance() // consume [

        var isNegated = false
        var elements: [String] = []

        if hasMore() && peek() == "^" {
            isNegated = true
            advance()
        }

        while hasMore() && peek() != "]" {
            if peek() == "\\" {
                advance()
                if hasMore() {
                    let escaped = peek()
                    advance()
                    elements.append(handleEscapeInClass(escaped))
                }
            } else if peek() == "[" && peekAhead() == ":" {
                // POSIX-style property
                var posixClass = ""
                advance() // [
                advance() // :
                while hasMore() && !(peek() == ":" && peekAhead() == "]") {
                    posixClass.append(peek())
                    advance()
                }
                if hasMore() { advance() } // :
                if hasMore() { advance() } // ]
                elements.append("\"[\(posixClass)]\"")
            } else {
                let char = peek()
                advance()

                // Check for range
                if hasMore() && peek() == "-" && peekAhead() != "]" {
                    advance() // consume -
                    if hasMore() {
                        let endChar = peek()
                        advance()
                        elements.append("\"[\(char)-\(endChar)]\"")
                    }
                } else {
                    elements.append("\"\(escapeForTerminal(String(char)))\"")
                }
            }
        }

        if hasMore() && peek() == "]" {
            advance() // consume ]
        }

        // Character classes are choices, so use <...> with commas
        let classContent = elements.isEmpty ? "!" : "<\(elements.joined(separator: ", "))>"
        let result = isNegated ? "{`\(NSLocalizedString("not", tableName: "RegexVisualization", comment: "Regex visualization: negated character class label"))`, \(classContent)}" : classContent
        return applyQuantifier(result)
    }

    private func parseEscape() -> String {
        advance() // consume \

        guard hasMore() else { return "\"\\\\\"" }

        let escaped = peek()
        advance()

        switch escaped {
            // Special sequences
        case "a": return applyQuantifier("\"\(NSLocalizedString("[bell]", tableName: "RegexVisualization", comment: "Regex visualization: bell character label"))\"")
        case "A": return "`\(NSLocalizedString("start of input", tableName: "RegexVisualization", comment: "Regex visualization: start of input anchor"))`"
        case "b": return "`\(NSLocalizedString("word boundary", tableName: "RegexVisualization", comment: "Regex visualization: word boundary anchor"))`"
        case "B": return "`\(NSLocalizedString("non-word boundary", tableName: "RegexVisualization", comment: "Regex visualization: non-word boundary anchor"))`"
        case "d": return applyQuantifier("\"\(NSLocalizedString("[digit]", tableName: "RegexVisualization", comment: "Regex visualization: digit character class label"))\"")
        case "D": return applyQuantifier("\"\(NSLocalizedString("[non-digit]", tableName: "RegexVisualization", comment: "Regex visualization: non-digit character class label"))\"")
        case "e": return applyQuantifier("\"\(NSLocalizedString("[escape]", tableName: "RegexVisualization", comment: "Regex visualization: escape character label"))\"")
        case "f": return applyQuantifier("\"\(NSLocalizedString("[form feed]", tableName: "RegexVisualization", comment: "Regex visualization: form feed character label"))\"")
        case "G": return "`\(NSLocalizedString("end of previous match", tableName: "RegexVisualization", comment: "Regex visualization: end of previous match anchor"))`"
        case "h": return applyQuantifier("\"\(NSLocalizedString("[horizontal whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: horizontal whitespace label"))\"")
        case "H": return applyQuantifier("\"\(NSLocalizedString("[non-horizontal whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-horizontal whitespace label"))\"")
        case "n": return applyQuantifier("\"\(NSLocalizedString("[line feed]", tableName: "RegexVisualization", comment: "Regex visualization: line feed character label"))\"")
        case "r": return applyQuantifier("\"\(NSLocalizedString("[carriage return]", tableName: "RegexVisualization", comment: "Regex visualization: carriage return character label"))\"")
        case "R": return applyQuantifier("\"\(NSLocalizedString("[newline]", tableName: "RegexVisualization", comment: "Regex visualization: newline character label"))\"")
        case "s": return applyQuantifier("\"\(NSLocalizedString("[whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: whitespace character class label"))\"")
        case "S": return applyQuantifier("\"\(NSLocalizedString("[non-whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-whitespace character class label"))\"")
        case "t": return applyQuantifier("\"\(NSLocalizedString("[tab]", tableName: "RegexVisualization", comment: "Regex visualization: tab character label"))\"")
        case "v": return applyQuantifier("\"\(NSLocalizedString("[vertical whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: vertical whitespace label"))\"")
        case "V": return applyQuantifier("\"\(NSLocalizedString("[non-vertical whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-vertical whitespace label"))\"")
        case "w": return applyQuantifier("\"\(NSLocalizedString("[word character]", tableName: "RegexVisualization", comment: "Regex visualization: word character class label"))\"")
        case "W": return applyQuantifier("\"\(NSLocalizedString("[non-word character]", tableName: "RegexVisualization", comment: "Regex visualization: non-word character class label"))\"")
        case "X": return applyQuantifier("\"\(NSLocalizedString("[grapheme cluster]", tableName: "RegexVisualization", comment: "Regex visualization: grapheme cluster label"))\"")
        case "Z": return "`\(NSLocalizedString("end of input (before final newline)", tableName: "RegexVisualization", comment: "Regex visualization: end of input before final newline anchor"))`"
        case "z": return "`\(NSLocalizedString("end of input", tableName: "RegexVisualization", comment: "Regex visualization: end of input anchor"))`"

            // Unicode escapes
        case "u":
            var hex = ""
            for _ in 0..<4 {
                if hasMore() && isHexDigit(peek()) {
                    hex.append(peek())
                    advance()
                }
            }
            return applyQuantifier("\"[U+\(hex)]\"")

        case "U":
            var hex = ""
            for _ in 0..<8 {
                if hasMore() && isHexDigit(peek()) {
                    hex.append(peek())
                    advance()
                }
            }
            return applyQuantifier("\"[U+\(hex)]\"")

        case "x":
            if hasMore() && peek() == "{" {
                advance() // consume {
                var hex = ""
                while hasMore() && peek() != "}" {
                    hex.append(peek())
                    advance()
                }
                if hasMore() { advance() } // consume }
                return applyQuantifier("\"[U+\(hex)]\"")
            } else {
                var hex = ""
                for _ in 0..<2 {
                    if hasMore() && isHexDigit(peek()) {
                        hex.append(peek())
                        advance()
                    }
                }
                return applyQuantifier("\"[U+\(hex)]\"")
            }

            // Named character
        case "N":
            if hasMore() && peek() == "{" {
                advance() // consume {
                var name = ""
                while hasMore() && peek() != "}" {
                    name.append(peek())
                    advance()
                }
                if hasMore() { advance() } // consume }
                return applyQuantifier("\"[\(name)]\"")
            }
            return applyQuantifier("\"N\"")

            // Properties
        case "p", "P":
            let isNegated = escaped == "P"
            if hasMore() && peek() == "{" {
                advance() // consume {
                var property = ""
                while hasMore() && peek() != "}" {
                    property.append(peek())
                    advance()
                }
                if hasMore() { advance() } // consume }
                let propDesc = isNegated ? String(format: NSLocalizedString("not %@", tableName: "RegexVisualization", comment: "Regex visualization: negated property label"), property) : property
                return applyQuantifier("\"[\(propDesc)]\"")
            }
            return applyQuantifier("\"\(escaped)\"")

            // Back reference
        case "k":
            if hasMore() && peek() == "<" {
                advance() // consume <
                var name = ""
                while hasMore() && peek() != ">" {
                    name.append(peek())
                    advance()
                }
                if hasMore() { advance() } // consume >
                return applyQuantifier("'\(name)'")
            }
            return applyQuantifier("\"k\"")

            // Numeric back reference
        case "1"..."9":
            return applyQuantifier("'\(String(format: NSLocalizedString("group %@", tableName: "RegexVisualization", comment: "Regex visualization: numeric backreference label"), String(escaped)))'")

            // Octal
        case "0":
            var octal = "0"
            for _ in 0..<3 {
                if hasMore() && isOctalDigit(peek()) {
                    octal.append(peek())
                    advance()
                }
            }
            return applyQuantifier("\"[\\\\o\(octal)]\"")

            // Control character
        case "c":
            if hasMore() {
                let control = peek()
                advance()
                return applyQuantifier("\"[\(String(format: NSLocalizedString("control-%@", tableName: "RegexVisualization", comment: "Regex visualization: control character label"), String(control)))]\"")
            }
            return applyQuantifier("\"c\"")

            // Quote sequences
        case "Q":
            var quoted = ""
            while hasMore() {
                if peek() == "\\" && peekAhead() == "E" {
                    advance() // consume \
                    advance() // consume E
                    break
                }
                quoted.append(peek())
                advance()
            }
            return applyQuantifier("\"\(escapeForTerminal(quoted))\"")

        case "E":
            return "" // End of quote - handled by \Q

            // Literal escaped characters
        default:
            return applyQuantifier("\"\(escapeForTerminal(String(escaped)))\"")
        }
    }

    private func applyQuantifier(_ base: String) -> String {
        guard hasMore() else { return base }

        let quantChar = peek()

        switch quantChar {
        case "*":
            advance()
            if hasMore() && peek() == "?" {
                advance()
                // Lazy zero-or-more: choice between empty and one-or-more
                return "<!, {\(base)*!, `\(NSLocalizedString("*? (lazy)", tableName: "RegexVisualization", comment: "Regex visualization: lazy zero-or-more quantifier"))`}>"
            } else if hasMore() && peek() == "+" {
                advance()
                // Possessive zero-or-more: choice between empty and one-or-more
                return "<!, {\(base)*!, `\(NSLocalizedString("*+ (possessive)", tableName: "RegexVisualization", comment: "Regex visualization: possessive zero-or-more quantifier"))`}>"
            }
            // Zero or more: choice between empty and one-or-more
            return "<!, {\(base)*!}>"

        case "+":
            advance()
            if hasMore() && peek() == "?" {
                advance()
                // Lazy one-or-more
                return "{\(base)*!, `\(NSLocalizedString("+? (lazy)", tableName: "RegexVisualization", comment: "Regex visualization: lazy one-or-more quantifier"))`}"
            } else if hasMore() && peek() == "+" {
                advance()
                // Possessive one-or-more
                return "{\(base)*!, `\(NSLocalizedString("++ (possessive)", tableName: "RegexVisualization", comment: "Regex visualization: possessive one-or-more quantifier"))`}"
            }
            // One or more
            return "{\(base)*!}"

        case "?":
            advance()
            if hasMore() && peek() == "?" {
                advance()
                // Lazy optional: prefer empty
                return "<!, \(base), `\(NSLocalizedString("?? (lazy)", tableName: "RegexVisualization", comment: "Regex visualization: lazy optional quantifier"))`>"
            } else if hasMore() && peek() == "+" {
                advance()
                // Possessive optional
                return "<!, \(base), `\(NSLocalizedString("?+ (possessive)", tableName: "RegexVisualization", comment: "Regex visualization: possessive optional quantifier"))`>"
            }
            // Optional: choice between empty and the element
            return "<!, \(base)>"

        case "{":
            advance()
            var quantifier = ""
            while hasMore() && peek() != "}" {
                quantifier.append(peek())
                advance()
            }
            if hasMore() { advance() } // consume }

            var suffix = ""
            if hasMore() {
                if peek() == "?" {
                    advance()
                    suffix = NSLocalizedString(" (lazy)", tableName: "RegexVisualization", comment: "Regex visualization: lazy quantifier suffix")
                } else if peek() == "+" {
                    advance()
                    suffix = NSLocalizedString(" (possessive)", tableName: "RegexVisualization", comment: "Regex visualization: possessive quantifier suffix")
                }
            }

            // Parse quantifier
            let parts = quantifier.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            if parts.count == 1 {
                // Exactly n times
                if let n = Int(parts[0]) {
                    if n == 0 {
                        // {0} means empty
                        return "!"
                    } else if n == 1 {
                        // {1} means exactly once
                        return suffix.isEmpty ? base : "{\(base), `{\(n)}\(suffix)`}"
                    } else {
                        // {n} means exactly n times - need n-1 in sequence then base
                        var result = [base]
                        for _ in 1..<n {
                            result.append(base)
                        }
                        let repeated = "{\(result.joined(separator: ", "))}"
                        return suffix.isEmpty ? repeated : "{\(repeated), `{\(n)}\(suffix)`}"
                    }
                }
            } else if parts.count == 2 {
                if parts[1].isEmpty {
                    // At least n times {n,}
                    if let n = Int(parts[0]) {
                        if n == 0 {
                            // {0,} is same as *
                            return suffix.isEmpty ? "<!, {\(base)*!}>" : "<!, {\(base)*!, `{0,}\(suffix)`}>"
                        } else if n == 1 {
                            // {1,} is same as +
                            return suffix.isEmpty ? "{\(base)*!}" : "{\(base)*!, `{1,}\(suffix)`}"
                        } else {
                            // {n,} means n required followed by zero or more
                            var required = [base]
                            for _ in 1..<n {
                                required.append(base)
                            }
                            let result = "{\(required.joined(separator: ", ")), {\(base)*!}?}"
                            return suffix.isEmpty ? result : "{\(result), `{\(n),}\(suffix)`}"
                        }
                    }
                } else {
                    // Between n and m times {n,m}
                    if let n = Int(parts[0]), let m = Int(parts[1]) {
                        if n == 0 && m == 1 {
                            // {0,1} is same as ?
                            return suffix.isEmpty ? "<!, \(base)>" : "<!, \(base), `{0,1}\(suffix)`>"
                        } else if n == 0 {
                            // {0,m} - all optional
                            var elements: [String] = []
                            for i in 0..<m {
                                if i == 0 {
                                    elements.append(base)
                                } else {
                                    elements.append("<!, \(base)>")
                                }
                            }
                            let result = "<!, {\(elements.joined(separator: ", "))}>"
                            return suffix.isEmpty ? result : "{\(result), `{\(n),\(m)}\(suffix)`}"
                        } else {
                            // {n,m} - n required, m-n optional
                            var elements: [String] = []
                            // Required elements
                            for _ in 0..<n {
                                elements.append(base)
                            }
                            // Optional elements
                            for _ in n..<m {
                                elements.append("<!, \(base)>")
                            }
                            let result = "{\(elements.joined(separator: ", "))}"
                            return suffix.isEmpty ? result : "{\(result), `{\(n),\(m)}\(suffix)`}"
                        }
                    }
                }
            }

            return "{\(base), `{\(quantifier)}\(suffix)`}"

        default:
            return base
        }
    }

    // MARK: - Helper Methods

    private func hasMore() -> Bool {
        return position < input.endIndex
    }

    private func peek() -> Character {
        guard hasMore() else { return "\0" }
        return input[position]
    }

    private func peekAhead() -> Character {
        let nextIndex = input.index(after: position)
        guard nextIndex < input.endIndex else { return "\0" }
        return input[nextIndex]
    }

    private func advance() {
        if hasMore() {
            position = input.index(after: position)
        }
    }

    private func isHexDigit(_ char: Character) -> Bool {
        return char.isHexDigit
    }

    private func isOctalDigit(_ char: Character) -> Bool {
        return char >= "0" && char <= "7"
    }

    private func isFlag(_ char: Character) -> Bool {
        return "ismwx".contains(char)
    }

    private func escapeForTerminal(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func handleEscapeInClass(_ char: Character) -> String {
        switch char {
        case "d": return "\"\(NSLocalizedString("[digit]", tableName: "RegexVisualization", comment: "Regex visualization: digit character class label"))\""
        case "D": return "\"\(NSLocalizedString("[non-digit]", tableName: "RegexVisualization", comment: "Regex visualization: non-digit character class label"))\""
        case "s": return "\"\(NSLocalizedString("[whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: whitespace character class label"))\""
        case "S": return "\"\(NSLocalizedString("[non-whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-whitespace character class label"))\""
        case "w": return "\"\(NSLocalizedString("[word character]", tableName: "RegexVisualization", comment: "Regex visualization: word character class label"))\""
        case "W": return "\"\(NSLocalizedString("[non-word character]", tableName: "RegexVisualization", comment: "Regex visualization: non-word character class label"))\""
        case "h": return "\"\(NSLocalizedString("[horizontal whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: horizontal whitespace label"))\""
        case "H": return "\"\(NSLocalizedString("[non-horizontal whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-horizontal whitespace label"))\""
        case "v": return "\"\(NSLocalizedString("[vertical whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: vertical whitespace label"))\""
        case "V": return "\"\(NSLocalizedString("[non-vertical whitespace]", tableName: "RegexVisualization", comment: "Regex visualization: non-vertical whitespace label"))\""
        case "n": return "\"\(NSLocalizedString("[line feed]", tableName: "RegexVisualization", comment: "Regex visualization: line feed character label"))\""
        case "r": return "\"\(NSLocalizedString("[carriage return]", tableName: "RegexVisualization", comment: "Regex visualization: carriage return character label"))\""
        case "t": return "\"\(NSLocalizedString("[tab]", tableName: "RegexVisualization", comment: "Regex visualization: tab character label"))\""
        case "f": return "\"\(NSLocalizedString("[form feed]", tableName: "RegexVisualization", comment: "Regex visualization: form feed character label"))\""
        case "a": return "\"\(NSLocalizedString("[bell]", tableName: "RegexVisualization", comment: "Regex visualization: bell character label"))\""
        case "e": return "\"\(NSLocalizedString("[escape]", tableName: "RegexVisualization", comment: "Regex visualization: escape character label"))\""
        default: return "\"\(escapeForTerminal(String(char)))\""
        }
    }
}
