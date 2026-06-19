//
//  WorkspacesSettingsView.swift
//  AstrixSettings
//
//  The "Workspaces" tab: a scrollable list of the user's workspaces. Each workspace
//  is a named bundle of launch actions that shows up in the menu bar and runs in one
//  click. Tapping a workspace opens its editor as a sheet (see WorkspaceEditorView).
//

import SwiftUI

struct WorkspacesSettingsView: View {
    @StateObject private var store = WorkspacesStore()
    @State private var editing: EditSession?
    @State private var workspaceToDelete: Workspace?

    /// One editing session for the sheet. A fresh `id` each time keeps `.sheet(item:)`
    /// happy, while `workspace` carries either an existing workspace or a blank draft.
    private struct EditSession: Identifiable {
        let id = UUID()
        var workspace: Workspace
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                betaBanner

                SettingsSection(
                    "Workspaces",
                    footer: "Workspaces appear in the menu bar. Click one to run all of its actions in order — open folders in your editor, URLs in your browser, terminals, and shell commands."
                ) {
                    ForEach(store.workspaces) { workspace in
                        WorkspaceRow(
                            workspace: workspace,
                            onEdit: { editing = EditSession(workspace: workspace) },
                            onMoveUp: { moveUp(workspace) },
                            onMoveDown: { moveDown(workspace) },
                            onDelete: { workspaceToDelete = workspace },
                            canMoveUp: store.workspaces.first?.id != workspace.id,
                            canMoveDown: store.workspaces.last?.id != workspace.id
                        )
                    }

                    if store.workspaces.isEmpty {
                        Text("No workspaces yet.")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        editing = EditSession(workspace: Workspace())
                    } label: {
                        Label("Add Workspace", systemImage: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $editing) { session in
            WorkspaceEditorView(store: store, workspace: session.workspace)
        }
        .alert("Delete Workspace?", isPresented: deleteAlertBinding, presenting: workspaceToDelete) { workspace in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { store.remove(workspace) }
        } message: { workspace in
            Text("“\(workspace.displayName)” will be permanently removed. This can't be undone.")
        }
    }

    /// A lightly-yellow warning banner noting the feature is still in beta.
    private var betaBanner: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Workspaces are currently in **beta** — you may run into rough edges as the feature is finalized.")
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.yellow.opacity(0.35))
        )
    }

    // MARK: - Reorder & delete

    /// Drives the delete alert; clearing it (Cancel/Delete) resets the pending workspace.
    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { workspaceToDelete != nil }, set: { if !$0 { workspaceToDelete = nil } })
    }

    private func moveUp(_ workspace: Workspace) {
        guard let index = store.workspaces.firstIndex(where: { $0.id == workspace.id }), index > 0 else { return }
        store.workspaces.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
    }

    private func moveDown(_ workspace: Workspace) {
        guard let index = store.workspaces.firstIndex(where: { $0.id == workspace.id }),
              index < store.workspaces.count - 1 else { return }
        store.workspaces.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
    }
}

#Preview {
    WorkspacesSettingsView()
        .frame(width: 680, height: 600)
}
