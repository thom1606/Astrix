//
//  RecommendationsSettingsView.swift
//  AstrixSettings
//
//  The "Recommendations" tab: control how Astrix suggests editors for your
//  folders. Toggle automatic project detection and pin specific editors to
//  folders you choose, which then show up in the Finder menu.
//

import SwiftUI
import AppKit

struct RecommendationsSettingsView: View {
    @AppStorage(Constants.DefaultsKey.autoSuggestEditors, store: .astrixShared)
    private var autoSuggestEditors: Bool = true

    @StateObject private var recommendations = FolderRecommendationsStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                folderRecommendationsSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sections

    private var folderRecommendationsSection: some View {
        SettingsSection(
            "Folder Recommendations",
            footer: "Recommend specific editors for folders you choose. When automatic suggestions are on, Astrix also detects project markers, like .xcodeproj files or .vscode folders, and suggests the matching editor in the Finder menu."
        ) {
            SettingsToggleRow("Automatically suggest editors", isOn: $autoSuggestEditors)

            ForEach(recommendations.recommendations) { recommendation in
                FolderRecommendationRow(recommendation: recommendation, store: recommendations)
            }

            if recommendations.recommendations.isEmpty {
                Text("No folder recommendations yet.")
                    .foregroundStyle(.secondary)
            }

            Button(action: addFolder) {
                Label("Add Folder…", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
    }

    // MARK: - Helpers

    /// Prompt the user for a folder and add a recommendation rule for it.
    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Choose a folder to recommend editors for."
        if panel.runModal() == .OK, let url = panel.url {
            recommendations.add(folderPath: url.path)
        }
    }
}

#Preview {
    RecommendationsSettingsView()
        .frame(width: 680, height: 600)
}
