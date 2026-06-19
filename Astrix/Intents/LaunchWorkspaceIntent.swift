//
//  LaunchWorkspaceIntent.swift
//  Astrix
//
//  The App Intent behind "Hey Siri, launch <workspace> in Astrix" — and the same
//  action in the Shortcuts app and Spotlight. Runs every launch action in the chosen
//  workspace (opens editors/terminals/browser tabs, starts tracked services) with no
//  interaction required.
//

import AppIntents

struct LaunchWorkspaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch Workspace"
    static var description = IntentDescription(
        "Run all of a workspace's launch actions: open its editor, terminal, and browser tabs, and start its services."
    )

    // Astrix is an always-running menu bar agent, so there's no window to bring
    // forward — the actions run in the background and we don't steal focus.
    static var openAppWhenRun = false

    @Parameter(title: "Workspace", description: "The workspace to launch.")
    var workspace: WorkspaceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Launch \(\.$workspace)")
    }

    // Isolated to the main actor: launching touches `WorkspaceRunner` /
    // `ProcessManager`, which are `@MainActor`. (The intent's `perform()` is
    // otherwise caller-isolated under the project's concurrency settings.)
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let launched = try WorkspaceControl.launch(id: workspace.id)
            return .result(dialog: "Launching \(launched.displayName).")
        } catch {
            throw LaunchWorkspaceError.unavailable(workspace.name)
        }
    }
}

/// Surfaces a readable reason to Siri/Shortcuts when a workspace can't be launched
/// (most likely it was deleted after the Shortcut was created).
enum LaunchWorkspaceError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case unavailable(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unavailable(let name):
            return "Astrix couldn't find a workspace named \(name)."
        }
    }
}
