//
//  Utilities.swift
//  FinderTools
//
//  Small helpers shared across the Finder extension's menu construction and
//  actions: building menu rows, launching apps, and copying paths.
//

import AppKit
import FinderSync

enum Utilities {
    // MARK: - Menu building

    /// A disabled menu item used as a non-clickable section header.
    static func createTitleItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - Finder context

    /// The folder the Finder menu was invoked in (the "workspace").
    static var workspaceURL: URL? {
        FIFinderSyncController.default().targetedURL()
    }

    /// The items the user has selected, if any.
    static var selectedURLs: [URL] {
        FIFinderSyncController.default().selectedItemURLs() ?? []
    }

    /// The folder a folder-level action should act on: a single selected directory
    /// if the user right-clicked one, otherwise the folder the menu opened in.
    ///
    /// `targetedURL()` is the *containing* folder, so right-clicking on a project
    /// folder would otherwise inspect/open its parent.
    static var contextFolderURL: URL? {
        if selectedURLs.count == 1 {
            let url = selectedURLs[0]
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                return url
            }
        }
        return FIFinderSyncController.default().targetedURL()
    }

    /// The names of a folder's direct children. Tries `FileManager` first; if the
    /// sandbox denies enumeration of a right-clicked folder — which can surface as
    /// either a throw *or* an empty result — falls back to the unsandboxed helper
    /// script (`ls`). The fallback is harmless for a genuinely empty folder.
    static func directoryEntries(of url: URL) -> [String] {
        if let entries = try? FileManager.default.contentsOfDirectory(atPath: url.path), !entries.isEmpty {
            return entries
        }
        let listing = runCommand("ls -1A \(shellQuote(url.path))").output
        return listing.split(whereSeparator: \.isNewline).map(String.init)
    }

    // MARK: - Opening

    /// Open the current workspace folder in the given app.
    @discardableResult
    static func openWorkspace(in app: SupportedApps) -> Bool {
        guard let url = workspaceURL else { return false }
        return open(url, in: app)
    }

    /// Open the first selected item in the given app.
    @discardableResult
    static func openSelected(in app: SupportedApps) -> Bool {
        guard let url = selectedURLs.first else { return false }
        return open(url, in: app)
    }

    /// Launch `app` with `url` (folder or file) as the document to open.
    ///
    /// The extension is sandboxed and can't launch apps directly, so this runs a
    /// shell command through the helper AppleScript (see `Scripting`). Editors with
    /// a first-class CLI (Xcode's `xed`, Zed's `zed`) use it for better behaviour;
    /// if the CLI isn't found we fall back to `open -b <bundle-id>`.
    @discardableResult
    static func open(_ url: URL, in app: SupportedApps) -> Bool {
        guard app != .none else { return false }
        let path = shellQuote(url.path)

        // Prefer the app's own CLI when it has one.
        if let cliCommand = cliOpenCommand(for: app, path: path), runCommand(cliCommand).success {
            return true
        }

        // Fallback, and the path for every other app: open via Launch Services.
        let result = runCommand("open -b \(app.rawValue) \(path)")
        if !result.success {
            NSSound.beep()
            NotificationManager.relay(
                title: NSLocalizedString("Couldn't open", comment: "Notification title shown when launching an app fails."),
                body: String(format: NSLocalizedString("Astrix couldn't open %@.", comment: "Notification body shown when launching an app fails. %@ is the app name."), app.displayName)
            )
        }
        return result.success
    }

    /// The preferred CLI command for editors that ship one, or `nil` to use
    /// `open -b`. `path` is already shell-quoted.
    private static func cliOpenCommand(for app: SupportedApps, path: String) -> String? {
        switch app {
        case .xcode:
            // `xed` ships with Xcode and lives in /usr/bin (already on PATH); it
            // opens folders as projects.
            return "xed \(path)"
        case .zed:
            // The `zed` CLI is installed alongside Zed but usually lives in
            // /usr/local/bin or Homebrew, which aren't on `do shell script`'s
            // default PATH — extend it so the command resolves. `-n` opens a new
            // window.
            return "export PATH=\"/usr/local/bin:/opt/homebrew/bin:$PATH\"; zed -n \(path)"
        case .zedPreview:
            // Zed's Preview channel installs its CLI as `zed-preview`. Same PATH
            // caveat as the stable `zed` CLI above; falls back to `open -b` if the
            // CLI isn't installed.
            return "export PATH=\"/usr/local/bin:/opt/homebrew/bin:$PATH\"; zed-preview -n \(path)"
        default:
            return nil
        }
    }

    /// Run a shell command via the sandbox-approved helper script and return its
    /// success and stdout. `success` is false if the script isn't installed yet
    /// (the Astrix app installs it on launch).
    @discardableResult
    static func runCommand(_ command: String) -> (success: Bool, output: String) {
        guard let scriptURL = Scripting.shared.scriptURL(name: Constants.Scripting.toolsFileName),
              FileManager.default.fileExists(atPath: scriptURL.path),
              let task = try? NSUserAppleScriptTask(url: scriptURL)
        else {
            NSLog("[Astrix] Helper script missing — launch the Astrix app once to install it.")
            return (false, "")
        }

        let event = Scripting.shared.scriptEvent(functionName: "runCommand", command)
        let semaphore = DispatchSemaphore(value: 0)
        var success = true
        var output = ""
        task.execute(withAppleEvent: event) { result, error in
            if let error {
                NSLog("[Astrix] Script error: %@", error.localizedDescription)
                success = false
            } else {
                output = result?.stringValue ?? ""
            }
            semaphore.signal()
        }
        semaphore.wait()
        return (success, output)
    }

    /// Single-quote a path for safe shell interpolation.
    private static func shellQuote(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: - Clipboard

    /// Copy the given paths to the clipboard, one per line.
    static func copyToClipboard(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths.joined(separator: "\n"), forType: .string)
    }
}
