//
//  WorkspaceLogs.swift
//  Astrix
//
//  Where tracked-process output is written. Each run of a service/task gets its own
//  log file under Application Support, so the menu bar's "Open Logs" can reveal them
//  and a restart never clobbers the previous run. Main app only — the sandboxed
//  targets neither spawn processes nor write here.
//

import Foundation

enum WorkspaceLogs {
    /// `~/Library/Application Support/Astrix/Logs`.
    nonisolated static var rootDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Astrix/Logs", isDirectory: true)
    }

    /// The per-workspace log folder (revealed by "Open Logs").
    static func directory(workspace: UUID) -> URL {
        rootDirectory.appendingPathComponent(workspace.uuidString, isDirectory: true)
    }

    /// A fresh log file URL for one run of an action, named so it's recognisable in
    /// Finder (`rails-server-1718700000.log`).
    static func newLogURL(workspace: UUID, label: String) -> URL {
        let stamp = Int(Date().timeIntervalSince1970)
        let name = "\(slug(label))-\(stamp).log"
        return directory(workspace: workspace).appendingPathComponent(name)
    }

    /// Delete log files last modified more than `days` days ago, so the Logs directory
    /// doesn't grow without bound. Best-effort and silent. A currently-running service's
    /// log keeps a recent modification time, so it's never pruned. `nonisolated` so it can
    /// run off the main thread.
    nonisolated static func pruneOldLogs(olderThanDays days: Int = 3) {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let url as URL in enumerator where url.pathExtension == "log" {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate,
                  modified < cutoff
            else { continue }
            try? fileManager.removeItem(at: url)
        }
    }

    /// Lowercase, dash-separated, filesystem-safe version of a label.
    private static func slug(_ label: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let lowered = label.lowercased()
        var result = ""
        var lastWasDash = false
        for scalar in lowered.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash {
                result.append("-")
                lastWasDash = true
            }
        }
        let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "process" : String(trimmed.prefix(40))
    }
}
