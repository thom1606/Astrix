//
//  SuggestionsSection.swift
//  FinderTools
//
//  Created by Thom van den Broek on 19/11/2024.
//

import SwiftUI
import FinderSync

class SuggestionsSection: AstrixSection {
    var sectionName: String { NSLocalizedString("Suggestions", comment: "Suggestions section") }

    func getSectionItems() -> [NSMenuItem] {
        var result: [NSMenuItem] = []

        if let workspacePath = FIFinderSyncController.default().targetedURL() {
            // check if the folder contains a .vscode folder
            if FileManager.default.fileExists(atPath: (workspacePath.appendingPathComponent(".vscode")).path) {
                if  Scripting.shared.isAppInstalled(bundleIdentifier: SupportedApps.vsCode.rawValue) {
                    let item = NSMenuItem(
                        title: NSLocalizedString("Open in \(Utilities.getBundleApplicationName(bundleId: .vsCode))", comment: ""),
                        action: #selector(FinderSync.openInVSCode(_:)),
                        keyEquivalent: ""
                    )
                    result.append(item)
                }
                if  Scripting.shared.isAppInstalled(bundleIdentifier: SupportedApps.vsCodeInsiders.rawValue) {
                    let item = NSMenuItem(
                        title: NSLocalizedString("Open in \(Utilities.getBundleApplicationName(bundleId: .vsCodeInsiders))", comment: ""),
                        action: #selector(FinderSync.openInVSCodeInsiders(_:)),
                        keyEquivalent: ""
                    )
                    result.append(item)
                }
                if  Scripting.shared.isAppInstalled(bundleIdentifier: SupportedApps.cursor.rawValue) {
                    let item = NSMenuItem(
                        title: NSLocalizedString("Open in \(Utilities.getBundleApplicationName(bundleId: .cursor))", comment: ""),
                        action: #selector(FinderSync.openInCursor(_:)),
                        keyEquivalent: ""
                    )
                    result.append(item)
                }
            }

            // check if there is any file ending with .xcodeproj
            let (success, response) = Utilities.runCommand("cd '\(workspacePath.relativePath)' && find *.xcodeproj -d 0")
            NSLog("success: \(success), res: \(response)")
            NSLog("installed: \(Scripting.shared.isAppInstalled(bundleIdentifier: SupportedApps.xcode.rawValue))")
            if success && Scripting.shared.isAppInstalled(bundleIdentifier: SupportedApps.xcode.rawValue) {
                let item = NSMenuItem(
                    title: NSLocalizedString("Open in \(Utilities.getBundleApplicationName(bundleId: .xcode))", comment: ""),
                    action: #selector(FinderSync.openInXCode(_:)),
                    keyEquivalent: ""
                )
                result.append(item)
            }
        }

        return result
    }
}
