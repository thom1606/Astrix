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
        default:
            break
        }
    }

    private static func handleLaunch(_ url: URL) {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let raw = items.first(where: { $0.name == "id" })?.value,
           let id = UUID(uuidString: raw) {
            try? WorkspaceControl.launch(id: id)
            return
        }
        if let name = items.first(where: { $0.name == "name" })?.value,
           !name.isEmpty {
            try? WorkspaceControl.launch(name: name)
        }
    }
}
