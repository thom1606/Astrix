//
//  PathField.swift
//  AstrixSettings
//
//  A native form row for choosing a file or folder path, shared by the command and
//  open action field groups: the current path on the left, a "Choose…" button that
//  opens an NSOpenPanel on the right.
//

import SwiftUI
import AppKit

struct PathField: View {
    let label: String
    let placeholder: String
    @Binding var path: String

    // A manual HStack rather than LabeledContent: LabeledContent stacks the label above
    // the value when the path is wide, but we always want a single line — the path
    // truncates in the middle to make room.
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
            Text(path.isEmpty ? placeholder : path)
                .foregroundStyle(path.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Button("Choose…", action: choose)
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose a folder or file for this action."
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
        }
    }
}
