//
//  WorkspaceEditorView.swift
//  AstrixSettings
//
//  Edits a single workspace: its name, menu bar icon, and ordered list of actions.
//  Presented as a sheet from the Workspaces tab. Each action is its own native Form
//  section (see WorkspaceActionSection). The sheet edits a local draft and only commits
//  it on "Done", so "Cancel" cleanly discards every change — including a brand-new
//  workspace that was never saved.
//

import SwiftUI

struct WorkspaceEditorView: View {
    @ObservedObject var store: WorkspacesStore

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Workspace
    @State private var showingIconPicker = false
    @State private var showingDeleteConfirmation = false

    init(store: WorkspacesStore, workspace: Workspace) {
        self.store = store
        _draft = State(initialValue: workspace)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    generalSection

                    ForEach($draft.actions) { $action in
                        WorkspaceActionSection(
                            action: $action,
                            onDelete: { deleteAction(action.id) },
                            onMoveUp: { moveUp(action.id) },
                            onMoveDown: { moveDown(action.id) },
                            canMoveUp: draft.actions.first?.id != action.id,
                            canMoveDown: draft.actions.last?.id != action.id
                        )
                    }

                    addActionSection
                    manageSection
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()
            bottomBar
        }
        .frame(width: 580, height: 620)
        .alert("Delete Workspace?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteWorkspace)
        } message: {
            Text("“\(draft.displayName)” will be permanently removed. This can't be undone.")
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        SettingsSection("General") {
            SettingsRow("Name") {
                TextField("Name", text: $draft.name)
                    .labelsHidden()
            }
            SettingsRow("Icon") {
                Button {
                    showingIconPicker = true
                } label: {
                    Image(systemName: draft.icon)
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingIconPicker, arrowEdge: .bottom) {
                    IconPicker(selection: $draft.icon) { showingIconPicker = false }
                }
            }
        }
    }

    private var addActionSection: some View {
        SettingsSection(
            footer: "Actions run top to bottom when you launch this workspace. Commands stay tracked, you may stop them from the workspace's menu bar submenu at any time."
        ) {
            Menu("Add Action") {
                addButton(.openInDefaultEditor)
                addButton(.openInEditor)
                Divider()
                addButton(.openInDefaultTerminal)
                addButton(.openInTerminal)
                addButton(.runCommand)
                Divider()
                addButton(.openInBrowser)
                Divider()
                addButton(.waitSeconds)
                addButton(.waitForPort)
                addButton(.killPort)
            }
            .menuStyle(.button)
            .fixedSize()
        }
    }

    private func addButton(_ type: WorkspaceAction.ActionType) -> some View {
        Button {
            addAction(type)
        } label: {
            Label(type.menuTitle, systemImage: type.iconName)
        }
    }

    private var manageSection: some View {
        SettingsSection("Manage") {
            Button("Delete Workspace", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button("Done") { save() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Mutations (local draft only — committed on Done)

    private func addAction(_ type: WorkspaceAction.ActionType) {
        draft.actions.append(WorkspaceAction(type: type))
    }

    private func deleteAction(_ id: UUID) {
        draft.actions.removeAll { $0.id == id }
    }

    private func moveUp(_ id: UUID) {
        guard let index = draft.actions.firstIndex(where: { $0.id == id }), index > 0 else { return }
        draft.actions.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
    }

    private func moveDown(_ id: UUID) {
        guard let index = draft.actions.firstIndex(where: { $0.id == id }),
              index < draft.actions.count - 1 else { return }
        draft.actions.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
    }

    // MARK: - Commit / discard

    private func save() {
        store.save(draft)
        dismiss()
    }

    private func deleteWorkspace() {
        store.remove(draft)
        dismiss()
    }
}
