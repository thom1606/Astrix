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
        switch menuKind {
            case .contextualMenuForContainer,
                    .contextualMenuForItems:
                return createMenu(context: true)
            case .toolbarItemMenu:
                return createMenu(context: false)
            default:
                return nil
        }
    }

    func createMenu(context: Bool) -> NSMenu {
        let menu = NSMenu(title: "")

        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let terminalKey = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.none.rawValue
        let editorKey = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue

        if (terminalKey != SupportedApps.none.rawValue) {
            let openInTerminalItem = NSMenuItem(title: NSLocalizedString("Open in Terminal", comment: ""), action: #selector(openInTerminal(_:)), keyEquivalent: "")
            openInTerminalItem.tag = 1
            menu.addItem(openInTerminalItem)
        }

        if (editorKey != SupportedApps.none.rawValue) {
            let openInEditorItem = NSMenuItem(title: NSLocalizedString("Open in Editor", comment: ""), action: #selector(openInEditor(_:)), keyEquivalent: "")
            openInEditorItem.tag = 2
            menu.addItem(openInEditorItem)
        }

        let copyPathItem = NSMenuItem(title: NSLocalizedString("Copy Path", comment: ""), action: #selector(copyPath(_:)), keyEquivalent: "")
        copyPathItem.tag = 3
        menu.addItem(copyPathItem)

        return menu
    }

    @objc func openInTerminal(_ sender: AnyObject?) {
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultTerminalKey) ?? SupportedApps.terminal.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .terminal
        if (!Utilities.openApp(bundleId: bundleId)) {
            Utilities.showNotification(title: NSLocalizedString("Something failed", comment: ""), body: NSLocalizedString("We were not able to open your terminal.", comment: ""));
        }
    }

    @objc func openInEditor(_ sender: AnyObject?) {
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        let bundleIdString = userDefaults?.string(forKey: Constants.Id.DefaultEditorKey) ?? SupportedApps.none.rawValue
        let bundleId = SupportedApps(rawValue: bundleIdString) ?? .none
        if (!Utilities.openApp(bundleId: bundleId)) {
            Utilities.showNotification(title: NSLocalizedString("Something failed", comment: ""), body: NSLocalizedString("We were not able to open your editor of choice.", comment: ""));
        }
    }

    @objc func copyPath(_ sender: AnyObject?) {
        let paths = Utilities.getSelectedPathsFromFinder().map { $0.path }
        let pasteboard = NSPasteboard.general;
        pasteboard.clearContents();
        pasteboard.setString(paths.joined(separator: "\n"), forType: .string);
        Utilities.showNotification(title: NSLocalizedString("Copied!", comment: ""), body: NSLocalizedString("The path is copied to your clipboard.", comment: ""));
    }
}

