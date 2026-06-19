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

    /// Launch the workspace with this exact id. Returns the workspace that ran, or
    /// throws `.notFound` if the id doesn't match any saved workspace (e.g. it was
    /// deleted after a Shortcut was recorded).
    @discardableResult
    static func launch(id: UUID) throws -> Workspace {
        guard let workspace = SharedSettings.workspaces.first(where: { $0.id == id }) else {
            throw LaunchError.notFound
        }
        WorkspaceRunner.launch(workspace)
        return workspace
    }

    /// Launch a workspace by name, tolerant of case and surrounding whitespace.
    /// Prefers an exact `displayName` match, then falls back to a unique substring
    /// match so "acme" finds "Acme API". Throws `.notFound` if nothing matches.
    @discardableResult
    static func launch(name: String) throws -> Workspace {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = SharedSettings.workspaces
        let match = all.first { $0.displayName.caseInsensitiveCompare(needle) == .orderedSame }
            ?? all.first { $0.displayName.localizedCaseInsensitiveContains(needle) }
        guard let workspace = match else { throw LaunchError.notFound }
        WorkspaceRunner.launch(workspace)
        return workspace
    }
}
