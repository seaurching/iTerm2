//
//  iTermWorkgroupToolbarItemRegistry.swift
//  iTerm2SharedARC
//
//  Created by George Nachman on 4/23/26.
//

import CoreGraphics
import Foundation

// Metadata catalog for the toolbar tools the user can attach to a
// workgroup session's toolbar. Phase 1 uses this to populate the settings
// UI's item-picker. Phase 2 will add the runtime factory that turns a
// concrete iTermWorkgroupToolbarItem value into a SessionToolbarGeneric-
// View, taking the runtime context (git poller, button delegates, etc.)
// that the settings UI doesn't have access to.
struct iTermWorkgroupToolbarItemMetadata {
    let kind: iTermWorkgroupToolbarItemKind
    let displayName: String
    let hasParameters: Bool          // true for .spacer
    let defaultValue: iTermWorkgroupToolbarItem
}

enum iTermWorkgroupToolbarItemRegistry {
    // Order here is the order the picker UI lists items.
    static let all: [iTermWorkgroupToolbarItemMetadata] = [
        .init(kind: .gitStatus,
              displayName: NSLocalizedString("Git Status", tableName: "Workgroups", comment: "Git状态工具栏项名称"),
              hasParameters: false,
              defaultValue: .gitStatus),
        .init(kind: .changedFileSelector,
              displayName: NSLocalizedString("Changed File Selector", tableName: "Workgroups", comment: "已更改文件选择器工具栏项名称"),
              hasParameters: false,
              defaultValue: .changedFileSelector),
        .init(kind: .modeSwitcher,
              displayName: NSLocalizedString("Peer Mode Switcher", tableName: "Workgroups", comment: "对等体模式切换器工具栏项名称"),
              hasParameters: false,
              defaultValue: .modeSwitcher),
        .init(kind: .navigation,
              displayName: NSLocalizedString("Navigation Buttons", tableName: "Workgroups", comment: "导航按钮工具栏项名称"),
              hasParameters: false,
              defaultValue: .navigation(WorkgroupNavigationShortcuts.defaults)),
        .init(kind: .reload,
              displayName: NSLocalizedString("Reload", tableName: "Workgroups", comment: "重载工具栏项名称"),
              hasParameters: false,
              defaultValue: .reload(WorkgroupToolbarShortcut.reloadDefault)),
        .init(kind: .gitBaseSelector,
              displayName: NSLocalizedString("Git Base Selector", tableName: "Workgroups", comment: "Git基准选择器工具栏项名称"),
              hasParameters: false,
              defaultValue: .gitBaseSelector),
        .init(kind: .autoSendClippingsWhenIdle,
              displayName: NSLocalizedString("Auto-Send Clippings When Idle", tableName: "Workgroups", comment: "空闲时自动发送剪辑工具栏项名称"),
              hasParameters: false,
              defaultValue: .autoSendClippingsWhenIdle),
        .init(kind: .autoRequestReviewWhenIdle,
              displayName: NSLocalizedString("Auto-Request Review When Idle", tableName: "Workgroups", comment: "空闲时自动请求审查工具栏项名称"),
              hasParameters: false,
              defaultValue: .autoRequestReviewWhenIdle),
        .init(kind: .spacer,
              displayName: NSLocalizedString("Spacer", tableName: "Workgroups", comment: "间隔工具栏项名称"),
              hasParameters: true,
              defaultValue: .spacer(minWidth: 4, maxWidth: 4)),
    ]

    static func metadata(forKind kind: iTermWorkgroupToolbarItemKind) -> iTermWorkgroupToolbarItemMetadata? {
        return all.first(where: { $0.kind == kind })
    }

    static func metadata(for item: iTermWorkgroupToolbarItem) -> iTermWorkgroupToolbarItemMetadata? {
        return metadata(forKind: item.kind)
    }
}
