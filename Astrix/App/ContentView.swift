//
//  ContentView.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import Sparkle

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    var updater: SPUUpdater

    var body: some View {
        ZStack {
            if onboardingCompleted {
                MainView(updater: updater)
            } else {
                Onboarding()
            }
        }
    }
}

#Preview {
    let mockUpdater = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil).updater
    ContentView(updater: mockUpdater)
        .frame(width: 425, height: 600)
}
