//
//  WorkspaceRow.swift
//  AstrixSettings
//
//  A single tappable workspace row for the Workspaces tab: the workspace's icon,
//  its name, and an action count, with a trailing chevron. Tapping it edits the
//  workspace; the context menu reorders or deletes it. Designed to live inside a
//  `SettingsSection`.
//

import SwiftUI

struct WorkspaceRow: View {
    let workspace: Workspace
    var onEdit: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onDelete: () -> Void
    var canMoveUp: Bool
    var canMoveDown: Bool

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Image(systemName: workspace.icon)
                    .foregroundStyle(.tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.displayName)
                        .fontWeight(.medium)
                    Text(actionCount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onMoveUp) {
                Label("Move Up", systemImage: "arrow.up")
            }
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Label("Move Down", systemImage: "arrow.down")
            }
            .disabled(!canMoveDown)

            Divider()

            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var actionCount: String {
        workspace.actions.count == 1 ? "1 action" : "\(workspace.actions.count) actions"
    }
}
