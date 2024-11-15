//
//  Utilities.swift
//  FinderTools
//
//  Created by Thom van den Broek on 12/11/2024.
//

import FinderSync
import UserNotifications

class Utilities {
    /// Get the currently selected paths from finder as an URL array
    static func getSelectedPathsFromFinder() -> [URL] {
        var urls = [URL]()
        if let items = FIFinderSyncController.default().selectedItemURLs(), items.count > 0 {
            items.forEach {
                urls.append($0)
            }
        } else if let url = FIFinderSyncController.default().targetedURL() {
            urls.append(url)
        }
        return urls
    }

    static func getOpenCommand(bundleId: SupportedApps, url: URL) -> String {
        if (bundleId == .xcode) { return "xed '\(url.path)'" }
        return "open -b \(bundleId.rawValue) '\(url.path)'"
    }

    /// Open the current folder with a specified app
    static func openApp (bundleId: SupportedApps) -> Bool {
        guard var url = Utilities.getSelectedPathsFromFinder().first else { return false }

        if bundleId == .none { return false }

        // check the path is directory or not
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return false }

        // if the selected is a file, then delete last path component
        if isDirectory.boolValue == false {
            url.deleteLastPathComponent()
        }

        let openCommand = getOpenCommand(bundleId: bundleId, url: url);
        NSLog(openCommand)

        // Try and load the applescript
        guard let scriptURL = Scripting.shared.getScriptURL(name: Constants.Scripting.ToolsFileName) else { return false }
        guard FileManager.default.fileExists(atPath: scriptURL.path) else { return false }
        guard let script = try? NSUserAppleScriptTask(url: scriptURL) else { return false }

        let event = Scripting.shared.getScriptEvent(functionName: "openApp", openCommand)
        let semaphore = DispatchSemaphore(value: 0)
        var success = true

        // Execute the script
        script.execute(withAppleEvent: event) { (appleEvent, error) in
            if let error = error {
                NSLog("could not load script: \(error.localizedDescription)")
                success = false
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)
        return success
    }

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
}
