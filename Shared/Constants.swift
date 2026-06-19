//
//  Constants.swift
//  Astrix
//
//  App-wide constants shared across every Astrix target: the menu bar app, the
//  Settings app, and (later) the Finder extension. Keep this file target-agnostic
//  — no SwiftUI/AppKit — so it can be compiled into any of them.
//

import Foundation

enum Constants {
    /// The Apple Developer team identifier, read at runtime from this target's
    /// Info.plist `TEAM_IDENTIFIER` key (populated from the `TEAM_IDENTIFIER`
    /// build setting in `Configuration/Global.xcconfig`). Read from settings — like
    /// the previously shipped app — rather than hardcoded, so there's one source of
    /// truth and the App Group identifier is derived consistently.
    static let teamIdentifier: String = {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "TEAM_IDENTIFIER") as? String,
              !identifier.isEmpty else {
            fatalError("TEAM_IDENTIFIER not set — check Configuration/Global.xcconfig and the target's Info.plist")
        }
        return identifier
    }()

    /// The App Group every Astrix target shares. Settings written by the Settings
    /// app must be readable by the menu bar app and the Finder extension, so they
    /// all read/write the same `UserDefaults` suite identified here.
    ///
    /// macOS uses the team-prefixed App Group format (not the iOS-style `group.`
    /// prefix, which a sandboxed process can't reliably read). This is the *same*
    /// identifier the previously shipped app used (`<team>.com.thom1606.Astrix`), so
    /// existing users' settings carry over untouched on update. Must match the
    /// `com.apple.security.application-groups` entitlement
    /// `$(TeamIdentifierPrefix)com.thom1606.Astrix` in every target.
    enum AppGroup {
        static let identifier = "\(Constants.teamIdentifier).com.thom1606.Astrix"
    }

    /// Keys for everything Astrix persists in the shared suite. Centralised so the
    /// writer (Settings app) and the readers (menu bar app, Finder extension) can
    /// never drift apart.
    enum DefaultsKey {
        static let showInMenuBar = "showInMenuBar"
        static let defaultEditor = "defaultEditor"
        static let defaultTerminal = "defaultTerminal"
        static let folderRecommendations = "folderRecommendations"
        static let workspaces = "workspaces"
        static let autoSuggestEditors = "autoSuggestEditors"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        /// Notification authorization status (UNAuthorizationStatus rawValue),
        /// written by the main app so other targets can display it.
        static let notificationAuthStatus = "notificationAuthStatus"
        /// JSON queue of notifications the main app should post on behalf of other
        /// targets (the Finder extension).
        static let pendingNotifications = "pendingNotifications"
    }

    /// Keys for the `userInfo` dictionary attached to posted notifications. The main
    /// app's notification delegate reads them back when a notification is tapped.
    enum NotificationUserInfo {
        /// Filesystem path of the task log to open when a crash / launch-error
        /// notification is clicked.
        static let logPath = "logPath"
    }

    /// Names for Darwin (process-wide) signals used to coordinate across the
    /// sandboxed Astrix targets. Notifications are owned solely by the main agent
    /// app; other targets signal it rather than posting/requesting themselves.
    enum DarwinSignal {
        /// Extension → main app: drain and post the pending-notification queue.
        static let postNotification = "com.thom1606.Astrix.postNotification"
        /// Settings → main app: request notification authorization.
        static let requestNotificationAccess = "com.thom1606.Astrix.requestNotificationAccess"
        /// Main app → others: the persisted authorization status changed.
        static let notificationStatusChanged = "com.thom1606.Astrix.notificationStatusChanged"
        /// Settings → main app: check for updates (Sparkle lives in the main app).
        static let checkForUpdates = "com.thom1606.Astrix.checkForUpdates"
        /// Settings → main app (DEBUG): reset and re-show onboarding.
        static let resetOnboarding = "com.thom1606.Astrix.resetOnboarding"
    }

    /// Bundle identifiers. The dev/prod split keeps debug builds from colliding
    /// with the released app installed in /Applications.
    enum BundleID {
        #if DEBUG
        static let finderExtension = "com.thom1606.Astrix.Dev.FinderTools"
        #else
        static let finderExtension = "com.thom1606.Astrix.FinderTools"
        #endif
    }

    /// The helper AppleScript the Finder extension runs to launch apps from inside
    /// the sandbox.
    enum Scripting {
        static let toolsFileName = "tools"
        static let toolsFileExtension = "scpt"
    }
}

extension UserDefaults {
    /// The shared App Group suite every Astrix target reads and writes. This is the
    /// single backing store that keeps all targets in sync; falls back to
    /// `.standard` only if the suite can't be created (e.g. missing entitlement).
    static let astrixShared = UserDefaults(suiteName: Constants.AppGroup.identifier) ?? .standard
}
