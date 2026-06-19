//
//  FolderRecommendationsStore.swift
//  Astrix
//
//  Persists the user's per-folder editor recommendations in the shared App Group.
//

import Foundation
import Combine

/// Single source of truth for the per-folder editor recommendations.
///
/// The list is stored as JSON in the shared App Group (`UserDefaults.astrixShared`),
/// so the Finder extension can read exactly what the Settings app wrote. SwiftUI
/// views observe this object; mutations persist automatically.
final class FolderRecommendationsStore: ObservableObject {
    @Published var recommendations: [FolderRecommendation] {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let key = Constants.DefaultsKey.folderRecommendations

    init(defaults: UserDefaults = .astrixShared) {
        self.defaults = defaults
        self.recommendations = SharedSettings.folderRecommendations
    }

    /// Add a rule for a folder. No-op if a rule already exists for that path.
    func add(folderPath: String) {
        guard !recommendations.contains(where: { $0.folderPath == folderPath }) else { return }
        recommendations.append(FolderRecommendation(folderPath: folderPath))
    }

    /// Remove a rule.
    func remove(_ recommendation: FolderRecommendation) {
        recommendations.removeAll { $0.id == recommendation.id }
    }

    /// Toggle whether an editor is recommended for a given folder rule.
    func toggleEditor(_ editor: SupportedApps, for recommendation: FolderRecommendation) {
        guard let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) else { return }
        if let editorIndex = recommendations[index].editors.firstIndex(of: editor.rawValue) {
            recommendations[index].editors.remove(at: editorIndex)
        } else {
            recommendations[index].editors.append(editor.rawValue)
        }
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(recommendations) else { return }
        defaults.set(data, forKey: key)
    }
}
