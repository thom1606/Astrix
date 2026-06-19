//
//  SettingsRow.swift
//  AstrixSettings
//
//  A label + trailing value row for use inside a `SettingsSection`. The value is
//  pinned to the trailing edge: compact controls (buttons, pickers, the version
//  string) sit flush right, while greedy controls (text fields) fill out to the
//  right edge. Text content is right-aligned too, so a text field's value reads on
//  the right rather than tucked at the field's leading edge. This mirrors how
//  System Settings aligns row values — and is needed because outside a Form,
//  `LabeledContent` packs label and value together rather than spreading them.
//

import SwiftUI

struct SettingsRow<Content: View>: View {
    private let label: LocalizedStringKey
    private let content: Content

    init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
            content
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    VStack {
        SettingsSection("General") {
            SettingsRow("Name") {
                TextField("Name", text: .constant("FileFlow")).labelsHidden()
            }
            SettingsRow("Icon") {
                Image(systemName: "square.grid.2x2").foregroundStyle(.tint)
            }
            SettingsRow("Version") {
                Text("2.0 (11)").foregroundStyle(.secondary)
            }
        }
    }
    .padding(20)
    .frame(width: 460)
}
