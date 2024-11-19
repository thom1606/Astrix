//
//  WorkspaceSection.swift
//  FinderTools
//
//  Created by Thom van den Broek on 19/11/2024.
//

import SwiftUI
import FinderSync

public class WorkspaceSection: AstrixSection {
    var sectionName: String { NSLocalizedString("Workspace", comment: "Workspace section") }

    func getSectionItems() -> [NSMenuItem] {
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let terminalKey = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.none.rawValue
        let editorKey = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue

        var result: [NSMenuItem] = []

        // Open a terminal in this workspace
        if terminalKey != SupportedApps.none.rawValue {
            let openInTerminalItem = NSMenuItem(title: NSLocalizedString("Open in Terminal", comment: ""), action: #selector(FinderSync.openInTerminal(_:)), keyEquivalent: "")
            result.append(openInTerminalItem)
        }
        // Open the editor in this workspace
        if editorKey != SupportedApps.none.rawValue {
            let openInEditorItem = NSMenuItem(title: NSLocalizedString("Open in Editor", comment: ""), action: #selector(FinderSync.openInEditor(_:)), keyEquivalent: "")
            result.append(openInEditorItem)
        }

        // Copy the path of the current workspace
        let copyPathItem = NSMenuItem(title: NSLocalizedString("Copy Workspace Path", comment: ""), action: #selector(FinderSync.copyWorkspacePath(_:)), keyEquivalent: "")
        result.append(copyPathItem)

        return result
    }
}
