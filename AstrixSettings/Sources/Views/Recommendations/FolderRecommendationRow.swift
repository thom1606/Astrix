//
//  FolderRecommendationRow.swift
//  AstrixSettings
//
//  A single editable folder recommendation row in the General tab.
//

import SwiftUI

/// A single editable folder recommendation: the folder, the editors recommended
/// for it, and a control to remove the rule.
struct FolderRecommendationRow: View {
    let recommendation: FolderRecommendation
    @ObservedObject var store: FolderRecommendationsStore

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.folderName)
                    .fontWeight(.medium)
                Text(recommendation.folderPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Menu {
                ForEach(SupportedApps.editors) { editor in
                    Button {
                        store.toggleEditor(editor, for: recommendation)
                    } label: {
                        if recommendation.editors.contains(editor.rawValue) {
                            Label(editor.displayName, systemImage: "checkmark")
                        } else {
                            Text(editor.displayName)
                        }
                    }
                }
            } label: {
                Text(editorsSummary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Button(role: .destructive) {
                store.remove(recommendation)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    private var editorsSummary: String {
        let resolved = recommendation.resolvedEditors
        switch resolved.count {
        case 0: return "Choose editors"
        case 1: return resolved[0].displayName
        default: return "\(resolved.count) editors"
        }
    }
}
