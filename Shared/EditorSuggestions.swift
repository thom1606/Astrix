//
//  EditorSuggestions.swift
//  Astrix
//
//  Automatic, content-based editor suggestions for a folder. When the user enables
//  "Automatically suggest editors", the Finder extension inspects a folder for
//  well-known project markers (e.g. a `.xcodeproj`, or a `.vscode`/`.cursor`
//  folder) and surfaces the editors that fit, without the user configuring a rule.
//

import Foundation

/// A rule that suggests editors when a folder contains a recognisable project marker.
struct EditorSuggestionRule: Hashable {
    /// What to look for among a folder's direct children.
    enum Marker: Hashable {
        /// A child entry with this exact name, e.g. ".vscode" or ".cursor".
        case named(String)
        /// Any child whose path extension matches, e.g. "xcodeproj".
        case fileExtension(String)
    }

    let marker: Marker
    /// Editors to suggest when the marker is present, in priority order.
    let editors: [SupportedApps]
}

enum EditorSuggestions {
    /// Built-in rules mapping common project markers to the editors that fit them.
    /// Order matters: earlier rules' editors are suggested first.
    static let rules: [EditorSuggestionRule] = [
        EditorSuggestionRule(marker: .fileExtension("xcodeproj"), editors: [.xcode]),
        EditorSuggestionRule(marker: .fileExtension("xcworkspace"), editors: [.xcode]),
        EditorSuggestionRule(marker: .named(".vscode"), editors: [.vsCode, .vsCodeInsiders, .cursor]),
        EditorSuggestionRule(marker: .named(".cursor"), editors: [.cursor]),
        EditorSuggestionRule(marker: .named(".zed"), editors: [.zed, .zedPreview]),
        EditorSuggestionRule(marker: .named(".idea"), editors: [.intelliJ, .phpStorm, .pyCharm, .rubyMine, .webStorm, .androidStudio])
    ]

    /// Editors automatically suggested for a folder, given the names of its direct
    /// children. Taking the listing as input keeps this testable and lets the
    /// caller decide how to read the directory (the sandboxed Finder extension may
    /// need an unsandboxed listing).
    ///
    /// Results are de-duplicated and keep rule/priority order. When `installedOnly`
    /// is true (the default — what the Finder menu wants) editors that aren't
    /// installed are dropped.
    static func suggestedEditors(entries: [String], installedOnly: Bool = true) -> [SupportedApps] {
        guard !entries.isEmpty else { return [] }

        var result: [SupportedApps] = []
        for rule in rules where matches(rule.marker, in: entries) {
            for editor in rule.editors where !result.contains(editor) {
                if installedOnly && !editor.isInstalled { continue }
                result.append(editor)
            }
        }
        return result
    }

    /// Convenience that reads the folder's contents via `FileManager` (suitable for
    /// non-sandboxed callers such as the Settings app).
    static func suggestedEditors(for folderURL: URL, installedOnly: Bool = true) -> [SupportedApps] {
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)) ?? []
        return suggestedEditors(entries: entries, installedOnly: installedOnly)
    }

    private static func matches(_ marker: EditorSuggestionRule.Marker, in contents: [String]) -> Bool {
        switch marker {
        case .named(let name):
            return contents.contains(name)
        case .fileExtension(let ext):
            return contents.contains { ($0 as NSString).pathExtension == ext }
        }
    }
}
