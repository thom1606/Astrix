//
//  ItemSection.swift
//  FinderTools
//
//  Actions that apply to the specific file/folder the user right-clicked. Only
//  shown for a single selected item (not when right-clicking the folder's empty
//  area, which is handled by the Workspace section).
//

import FinderSync

class ItemSection: AstrixSection {
    var sectionName: String { "Item" }

    func getSectionItems() -> [NSMenuItem] {
        let selected = FIFinderSyncController.default().selectedItemURLs() ?? []
        let workspace = FIFinderSyncController.default().targetedURL()

        // Only for a single item, and not the workspace folder itself.
        guard selected.count == 1, selected.first?.path != workspace?.path else { return [] }

        var items: [NSMenuItem] = []
        if SharedSettings.defaultEditor != .none {
            items.append(NSMenuItem(title: "Open in Editor", action: #selector(FinderSync.openItemInEditor(_:)), keyEquivalent: ""))
        }
        items.append(NSMenuItem(title: "Copy Path", action: #selector(FinderSync.copyItemPath(_:)), keyEquivalent: ""))
        return items
    }
}
