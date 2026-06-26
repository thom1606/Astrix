//
//  AstrixApp.swift
//  Astrix
//
//  Created by Thom van den Broek on 09/06/2026.
//

import SwiftUI
import AppKit
import Sparkle
import UserNotifications

@main
struct AstrixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage(Constants.DefaultsKey.showInMenuBar, store: .astrixShared)
    private var showInMenuBar = true

    // Read workspaces straight from the shared App Group. Because it's an
    // @AppStorage on the shared suite, the menu re-renders whenever the Settings app
    // writes a change — no restart needed (same mechanism as showInMenuBar).
    @AppStorage(Constants.DefaultsKey.workspaces, store: .astrixShared)
    private var workspacesData = Data()

    private var workspaces: [Workspace] {
        (try? JSONDecoder().decode([Workspace].self, from: workspacesData)) ?? []
    }

    var body: some Scene {
        MenuBarExtra("Astrix", image: "MenuBarIcon", isInserted: .constant(showInMenuBar)) {
            if !workspaces.isEmpty {
                WorkspacesMenu(workspaces: workspaces)
                Divider()
            }

            Button("Settings...") {
                SettingsLauncher.open()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Check for Updates…") {
                appDelegate.updaterController.updater.checkForUpdates()
            }

            Divider()

            Button("Quit Astrix") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Handles app lifecycle events that SwiftUI's `App` doesn't expose directly.
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var onboardingWindow: NSWindow?

    /// Drives Sparkle in-app updates (checks against the appcast feed in Info.plist).
    /// Lives here so both the menu bar item and the Settings app (via a Darwin
    /// signal) can trigger a check — Sparkle only exists in this process.
    let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for astrix:// URLs so external triggers (Shortcuts, the `open`
        // command, other tools) can launch workspaces hands-free. Registered first
        // so a URL that launches the app is handled as soon as we're ready.
        registerURLSchemeHandler()
        // Install/refresh the Finder extension's helper script so it can launch
        // apps from inside its sandbox. Must run from the containing app.
        try? Scripting.shared.updateSystemScripts()
        // Become the single notification authority: receive taps (to open a crashed
        // task's log), post anything other targets queued, and listen for their
        // relay/request signals. The delegate must be set before launch finishes.
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.startHost()
        // The Settings app can't run Sparkle itself, so it signals us to check.
        DarwinNotify.startBridging(Constants.DarwinSignal.checkForUpdates)
        NotificationCenter.default.addObserver(forName: .init(Constants.DarwinSignal.checkForUpdates), object: nil, queue: .main) { [weak self] _ in
            self?.updaterController.updater.checkForUpdates()
        }
        // Open-at-login lives here: SMAppService registers *this* app, so the sandboxed
        // Settings app can only flip the shared preference and signal us to apply it.
        // Mirror the real status on launch so the toggle tracks changes made in System
        // Settings while we weren't running.
        LoginItemManager.syncStatusToPreference()
        DarwinNotify.startBridging(Constants.DarwinSignal.setOpenAtLogin)
        NotificationCenter.default.addObserver(forName: .init(Constants.DarwinSignal.setOpenAtLogin), object: nil, queue: .main) { _ in
            LoginItemManager.applyStoredPreference()
        }
        #if DEBUG
        // Dev tool: the Settings "Reset Onboarding" button clears the flag and
        // re-shows onboarding so it can be iterated on.
        DarwinNotify.startBridging(Constants.DarwinSignal.resetOnboarding)
        NotificationCenter.default.addObserver(forName: .init(Constants.DarwinSignal.resetOnboarding), object: nil, queue: .main) { [weak self] _ in
            UserDefaults.astrixShared.set(false, forKey: Constants.DefaultsKey.hasCompletedOnboarding)
            self?.presentOnboarding()
        }
        #endif
        presentOnboardingIfNeeded()

        // With the menu bar item hidden there's no other way into the app, so open
        // Settings straight away on launch (unless onboarding is already showing).
        if onboardingWindow == nil && !SharedSettings.showInMenuBar {
            SettingsLauncher.open()
        }
    }

    /// Stop every tracked workspace process before the app exits, so dev-server trees
    /// (`bin/dev` → foreman → ruby/node, `docker compose up`, …) don't leak and re-hold
    /// their ports after a quit. Runs synchronously on the main thread during quit.
    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated {
            ProcessManager.shared.terminateAllForQuit()
        }
    }

    /// Sent when the user launches the app while it's already running (double-click
    /// in Finder, clicking the Dock icon, `open`, etc.). Since Astrix has no main
    /// window — and the menu bar extra may be hidden ("Never") — we treat a relaunch
    /// as a request to reopen onboarding (if unfinished) or Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            SettingsLauncher.open()
        }
        return true
    }

    // MARK: - Onboarding

    /// On first launch, present onboarding unless it's already done or the user is
    /// migrating from the previously shipped app.
    private func presentOnboardingIfNeeded() {
        let defaults = UserDefaults.astrixShared
        guard !defaults.bool(forKey: Constants.DefaultsKey.hasCompletedOnboarding) else { return }

        // Migration: users updating from the previously shipped app already have
        // settings in the shared suite (e.g. a chosen editor/terminal). They're not
        // new users, so skip onboarding rather than interrupting their update.
        let isExistingUser = defaults.string(forKey: Constants.DefaultsKey.defaultEditor) != nil
            || defaults.string(forKey: Constants.DefaultsKey.defaultTerminal) != nil
        if isExistingUser {
            defaults.set(true, forKey: Constants.DefaultsKey.hasCompletedOnboarding)
            return
        }

        presentOnboarding()
    }

    /// Present the (mocked) onboarding window. The menu bar app has no SwiftUI window
    /// scene, so we host the view in an `NSWindow` directly.
    private func presentOnboarding() {
        guard onboardingWindow == nil else {
            onboardingWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 600),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        // Match the onboarding background so the transparent title bar never shows white.
        window.backgroundColor = NSColor(srgbRed: 251.0 / 255, green: 232.0 / 255, blue: 215.0 / 255, alpha: 1)
        window.center()
        window.delegate = self
        // A hosting view that reports no safe-area insets, so the onboarding content
        // fills the entire window (under the transparent title bar) with no offset —
        // this keeps it horizontally centered and the decorations flush at the bottom.
        window.contentView = FullBleedHostingView(rootView: AnyView(OnboardingView { [weak window] in
            UserDefaults.astrixShared.set(true, forKey: Constants.DefaultsKey.hasCompletedOnboarding)
            // New installs opt into launch-at-login: Astrix needs to be running for the
            // Finder menu and shortcuts to work, so finishing onboarding enables it.
            LoginItemManager.setEnabled(true)
            window?.close()
        }))
        onboardingWindow = window

        // Stay an accessory (LSUIElement) app so the onboarding window never adds a
        // Dock icon — accessory apps can still show and focus windows.
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === onboardingWindow else { return }
        onboardingWindow = nil
    }
}

// MARK: - Notification taps

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Keep crash / launch-error banners visible even when Astrix itself is the
    /// frontmost app (e.g. Settings or onboarding is open) — macOS otherwise
    /// suppresses notifications posted by the active app.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    /// When a notification carrying a log path is tapped, open that task's log so the
    /// user lands straight on the failed run's output. Falls back to the workspace's
    /// log folder if the specific file is gone (pruned) or was never written (e.g. the
    /// working directory didn't exist), and does nothing for notifications without a log.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let path = response.notification.request.content.userInfo[Constants.NotificationUserInfo.logPath] as? String else {
            return
        }
        let logURL = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: logURL.path) {
            NSWorkspace.shared.open(logURL)
        } else {
            let directory = logURL.deletingLastPathComponent()
            if fileManager.fileExists(atPath: directory.path) {
                NSWorkspace.shared.open(directory)
            }
        }
    }
}

/// An `NSHostingView` that ignores safe-area insets, letting SwiftUI content fill
/// the whole window (including under a transparent title bar) with no offset.
///
/// Deliberately non-generic (hosts `AnyView`): a generic `NSHostingView` subclass
/// crashes the Swift 6.3 SIL optimizer (EarlyPerfInliner) on its implicit deinit in
/// `-O` Release builds. AnyView erasure sidesteps the generic-layout codepath.
private final class FullBleedHostingView: NSHostingView<AnyView> {
    override var safeAreaInsets: NSEdgeInsets { NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
}

/// Launches the separate Settings app. Prefers the copy embedded inside this app
/// bundle (used for distribution) and falls back to a sibling build product (used
/// when running from Xcode's build directory).
enum SettingsLauncher {
    static func open() {
        let embedded = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/Astrix.app")
        let sibling = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("AstrixSettings.app")

        let settingsAppURL = FileManager.default.fileExists(atPath: embedded.path) ? embedded : sibling

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: settingsAppURL, configuration: configuration)
    }
}
