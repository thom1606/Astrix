//
//  OpenActionFields.swift
//  AstrixSettings
//
//  Fields for the editor/terminal "open" actions: an app picker for the specific
//  ("Open in Editor…"/"Open in Terminal…") variants, plus the path to open. The
//  "default" variants resolve the app from settings at launch, so they only need a path.
//

import SwiftUI

struct OpenActionFields: View {
    @Binding var action: WorkspaceAction

    var body: some View {
        if action.type.usesSpecificApp {
            SettingsRow(action.type == .openInTerminal ? "Terminal" : "Editor") {
                Picker("", selection: $action.appBundleID) {
                    Text("Choose…").tag("")
                    ForEach(appChoices) { app in
                        Text(app.displayName).tag(app.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
        }

        PathField(label: "Path", placeholder: "Choose a path…", path: $action.path)
    }

    private var appChoices: [SupportedApps] {
        action.type == .openInTerminal ? SupportedApps.terminals : SupportedApps.editors
    }
}
