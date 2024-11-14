//
//  ContentView.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    var body: some View {
        ZStack {
            if onboardingCompleted {
                MainView()
            } else {
                Onboarding()
            }
        }
    }
}

#Preview {
    ContentView()
}
