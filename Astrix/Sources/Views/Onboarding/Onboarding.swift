//
//  Onboarding.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct Onboarding: View {
    @State private var selection = 0

    var body: some View {
        VStack {
            Header()
            PagingView(selection: $selection, pageCount: 3) {
                OnboardingStepWelcome(pageSelection: $selection)
                    .padding(24)
                    .tag(0)
                OnboardingStepNotifications(pageSelection: $selection)
                    .padding(24)
                    .tag(1)
                OnboardingStepFinal()
                    .padding(24)
                    .tag(2)
            }
        }
    }
}

#Preview {
    Onboarding()
}
