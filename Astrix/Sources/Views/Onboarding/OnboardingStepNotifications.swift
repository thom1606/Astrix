//
//  OnboardingStepNotifications.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import UserNotifications

struct OnboardingStepNotifications: View {
    @State private var navigateToFinalStep = false

    func handleError() {
        // TODO: show error to user that something failed when setting up
//        appModel?.backgroundColor = .red
    }

    // Request notifiation permissions from the user
    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                NSLog("Error requesting notification authorization: \(error.localizedDescription)")
                handleError()
            }
            NSLog("We have permission: \(granted)")
            // Navigate after the user decided to give permission or not
            DispatchQueue.main.async {
                navigateToFinalStep = true
            }
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Keep notified")
            Text("To keep you up to date with your workflow. We'll only send you notifications when you're working on something which requires it.")
            Button(action: {
                requestNotifications()
            }) {
                Text("Request access")
            }
            .navigationDestination(isPresented: $navigateToFinalStep) {
                OnboardingStepFinal().navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingStepNotifications()
    }
}
