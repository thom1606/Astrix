//
//  WorkspaceRunner.swift
//  Astrix
//
//  Runs one launch configuration's actions in order: per-action delays, port-readiness
//  gates, long-running tracked services (idempotent), and "wait for exit" tasks. The
//  opens (editor/terminal/browser) still go through `WorkspaceLauncher`. The owning
//  workspace comes along for its folder (the fallback path for actions that don't set
//  one) and its log directory. Main app only.
//

import AppKit

@MainActor
enum WorkspaceRunner {
    /// Start a launch configuration. Returns immediately; the sequence runs in a
    /// detached task so the menu stays responsive and services don't block it.
    static func launch(_ launch: Launch, in workspace: Workspace) {
        // Housekeeping: prune stale logs off the main thread so it never delays launch.
        Task.detached(priority: .utility) { WorkspaceLogs.pruneOldLogs() }
        Task { await run(launch, in: workspace) }
    }

    /// Restart a launch's commands without re-opening its editors, terminals, or
    /// browser tabs — the windows you already have stay where they are. Tracked services
    /// are stopped and awaited first so the re-run starts clean, and the surrounding
    /// waits and port-kills still run, so commands come back up with the same readiness
    /// gating and port freeing as a full start.
    static func restart(_ launch: Launch, in workspace: Workspace) {
        Task {
            await ProcessManager.shared.stopAllAndWait(in: launch.id)
            await run(launch, in: workspace, skippingOpens: true)
        }
    }

    /// Start a single action again — used to restart a service the user stopped without
    /// touching the rest of the launch. `runCommand`'s idempotency guard still prevents
    /// double-starting one that's somehow already live.
    static func launchAction(_ actionID: UUID, in launch: Launch, workspace: Workspace) {
        guard let action = launch.actions.first(where: { $0.id == actionID }) else { return }
        Task { await runCommand(action, launch: launch, workspace: workspace) }
    }

    private static func run(_ launch: Launch, in workspace: Workspace, skippingOpens: Bool = false) async {
        for action in launch.actions where action.enabled {
            switch action.type {
            case .openInDefaultEditor, .openInEditor,
                 .openInDefaultTerminal, .openInTerminal, .openInBrowser:
                if !skippingOpens { WorkspaceLauncher.performOpen(action, folder: workspace.folder) }
            case .runCommand:
                await runCommand(action, launch: launch, workspace: workspace)
            case .waitSeconds:
                if action.seconds > 0 {
                    try? await Task.sleep(for: .seconds(action.seconds))
                }
            case .waitForPort:
                await waitForPort(action, workspace: workspace)
            case .killPort:
                if action.port > 0 { PortUtilities.killProcesses(onPort: action.port) }
            }
        }
    }

    /// Block until `action.port` accepts connections (e.g. wait for the database before
    /// starting the app server). Returns as soon as the port opens; otherwise gives up
    /// after the action's timeout (`seconds`, default 10s) and continues.
    private static func waitForPort(_ action: WorkspaceAction, workspace: Workspace) async {
        guard action.port > 0 else { return }
        let timeout: TimeInterval = action.seconds > 0 ? TimeInterval(action.seconds) : 10
        let ready = await PortUtilities.waitUntilOpen(action.port, timeout: timeout)
        if !ready {
            NotificationManager.notify(
                title: workspace.displayName,
                body: "Port \(action.port) wasn't ready within \(Int(timeout))s; continuing anyway."
            )
        }
    }

    private static func runCommand(_ action: WorkspaceAction, launch: Launch, workspace: Workspace) async {
        let command = action.command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        // Idempotent: a service that's already running is left alone, so re-launching
        // can't double-start `bin/dev` and collide on the port.
        if action.isTrackedService,
           ProcessManager.shared.isActionRunning(action.id, in: launch.id) {
            return
        }

        let process = ManagedProcess(
            actionID: action.id,
            label: action.resolvedLabel,
            workspaceName: "\(workspace.displayName) · \(launch.displayName)",
            command: command,
            workingDirectory: action.resolvedPath(folder: workspace.folder),
            logURL: WorkspaceLogs.newLogURL(workspace: workspace.id, label: action.resolvedLabel)
        )

        do {
            try process.start()
        } catch {
            NotificationManager.notify(
                title: workspace.displayName,
                body: "Couldn't start \(action.resolvedLabel): \(error.localizedDescription)",
                logURL: process.logURL
            )
            return
        }

        if action.isTrackedService {
            // Keeps running — track it (shows in the submenu, stoppable) and move on.
            ProcessManager.shared.register(process, launch: launch.id)
        } else {
            // Wait for exit — block the sequence until it finishes before the next action.
            await process.waitUntilExit()
        }
    }
}
