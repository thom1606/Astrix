//
//  FolderRecommendation.swift
//  Astrix
//
//  A user-defined rule that recommends specific editors for a specific folder.
//

import Foundation

/// Recommends one or more editors for a specific folder.
///
/// The Finder extension reads these from the shared defaults and, when the user
/// interacts with a matching folder, surfaces the recommended editors as quick
/// "Open in …" actions. `Codable` so the whole list can be JSON-encoded into the
/// shared App Group and read back by any target.
struct FolderRecommendation: Codable, Identifiable, Hashable {
    var id: UUID
    /// Absolute path of the folder this rule applies to.
    var folderPath: String
    /// Bundle identifiers (`SupportedApps.rawValue`) of the recommended editors.
    var editors: [String]

    init(id: UUID = UUID(), folderPath: String, editors: [String] = []) {
        self.id = id
        self.folderPath = folderPath
        self.editors = editors
    }

    /// The folder's display name (its last path component).
    var folderName: String {
        URL(fileURLWithPath: folderPath).lastPathComponent
    }

    /// The recommended editors resolved back to `SupportedApps`, dropping any that
    /// are no longer recognised.
    var resolvedEditors: [SupportedApps] {
        editors.compactMap(SupportedApps.init(rawValue:))
    }
}
