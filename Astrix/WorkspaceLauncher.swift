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

    /// Open a filesystem path in the given app via Launch Services (the native
    /// equivalent of `open -b <bundle-id> <path>`).
    private static func open(path: String, in app: SupportedApps) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard app != .none, !trimmed.isEmpty,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.rawValue) else {
            NSSound.beep()
            return
        }

        let fileURL = URL(fileURLWithPath: (trimmed as NSString).expandingTildeInPath)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration) { _, error in
            if error != nil { NSSound.beep() }
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
