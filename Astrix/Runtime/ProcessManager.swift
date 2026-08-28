//
//  ProcessManager.swift
//  Astrix
//
//  The live registry of tracked workspace processes, keyed by launch configuration.
//  Held in the main app's memory (PIDs are runtime-only and only this process owns
//  them) and observed directly by the menu bar for live running-state. Main app only.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProcessManager {
    static let shared = ProcessManager()

    /// Launch id → its running tracked processes, in start order.
    private(set) var running: [UUID: [ManagedProcess]] = [:]

    /// Launch id → services the user stopped this session, in stop order. Kept so the
    /// menu can offer to start them again instead of having them vanish; cleared once the
    /// action runs again (see `register`). Runtime-only, like `running`.
    private(set) var stopped: [UUID: [StoppedService]] = [:]

    /// A tracked service the user stopped — just enough to re-run its action and label it.
    struct StoppedService: Identifiable {
        /// The originating action's id (unique per launch), so restart maps back to it.
        let id: UUID
        let label: String
    }

    /// Process ids being stopped as part of a "Stop All" teardown, so their exit is a
    /// full removal rather than a restartable entry (see `handleExit`).
    @ObservationIgnored private var tearingDown: Set<UUID> = []

    private init() {}

    // MARK: - Queries

    func services(for launchID: UUID) -> [ManagedProcess] { running[launchID] ?? [] }

    /// Services the user stopped in this launch, offered as restartable entries.
    func stoppedServices(for launchID: UUID) -> [StoppedService] { stopped[launchID] ?? [] }

    /// Whether the launch has anything to show: live processes or user-stopped services
    /// waiting to be started again.
    func hasServices(_ launchID: UUID) -> Bool {
        isRunning(launchID) || !(stopped[launchID]?.isEmpty ?? true)
    }

    func isRunning(_ launchID: UUID) -> Bool { !(running[launchID]?.isEmpty ?? true) }

    func runningCount(_ launchID: UUID) -> Int { running[launchID]?.count ?? 0 }

    /// Whether anything at all is running (drives the menu-bar icon badge).
    var hasAnyRunning: Bool { running.values.contains { !$0.isEmpty } }

    /// Whether a specific action already has a live process — the runner uses this to
    /// skip re-starting a service that's already up (so re-launching can't double-bind
    /// a port).
    func isActionRunning(_ actionID: UUID, in launchID: UUID) -> Bool {
        (running[launchID] ?? []).contains { $0.actionID == actionID }
    }

    // MARK: - Registration

    /// Track a started process and remove it automatically when it exits.
    func register(_ process: ManagedProcess, launch launchID: UUID) {
        // Starting (or restarting) this action clears any "stopped" entry it left behind.
        clearStopped(actionID: process.actionID, in: launchID)
        process.onExit = { [weak self] userInitiated, status in
            self?.handleExit(process, launch: launchID, userInitiated: userInitiated, status: status)
        }
        running[launchID, default: []].append(process)
    }

    // MARK: - Stopping

    func stop(_ processID: UUID, in launchID: UUID) {
        running[launchID]?.first { $0.id == processID }?.stop()
    }

    /// Full teardown for the user's "Stop All": stop every live service and forget the
    /// restartable entries too, so the launch collapses back to a single start button.
    /// Torn-down exits are silent — no "Start …" entry and no crash notification (see
    /// `handleExit`).
    func stopAll(in launchID: UUID) {
        stopped[launchID] = nil
        let services = running[launchID] ?? []
        for service in services { tearingDown.insert(service.id) }
        services.forEach { $0.stop() }
    }

    /// Stop every tracked process in a launch and suspend until they've all actually
    /// exited. Restart uses this so the re-run starts from a clean slate: the runner's
    /// idempotency guard won't skip a service that's merely *stopping*, and the freed
    /// port is truly free before the command rebinds it.
    func stopAllAndWait(in launchID: UUID) async {
        let services = running[launchID] ?? []
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
        launch launchID: UUID,
        userInitiated: Bool,
        status: ManagedProcess.Status
    ) {
        running[launchID]?.removeAll { $0.id == process.id }
        if running[launchID]?.isEmpty == true { running[launchID] = nil }

        // A "Stop All" teardown removes the service outright — no restartable entry and no
        // crash notice — so the launch can collapse back to its start button.
        if tearingDown.remove(process.id) != nil { return }

        // Otherwise keep the service listed as a restartable entry rather than dropping it,
        // whether the user stopped it or it exited on its own — the menu turns it into a
        // "Start …" button. An unexpected exit additionally raises a crash notification.
        recordStopped(process, in: launchID)

        guard !userInitiated else { return }
        var detail = ""
        if case .exited(let code) = status, code != 0 { detail = " (exit \(code))" }
        NotificationManager.notify(
            title: "\(process.label) stopped",
            body: "A process in \(process.workspaceName) stopped unexpectedly\(detail).",
            logURL: process.logURL
        )
    }

    // MARK: - Stopped registry

    /// Remember a user-stopped service so the menu can offer to start it again. Replaces
    /// any prior entry for the same action, keeping it at the end in most-recent order.
    private func recordStopped(_ process: ManagedProcess, in launchID: UUID) {
        var list = stopped[launchID] ?? []
        list.removeAll { $0.id == process.actionID }
        list.append(StoppedService(id: process.actionID, label: process.label))
        stopped[launchID] = list
    }

    /// Drop the stopped entry for an action once it's running again.
    private func clearStopped(actionID: UUID, in launchID: UUID) {
        guard stopped[launchID] != nil else { return }
        stopped[launchID]?.removeAll { $0.id == actionID }
        if stopped[launchID]?.isEmpty == true { stopped[launchID] = nil }
    }
}
