//
//  WorkspacesMenu.swift
//  Astrix
//
//  The workspace entries in the menu bar. Every workspace is a submenu: its launch
//  configurations at the top (a start button, or a nested menu of running services once
//  started), then the folder actions (open in editor / terminal / Finder, copy path),
//  and always Open Logs at the bottom. Reads the live `ProcessManager`, so the menu
//  reflects what's actually running each time it opens.
//

import SwiftUI
import AppKit

struct WorkspacesMenu: View {
    let workspaces: [Workspace]

    /// Held in `@State` so reads are observed — the rows reflect current running state.
    @State private var processes = ProcessManager.shared

    var body: some View {
        ForEach(workspaces) { workspace in
            Menu {
                ForEach(workspace.launches) { launch in
                    if processes.hasServices(launch.id) {
                        runningMenu(launch, in: workspace)
                    } else {
                        Button {
                            WorkspaceRunner.launch(launch, in: workspace)
                        } label: {
                            Label(launch.displayName, systemImage: "play.fill")
                        }
                    }
                }

                if workspace.folderURL != nil {
                    Divider()
                    folderActions(workspace)
                }

                Divider()

                Button {
                    openLogs(workspace)
                } label: {
                    Label("Open Logs", systemImage: "doc.plaintext")
                }
            } label: {
                Label(title(workspace), systemImage: workspace.icon)
            }
        }
    }

    /// A started launch: a submenu with per-process Stop, a Start entry for each service
    /// the user stopped, plus Stop All and Restart.
    @ViewBuilder
    private func runningMenu(_ launch: Launch, in workspace: Workspace) -> some View {
        let services = processes.services(for: launch.id)
        let stoppedServices = processes.stoppedServices(for: launch.id)
        Menu {
            ForEach(services) { service in
                Button {
                    processes.stop(service.id, in: launch.id)
                } label: {
                    Label("Stop \(menuLabel(service.label))", systemImage: "stop.circle")
                }
            }
            ForEach(stoppedServices) { service in
                Button {
                    WorkspaceRunner.launchAction(service.id, in: launch, workspace: workspace)
                } label: {
                    Label("Start \(menuLabel(service.label))", systemImage: "play.circle")
                }
            }

            Divider()

            Button {
                let hadRunning = !services.isEmpty
                processes.stopAll(in: launch.id)
                if hadRunning {
                    NotificationManager.notify(
                        title: "\(launch.displayName) stopped",
                        body: "All processes have been ended."
                    )
                }
            } label: {
                Label("Stop All", systemImage: "stop.fill")
            }
            Button {
                WorkspaceRunner.restart(launch, in: workspace)
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
        } label: {
            Label(launchTitle(launch, runningCount: services.count), systemImage: "play.fill")
        }
    }

    /// What you can do with the workspace's folder — the same set the Finder extension
    /// offers, resolved against the user's default editor/terminal.
    @ViewBuilder
    private func folderActions(_ workspace: Workspace) -> some View {
        let path = workspace.folderURL?.path ?? ""

        if SharedSettings.defaultEditor != .none {
            Button {
                WorkspaceLauncher.open(path: path, in: SharedSettings.defaultEditor)
            } label: {
                Label("Open in Editor", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
        if SharedSettings.defaultTerminal != .none {
            Button {
                WorkspaceLauncher.open(path: path, in: SharedSettings.defaultTerminal)
            } label: {
                Label("Open in Terminal", systemImage: "terminal")
            }
        }
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        } label: {
            Label("Reveal in Finder", systemImage: "folder")
        }
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(path, forType: .string)
        } label: {
            Label("Copy Path", systemImage: "doc.on.doc")
        }
    }

    // MARK: - Helpers

    /// Workspace title: append the live process count across all its launches while
    /// anything is running.
    private func title(_ workspace: Workspace) -> String {
        let running = workspace.launches.reduce(0) { $0 + processes.runningCount($1.id) }
        return running > 0 ? "\(workspace.displayName) (\(running) running)" : workspace.displayName
    }

    /// Launch submenu title: append its own live count, otherwise just the name (its
    /// stopped services are listed inside as Start entries).
    private func launchTitle(_ launch: Launch, runningCount: Int) -> String {
        runningCount > 0 ? "\(launch.displayName) (\(runningCount) running)" : launch.displayName
    }

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
