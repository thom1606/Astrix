//
//  WorkspaceActionSection.swift
//  AstrixSettings
//
//  One workspace action rendered as a native Form section: a header naming the action
//  (with a ⋯ menu to enable/reorder/remove it), the type-specific fields, and the
//  shared timing controls (delay before, wait-for-port) that apply to any action.
//

import SwiftUI

struct WorkspaceActionSection: View {
    @Binding var action: WorkspaceAction
    var onDelete: () -> Void
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var canMoveUp: Bool
    var canMoveDown: Bool

    var body: some View {
        SettingsSection {
            header
            fields
        }
    }

    // MARK: - Type-specific fields

    @ViewBuilder
    private var fields: some View {
        switch action.type {
        case .runCommand:
            CommandActionFields(action: $action)
        case .openInBrowser:
            BrowserActionFields(action: $action)
        case .openInDefaultEditor, .openInEditor, .openInDefaultTerminal, .openInTerminal:
            OpenActionFields(action: $action)
        case .waitSeconds:
            WaitSecondsActionFields(action: $action)
        case .waitForPort, .killPort:
            PortActionFields(action: $action)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Label(action.title, systemImage: action.iconName)
                .font(.headline)
            if !action.enabled {
                Text("· Disabled").foregroundStyle(.secondary)
            }
            Spacer()
            overflowMenu
        }
    }

    private var overflowMenu: some View {
        Menu {
            Button(action: onMoveUp) { Label("Move Up", systemImage: "arrow.up") }
                .disabled(!canMoveUp)
            Button(action: onMoveDown) { Label("Move Down", systemImage: "arrow.down") }
                .disabled(!canMoveDown)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
