//
//  OnboardingStepNotifications.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import UserNotifications

struct OnboardingStepNotifications: View {
    @Binding var pageSelection: Int
    @State private var errored = false
    @State private var navigateToFinalStep = false

    // Request notifiation permissions from the user
    func requestNotifications() {
        if errored {
            pageSelection += 1
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            if let error = error {
                NSLog("Error requesting notification authorization: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    withAnimation {
                        errored = true
                    }
                }
            }
            NSLog("We have permission: \(granted)")
            // Navigate after the user decided to give permission or not
            DispatchQueue.main.async {
                pageSelection += 1
            }
        }
    }

    var title: LocalizedStringKey {
        if errored { return LocalizedStringKey("Oops!") }
        return LocalizedStringKey("Stay Informed")
    }

    var description: LocalizedStringKey {
        if errored { return ("We encountered a problem whilst requestion notification permissions. Would you like to continue without?") }
        return LocalizedStringKey("To ensure you are always up to date with your workflow, we will only send you notifications when it's essential for your tasks.")
    }

    var buttonText: LocalizedStringKey {
        if errored { return LocalizedStringKey("Continue") }
        return LocalizedStringKey("Request access")
    }

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                if #available(macOS 15.0, *) {
                    Image(systemName: errored ? "bell.slash.fill" : "bell.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 64)
                        .symbolEffect(.wiggle.byLayer, options: .repeating)
                        .contentTransition(.symbolEffect(.replace))
                } else {
                    Image(systemName: errored ? "bell.slash.fill" : "bell.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 64)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            Text(title)
                .foregroundStyle(Color(NSColor.labelColor))
                .font(.system(size: 19, weight: .semibold))
                .animation(.snappy, value: title)
                .contentTransition(.numericText(countsDown: true))
                .padding(.bottom, 3)
            Text(description)
                .foregroundStyle(Color(NSColor.secondaryLabelColor))
                .font(.system(size: 19, weight: .regular))
                .animation(.snappy, value: description)
                .contentTransition(.numericText(countsDown: true))
                .padding(.bottom, 20)
            Button(action: requestNotifications) {
                Text(buttonText)
                    .animation(.snappy, value: buttonText)
                    .contentTransition(.numericText(countsDown: true))
            }
            .buttonStyle(MainButtonStyle(size: .medium, errored: errored))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        OnboardingStepNotifications(pageSelection: .constant(0))
    }
}
