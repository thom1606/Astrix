//
//  LoginItemManager.swift
//  Astrix
//
//  Owns Astrix's "open at login" registration. Lives in the main (non-sandboxed)
//  agent app on purpose: `SMAppService.mainApp` registers *the calling process's*
//  app, so registering here puts the menu bar app in Login Items — not the
//  sandboxed Settings helper. The Settings app flips the shared preference and
//  signals us (`DarwinSignal.setOpenAtLogin`); we apply it and publish the real
//  status back so the toggle reflects reality.
//

import Foundation
import ServiceManagement

enum LoginItemManager {
    private static var service: SMAppService { .mainApp }

    /// Whether Astrix is currently registered as a login item.
    static var isEnabled: Bool { service.status == .enabled }

    /// Register or unregister so the actual login-item state matches the user's
    /// stored intent. Idempotent. After applying, the real status is published back
    /// to the shared suite so the Settings toggle can correct itself if needed.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled, service.status != .enabled {
                try service.register()
            } else if !enabled, service.status == .enabled {
                try service.unregister()
            }
        } catch {
            NSLog("[Astrix] Open-at-login %@ failed: %@", enabled ? "register" : "unregister", error.localizedDescription)
        }
        publishStatus()
    }

    /// Apply whatever preference the Settings app last wrote. Called when it signals a
    /// change via `DarwinSignal.setOpenAtLogin`.
    static func applyStoredPreference() {
        setEnabled(SharedSettings.openAtLogin)
    }

    /// On launch, mirror the real login-item status into the shared preference so the
    /// toggle reflects any change the user made in System Settings › General › Login
    /// Items while Astrix wasn't running. We don't force-register here — only explicit
    /// toggles (onboarding or the Settings switch) change the registration.
    static func syncStatusToPreference() {
        publishStatus()
    }

    /// Persist the real status to the shared suite and tell other targets to refresh.
    private static func publishStatus() {
        let enabled = isEnabled
        let defaults = UserDefaults.astrixShared
        if defaults.bool(forKey: Constants.DefaultsKey.openAtLogin) != enabled {
            defaults.set(enabled, forKey: Constants.DefaultsKey.openAtLogin)
        }
        DarwinNotify.post(Constants.DarwinSignal.openAtLoginChanged)
    }
}
