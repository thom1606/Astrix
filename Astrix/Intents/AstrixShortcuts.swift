//
//  AstrixShortcuts.swift
//  Astrix
//
//  Publishes Astrix's intents as ready-made App Shortcuts so they appear in Siri,
//  Spotlight, and the Shortcuts app with zero user setup. Every phrase must include
//  the `\(.applicationName)` token; the parameterized phrases ("Launch Acme in
//  Astrix") run hands-free, while the bare phrase prompts for which workspace.
//

import AppIntents

struct AstrixShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LaunchWorkspaceIntent(),
            phrases: [
                "Launch \(\.$workspace) in \(.applicationName)",
                "Open \(\.$workspace) in \(.applicationName)",
                "Start \(\.$workspace) with \(.applicationName)",
                "Launch a workspace in \(.applicationName)"
            ],
            shortTitle: "Launch Workspace",
            systemImageName: "square.grid.2x2"
        )
    }
}
