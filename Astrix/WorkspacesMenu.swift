//
//  WorkspacesMenu.swift
//  Astrix
//
//  The workspace entries in the menu bar. A workspace that isn't running is a single
//  launch button; once it has tracked processes it becomes a submenu listing each
//  running process with Stop / Stop All / Restart / Open Logs. Reads the live
//  `ProcessManager`, so the menu reflects what's actually running each time it opens.
//

import SwiftUI
import AppKit

struct WorkspacesMenu: View {
    let workspaces: [Workspace]

    /// Held in `@State` so reads are observed — the rows reflect current running state.
    @State private var processes = ProcessManager.shared

    var body: some View {
        ForEach(workspaces) { workspace in
            if processes.isRunning(workspace.id) {
                runningMenu(workspace)
            } else {
                Button {
                    WorkspaceRunner.launch(workspace)
                } label: {
                    Label(workspace.displayName, systemImage: workspace.icon)
                }
            }
        }
    }

    /// A running workspace: a submenu with per-process Stop, Stop All, Restart, and
    /// Open Logs.
    @ViewBuilder
    private func runningMenu(_ workspace: Workspace) -> some View {
        let services = processes.services(for: workspace.id)
        Menu {
            ForEach(services) { service in
                Button {
                    processes.stop(service.id, in: workspace.id)
                } label: {
                    Label("Stop \(menuLabel(service.label))", systemImage: "stop.circle")
                }
            }

            Divider()

            Button {
                processes.stopAll(in: workspace.id)
                NotificationManager.notify(
                    title: "\(workspace.displayName) stopped",
                    body: "All processes have been ended."
                )
            } label: {
                Label("Stop All", systemImage: "stop.fill")
            }
            Button {
                WorkspaceRunner.restart(workspace)
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }

            Divider()

            Button {
                openLogs(workspace)
            } label: {
                Label("Open Logs", systemImage: "doc.plaintext")
            }
        } label: {
            Label("\(workspace.displayName) (\(services.count) running)", systemImage: workspace.icon)
        }
    }

    // MARK: - Helpers

    /// Collapse a possibly multi-line command into a short single-line menu title.
    private func menuLabel(_ label: String) -> String {
        let firstLine = label.split(whereSeparator: \.isNewline).first.map(String.init) ?? label
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 50 ? String(trimmed.prefix(50)) + "…" : trimmed
    }

    /// Reveal the workspace's log folder in Finder.
    private func openLogs(_ workspace: Workspace) {
        let directory = WorkspaceLogs.directory(workspace: workspace.id)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = NSWorkspace.shared.open(directory)
    }
}
