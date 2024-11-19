//
//  MainView.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import UserNotifications

struct MainView: View {
    @AppStorage(Constants.Id.DefaultEditorKey, store: UserDefaults(suiteName: Constants.Id.DefaultsDomain)) private var defaultEditor = Scripting.shared.getFirstInstalledEditor().rawValue
    @AppStorage(Constants.Id.DefaultTerminalKey, store: UserDefaults(suiteName: Constants.Id.DefaultsDomain)) private var defaultTerminal = Scripting.shared.getFirstInstalledTerminal().rawValue

    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var isNewUpdateAvailable = false
    @State private var loaded = false

    // Check what the status is of our notifications
    func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
                loaded = true
            }
        }
    }
    // Request access to the notifications
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in
            checkNotificationPermissionStatus()
        }
    }
    // Check for available updates
    func checkForUpdates() {
        // get app version from Info.plist
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Failed to get app version")
            return
        }
        let encodedAppVersion = appVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appVersion
        let updateURL = URL(string: "https://astrix.thomvandenbroek.com/api/update?version=\(encodedAppVersion)")!
        URLSession.shared.dataTask(with: updateURL) { _, response, error in
            guard error == nil else {
                print("Failed to check for updates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            // Check if the current version is the latest available
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    isNewUpdateAvailable = true
                }
            }
        }.resume()
    }

    func load() {
        // Check if the notifications are correctly set up
        checkNotificationPermissionStatus()
        // Update the scripting api
        try? Scripting.shared.updateSystemScripts()
        // Check if there are any updates available to download
        checkForUpdates()
    }

    var body: some View {
        VStack(spacing: 0) {
            Header(title: "Settings")
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Customize Astrix to suit your preferences. If you don't find your preferred software, feel free to [open an issue](https://github.com/thom1606/Astrix/issues/new?labels=enhancement&template=request-new-software.md&title=%5BRequest%5D+Add+new+software%3A+%3CSoftware+Name%3E) so we can consider adding it!")
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))
                        .font(.system(size: 19, weight: .regular))

                    LabeledPicker(label: "Default editor", selection: $defaultEditor, items: [(SupportedApps.none.rawValue, NSLocalizedString("None", comment: ""))] + Constants.Scripting.SupportedEditorApplications.filter { $0.0 != .none }.sorted(by: { $0.1 < $1.1 }).map { ($0.rawValue, $1) })
                    LabeledPicker(label: "Default terminal", selection: $defaultTerminal, items: [(SupportedApps.none.rawValue, NSLocalizedString("None", comment: ""))] + Constants.Scripting.SupportedTerminalApplications.filter { $0.0 != .none }.sorted(by: { $0.1 < $1.1 }).map { ($0.rawValue, $1) })

                    if notificationPermissionStatus == .notDetermined && loaded {
                        Seperator()
                        Text("You currently don’t have notifications permissions set up. Would you like to?")
                            .foregroundStyle(Color(NSColor.secondaryLabelColor))
                            .font(.system(size: 19, weight: .regular))
                        Button(action: requestNotificationAccess) {
                            Text("Request notification access")
                        }
                        .buttonStyle(MainButtonStyle(fullWidth: true))
                    }

                    if isNewUpdateAvailable {
                        Seperator()
                        Text("There is a new update available for Astrix! Please download the latest version to enjoy new features and improvements.")
                            .foregroundStyle(Color(NSColor.secondaryLabelColor))
                            .font(.system(size: 19, weight: .regular))
                        Link("New update available", destination: URL(string: "https://astrix.thomvandenbroek.com/download")!)
                            .buttonStyle(MainButtonStyle(fullWidth: true))
                    }

                    Rectangle()
                        .fill(.clear)
                        .frame(width: 30, height: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear(perform: load)
    }
}

#Preview {
    MainView()
}
