//
//  SuggestionsSection.swift
//  FinderTools
//
//  Created by Thom van den Broek on 19/11/2024.
//

import SwiftUI
import FinderSync

class ItemSection: AstrixSection {
    var sectionName: String { NSLocalizedString("Item", comment: "Item section") }

    func getSectionItems() -> [NSMenuItem] {
        var result: [NSMenuItem] = []

        if let workspacePath = FIFinderSyncController.default().targetedURL(),
           let itemPaths = FIFinderSyncController.default().selectedItemURLs() {
            // Only allow it on single items
            if itemPaths.count > 1 || workspacePath.relativePath == itemPaths.first?.relativePath { return [] }

            let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
            let editorKey = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue

            // Open the editor in this workspace
            if editorKey != SupportedApps.none.rawValue {
                let openInEditorItem = NSMenuItem(title: NSLocalizedString("Open in Editor", comment: ""), action: #selector(FinderSync.openItemInEditor(_:)), keyEquivalent: "")
                result.append(openInEditorItem)
            }
        }
        return result
    }
}
