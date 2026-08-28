//
//  WorkspaceControl.swift
//  Astrix
//
//  Launch a workspace by *identity* (id or name) rather than by value. The menu bar
//  already has the whole `Workspace` in hand when the user clicks it; external
//  triggers — the `astrix://` URL scheme and the App Intents that back Siri /
//  Shortcuts / Spotlight — only know an id or a spoken name. This resolves that
//  against the workspaces persisted in the shared App Group, then hands off to the
//  existing `WorkspaceRunner`. Main app only.
//

import Foundation

@MainActor
enum WorkspaceControl {
    enum LaunchError: Error { case notFound }

    /// Launch the workspace with this exact id. `launchNamed` picks one of its launch
    /// configurations by name; without it the first one runs. Returns the workspace that
    /// ran, or throws `.notFound` if nothing matches (e.g. it was deleted after a
    /// Shortcut was recorded).
    @discardableResult
    static func launch(id: UUID, launchNamed: String? = nil) throws -> Workspace {
        guard let workspace = SharedSettings.workspaces.first(where: { $0.id == id }) else {
            throw LaunchError.notFound
        }
        try run(workspace, launchNamed: launchNamed)
        return workspace
    }

    /// Launch a workspace by name, tolerant of case and surrounding whitespace.
    /// Prefers an exact `displayName` match, then falls back to a unique substring
    /// match so "acme" finds "Acme API". Throws `.notFound` if nothing matches.
    @discardableResult
    static func launch(name: String, launchNamed: String? = nil) throws -> Workspace {
        let all = SharedSettings.workspaces
        guard let workspace = match(name, in: all, by: \.displayName) else { throw LaunchError.notFound }
        try run(workspace, launchNamed: launchNamed)
        return workspace
    }

    /// Run one of the workspace's launch configurations — the named one, or the first.
    private static func run(_ workspace: Workspace, launchNamed: String?) throws {
        let launch: Launch?
        if let launchNamed, !launchNamed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            launch = match(launchNamed, in: workspace.launches, by: \.displayName)
        } else {
            launch = workspace.launches.first
        }
        guard let launch else { throw LaunchError.notFound }
        WorkspaceRunner.launch(launch, in: workspace)
    }

    /// Name lookup tolerant of case and surrounding whitespace: an exact match first,
    /// then a substring match so "acme" finds "Acme API".
    private static func match<T>(_ name: String, in items: [T], by key: KeyPath<T, String>) -> T? {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.first { $0[keyPath: key].caseInsensitiveCompare(needle) == .orderedSame }
            ?? items.first { $0[keyPath: key].localizedCaseInsensitiveContains(needle) }
    }
}
