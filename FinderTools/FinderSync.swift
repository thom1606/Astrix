//
//  FinderSync.swift
//  FinderTools
//
//  The Finder Sync extension entry point. Builds the right-click (contextual)
//  menu for files/folders and the Finder toolbar menu. For now the actions are
//  placeholders that log to the console — real behaviour comes later.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    override init() {
        super.init()

        // Observe every mounted volume so the extension's menus are offered
        // everywhere in Finder, and keep up with volumes mounted later.
        let controller = FIFinderSyncController.default()
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            controller.directoryURLs = Set<URL>(mountedVolumes)
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                controller.directoryURLs.insert(volumeURL)
            }
        }
    }

    // MARK: - Toolbar item

    override var toolbarItemName: String { "Astrix (DEV)" }

    override var toolbarItemToolTip: String { "Easily navigate right from your Finder window" }

    override var toolbarItemImage: NSImage {
        let image = NSImage(named: "icon-template") ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 19, height: 19)
        return image
    }

    // MARK: - Menus

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        if menuKind == .contextualMenuForSidebar { return nil }

        let menu = NSMenu(title: "")

        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForItems:
            // Right-click on a folder or file: nest everything under an "Astrix"
            // submenu with the Item, Workspace, and Suggestions sections.
            let astrixMenu = NSMenu(title: "")
            addSection(ItemSection(), to: astrixMenu)
            addSection(WorkspaceSection(), to: astrixMenu)
            addSection(SuggestionsSection(), to: astrixMenu)

            let mainMenuItem = NSMenuItem(title: "Astrix (DEV)", action: nil, keyEquivalent: "")
            mainMenuItem.submenu = astrixMenu
            menu.addItem(mainMenuItem)
        case .toolbarItemMenu:
            // Finder toolbar button: the Workspace and Suggestions sections.
            addSection(WorkspaceSection(), to: menu)
            addSection(SuggestionsSection(), to: menu)
        default:
            return nil
        }

        return menu
    }

    /// Append a section's items to a menu, prefixed by a disabled title row.
    private func addSection(_ section: AstrixSection, to menu: NSMenu, showTitle: Bool = true) {
        let items = section.getSectionItems()
        guard !items.isEmpty else { return }

        if showTitle {
            menu.addItem(Utilities.createTitleItem(title: section.sectionName))
        }
        for item in items {
            menu.addItem(item)
        }
    }

    // MARK: - Item actions

    @objc func openItemInEditor(_ sender: AnyObject?) {
        Utilities.openSelected(in: SharedSettings.defaultEditor)
    }

    @objc func copyItemPath(_ sender: AnyObject?) {
        let paths = Utilities.selectedURLs.map(\.path)
        guard !paths.isEmpty else { return }
        Utilities.copyToClipboard(paths)
        let body = paths.count > 1
            ? NSLocalizedString("The paths were copied to your clipboard.", comment: "Notification body after copying multiple paths.")
            : NSLocalizedString("The path was copied to your clipboard.", comment: "Notification body after copying a single path.")
        NotificationManager.relay(title: NSLocalizedString("Copied", comment: "Notification title shown after copying a path."), body: body)
    }

    // MARK: - Workspace actions

    @objc func openInEditor(_ sender: AnyObject?) {
        Utilities.openWorkspace(in: SharedSettings.defaultEditor)
    }

    @objc func openInTerminal(_ sender: AnyObject?) {
        Utilities.openWorkspace(in: SharedSettings.defaultTerminal)
    }

    @objc func copyWorkspacePath(_ sender: AnyObject?) {
        guard let url = Utilities.workspaceURL else { return }
        Utilities.copyToClipboard([url.path])
        NotificationManager.relay(
            title: NSLocalizedString("Copied", comment: "Notification title shown after copying a path."),
            body: NSLocalizedString("The workspace path was copied to your clipboard.", comment: "Notification body after copying the workspace folder path.")
        )
    }

    // MARK: - Suggestion actions

    /// Open the suggested folder in the editor carried on the clicked menu item
    /// (`representedObject` is a `SupportedApps` raw value / bundle id).
    @objc func openSuggestion(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let app = SupportedApps(rawValue: raw),
              let folder = Utilities.contextFolderURL else { return }
        Utilities.open(folder, in: app)
    }
}
