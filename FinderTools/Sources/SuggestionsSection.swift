//
//  SuggestionsSection.swift
//  FinderTools
//
//  Editor suggestions for the current folder, driven entirely by the user's
//  settings: automatic content-based suggestions (when enabled) plus any
//  per-folder recommendations the user configured in the Settings app.
//

import FinderSync

class SuggestionsSection: AstrixSection {
    var sectionName: String { "Suggestions" }

    func getSectionItems() -> [NSMenuItem] {
        guard let folder = Utilities.contextFolderURL else { return [] }

        var editors: [SupportedApps] = []

        // 1. Automatic, content-based suggestions (e.g. .xcodeproj → Xcode), gated
        //    by the "Automatically suggest editors" setting.
        if SharedSettings.autoSuggestEditors {
            let entries = Utilities.directoryEntries(of: folder)
            let auto = EditorSuggestions.suggestedEditors(entries: entries)
            NSLog("[Astrix] Suggestions: folder=%@ entries=%d auto=%@", folder.path, entries.count, auto.map(\.rawValue).description)
            editors.append(contentsOf: auto)
        } else {
            NSLog("[Astrix] Suggestions: auto-suggest disabled")
        }

        // 2. The user's per-folder recommendations matching this folder.
        for recommendation in SharedSettings.folderRecommendations where matches(recommendation, folder: folder) {
            for editor in recommendation.resolvedEditors where editor.isInstalled && !editors.contains(editor) {
                editors.append(editor)
            }
        }

        return editors.map { editor in
            let item = NSMenuItem(title: "Open in \(editor.displayName)", action: #selector(FinderSync.openSuggestion(_:)), keyEquivalent: "")
            // Carry the editor on `tag`, not `representedObject`. Finder serializes
            // the menu into its own process to display it, and only primitive
            // properties (title, tag) survive that boundary — `representedObject`
            // comes back nil at click time. `tag` is the editor's index in
            // `SupportedApps.allCases`.
            item.tag = SupportedApps.allCases.firstIndex(of: editor) ?? 0
            return item
        }
    }

    /// A recommendation applies to its folder and everything beneath it.
    private func matches(_ recommendation: FolderRecommendation, folder: URL) -> Bool {
        let target = folder.standardizedFileURL.path
        let base = URL(fileURLWithPath: recommendation.folderPath).standardizedFileURL.path
        return target == base || target.hasPrefix(base + "/")
    }
}
