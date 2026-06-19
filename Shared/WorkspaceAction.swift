//
//  WorkspaceAction.swift
//  Astrix
//
//  A single launch step inside a workspace: open a path in an editor or terminal,
//  open a URL in the browser, or run a shell command.
//

import Foundation

/// One step in a workspace's launch sequence.
///
/// All possible parameters live on the struct; which ones are meaningful depends on
/// `type` (e.g. `url` only matters for `.openInBrowser`). This keeps the model flat
/// and trivially `Codable` for storage in the shared App Group. The "default"
/// editor/terminal variants leave `appBundleID` empty and resolve the app live from
/// the user's settings at launch time.
struct WorkspaceAction: Codable, Identifiable, Hashable {
    var id: UUID
    var type: ActionType
    /// Folder/file to open, for the editor & terminal actions. Also used as the
    /// working directory for `.runCommand`.
    var path: String
    /// `SupportedApps.rawValue` (bundle id) for the *specific* editor/terminal
    /// variants. Empty for the "default" variants.
    var appBundleID: String
    /// The URL to open, for `.openInBrowser`.
    var url: String
    /// The shell command to run, for `.runCommand`.
    var command: String
    /// Friendly name shown for a running service in the menu bar submenu (used when the
    /// command keeps running, i.e. `waitForExit` is off). Falls back to the command.
    var label: String
    /// For a `.runCommand`: when ON, run the command to completion and block the launch
    /// sequence until it exits (a one-shot setup step like `bundle install`). When OFF,
    /// the command keeps running as a tracked service shown in the menu bar.
    var waitForExit: Bool
    /// Number of seconds to pause, for `.waitSeconds`.
    var seconds: Int
    /// TCP port to wait for (until it accepts connections) or to free, for the
    /// `.waitForPort` / `.killPort` actions.
    var port: Int
    /// Whether this action runs at all. Disabled actions are skipped without deletion.
    var enabled: Bool

    init(
        id: UUID = UUID(),
        type: ActionType,
        path: String = "",
        appBundleID: String = "",
        url: String = "",
        command: String = "",
        label: String = "",
        waitForExit: Bool = false,
        seconds: Int = 0,
        port: Int = 0,
        enabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.path = path
        self.appBundleID = appBundleID
        self.url = url
        self.command = command
        self.label = label
        self.waitForExit = waitForExit
        self.seconds = seconds
        self.port = port
        self.enabled = enabled
    }

    /// The kinds of action a workspace can run.
    enum ActionType: String, Codable, CaseIterable, Identifiable {
        case openInDefaultEditor
        case openInEditor
        case openInBrowser
        case openInDefaultTerminal
        case openInTerminal
        case runCommand
        case waitSeconds
        case waitForPort
        case killPort

        var id: String { rawValue }

        /// Label shown when picking a new action type to add.
        var menuTitle: String {
            switch self {
            case .openInDefaultEditor: return "Open in Default Editor"
            case .openInEditor: return "Open in Editor…"
            case .openInBrowser: return "Open in Browser"
            case .openInDefaultTerminal: return "Open in Default Terminal"
            case .openInTerminal: return "Open in Terminal…"
            case .runCommand: return "Run Command"
            case .waitSeconds: return "Wait for Seconds"
            case .waitForPort: return "Wait for Port"
            case .killPort: return "Kill Port"
            }
        }

        /// SF Symbol representing the action in lists and menus.
        var iconName: String {
            switch self {
            case .openInDefaultEditor, .openInEditor:
                return "chevron.left.forwardslash.chevron.right"
            case .openInBrowser:
                return "globe"
            case .openInDefaultTerminal, .openInTerminal:
                return "terminal"
            case .runCommand:
                return "bolt"
            case .waitSeconds:
                return "clock"
            case .waitForPort:
                return "network"
            case .killPort:
                return "xmark.octagon"
            }
        }

        /// Whether the action targets a filesystem path (editor/terminal/command).
        var usesPath: Bool {
            switch self {
            case .openInBrowser, .waitSeconds, .waitForPort, .killPort: return false
            default: return true
            }
        }

        /// Whether the action lets the user pick a specific app (the "…" variants).
        var usesSpecificApp: Bool {
            self == .openInEditor || self == .openInTerminal
        }
    }

    /// The specific app this action targets, if any. `nil` for the default variants
    /// (resolved from settings at launch) and for non-app actions.
    var resolvedApp: SupportedApps? {
        guard type.usesSpecificApp, !appBundleID.isEmpty else { return nil }
        return SupportedApps(rawValue: appBundleID)
    }

    /// Whether launching this action starts a long-running process Astrix tracks — a
    /// command that isn't waited on (`waitForExit` off).
    var isTrackedService: Bool { type == .runCommand && !waitForExit }

    /// The name to show for a running service: the user's label, else the command.
    var resolvedLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A short human-readable title for the action row and menu.
    var title: String {
        switch type {
        case .openInDefaultEditor:
            return "Open in Default Editor"
        case .openInEditor:
            return resolvedApp.map { "Open in \($0.displayName)" } ?? "Open in Editor…"
        case .openInBrowser:
            return "Open in Browser"
        case .openInDefaultTerminal:
            return "Open in Default Terminal"
        case .openInTerminal:
            return resolvedApp.map { "Open in \($0.displayName)" } ?? "Open in Terminal…"
        case .runCommand:
            return "Run Command"
        case .waitSeconds:
            return "Wait for Seconds"
        case .waitForPort:
            return "Wait for Port"
        case .killPort:
            return "Kill Port"
        }
    }

    /// The parameter detail shown under the title (path / URL / command / seconds / port).
    var subtitle: String {
        switch type {
        case .openInBrowser:
            return url
        case .runCommand:
            return command
        case .waitSeconds:
            return "\(seconds)s"
        case .waitForPort, .killPort:
            return port == 0 ? "" : "Port \(port)"
        default:
            return path
        }
    }

    /// SF Symbol for the action.
    var iconName: String { type.iconName }
}
