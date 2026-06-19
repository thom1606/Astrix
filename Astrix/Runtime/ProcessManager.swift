//
//  ProcessManager.swift
//  Astrix
//
//  The live registry of tracked workspace processes, keyed by workspace. Held in the
//  main app's memory (PIDs are runtime-only and only this process owns them) and
//  observed directly by the menu bar for live running-state. Main app only.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProcessManager {
    static let shared = ProcessManager()

    /// Workspace id → its running tracked processes, in start order.
    private(set) var running: [UUID: [ManagedProcess]] = [:]

    private init() {}

    // MARK: - Queries

    func services(for workspaceID: UUID) -> [ManagedProcess] { running[workspaceID] ?? [] }

    func isRunning(_ workspaceID: UUID) -> Bool { !(running[workspaceID]?.isEmpty ?? true) }

    func runningCount(_ workspaceID: UUID) -> Int { running[workspaceID]?.count ?? 0 }

    /// Whether any workspace has tracked processes (drives the menu-bar icon badge).
    var hasAnyRunning: Bool { running.values.contains { !$0.isEmpty } }

    /// Whether a specific action already has a live process — the runner uses this to
    /// skip re-starting a service that's already up (so re-launching can't double-bind
    /// a port).
    func isActionRunning(_ actionID: UUID, in workspaceID: UUID) -> Bool {
        (running[workspaceID] ?? []).contains { $0.actionID == actionID }
    }

    // MARK: - Registration

    /// Track a started process and remove it automatically when it exits.
    func register(_ process: ManagedProcess, workspace workspaceID: UUID) {
        process.onExit = { [weak self] userInitiated, status in
            self?.handleExit(process, workspace: workspaceID, userInitiated: userInitiated, status: status)
        }
        running[workspaceID, default: []].append(process)
    }

    // MARK: - Stopping

    func stop(_ processID: UUID, in workspaceID: UUID) {
        running[workspaceID]?.first { $0.id == processID }?.stop()
    }

    func stopAll(in workspaceID: UUID) {
        (running[workspaceID] ?? []).forEach { $0.stop() }
    }

    /// Stop every tracked process in a workspace and suspend until they've all actually
    /// exited. Restart uses this so the re-run starts from a clean slate: the runner's
    /// idempotency guard won't skip a service that's merely *stopping*, and the freed
    /// port is truly free before the command rebinds it.
    func stopAllAndWait(in workspaceID: UUID) async {
        let services = running[workspaceID] ?? []
        services.forEach { $0.stop() }
        for service in services { await service.waitUntilExit() }
    }

    /// SIGTERM every tracked group, briefly wait, then SIGKILL stragglers. Synchronous
    /// so it completes inside `applicationWillTerminate` before the app exits — without
    /// this, every quit would leak the dev-server trees and re-create the port problem.
    func terminateAllForQuit() {
        let all = running.values.flatMap { $0 }
        guard !all.isEmpty else { return }
        for process in all { process.signalGroup(SIGTERM) }
        usleep(400_000)   // ~0.4s grace for clean shutdown
        for process in all { process.signalGroup(SIGKILL) }
    }

    // MARK: - Exit

    private func handleExit(
        _ process: ManagedProcess,
        workspace workspaceID: UUID,
        userInitiated: Bool,
        status: ManagedProcess.Status
    ) {
        running[workspaceID]?.removeAll { $0.id == process.id }
        if running[workspaceID]?.isEmpty == true { running[workspaceID] = nil }

        guard !userInitiated else { return }
        var detail = ""
        if case .exited(let code) = status, code != 0 { detail = " (exit \(code))" }
        NotificationManager.notify(
            title: "\(process.label) stopped",
            body: "A process in \(process.workspaceName) stopped unexpectedly\(detail).",
            logURL: process.logURL
        )
    }
}
