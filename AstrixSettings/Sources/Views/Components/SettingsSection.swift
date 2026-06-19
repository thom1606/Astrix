//
//  SettingsSection.swift
//  AstrixSettings
//
//  A grouped "card" of rows styled to match macOS System Settings: an elevated,
//  rounded surface sitting on the window background, with an optional caption
//  header above and footer below. Each row passed as content is given uniform
//  padding and separated from the next by a hairline divider automatically — so
//  call sites just list their rows (Toggles, LabeledContent, Buttons, ForEach…)
//  the way they would inside a Form's Section.
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    private let header: LocalizedStringKey?
    private let footer: LocalizedStringKey?
    private let content: Content

    init(
        _ header: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let header {
                Text(header)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
            }

            // `_VariadicView` lets us treat each top-level child (and the elements of
            // any ForEach) as an individual row, so we can pad them uniformly and
            // weave dividers between them — exactly how List/Form build grouped rows.
            _VariadicView.Tree(SettingsSectionRows()) {
                content
            }
            .frame(maxWidth: .infinity)
            .background(Color.settingsCard)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
            }
        }
    }
}

/// Stacks the section's rows, padding each one and inserting a leading-inset
/// divider between consecutive rows (never after the last).
private struct SettingsSectionRows: _VariadicView_UnaryViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let lastID = children.last?.id
        VStack(spacing: 0) {
            ForEach(children) { child in
                child
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)

                if child.id != lastID {
                    Divider()
                        .padding(.leading, 14)
                }
            }
        }
        // Switches, not checkboxes, to match the rest of the design.
        .toggleStyle(.switch)
    }
}

extension Color {
    /// The elevated surface a `SettingsSection` card draws on. White in light mode,
    /// a touch lighter than the window background in dark mode so the card still
    /// reads as raised. (No public system color gives this in both appearances.)
    static let settingsCard = Color("SettingsCardBackground")
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 22) {
            SettingsSection {
                SettingsToggleRow("Show in Menu Bar", isOn: .constant(true))
            }
            SettingsSection("Default Applications", footer: "Choose which editor Astrix opens your folders in.") {
                SettingsRow("Default Editor") { Text("VS Code").foregroundStyle(.secondary) }
                SettingsRow("Default Terminal") { Text("iTerm").foregroundStyle(.secondary) }
                Button("Check for Updates…") {}
            }
        }
        .padding(20)
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .frame(width: 480, height: 400)
}
