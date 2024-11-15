//
//  MainView.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import UserNotifications

struct MainView: View {
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("defaultEditor", store: UserDefaults(suiteName: "group.com.thom1606.Astrix")) private var defaultEditor = SupportedApps.none.rawValue
    @AppStorage("defaultTerminal", store: UserDefaults(suiteName: "group.com.thom1606.Astrix")) private var defaultTerminal = SupportedApps.terminal.rawValue

    func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }

    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            checkNotificationPermissionStatus()
        }
    }

    func load() {
        checkNotificationPermissionStatus()
    }

    var body: some View {
        VStack(spacing: 0) {
            Header(title: "Settings")
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Customize Astrix to suit your preferences. If you don't find your preferred software, feel free to [open an issue](https://github.com/thom1606/Astrix/issues/new?template=request-new-software.md) so we can consider adding it!")
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))
                        .font(.system(size: 19, weight: .regular))

                    Picker("Default editor", selection: $defaultEditor) {
                        ForEach(Constants.Scripting.SupportedEditorApplications, id: \.0.rawValue) {
                            Text($1)
                        }
                    }
                    Picker("Default terminal", selection: $defaultTerminal) {
                        ForEach(Constants.Scripting.SupportedTerminalApplications, id: \.0.rawValue) {
                            Text($1)
                        }
                    }
                    if notificationPermissionStatus == .notDetermined {
                        Seperator()
                        Text("You currently don’t have notifications permissions set up. Would you like to?")
                            .foregroundStyle(Color(NSColor.secondaryLabelColor))
                            .font(.system(size: 19, weight: .regular))
                        Button(action: requestNotificationAccess) {
                            Text("Request notification access")
                        }
                        .buttonStyle(MainButtonStyle(fullWidth: true))
                    }
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
