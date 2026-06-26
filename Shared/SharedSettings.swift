//
//  SharedSettings.swift
//  Astrix
//
//  Read-only access to everything Astrix persists in the shared App Group.
//
//  The Settings app writes these (via @AppStorage / FolderRecommendationsStore);
//  non-UI readers — chiefly the Finder extension — read them back here without
//  pulling in SwiftUI/Combine. One place that knows the keys, defaults, and
//  fallbacks so every target agrees.
//

import Foundation
import UserNotifications

enum SharedSettings {
    private static var defaults: UserDefaults { .astrixShared }

    /// The notification authorization status as last published by the main agent
    /// app. Other targets read this instead of querying notifications themselves.
    static var notificationStatus: UNAuthorizationStatus {
        UNAuthorizationStatus(rawValue: defaults.integer(forKey: Constants.DefaultsKey.notificationAuthStatus)) ?? .notDetermined
    }

    /// The user's default editor. Falls back to the first installed editor when the
    /// user hasn't made a choice yet (mirrors the Settings picker's default).
    static var defaultEditor: SupportedApps {
        guard let raw = defaults.string(forKey: Constants.DefaultsKey.defaultEditor) else {
            return SupportedApps.firstInstalledEditor
        }
        return SupportedApps(rawValue: raw) ?? .none
    }

    /// The user's default terminal. Falls back to the first installed terminal when
    /// the user hasn't made a choice yet.
    static var defaultTerminal: SupportedApps {
        guard let raw = defaults.string(forKey: Constants.DefaultsKey.defaultTerminal) else {
            return SupportedApps.firstInstalledTerminal
        }
        return SupportedApps(rawValue: raw) ?? .none
    }

    /// Whether to auto-suggest editors based on a folder's contents. Defaults to on.
    static var autoSuggestEditors: Bool {
        defaults.object(forKey: Constants.DefaultsKey.autoSuggestEditors) as? Bool ?? true
    }

    /// Whether the menu bar item is shown. Defaults to on.
    static var showInMenuBar: Bool {
        defaults.object(forKey: Constants.DefaultsKey.showInMenuBar) as? Bool ?? true
    }

    /// Whether Astrix launches automatically at login. Defaults to off. The main app
    /// owns the actual `SMAppService` registration and keeps this in sync with the
    /// real status; other targets read it (e.g. the Settings toggle's initial value).
    static var openAtLogin: Bool {
        defaults.bool(forKey: Constants.DefaultsKey.openAtLogin)
    }

    /// The user's per-folder editor recommendations.
    static var folderRecommendations: [FolderRecommendation] {
        guard let data = defaults.data(forKey: Constants.DefaultsKey.folderRecommendations),
              let decoded = try? JSONDecoder().decode([FolderRecommendation].self, from: data)
        else { return [] }
        return decoded
    }

    /// The user's workspaces. Written by the Settings app; read by the menu bar app
    /// to build and run its workspace menu items.
    static var workspaces: [Workspace] {
        guard let data = defaults.data(forKey: Constants.DefaultsKey.workspaces),
              let decoded = try? JSONDecoder().decode([Workspace].self, from: data)
        else { return [] }
        return decoded
    }
}
