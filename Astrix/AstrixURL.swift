//
//  AstrixURL.swift
//  Astrix
//
//  Parses and dispatches `astrix://` URLs — Astrix's lowest-common-denominator
//  external entry point. Anything that can open a URL can drive it with zero setup:
//  `open "astrix://launch?name=Acme"`, a Shortcuts "Open URL" action, Raycast/Alfred,
//  a cron job, or Claude Code via a shell command.
//
//  Supported:
//    astrix://launch?id=<uuid>      — launch a workspace by id (stable, survives renames)
//    astrix://launch?name=<name>    — launch a workspace by name (URL-encoded)
//    astrix://open?kind=editor&path=<absolute folder path>
//    astrix://open?kind=terminal&path=<absolute folder path>
//
//  The launch URLs accept an optional `&launch=<name>` to pick one of the
//  workspace's launch configurations; without it the first launch runs.
//

import Foundation

@MainActor
enum AstrixURL {
    static let scheme = "astrix"

    /// Route an incoming URL to the matching action. Unknown schemes/verbs are
    /// ignored rather than erroring — this is a fire-and-forget surface.
    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == scheme else { return }
        // The verb rides in the host (`astrix://launch?…`); also tolerate a leading
        // path component (`astrix:///launch`) so both URL shapes work.
        let verb = (url.host ?? url.pathComponents.first { $0 != "/" })?.lowercased()
        switch verb {
        case "launch":
            handleLaunch(url)
        case "open":
            handleOpen(url)
        default:
            break
        }
    }

    private static func handleOpen(_ url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let kinds = items.filter { $0.name == "kind" }
        let paths = items.filter { $0.name == "path" }
        guard kinds.count == 1, paths.count == 1,
              let kind = kinds.first?.value,
              let path = paths.first?.value,
              (path as NSString).isAbsolutePath else { return }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else { return }

        switch kind {
        case "editor":
            WorkspaceLauncher.open(path: path, in: SharedSettings.defaultEditor)
        case "terminal":
            WorkspaceLauncher.open(path: path, in: SharedSettings.defaultTerminal)
        default:
            break
        }
    }

    private static func handleLaunch(_ url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let launchNamed = items.first { $0.name == "launch" }?.value
        if let raw = items.first(where: { $0.name == "id" })?.value,
           let id = UUID(uuidString: raw) {
            try? WorkspaceControl.launch(id: id, launchNamed: launchNamed)
            return
        }
        if let name = items.first(where: { $0.name == "name" })?.value,
           !name.isEmpty {
            try? WorkspaceControl.launch(name: name, launchNamed: launchNamed)
        }
    }
}
