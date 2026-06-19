//
//  AppDelegate+URLScheme.swift
//  Astrix
//
//  Wires the `astrix://` URL scheme into the running app. A menu bar (accessory)
//  app has no document/window plumbing, so we register a GetURL Apple Event handler
//  directly — the most reliable path for an LSUIElement app. The system delivers a
//  GetURL event whenever anything opens an `astrix://…` URL.
//

import AppKit
import CoreServices

extension AppDelegate {
    /// Start listening for `astrix://` URLs. Call once, early in launch.
    func registerURLSchemeHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: string) else { return }
        AstrixURL.handle(url)
    }
}
