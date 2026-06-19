//
//  WorkspacesStore.swift
//  Astrix
//
//  Persists the user's workspaces in the shared App Group.
//

import Foundation
import Combine

/// Single source of truth for the user's workspaces.
///
/// Stored as JSON in the shared App Group (`UserDefaults.astrixShared`) so the menu
/// bar app reads exactly what the Settings app wrote. SwiftUI views observe this
/// object; mutations persist automatically.
final class WorkspacesStore: ObservableObject {
    @Published var workspaces: [Workspace] {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let key = Constants.DefaultsKey.workspaces

    init(defaults: UserDefaults = .astrixShared) {
        self.defaults = defaults
        self.workspaces = SharedSettings.workspaces
    }

    // MARK: - Workspaces

    /// Insert or update a workspace (matched by id). The editor commits its draft
    /// through this on "Done"; a brand-new workspace is appended, an edited one is
    /// replaced in place.
    func save(_ workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
        } else {
            workspaces.append(workspace)
        }
    }

    /// Remove a workspace.
    func remove(_ workspace: Workspace) {
        workspaces.removeAll { $0.id == workspace.id }
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(workspaces) else { return }
        defaults.set(data, forKey: key)
    }
}
