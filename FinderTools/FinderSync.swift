//
//  FinderSync.swift
//  FinderTools
//
//  Created by Thom van den Broek on 14/11/2024.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    override init() {
        super.init()

        let finderSync = FIFinderSyncController.default()
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            finderSync.directoryURLs = Set<URL>(mountedVolumes)
        }
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                finderSync.directoryURLs.insert(volumeURL)
            }
        }
    }

    override var toolbarItemName: String {
        return "Astrix"
    }

    override var toolbarItemToolTip: String {
        return NSLocalizedString("Easily navigate right from your finder window", comment: "Toolbar itme tooltip")
    }

    override var toolbarItemImage: NSImage {
        let image = NSImage(named: "icon-template")!
        image.isTemplate = true
        return image
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        if menuKind == .contextualMenuForSidebar { return nil }

        let menu = NSMenu(title: "")

        switch menuKind {
            case .contextualMenuForContainer,
                .contextualMenuForItems:
                let itemPaths = FIFinderSyncController.default().selectedItemURLs()
                let workspacePath = FIFinderSyncController.default().targetedURL()

                let astrixMenu = NSMenu(title: "")


                // Check if there are any selected files which could be copied to the clipboard
                if itemPaths != nil && itemPaths!.count > 0 {
                    if itemPaths!.first!.relativePath != workspacePath?.relativePath {
                        // Create items menu title
                        astrixMenu.addItem(Utilities.createTitleItem(title: "Item"))

                        // Create the copy path for the items
                        var title = NSLocalizedString("Copy Path", comment: "")
                        if itemPaths!.count > 1 {
                            title = NSLocalizedString("Copy Paths", comment: "")
                        }
                        let copyPathItem = NSMenuItem(title: title, action: #selector(copyItemPath(_:)), keyEquivalent: "")
                        astrixMenu.addItem(copyPathItem)
                    }
                }

                // Create workspace menu title
                astrixMenu.addItem(Utilities.createTitleItem(title: "Workspace"))

                // Add all the workspace items
                for item in getWorkspaceItems() {
                    astrixMenu.addItem(item)
                }

                let mainMenuItem = NSMenuItem(title: "Astrix", action: nil, keyEquivalent: "")
                mainMenuItem.submenu = astrixMenu
                menu.addItem(mainMenuItem)
            case .toolbarItemMenu:
                for item in getWorkspaceItems() {
                    menu.addItem(item)
                }
            default:
                return nil
        }

        return menu
    }

    private func getWorkspaceItems() -> [NSMenuItem] {
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let terminalKey = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.none.rawValue
        let editorKey = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue

        var result: [NSMenuItem] = []

        // Open a terminal in this workspace
        if (terminalKey != SupportedApps.none.rawValue) {
            let openInTerminalItem = NSMenuItem(title: NSLocalizedString("Open in Terminal", comment: ""), action: #selector(openInTerminal(_:)), keyEquivalent: "")
            result.append(openInTerminalItem)
        }
        // Open the editor in this workspace
        if (editorKey != SupportedApps.none.rawValue) {
            let openInEditorItem = NSMenuItem(title: NSLocalizedString("Open in Editor", comment: ""), action: #selector(openInEditor(_:)), keyEquivalent: "")
            result.append(openInEditorItem)
        }

        // Copy the path of the current workspace
        let copyPathItem = NSMenuItem(title: NSLocalizedString("Copy Workspace Path", comment: ""), action: #selector(copyWorkspacePath(_:)), keyEquivalent: "")
        result.append(copyPathItem)

        return result
    }

    // MARK: -- Actions
    /// Open the current workspace in a new  terminal
    @objc func openInTerminal(_ sender: AnyObject?) {
        // Get the preferred terminal
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.terminal.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .terminal
        // Try to open the app with the bundle Id
        if (!Utilities.openApp(bundleId: bundleId)) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open your terminal.", comment: ""));
        }
    }

    /// Open the current workspace in the users preferred editor
    @objc func openInEditor(_ sender: AnyObject?) {
        // Get the preferred editor
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .none
        // Try to open the app with the bundle Id
        if (!Utilities.openApp(bundleId: bundleId)) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open your editor of choice.", comment: ""));
        }
    }

    /// Copy the path of the selected  item selected
    @objc func copyItemPath(_ sender: AnyObject?) {
        // Get the selected items
        let itemPaths = FIFinderSyncController.default().selectedItemURLs()

        // If no items are found, show an error
        if itemPaths == nil && itemPaths!.count == 0 {
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to copy the path(s) to your clipboard.", comment: ""));
            return
        }

        // Map all the paths
        let paths = itemPaths!.map { $0.relativePath }

        // Add the paths in a string with \n to the clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths.joined(separator: "\n"), forType: .string)
        if (paths.count > 1) {
            Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The paths are copied to your clipboard.", comment: ""))
        } else {
            Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The path is copied to your clipboard.", comment: ""))
        }
    }

    /// Copy the path of the workspace folder
    @objc func copyWorkspacePath(_ sender: AnyObject?) {
        // Get the workspace path
        let workspacePath = FIFinderSyncController.default().targetedURL()

        // If there is no workspace path, show an error
        if workspacePath == nil {
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to copy the path to your clipboard.", comment: ""));
            return
        }

        // Add the path to the users clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(workspacePath!.relativePath, forType: .string)
        Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The path is copied to your clipboard.", comment: ""));
    }
}

