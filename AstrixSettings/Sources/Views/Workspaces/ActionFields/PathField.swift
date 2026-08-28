//
//  PathField.swift
//  AstrixSettings
//
//  A native form row for choosing a file or folder path, shared by the workspace's
//  folder row and the command/open action field groups: the current path on the left,
//  a "Choose…" button that opens an NSOpenPanel on the right.
//

import SwiftUI
import AppKit

struct PathField: View {
    let label: String
    let placeholder: String
    @Binding var path: String
    /// Restricts the panel to directories (used for the workspace folder).
    var foldersOnly = false

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
            if !path.isEmpty {
                Button {
                    path = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear")
            }
            Button("Choose…", action: choose)
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = !foldersOnly
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = foldersOnly ? "Choose this workspace's folder." : "Choose a folder or file for this action."
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
        }
    }
}
