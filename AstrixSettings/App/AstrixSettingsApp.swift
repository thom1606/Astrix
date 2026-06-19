//
//  AstrixSettingsApp.swift
//  AstrixSettings
//
//  Created by Thom van den Broek on 09/06/2026.
//

import SwiftUI
import AppKit

@main
struct AstrixSettingsApp: App {
    @NSApplicationDelegateAdaptor(SettingsAppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Astrix Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            // Replace the default "New Window" item; this app only ever has one window.
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class SettingsAppDelegate: NSObject, NSApplicationDelegate {
    private var mainAppMonitor: Timer?

    // The menu bar app's bundle id is this Settings app's id without the ".Settings" suffix.
    private var mainAppBundleID: String {
        let id = Bundle.main.bundleIdentifier ?? ""
        return id.hasSuffix(".Settings") ? String(id.dropLast(".Settings".count)) : "com.thom1606.Astrix"
    }

    private var isMainAppRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: mainAppBundleID).isEmpty
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        // Quit alongside the menu bar app: if it quits (e.g. "Quit Astrix"), there's
        // nothing left to configure, so close Settings too.
        //
        // Instant path: any app terminating triggers a fresh check of whether the menu
        // bar app is still around. (We re-query rather than trust the notification's
        // NSRunningApplication, whose properties may already be nil post-termination.)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(quitIfMainAppGone),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        // Reliable fallback: poll, in case the notification is missed or filtered.
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.quitIfMainAppGone()
        }
        RunLoop.main.add(timer, forMode: .common)
        mainAppMonitor = timer
    }

    @objc private func quitIfMainAppGone() {
        guard !isMainAppRunning else { return }
        NSApp.terminate(nil)
    }

    // Quitting (Cmd+Q) or closing the window terminates only this Settings process,
    // leaving the menu bar extra running.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
