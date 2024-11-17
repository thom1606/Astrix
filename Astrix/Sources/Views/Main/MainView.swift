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
    @State private
    @State private var loaded = false

    func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
                loaded = true
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
                    Text("Customize Astrix to suit your preferences. If you don't find your preferred software, feel free to [open an issue](https://github.com/thom1606/Astrix/issues/new?labels=enhancement&template=request-new-software.md&title=%5BRequest%5D+Add+new+software%3A+%3CSoftware+Name%3E) so we can consider adding it!")
                        .foregroundStyle(Color(NSColor.secondaryLabelColor))
                        .font(.system(size: 19, weight: .regular))


                    LabeledPicker(label: "Default editor", selection: $defaultEditor, items: Constants.Scripting.SupportedEditorApplications.map { ($0.rawValue, $1) })
                    LabeledPicker(label: "Default terminal", selection: $defaultTerminal, items: Constants.Scripting.SupportedTerminalApplications.map { ($0.rawValue, $1) })

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
