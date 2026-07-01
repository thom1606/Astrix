//
//  WorkspaceLauncher.swift
//  Astrix
//
//  The "open" operations a workspace action can perform: open a path in an editor or
//  terminal via Launch Services, or a URL in the browser. Lives in the main
//  (non-sandboxed) app so it can use NSWorkspace directly. Command actions are handled
//  separately by `WorkspaceRunner`/`ManagedProcess` (tracked processes); the overall
//  launch sequence is driven by `WorkspaceRunner`.
//

import AppKit

enum WorkspaceLauncher {
    /// Perform one of the open/browse actions. Command actions are a no-op here — the
    /// runner spawns and tracks those.
    static func performOpen(_ action: WorkspaceAction) {
        switch action.type {
        case .openInDefaultEditor:
            open(path: action.path, in: SharedSettings.defaultEditor)
        case .openInEditor:
            open(path: action.path, in: action.resolvedApp ?? .none)
        case .openInDefaultTerminal:
            open(path: action.path, in: SharedSettings.defaultTerminal)
        case .openInTerminal:
            open(path: action.path, in: action.resolvedApp ?? .none)
        case .openInBrowser:
            openBrowser(action.url)
        case .runCommand, .waitSeconds, .waitForPort, .killPort:
            break   // handled by WorkspaceRunner, not an "open" action
        }
    }

    // MARK: - Opening

    /// Open a filesystem path in the given app. Apps that ship a CLI (cmux) are
    /// launched through it; everything else goes via Launch Services (the native
    /// equivalent of `open -b <bundle-id> <path>`).
    private static func open(path: String, in app: SupportedApps) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard app != .none, !trimmed.isEmpty,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.rawValue) else {
            NSSound.beep()
            return
        }

        let expandedPath = (trimmed as NSString).expandingTildeInPath

        // Prefer the app's bundled CLI (e.g. `cmux <path>`, which opens the folder
        // as a workspace in the active cmux window). Fall through to Launch Services
        // if the CLI is missing or won't spawn.
        if let cli = app.bundledCLIPath, launchCLI(cli, with: expandedPath) {
            return
        }

        let fileURL = URL(fileURLWithPath: expandedPath)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration) { _, error in
            if error != nil { NSSound.beep() }
        }
    }

    /// Run a bundled CLI (`cliPath <path>`) to open `path`. Returns `false` when the
    /// binary is missing or can't be spawned so the caller can fall back to Launch
    /// Services. Doesn't wait for exit — these tools launch/foreground their app.
    private static func launchCLI(_ cliPath: String, with path: String) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: cliPath) else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = [path]
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    /// Open a URL in the user's default browser, defaulting to `https://` when the
    /// user typed a bare host with no scheme.
    private static func openBrowser(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { NSSound.beep(); return }

        let normalized = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: normalized) else { NSSound.beep(); return }
        NSWorkspace.shared.open(url)
    }
}
