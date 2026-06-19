//
//  IconPicker.swift
//  AstrixSettings
//
//  The SF Symbol grid shown in a popover when picking a workspace's menu bar icon.
//

import SwiftUI

struct IconPicker: View {
    @Binding var selection: String
    /// Called after a symbol is chosen (lets the host dismiss the popover).
    var onPick: () -> Void = {}

    private let columns = Array(repeating: GridItem(.fixed(40), spacing: 6), count: 6)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Workspace.iconChoices, id: \.self) { symbol in
                    Button {
                        selection = symbol
                        onPick()
                    } label: {
                        Image(systemName: symbol)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(selection == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .frame(width: 300, height: 320)
    }
}
