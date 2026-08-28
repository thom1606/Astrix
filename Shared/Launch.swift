//
//  Launch.swift
//  Astrix
//
//  One named launch configuration inside a workspace — e.g. "Dev Server" (kill the
//  port, run `bin/dev`, open the browser) and "Storybook" (run `yarn storybook`) both
//  living under the same workspace. Each launch owns its own ordered action list and
//  its own tracked processes; the workspace groups them and supplies the folder they
//  default to.
//

import Foundation

struct Launch: Codable, Identifiable, Hashable {
    var id: UUID
    /// User-facing name shown in the workspace's menu bar submenu.
    var name: String
    /// The actions run, in order, when this launch is started.
    var actions: [WorkspaceAction]

    init(id: UUID = UUID(), name: String = "", actions: [WorkspaceAction] = []) {
        self.id = id
        self.name = name
        self.actions = actions
    }

    /// Fallback name for a launch the user hasn't named yet.
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Launch" : name
    }
}
