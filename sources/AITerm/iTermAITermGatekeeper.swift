//
//  iTermAITermGatekeeper.swift
//  iTerm2
//
//  Created by George Nachman on 6/5/25.
//

@objc
class iTermAITermGatekeeper: NSObject {
    @objc
    static func validatePlugin(_ completion: @escaping (String?) -> ()) {
        DLog("validatePlugin")
        iTermAIClient.instance.validate(completion)
    }

    @objc
    static func reloadPlugin(_ completion: @escaping () -> ()) {
        DLog("reloadPlugin")
        iTermAIClient.instance.reload(completion)
    }

    @objc(checkSilently:)
    static func check(silent: Bool = false) -> Bool {
        DLog("check")
        if !iTermAdvancedSettingsModel.generativeAIAllowed() {
            if !silent {
                iTermWarning.show(withTitle: NSLocalizedString("Generative AI features have been disabled. Check with your system administrator.", tableName: "AITermXC", comment: "生成式 AI 功能已被禁用。请联系系统管理员。"),
                                  actions: [NSLocalizedString("OK", tableName: "AITermXC", comment: "好")],
                                  accessory: nil,
                                  identifier: nil,
                                  silenceable: .kiTermWarningTypePersistent,
                                  heading: NSLocalizedString("Feature Unavailable", tableName: "AITermXC", comment: "功能不可用"),
                                  window: nil)
            }
            return false
        }
        if !iTermAITermGatekeeper.pluginInstalled() {
            if !silent {
                let selection = iTermWarning.show(withTitle: NSLocalizedString("You must install the AI plugin before you can use this feature.", tableName: "AITermXC", comment: "您必须先安装 AI 插件才能使用此功能。"),
                                                  actions: [NSLocalizedString("Reveal in Settings", tableName: "AITermXC", comment: "在设置中显示"), NSLocalizedString("Cancel", tableName: "AITermXC", comment: "取消")],
                                                  accessory: nil,
                                                  identifier: nil,
                                                  silenceable: .kiTermWarningTypePersistent,
                                                  heading: NSLocalizedString("Plugin Missing", tableName: "AITermXC", comment: "插件缺失"),
                                                  window: nil)
                if selection == .kiTermWarningSelection0 {
                    PreferencePanel.sharedInstance().openToPreference(withKey: kPhonyPreferenceKeyInstallAIPlugin)
                }
            }
            return false
        }
        if !SecureUserDefaults.instance.enableAI.value {
            if !silent {
                let selection = iTermWarning.show(withTitle: NSLocalizedString("You must enable AI features in settings before you can use this feature.", tableName: "AITermXC", comment: "您必须先在设置中启用 AI 功能才能使用此功能。"),
                                                  actions: [NSLocalizedString("Reveal", tableName: "AITermXC", comment: "显示"), NSLocalizedString("Cancel", tableName: "AITermXC", comment: "取消")],
                                                  accessory: nil,
                                                  identifier: nil,
                                                  silenceable: .kiTermWarningTypePersistent,
                                                  heading: NSLocalizedString("Feature Unavailable", tableName: "AITermXC", comment: "功能不可用"),
                                                  window: nil)
                if selection == .kiTermWarningSelection0 {
                    PreferencePanel.sharedInstance().openToPreference(withKey: kPreferenceKeyEnableAI)
                }
            }
            return false
        }
        do {
            try iTermAIClient.instance.validate()
        } catch let error as PluginError {
            RLog("\(error.reason)")
            if !silent {
                iTermWarning.show(withTitle: error.reason,
                                  actions: [NSLocalizedString("OK", tableName: "AITermXC", comment: "好")],
                                  accessory: nil,
                                  identifier: nil,
                                  silenceable: .kiTermWarningTypePersistent,
                                  heading: NSLocalizedString("Feature Unavailable", tableName: "AITermXC", comment: "功能不可用"),
                                  window: nil)
            }
            return false
        } catch {
            if !silent {
                iTermWarning.show(withTitle: error.localizedDescription,
                                  actions: [NSLocalizedString("OK", tableName: "AITermXC", comment: "好")],
                                  accessory: nil,
                                  identifier: nil,
                                  silenceable: .kiTermWarningTypePersistent,
                                  heading: NSLocalizedString("Feature Unavailable", tableName: "AITermXC", comment: "功能不可用"),
                                  window: nil)
            }
            return false
        }
        return true
    }

    @objc
    static func pluginInstalled() -> Bool {
        switch Plugin.instance() {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    @objc
    static var allowed: Bool {
        DLog("allowed")
        return iTermAdvancedSettingsModel.generativeAIAllowed() && SecureUserDefaults.instance.enableAI.value
    }
}
