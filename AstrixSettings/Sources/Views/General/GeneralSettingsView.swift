//
//  GeneralSettingsView.swift
//  AstrixSettings
//
//  The "General" tab: a full-bleed vertical banner down the left edge and a
//  scrollable column of setting cards on the right — menu bar visibility,
//  notifications, default editor/terminal, and updates.
//

import SwiftUI
import AppKit
import UserNotifications
import Combine

struct GeneralSettingsView: View {
    @AppStorage(Constants.DefaultsKey.showInMenuBar, store: .astrixShared)
    private var showInMenuBar = true

    @AppStorage(Constants.DefaultsKey.defaultEditor, store: .astrixShared)
    private var defaultEditor: String = SupportedApps.firstInstalledEditor.rawValue

    @AppStorage(Constants.DefaultsKey.defaultTerminal, store: .astrixShared)
    private var defaultTerminal: String = SupportedApps.firstInstalledTerminal.rawValue

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    // Open-at-login is applied by the main app (SMAppService registers the calling
    // app, so the sandboxed Settings app can't do it itself). We hold the value in
    // local state, flip the shared preference + signal the main app on change, and
    // refresh when it publishes the real status back — mirroring the notification
    // pattern above rather than binding @AppStorage straight to the switch.
    @State private var openAtLogin = SharedSettings.openAtLogin

    var body: some View {
        HStack(spacing: 0) {
            banner

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    behaviorSection
                    notificationsSection
                    defaultApplicationsSection
                    updatesSection
                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            DarwinNotify.startBridging(Constants.DarwinSignal.notificationStatusChanged)
            DarwinNotify.startBridging(Constants.DarwinSignal.openAtLoginChanged)
            refreshNotificationStatus()
            openAtLogin = SharedSettings.openAtLogin
        }
        .onReceive(NotificationCenter.default.publisher(for: .init(Constants.DarwinSignal.notificationStatusChanged))) { _ in
            refreshNotificationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init(Constants.DarwinSignal.openAtLoginChanged))) { _ in
            // The main app published the real status (it may differ from what we asked
            // for); reflect it without re-triggering onChange when it already matches.
            openAtLogin = SharedSettings.openAtLogin
        }
        .onChange(of: openAtLogin) { _, newValue in
            UserDefaults.astrixShared.set(newValue, forKey: Constants.DefaultsKey.openAtLogin)
            DarwinNotify.post(Constants.DarwinSignal.setOpenAtLogin)
        }
    }

    // MARK: - Banner

    /// The top banner, turned on its side and run down the left edge as an inset,
    /// rounded panel (not edge-to-edge). Center-cropped for now (the artwork is
    /// landscape); a purpose-made vertical banner will slot in here later.
    private var banner: some View {
        Image("settings-banner")
            .resizable()
            .scaledToFill()
            .frame(width: 180)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.leading, 20)
            .padding(.vertical, 20)
    }

    // MARK: - Sections

    private var behaviorSection: some View {
        SettingsSection(
            footer: "Astrix runs in the background so its Finder menu and shortcuts stay available."
        ) {
            SettingsToggleRow("Show in Menu Bar", isOn: $showInMenuBar)
            SettingsToggleRow("Open at Login", isOn: $openAtLogin)
        }
    }

    private var notificationsSection: some View {
        SettingsSection(
            "Notifications",
            footer: "Get feedback about important changes in processes and actions."
        ) {
            switch notificationStatus {
            case .notDetermined:
                Button("Request Notification Access", action: requestNotifications)
            case .denied:
                Button("Open System Settings", action: openNotificationSettings)
            default:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Notifications are enabled.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var defaultApplicationsSection: some View {
        SettingsSection(
            "Default Applications",
            footer: "Choose which editor and terminal Astrix opens your folders in from the Finder menu."
        ) {
            appPicker("Default Editor", selection: $defaultEditor, apps: SupportedApps.editors)
            appPicker("Default Terminal", selection: $defaultTerminal, apps: SupportedApps.terminals)
        }
    }

    private var updatesSection: some View {
        SettingsSection("Software Updates") {
            SettingsRow("Version") {
                Text(appVersion).foregroundStyle(.secondary)
            }
            // Sparkle runs in the main app, so ask it to check (see AppDelegate).
            Button("Check for Updates…") {
                DarwinNotify.post(Constants.DarwinSignal.checkForUpdates)
            }
        }
    }

    #if DEBUG
    private var developerSection: some View {
        SettingsSection("Developer") {
            Button("Reset Onboarding") {
                DarwinNotify.post(Constants.DarwinSignal.resetOnboarding)
            }
        }
    }
    #endif

    // MARK: - Helpers

    /// App version string, e.g. "1.0 (10)".
    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }

    private func refreshNotificationStatus() {
        // Read the status the main agent app published; the Settings app never owns
        // notifications itself.
        notificationStatus = SharedSettings.notificationStatus
    }

    private func requestNotifications() {
        // Ask the main agent app to request authorization (it owns notifications).
        DarwinNotify.post(Constants.DarwinSignal.requestNotificationAccess)
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    /// A labeled menu picker over a set of apps, with "None" always available as
    /// the first option. `fixedSize` keeps the popup snug to its widest option so
    /// both rows' popups line up on the trailing edge.
    private func appPicker(_ title: LocalizedStringKey, selection: Binding<String>, apps: [SupportedApps]) -> some View {
        SettingsRow(title) {
            Picker("", selection: selection) {
                Text(SupportedApps.none.displayName).tag(SupportedApps.none.rawValue)
                ForEach(apps) { app in
                    Text(app.displayName).tag(app.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
        }
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 680, height: 600)
}
