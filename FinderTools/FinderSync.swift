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
        return resize(image: image, w: 19, h: 19)
    }

    func resize(image: NSImage, w width: Int, h height: Int) -> NSImage {
        let destSize = NSSize(width: CGFloat(width), height: CGFloat(height))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: destSize.width, height: destSize.height), from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height), operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        newImage.size = destSize
        return newImage
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        if menuKind == .contextualMenuForSidebar { return nil }

        let menu = NSMenu(title: "")

        switch menuKind {
            case .contextualMenuForContainer,
                .contextualMenuForItems:
                let astrixMenu = NSMenu(title: "")

                addSection(ItemSection(), to: astrixMenu)
                addSection(WorkspaceSection(), to: astrixMenu)

                // Create the main menu button
                let mainMenuItem = NSMenuItem(title: "Astrix", action: nil, keyEquivalent: "")
                mainMenuItem.submenu = astrixMenu
                menu.addItem(mainMenuItem)
            case .toolbarItemMenu:
                addSection(WorkspaceSection(), to: menu)
                addSection(SuggestionsSection(), to: menu)
            default:
                return nil
        }
        return menu
    }

    private func addSection(_ section: AstrixSection, to menu: NSMenu, showTitle: Bool = true) {
        let items = section.getSectionItems()
        if showTitle && !items.isEmpty {
            menu.addItem(Utilities.createTitleItem(title: section.sectionName))
        }

        for item in items {
            menu.addItem(item)
        }
    }

    /// Copy the path of the selected  item selected
    @objc func copyItemPath(_ sender: AnyObject?) {
        // Get the selected items
        let itemPaths = FIFinderSyncController.default().selectedItemURLs()

        // If no items are found, show an error
        if itemPaths == nil || itemPaths!.isEmpty {
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to copy the path(s) to your clipboard.", comment: ""))
            return
        }

        // Map all the paths
        let paths = itemPaths!.map { $0.relativePath }

        // Add the paths in a string with \n to the clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths.joined(separator: "\n"), forType: .string)
        if paths.count > 1 {
            Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The paths are copied to your clipboard.", comment: ""))
        } else {
            Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The path is copied to your clipboard.", comment: ""))
        }
    }

    // MARK: -- Workspace Actions
    /// Open the current workspace in the users preferred terminal
    @objc public func openInTerminal(_ sender: AnyObject?) {
        // Get the preferred terminal
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.terminal.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .terminal
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: bundleId) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open your terminal.", comment: ""))
        }
    }

    /// Open the current workspace in the users preferred editor
    @objc open func openInEditor(_ sender: AnyObject?) {
        // Get the preferred editor
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .none
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: bundleId) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open your editor of choice.", comment: ""))
        }
    }

    /// Copy the path of the workspace folder
    @objc open func copyWorkspacePath(_ sender: AnyObject?) {
        // Get the workspace path
        let workspacePath = FIFinderSyncController.default().targetedURL()

        // If there is no workspace path, show an error
        if workspacePath == nil {
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to copy the path to your clipboard.", comment: ""))
            return
        }

        // Add the path to the users clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(workspacePath!.relativePath, forType: .string)
        Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The path is copied to your clipboard.", comment: ""))
    }

    // MARK: -- Item Actions
    /// Open the current selected file/folder in the users preferred editor
    @objc open func openItemInEditor(_ sender: AnyObject?) {
        // Get the preferred editor
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .none
        // Try to open the app with the bundle Id
        if !Utilities.openSelectedInApp(bundleId: bundleId) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open your editor of choice.", comment: ""))
        }
    }

    // MARK: -- Suggestion Actions
    @objc func openInVSCode(_ sender: Any) {
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: .vsCode) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open the workspace in \(Utilities.getBundleApplicationName(bundleId: .vsCode)).", comment: ""))
        }
    }
    @objc func openInVSCodeInsiders(_ sender: Any) {
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: .vsCodeInsiders) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open the workspace in \(Utilities.getBundleApplicationName(bundleId: .vsCodeInsiders)).", comment: ""))
        }
    }
    @objc func openInCursor(_ sender: Any) {
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: .cursor) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open the workspace in \(Utilities.getBundleApplicationName(bundleId: .cursor)).", comment: ""))
        }
    }
    @objc func openInXCode(_ sender: Any) {
        // Try to open the app with the bundle Id
        if !Utilities.openWorkspaceInApp(bundleId: .xcode) {
            // Warn the user if it failed
            Utilities.showNotification(title: NSLocalizedString("Oops!", comment: ""), body: NSLocalizedString("We were not able to open the workspace in \(Utilities.getBundleApplicationName(bundleId: .xcode)).", comment: ""))
        }
    }
}
