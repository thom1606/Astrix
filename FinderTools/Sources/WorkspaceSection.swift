//
//  WorkspaceSection.swift
//  FinderTools
//
//  Actions that apply to the current workspace (the folder the menu opened in).
//  Shared between the right-click menu and the Finder toolbar menu. Which items
//  appear depends on the user's default editor/terminal settings.
//

import FinderSync

class WorkspaceSection: AstrixSection {
    var sectionName: String { "Workspace" }

    func getSectionItems() -> [NSMenuItem] {
        var items: [NSMenuItem] = []

        if SharedSettings.defaultEditor != .none {
            items.append(NSMenuItem(title: "Open in Editor", action: #selector(FinderSync.openInEditor(_:)), keyEquivalent: ""))
        }
        if SharedSettings.defaultTerminal != .none {
            items.append(NSMenuItem(title: "Open in Terminal", action: #selector(FinderSync.openInTerminal(_:)), keyEquivalent: ""))
        }
        items.append(NSMenuItem(title: "Copy Workspace Path", action: #selector(FinderSync.copyWorkspacePath(_:)), keyEquivalent: ""))

        return items
    }
}
