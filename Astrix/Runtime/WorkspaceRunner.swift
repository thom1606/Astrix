//
//  WorkspaceRunner.swift
//  Astrix
//
//  Runs a workspace's actions in order. Replaces the old synchronous fire-and-forget
//  loop with an async sequencer that supports per-action delays, port-readiness gates,
//  long-running tracked services (idempotent), and "wait for exit" tasks. The opens
//  (editor/terminal/browser) still go through `WorkspaceLauncher`. Main app only.
//

import AppKit

@MainActor
enum WorkspaceRunner {
    /// Launch a workspace. Returns immediately; the sequence runs in a detached task so
    /// the menu stays responsive and long-running services don't block it.
    static func launch(_ workspace: Workspace) {
        // Housekeeping: prune stale logs off the main thread so it never delays launch.
        Task.detached(priority: .utility) { WorkspaceLogs.pruneOldLogs() }
        Task { await run(workspace) }
    }

    /// Restart a workspace's commands without re-opening its editors, terminals, or
    /// browser tabs — the windows you already have stay where they are. Tracked services
    /// are stopped and awaited first so the re-run starts clean, and the surrounding
    /// waits and port-kills still run, so commands come back up with the same readiness
    /// gating and port freeing as a full launch.
    static func restart(_ workspace: Workspace) {
        Task {
            await ProcessManager.shared.stopAllAndWait(in: workspace.id)
            await run(workspace, skippingOpens: true)
        }
    }

    private static func run(_ workspace: Workspace, skippingOpens: Bool = false) async {
        for action in workspace.actions where action.enabled {
            switch action.type {
            case .openInDefaultEditor, .openInEditor,
                 .openInDefaultTerminal, .openInTerminal, .openInBrowser:
                if !skippingOpens { WorkspaceLauncher.performOpen(action) }
            case .runCommand:
                await runCommand(action, workspace: workspace)
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

    private static func runCommand(_ action: WorkspaceAction, workspace: Workspace) async {
        let command = action.command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        // Idempotent: a service that's already running is left alone, so re-launching a
        // workspace can't double-start `bin/dev` and collide on the port.
        if action.isTrackedService,
           ProcessManager.shared.isActionRunning(action.id, in: workspace.id) {
            return
        }

        let process = ManagedProcess(
            actionID: action.id,
            label: action.resolvedLabel,
            workspaceName: workspace.displayName,
            command: command,
            workingDirectory: action.path,
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
            ProcessManager.shared.register(process, workspace: workspace.id)
        } else {
            // Wait for exit — block the sequence until it finishes before the next action.
            await process.waitUntilExit()
        }
    }
}
