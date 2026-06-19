//
//  CommandActionFields.swift
//  AstrixSettings
//
//  Fields for a "Run Command" action: a multi-line command editor, a working directory,
//  and a "Wait for exit" toggle. Off (default) keeps the command running as a tracked
//  service shown in the menu bar (with a name); on runs it to completion and blocks the
//  sequence until it finishes.
//

import SwiftUI

struct CommandActionFields: View {
    @Binding var action: WorkspaceAction

    var body: some View {
        // Label sits above the editor since the field grows to several lines.
        VStack(alignment: .leading, spacing: 6) {
            Text("Command")
                .foregroundStyle(.secondary)
            TextField("Command", text: $action.command, prompt: Text("e.g. bin/dev"), axis: .vertical)
                .labelsHidden()
                .lineLimit(3...12)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        PathField(label: "Working Directory", placeholder: "Optional", path: $action.path)

        SettingsToggleRow("Wait for exit", isOn: $action.waitForExit)

        // When the command isn't waited on it keeps running as a tracked service, so let
        // the user name how it appears in the menu bar.
        if !action.waitForExit {
            SettingsRow("Name in menu") {
                TextField("Name in menu", text: $action.label, prompt: Text("e.g. Rails server"))
                    .labelsHidden()
            }
        }
    }
}
