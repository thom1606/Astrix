//
//  WorkspaceEditorView.swift
//  AstrixSettings
//
//  Edits a single workspace: its name, menu bar icon, and folder up top, then a tab bar
//  of its launch configurations — each tab renames in place and owns an ordered action
//  list (see WorkspaceActionSection). Presented as a sheet from the Workspaces tab. The sheet
//  edits a local draft and only commits it on "Done", so "Cancel" cleanly discards every
//  change — including a brand-new workspace that was never saved.
//

import SwiftUI

struct WorkspaceEditorView: View {
    @ObservedObject var store: WorkspacesStore

    @Environment(\.dismiss) private var dismiss
    @State private var draft: Workspace
    @State private var selectedLaunchID: UUID
    @State private var showingIconPicker = false
    /// Focuses a launch's tab field — set when adding one so you can type its name.
    @FocusState private var focusedLaunch: UUID?
    @State private var showingDeleteConfirmation = false

    /// Whether this workspace already exists in the store. A brand-new workspace being
    /// added can't be deleted yet — the "Delete Workspace" option only shows when editing.
    private let isExisting: Bool

    init(store: WorkspacesStore, workspace: Workspace) {
        self.store = store
        var workspace = workspace
        // A workspace always has at least one launch to edit.
        if workspace.launches.isEmpty { workspace.launches = [Launch(name: "Launch")] }
        _draft = State(initialValue: workspace)
        _selectedLaunchID = State(initialValue: workspace.launches[0].id)
        self.isExisting = store.workspaces.contains { $0.id == workspace.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    generalSection
                    launchTabs

                    if let index = selectedIndex {
                        ForEach($draft.launches[index].actions) { $action in
                            WorkspaceActionSection(
                                action: $action,
                                onDelete: { deleteAction(action.id) },
                                onMoveUp: { moveAction(action.id, by: -1) },
                                onMoveDown: { moveAction(action.id, by: 1) },
                                canMoveUp: draft.launches[index].actions.first?.id != action.id,
                                canMoveDown: draft.launches[index].actions.last?.id != action.id
                            )
                        }

                        addActionSection
                    }

                    if isExisting {
                        manageSection
                    }
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

    /// Index of the launch currently being edited, or `nil` if the selection went stale.
    private var selectedIndex: Int? {
        draft.launches.firstIndex { $0.id == selectedLaunchID }
    }

    // MARK: - Sections

    private var generalSection: some View {
        SettingsSection(
            "General",
            footer: "Actions that leave their path empty use the workspace folder, and the menu bar offers to open it in your editor, terminal, or Finder."
        ) {
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
            PathField(label: "Folder", placeholder: "Choose a folder…", path: $draft.folder, foldersOnly: true)
        }
    }

    /// The launch configuration switcher: one tab per launch, plus a "+" to add one.
    private var launchTabs: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach($draft.launches) { $launch in
                        launchTab($launch)
                    }
                }
                .padding(.vertical, 2)
            }
            Button(action: addLaunch) {
                Image(systemName: "plus")
            }
            .help("Add a launch configuration")
        }
    }

    /// One launch's tab. The selected tab *is* its name field — rename in place; the
    /// others just select on click. Right-click deletes (never the last one — a
    /// workspace with no launch has nothing to run).
    @ViewBuilder
    private func launchTab(_ launch: Binding<Launch>) -> some View {
        let isSelected = launch.wrappedValue.id == selectedLaunchID
        Group {
            if isSelected {
                // The hidden Text sizes the chip; the field is overlaid at exactly that
                // size, so the tab grows and shrinks as you type.
                Text(launch.wrappedValue.displayName)
                    .opacity(0)
                    .overlay {
                        TextField("Launch", text: launch.name)
                            .textFieldStyle(.plain)
                            // Without this the field paints its own white focus box
                            // over the chip while you're typing in it.
                            .focusEffectDisabled()
                            .focused($focusedLaunch, equals: launch.wrappedValue.id)
                    }
            } else {
                Text(launch.wrappedValue.displayName)
            }
        }
        .fontWeight(isSelected ? .semibold : .regular)
        .frame(minWidth: 46)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected
                      ? Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
                      : Color.settingsCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .contentShape(Rectangle())
        // Only on the unselected tabs, so a click on the selected one reaches its field.
        .onTapGesture { if !isSelected { selectedLaunchID = launch.wrappedValue.id } }
        .contextMenu {
            if draft.launches.count > 1 {
                Button("Delete Launch", role: .destructive) { deleteLaunch(launch.wrappedValue.id) }
            }
        }
    }

    private var addActionSection: some View {
        SettingsSection(
            footer: "Actions run top to bottom when you start this launch. Commands stay tracked, you may stop them from the workspace's menu bar submenu at any time."
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

    private func addLaunch() {
        let launch = Launch(name: "Launch \(draft.launches.count + 1)")
        draft.launches.append(launch)
        selectedLaunchID = launch.id
        focusedLaunch = launch.id
    }

    private func deleteLaunch(_ id: UUID) {
        guard let index = draft.launches.firstIndex(where: { $0.id == id }),
              draft.launches.count > 1 else { return }
        draft.launches.remove(at: index)
        // Keep a valid selection: the tab that slid into this slot, else the new last one.
        if selectedLaunchID == id {
            selectedLaunchID = draft.launches[min(index, draft.launches.count - 1)].id
        }
    }

    private func addAction(_ type: WorkspaceAction.ActionType) {
        guard let index = selectedIndex else { return }
        draft.launches[index].actions.append(WorkspaceAction(type: type))
    }

    private func deleteAction(_ id: UUID) {
        guard let index = selectedIndex else { return }
        draft.launches[index].actions.removeAll { $0.id == id }
    }

    /// Move an action one slot up (-1) or down (+1) in the selected launch.
    private func moveAction(_ id: UUID, by offset: Int) {
        guard let index = selectedIndex,
              let from = draft.launches[index].actions.firstIndex(where: { $0.id == id }) else { return }
        let to = from + offset
        guard draft.launches[index].actions.indices.contains(to) else { return }
        draft.launches[index].actions.swapAt(from, to)
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
