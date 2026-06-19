//
//  SettingsToggleRow.swift
//  AstrixSettings
//
//  A toggle row for use inside a `SettingsSection`: a title (with an optional
//  secondary subtitle) on the leading edge and a switch pinned to the trailing
//  edge — the layout System Settings uses. Spreading is explicit (HStack +
//  Spacer) so it behaves the same outside a Form, where a bare Toggle wouldn't
//  push its switch to the trailing edge.
//

import SwiftUI

struct SettingsToggleRow: View {
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey?
    @Binding private var isOn: Bool

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

#Preview {
    VStack {
        SettingsSection {
            SettingsToggleRow("Show in Menu Bar", isOn: .constant(true))
            SettingsToggleRow(
                "Automatically suggest editors",
                subtitle: "Detects project markers like .xcodeproj files.",
                isOn: .constant(false)
            )
        }
    }
    .padding(20)
    .frame(width: 460)
}
