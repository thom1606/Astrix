//
//  BrowserActionFields.swift
//  AstrixSettings
//
//  Fields for an "Open in Browser" action: just the URL to open.
//

import SwiftUI

struct BrowserActionFields: View {
    @Binding var action: WorkspaceAction

    var body: some View {
        SettingsRow("URL") {
            TextField("URL", text: $action.url, prompt: Text("https://example.com"))
                .labelsHidden()
        }
    }
}
