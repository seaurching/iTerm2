//
//  iTermEventTriggerParameterView.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 3/1/26.
//

import AppKit

/// View for configuring event-specific trigger parameters
@objc(iTermEventTriggerParameterView)
class EventTriggerParameterView: NSView, NSTextFieldDelegate {

    // MARK: - Properties

    private var stackView: NSStackView!
    private var currentMatchType: iTermTriggerMatchType = .eventPromptDetected

    /// The current event parameters
    @objc var eventParams: [String: Any] {
        get {
            return collectParams()
        }
        set {
            applyParams(newValue)
        }
    }

    /// Callback when parameters change
    @objc var onParametersChanged: (() -> Void)?

    // UI elements for different event types
    private var exitCodeFilterPopup: NSPopUpButton?
    private var exitCodeTextField: NSTextField?
    private var timeoutTextField: NSTextField?
    private var thresholdTextField: NSTextField?
    private var sequenceIdTextField: NSTextField?
    private var directoryRegexTextField: NSTextField?
    private var hostRegexTextField: NSTextField?
    private var userRegexTextField: NSTextField?
    private var commandRegexTextField: NSTextField?
    private var notificationMessageRegexTextField: NSTextField?
    private var progressBarFilterPopup: NSPopUpButton?
    private var jobNameTextField: NSTextField?
    private var variableNameTextField: NSTextField?
    private var variableValueRegexTextField: NSTextField?

    // Completion support for the variable-name field. Mirrors the auto-
    // complete behavior of iTermFunctionCallTextFieldDelegate but for a bare
    // variable path (not an interpolated string).
    private let variablePathSource = iTermVariableHistory.pathSource(for: .session)
    private var isAutocompleting = false
    private var suppressAutocomplete = false

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Make sure we don't expand beyond our content
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override var intrinsicContentSize: NSSize {
        return stackView.fittingSize
    }

    override var firstBaselineAnchor: NSLayoutYAxisAnchor {
        // Return the first baseline of the stackView, which will be the first row's baseline
        return stackView.firstBaselineAnchor
    }

    // MARK: - Public Methods

    /// Configure the view for a specific event type
    @objc func configure(forMatchType matchType: iTermTriggerMatchType) {
        currentMatchType = matchType

        // Clear existing views
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Reset UI element references
        exitCodeFilterPopup = nil
        exitCodeTextField = nil
        timeoutTextField = nil
        thresholdTextField = nil
        sequenceIdTextField = nil
        directoryRegexTextField = nil
        hostRegexTextField = nil
        userRegexTextField = nil
        commandRegexTextField = nil
        notificationMessageRegexTextField = nil
        progressBarFilterPopup = nil
        jobNameTextField = nil
        variableNameTextField = nil
        variableValueRegexTextField = nil

        // Add appropriate UI for this event type
        switch matchType {
        case .eventCommandFinished:
            addExitCodeFilterUI()
        case .eventDirectoryChanged:
            addDirectoryRegexUI()
        case .eventHostChanged:
            addHostRegexUI()
        case .eventUserChanged:
            addUserRegexUI()
        case .eventIdle, .eventActivityAfterIdle:
            addTimeoutUI()
        case .eventLongRunningCommand:
            addLongRunningCommandUI()
        case .eventCustomEscapeSequence:
            addSequenceIdUI()
        case .eventNotificationPosted:
            addNotificationMessageRegexUI()
        case .eventProgressBarChanged:
            addProgressBarFilterUI()
        case .eventJobStarted, .eventJobEnded:
            addJobNameUI()
        case .eventVariableChanged:
            addVariableChangedUI()
        default:
            // No parameters needed for other event types
            addNoParametersLabel()
        }

        // Tell the layout system our size changed
        invalidateIntrinsicContentSize()
        superview?.needsLayout = true
    }

    // MARK: - UI Construction

    private func addExitCodeFilterUI() {
        let row = createRow(label: NSLocalizedString("Exit Code:", tableName: "Triggers", comment: "行标签：退出码"))

        let popup = NSPopUpButton()
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.addItems(withTitles: [NSLocalizedString("Any", tableName: "Triggers", comment: "退出码过滤：任意"), NSLocalizedString("Zero (Success)", tableName: "Triggers", comment: "退出码过滤：零（成功）"), NSLocalizedString("Non-Zero (Failure)", tableName: "Triggers", comment: "退出码过滤：非零（失败）"), NSLocalizedString("Specific Value…", tableName: "Triggers", comment: "退出码过滤：特定值…")])
        popup.target = self
        popup.action = #selector(exitCodeFilterChanged(_:))
        exitCodeFilterPopup = popup

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = NSLocalizedString("Exit code", tableName: "Triggers", comment: "占位符：退出码")
        textField.isHidden = true
        textField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        textField.delegate = self
        textField.formatter = iTermSaneNumberFormatter()
        exitCodeTextField = textField

        row.addArrangedSubview(popup)
        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)
    }

    private func addJobNameUI() {
        let row = createRow(label: NSLocalizedString("Job:", tableName: "Triggers", comment: "行标签：作业"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = "claude"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        jobNameTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Process name to match in the foreground-job ancestry chain (case-insensitive)", tableName: "Triggers", comment: "帮助：匹配的前台作业进程名"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addVariableChangedUI() {
        // Variable name row (with completion).
        let nameRow = createRow(label: NSLocalizedString("Variable:", tableName: "Triggers", comment: "行标签：变量"))

        let nameField = NSTextField()
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholderString = "user.myVar"
        nameField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        nameField.delegate = self
        variableNameTextField = nameField

        nameRow.addArrangedSubview(nameField)
        stackView.addArrangedSubview(nameRow)

        let nameHelp = NSTextField(labelWithString: NSLocalizedString("Name of the session variable to watch", tableName: "Triggers", comment: "帮助：要监视的会话变量名"))
        nameHelp.translatesAutoresizingMaskIntoConstraints = false
        nameHelp.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        nameHelp.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(nameHelp)

        // Value regex row.
        let valueRow = createRow(label: NSLocalizedString("Value:", tableName: "Triggers", comment: "行标签：值"))

        let valueField = NSTextField()
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.placeholderString = ".*"
        valueField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        valueField.delegate = self
        variableValueRegexTextField = valueField

        valueRow.addArrangedSubview(valueField)
        stackView.addArrangedSubview(valueRow)

        let valueHelp = NSTextField(labelWithString: NSLocalizedString("Regular expression the new value must match (leave blank to match any change)", tableName: "Triggers", comment: "帮助：新值须匹配的正则"))
        valueHelp.translatesAutoresizingMaskIntoConstraints = false
        valueHelp.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        valueHelp.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(valueHelp)
    }

    private func addDirectoryRegexUI() {
        let row = createRow(label: NSLocalizedString("Directory:", tableName: "Triggers", comment: "行标签：目录"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = ".*"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        directoryRegexTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the directory path", tableName: "Triggers", comment: "帮助：匹配目录路径的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addTimeoutUI() {
        let row = createRow(label: NSLocalizedString("Timeout:", tableName: "Triggers", comment: "行标签：超时"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = "30"
        textField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        textField.delegate = self
        textField.formatter = iTermSaneNumberFormatter()
        timeoutTextField = textField

        let unitsLabel = NSTextField(labelWithString: NSLocalizedString("seconds", tableName: "Triggers", comment: "单位：秒"))
        unitsLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(textField)
        row.addArrangedSubview(unitsLabel)
        stackView.addArrangedSubview(row)
    }

    private func addSequenceIdUI() {
        let row = createRow(label: NSLocalizedString("Sequence ID:", tableName: "Triggers", comment: "行标签：序列 ID"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = ".*"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        sequenceIdTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the sequence identifier", tableName: "Triggers", comment: "帮助：匹配序列标识符的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addNotificationMessageRegexUI() {
        let row = createRow(label: NSLocalizedString("Message:", tableName: "Triggers", comment: "行标签：消息"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = ".*"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        notificationMessageRegexTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the notification message", tableName: "Triggers", comment: "帮助：匹配通知消息的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addHostRegexUI() {
        let row = createRow(label: NSLocalizedString("Host:", tableName: "Triggers", comment: "行标签：主机"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = ".*"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        hostRegexTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the hostname", tableName: "Triggers", comment: "帮助：匹配主机名的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addUserRegexUI() {
        let row = createRow(label: NSLocalizedString("User:", tableName: "Triggers", comment: "行标签：用户"))

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholderString = ".*"
        textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        textField.delegate = self
        userRegexTextField = textField

        row.addArrangedSubview(textField)
        stackView.addArrangedSubview(row)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the username", tableName: "Triggers", comment: "帮助：匹配用户名的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addLongRunningCommandUI() {
        // Threshold row
        let thresholdRow = createRow(label: NSLocalizedString("Threshold:", tableName: "Triggers", comment: "行标签：阈值"))

        let thresholdField = NSTextField()
        thresholdField.translatesAutoresizingMaskIntoConstraints = false
        thresholdField.placeholderString = "60"
        thresholdField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        thresholdField.delegate = self
        thresholdField.formatter = iTermSaneNumberFormatter()
        thresholdTextField = thresholdField

        let unitsLabel = NSTextField(labelWithString: NSLocalizedString("seconds", tableName: "Triggers", comment: "单位：秒"))
        unitsLabel.translatesAutoresizingMaskIntoConstraints = false

        thresholdRow.addArrangedSubview(thresholdField)
        thresholdRow.addArrangedSubview(unitsLabel)
        stackView.addArrangedSubview(thresholdRow)

        // Command regex row
        let commandRow = createRow(label: NSLocalizedString("Command:", tableName: "Triggers", comment: "行标签：命令"))

        let commandField = NSTextField()
        commandField.translatesAutoresizingMaskIntoConstraints = false
        commandField.placeholderString = ".*"
        commandField.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        commandField.delegate = self
        commandRegexTextField = commandField

        commandRow.addArrangedSubview(commandField)
        stackView.addArrangedSubview(commandRow)

        let helpLabel = NSTextField(labelWithString: NSLocalizedString("Regular expression to match the command line", tableName: "Triggers", comment: "帮助：匹配命令行的正则"))
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        helpLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(helpLabel)
    }

    private func addProgressBarFilterUI() {
        let row = createRow(label: NSLocalizedString("Fire When:", tableName: "Triggers", comment: "行标签：触发时机"))

        let popup = NSPopUpButton()
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.addItems(withTitles: [NSLocalizedString("Appears or Disappears", tableName: "Triggers", comment: "进度条过滤：出现或消失"), NSLocalizedString("Appears", tableName: "Triggers", comment: "进度条过滤：出现"), NSLocalizedString("Disappears", tableName: "Triggers", comment: "进度条过滤：消失")])
        popup.target = self
        popup.action = #selector(progressBarFilterChanged(_:))
        progressBarFilterPopup = popup

        row.addArrangedSubview(popup)
        stackView.addArrangedSubview(row)
    }

    private func addNoParametersLabel() {
        let label = NSTextField(labelWithString: NSLocalizedString("No additional parameters required.", tableName: "Triggers", comment: "无参数提示"))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(label)
    }

    private func createRow(label: String) -> NSStackView {
        let row = NSStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 6

        let labelView = NSTextField(labelWithString: label)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        labelView.alignment = .right
        row.addArrangedSubview(labelView)

        return row
    }

    // MARK: - Actions

    @objc private func exitCodeFilterChanged(_ sender: NSPopUpButton) {
        let isSpecific = sender.indexOfSelectedItem == 3
        exitCodeTextField?.isHidden = !isSpecific
        onParametersChanged?()
    }

    @objc private func progressBarFilterChanged(_ sender: NSPopUpButton) {
        onParametersChanged?()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        // Filter non-digit characters from numeric fields
        if let textField = obj.object as? NSTextField {
            if textField === exitCodeTextField ||
               textField === timeoutTextField ||
               textField === thresholdTextField {
                let digitsOnly = textField.stringValue.filter { $0.isNumber }
                if digitsOnly != textField.stringValue {
                    textField.stringValue = digitsOnly
                }
            } else if textField === variableNameTextField,
                      let fieldEditor = obj.userInfo?["NSFieldEditor"] as? NSTextView {
                // Offer variable-name completions as the user types, but not
                // while deleting (it's disruptive to re-suggest on backspace).
                if !isAutocompleting && !suppressAutocomplete {
                    isAutocompleting = true
                    fieldEditor.complete(nil)
                    isAutocompleting = false
                }
                suppressAutocomplete = false
            }
        }
        onParametersChanged?()
    }

    func control(_ control: NSControl,
                 textView: NSTextView,
                 completions words: [String],
                 forPartialWordRange charRange: NSRange,
                 indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        guard control === variableNameTextField else {
            return words
        }
        // Don't preselect; preselection causes pathological behavior when
        // typing a period.
        index.pointee = -1

        let full = textView.string as NSString
        // We can't sensibly complete in the middle of the value.
        guard NSMaxRange(charRange) == full.length else {
            return []
        }
        // pathSource wants the full path typed so far (including any leading
        // components like "user."), not just the partial word after the last
        // dot, which is what charRange covers.
        let typed = full.substring(to: NSMaxRange(charRange))
        let matches = variablePathSource(typed)
        let completions = matches.map { (path: String) -> String in
            (path as NSString).substring(from: charRange.location)
        }
        return completions.sorted()
    }

    func control(_ control: NSControl,
                 textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        if control === variableNameTextField &&
            (commandSelector == #selector(NSResponder.deleteBackward(_:)) ||
             commandSelector == #selector(NSResponder.deleteForward(_:)) ||
             commandSelector == #selector(NSResponder.deleteWordBackward(_:)) ||
             commandSelector == #selector(NSResponder.deleteWordForward(_:))) {
            suppressAutocomplete = true
        }
        return false
    }

    // MARK: - Parameter Collection

    private func collectParams() -> [String: Any] {
        var params: [String: Any] = [:]

        switch currentMatchType {
        case .eventCommandFinished:
            if let popup = exitCodeFilterPopup {
                switch popup.indexOfSelectedItem {
                case 0:
                    params["exitCodeFilter"] = "*"
                case 1:
                    params["exitCodeFilter"] = "0"
                case 2:
                    params["exitCodeFilter"] = "!0"
                case 3:
                    params["exitCodeFilter"] = exitCodeTextField?.stringValue ?? "*"
                default:
                    params["exitCodeFilter"] = "*"
                }
            }

        case .eventIdle, .eventActivityAfterIdle:
            if let text = timeoutTextField?.stringValue, let timeout = Double(text) {
                params["timeout"] = NSNumber(value: timeout)
            } else {
                params["timeout"] = NSNumber(value: 30.0)
            }

        case .eventLongRunningCommand:
            if let text = thresholdTextField?.stringValue, let threshold = Double(text) {
                params["threshold"] = NSNumber(value: threshold)
            } else {
                params["threshold"] = NSNumber(value: 60.0)
            }
            let commandRegex = commandRegexTextField?.stringValue ?? ""
            if !commandRegex.isEmpty {
                params["commandRegex"] = commandRegex
            }

        case .eventCustomEscapeSequence:
            params["sequenceId"] = sequenceIdTextField?.stringValue ?? ""

        case .eventNotificationPosted:
            let regex = notificationMessageRegexTextField?.stringValue ?? ""
            if !regex.isEmpty {
                params["messageRegex"] = regex
            }

        case .eventDirectoryChanged:
            let regex = directoryRegexTextField?.stringValue ?? ""
            if !regex.isEmpty {
                params["directoryRegex"] = regex
            }

        case .eventHostChanged:
            let regex = hostRegexTextField?.stringValue ?? ""
            if !regex.isEmpty {
                params["hostRegex"] = regex
            }

        case .eventUserChanged:
            let regex = userRegexTextField?.stringValue ?? ""
            if !regex.isEmpty {
                params["userRegex"] = regex
            }

        case .eventProgressBarChanged:
            if let popup = progressBarFilterPopup {
                switch popup.indexOfSelectedItem {
                case 0:
                    params["progressBarFilter"] = "*"
                case 1:
                    params["progressBarFilter"] = "appeared"
                case 2:
                    params["progressBarFilter"] = "disappeared"
                default:
                    params["progressBarFilter"] = "*"
                }
            }

        case .eventJobStarted, .eventJobEnded:
            let jobName = jobNameTextField?.stringValue ?? ""
            if !jobName.isEmpty {
                params["jobName"] = jobName
            }

        case .eventVariableChanged:
            let variableName = variableNameTextField?.stringValue ?? ""
            if !variableName.isEmpty {
                params[kTriggerVariableNameKey] = variableName
            }
            let valueRegex = variableValueRegexTextField?.stringValue ?? ""
            if !valueRegex.isEmpty {
                params[kTriggerVariableValueRegexKey] = valueRegex
            }

        default:
            break
        }

        return params
    }

    private func applyParams(_ params: [String: Any]) {
        switch currentMatchType {
        case .eventCommandFinished:
            if let filter = params["exitCodeFilter"] as? String {
                switch filter {
                case "*", "":
                    exitCodeFilterPopup?.selectItem(at: 0)
                    exitCodeTextField?.isHidden = true
                case "0":
                    exitCodeFilterPopup?.selectItem(at: 1)
                    exitCodeTextField?.isHidden = true
                case "!0":
                    exitCodeFilterPopup?.selectItem(at: 2)
                    exitCodeTextField?.isHidden = true
                default:
                    exitCodeFilterPopup?.selectItem(at: 3)
                    exitCodeTextField?.stringValue = filter
                    exitCodeTextField?.isHidden = false
                }
            }

        case .eventIdle, .eventActivityAfterIdle:
            if let timeout = params["timeout"] as? NSNumber {
                timeoutTextField?.stringValue = "\(timeout.intValue)"
            }

        case .eventLongRunningCommand:
            if let threshold = params["threshold"] as? NSNumber {
                thresholdTextField?.stringValue = "\(threshold.intValue)"
            }
            if let regex = params["commandRegex"] as? String {
                commandRegexTextField?.stringValue = regex
            }

        case .eventCustomEscapeSequence:
            if let sequenceId = params["sequenceId"] as? String {
                sequenceIdTextField?.stringValue = sequenceId
            }

        case .eventNotificationPosted:
            if let regex = params["messageRegex"] as? String {
                notificationMessageRegexTextField?.stringValue = regex
            }

        case .eventDirectoryChanged:
            if let regex = params["directoryRegex"] as? String {
                directoryRegexTextField?.stringValue = regex
            }

        case .eventHostChanged:
            if let regex = params["hostRegex"] as? String {
                hostRegexTextField?.stringValue = regex
            }

        case .eventUserChanged:
            if let regex = params["userRegex"] as? String {
                userRegexTextField?.stringValue = regex
            }

        case .eventProgressBarChanged:
            if let filter = params["progressBarFilter"] as? String {
                switch filter {
                case "*", "":
                    progressBarFilterPopup?.selectItem(at: 0)
                case "appeared":
                    progressBarFilterPopup?.selectItem(at: 1)
                case "disappeared":
                    progressBarFilterPopup?.selectItem(at: 2)
                default:
                    progressBarFilterPopup?.selectItem(at: 0)
                }
            }

        case .eventJobStarted, .eventJobEnded:
            if let jobName = params["jobName"] as? String {
                jobNameTextField?.stringValue = jobName
            }

        case .eventVariableChanged:
            if let variableName = params[kTriggerVariableNameKey] as? String {
                variableNameTextField?.stringValue = variableName
            }
            if let valueRegex = params[kTriggerVariableValueRegexKey] as? String {
                variableValueRegexTextField?.stringValue = valueRegex
            }

        default:
            break
        }
    }
}

// MARK: - Event Type Display Names

@objc(iTermEventTriggerMatchTypeHelper)
class EventTriggerMatchTypeHelper: NSObject {

    /// Get a human-readable name for an event match type
    @objc static func displayName(for matchType: iTermTriggerMatchType) -> String {
        switch matchType {
        case .eventPromptDetected:
            return NSLocalizedString("Prompt Detected", tableName: "Triggers", comment: "事件名：检测到提示")
        case .eventCommandFinished:
            return NSLocalizedString("Command Finished", tableName: "Triggers", comment: "事件名：命令完成")
        case .eventDirectoryChanged:
            return NSLocalizedString("Directory Changed", tableName: "Triggers", comment: "事件名：目录已更改")
        case .eventHostChanged:
            return NSLocalizedString("Host Changed", tableName: "Triggers", comment: "事件名：主机已更改")
        case .eventUserChanged:
            return NSLocalizedString("User Changed", tableName: "Triggers", comment: "事件名：用户已更改")
        case .eventIdle:
            return NSLocalizedString("Idle (Silence)", tableName: "Triggers", comment: "事件名：空闲（静默）")
        case .eventActivityAfterIdle:
            return NSLocalizedString("Activity After Idle", tableName: "Triggers", comment: "事件名：空闲后活动")
        case .eventSessionEnded:
            return NSLocalizedString("Session Ended", tableName: "Triggers", comment: "事件名：会话已结束")
        case .eventBellReceived:
            return NSLocalizedString("Bell Received", tableName: "Triggers", comment: "事件名：收到响铃")
        case .eventLongRunningCommand:
            return NSLocalizedString("Long-Running Command", tableName: "Triggers", comment: "事件名：长时间运行的命令")
        case .eventCustomEscapeSequence:
            return NSLocalizedString("Custom Escape Sequence", tableName: "Triggers", comment: "事件名：自定义转义序列")
        case .eventNotificationPosted:
            return NSLocalizedString("Notification Posted", tableName: "Triggers", comment: "事件名：已发送通知")
        case .eventProgressBarChanged:
            return NSLocalizedString("Progress Bar Changed", tableName: "Triggers", comment: "事件名：进度条已更改")
        case .eventJobStarted:
            return NSLocalizedString("Job Started", tableName: "Triggers", comment: "事件名：作业已开始")
        case .eventJobEnded:
            return NSLocalizedString("Job Ended", tableName: "Triggers", comment: "事件名：作业已结束")
        case .eventVariableChanged:
            return NSLocalizedString("Variable Changed", tableName: "Triggers", comment: "事件名：变量已更改")
        default:
            return NSLocalizedString("Unknown Event", tableName: "Triggers", comment: "事件名：未知事件")
        }
    }

    /// Get a description/help text for an event match type
    @objc static func helpText(for matchType: iTermTriggerMatchType) -> String {
        switch matchType {
        case .eventPromptDetected:
            return NSLocalizedString("Fires when shell integration detects a new prompt.", tableName: "Triggers", comment: "帮助：检测到新提示时触发")
        case .eventCommandFinished:
            return NSLocalizedString("Fires when a command exits. Requires shell integration.", tableName: "Triggers", comment: "帮助：命令退出时触发")
        case .eventDirectoryChanged:
            return NSLocalizedString("Fires when the working directory changes.", tableName: "Triggers", comment: "帮助：工作目录更改时触发")
        case .eventHostChanged:
            return NSLocalizedString("Fires when connecting to a different host via SSH.", tableName: "Triggers", comment: "帮助：SSH 连接到不同主机时触发")
        case .eventUserChanged:
            return NSLocalizedString("Fires when the current user changes (su/sudo).", tableName: "Triggers", comment: "帮助：当前用户更改时触发")
        case .eventIdle:
            return NSLocalizedString("Fires when no output is received for the specified duration.", tableName: "Triggers", comment: "帮助：指定时长无输出时触发")
        case .eventActivityAfterIdle:
            return NSLocalizedString("Fires when output resumes after being idle.", tableName: "Triggers", comment: "帮助：空闲后恢复输出时触发")
        case .eventSessionEnded:
            return NSLocalizedString("Fires when the session terminates.", tableName: "Triggers", comment: "帮助：会话终止时触发")
        case .eventBellReceived:
            return NSLocalizedString("Fires when a terminal bell (\\a) is received.", tableName: "Triggers", comment: "帮助：收到终端响铃时触发")
        case .eventLongRunningCommand:
            return NSLocalizedString("Fires when a command runs longer than the threshold.", tableName: "Triggers", comment: "帮助：命令运行超阈值时触发")
        case .eventCustomEscapeSequence:
            return NSLocalizedString("Fires when a specific OSC escape sequence is received.", tableName: "Triggers", comment: "帮助：收到特定 OSC 转义序列时触发")
        case .eventNotificationPosted:
            return NSLocalizedString("Fires when a notification is posted by a control sequence (OSC 9).", tableName: "Triggers", comment: "帮助：控制序列发送通知时触发")
        case .eventProgressBarChanged:
            return NSLocalizedString("Fires when a progress bar appears or disappears.", tableName: "Triggers", comment: "帮助：进度条出现或消失时触发")
        case .eventJobStarted:
            return NSLocalizedString("Fires when a process matching the job filter enters the foreground-job ancestry chain.", tableName: "Triggers", comment: "帮助：进程进入前台作业祖链时触发")
        case .eventJobEnded:
            return NSLocalizedString("Fires when a process matching the job filter leaves the foreground-job ancestry chain.", tableName: "Triggers", comment: "帮助：进程离开前台作业祖链时触发")
        case .eventVariableChanged:
            return NSLocalizedString("Fires when a session variable changes to a value matching the regex.", tableName: "Triggers", comment: "帮助：会话变量更改为匹配正则的值时触发")
        default:
            return ""
        }
    }

    /// Get all event match types
    @objc static var allEventTypes: [NSNumber] {
        return [
            NSNumber(value: iTermTriggerMatchType.eventPromptDetected.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventCommandFinished.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventDirectoryChanged.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventHostChanged.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventUserChanged.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventIdle.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventActivityAfterIdle.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventSessionEnded.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventBellReceived.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventLongRunningCommand.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventCustomEscapeSequence.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventNotificationPosted.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventProgressBarChanged.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventJobStarted.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventJobEnded.rawValue),
            NSNumber(value: iTermTriggerMatchType.eventVariableChanged.rawValue)
        ]
    }

    /// Get all event match types except session ended (for triggers that need a live session)
    @objc static var allEventTypesExceptSessionEnded: [NSNumber] {
        let sessionEndedValue = NSNumber(value: iTermTriggerMatchType.eventSessionEnded.rawValue)
        return allEventTypes.filter { $0 != sessionEndedValue }
    }

    /// Get the set of all event match types as NSSet<NSNumber *>
    @objc static var allEventTypesSet: Set<NSNumber> {
        return Set(allEventTypes)
    }

    /// Get the set of all event match types except session ended as NSSet<NSNumber *>
    @objc static var allEventTypesExceptSessionEndedSet: Set<NSNumber> {
        return Set(allEventTypesExceptSessionEnded)
    }
}
