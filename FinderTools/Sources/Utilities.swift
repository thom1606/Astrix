//
//  Utilities.swift
//  FinderTools
//
//  Created by Thom van den Broek on 12/11/2024.
//

import FinderSync
import UserNotifications

class Utilities {
    /// Get the correct open command based on the bundle id provided.
    /// We do this because some applications have a specific open command
    static func getOpenCommand(bundleId: SupportedApps, url: URL) -> String {
        if bundleId == .xcode { return "xed '\(url.path)'" }
        return "open -b \(bundleId.rawValue) '\(url.path)'"
    }

    /// Open the current folder with a specified app
    static func openWorkspaceInApp (bundleId: SupportedApps) -> Bool {
        if bundleId == .none { return false }

        // Get the workspace url
        let url = FIFinderSyncController.default().targetedURL()
        if url == nil { return false }

        // Create the open command
        let openCommand = getOpenCommand(bundleId: bundleId, url: url!)
        let (success, _) = runCommand(openCommand)
        return success
    }

    /// Open the the selected file/folder with a specified app
    static func openSelectedInApp (bundleId: SupportedApps) -> Bool {
        if bundleId == .none { return false }

        // Get the workspace url
        let url = FIFinderSyncController.default().selectedItemURLs()?.first
        if url == nil { return false }

        // Create the open command
        let openCommand = getOpenCommand(bundleId: bundleId, url: url!)
        let (success, _) = runCommand(openCommand)
        return success
    }

    static func runCommand(_ command: String) -> (success: Bool, response: String) {
        // Try and load the applescript
        guard let scriptURL = Scripting.shared.getScriptURL(name: Constants.Scripting.ToolsFileName) else { return (false, "") }
        guard FileManager.default.fileExists(atPath: scriptURL.path) else { return (false, "") }
        guard let script = try? NSUserAppleScriptTask(url: scriptURL) else { return (false, "") }

        let event = Scripting.shared.getScriptEvent(functionName: "runCommand", command)
        let semaphore = DispatchSemaphore(value: 0)
        var success = true
        var response = ""

        // Execute the script
        script.execute(withAppleEvent: event) { (result, error) in
            if let error = error {
                NSLog("could not load script: \(error.localizedDescription)")
                success = false
            } else if let scriptResult = result?.stringValue {
                response = scriptResult
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)
        return (success, response)
    }

    /// Create a local notification for the user
    static func showNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { (error) in
            if let error = error {
                NSLog("Error adding notification: \(error.localizedDescription)")
            }
        }
    }

    static func createTitleItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: NSLocalizedString(title, comment: ""), action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    static func getBundleApplicationName(bundleId: SupportedApps) -> String {
        Constants.Scripting.SupportedEditorApplications.first(where: { $0.0 == bundleId })?.1 ?? "Unknown"
    }
}
