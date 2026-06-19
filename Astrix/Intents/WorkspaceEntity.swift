//
//  WorkspaceEntity.swift
//  Astrix
//
//  A workspace surfaced to Apple's App Intents framework — the bridge that lets
//  Siri, the Shortcuts app, and Spotlight see and pick a workspace. A lightweight,
//  Sendable value mirror of `Workspace`, always resolved from the shared App Group
//  so it reflects whatever the Settings app last saved.
//

import AppIntents

struct WorkspaceEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String
    let icon: String

    init(id: UUID, name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    init(_ workspace: Workspace) {
        self.id = workspace.id
        self.name = workspace.displayName
        self.icon = workspace.icon
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Workspace")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }

    static var defaultQuery = WorkspaceQuery()
}

/// Resolves workspaces for the intents framework: by id (re-resolving a workspace a
/// Shortcut was built around), by spoken/typed name (Siri voice matching), and by
/// enumerating them all for Shortcuts pickers. Every lookup reads the shared App
/// Group, so it always reflects the current set.
struct WorkspaceQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WorkspaceEntity] {
        let all = SharedSettings.workspaces
        return identifiers.compactMap { id in
            all.first { $0.id == id }.map(WorkspaceEntity.init)
        }
    }

    func suggestedEntities() async throws -> [WorkspaceEntity] {
        SharedSettings.workspaces.map(WorkspaceEntity.init)
    }
}

extension WorkspaceQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [WorkspaceEntity] {
        SharedSettings.workspaces.map(WorkspaceEntity.init)
    }
}

extension WorkspaceQuery: EntityStringQuery {
    /// Match a spoken or typed name. Returns everything for an empty string so the
    /// Shortcuts/Siri disambiguation list is populated.
    func entities(matching string: String) async throws -> [WorkspaceEntity] {
        let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = SharedSettings.workspaces
        guard !needle.isEmpty else { return all.map(WorkspaceEntity.init) }
        return all
            .filter { $0.displayName.localizedCaseInsensitiveContains(needle) }
            .map(WorkspaceEntity.init)
    }
}
