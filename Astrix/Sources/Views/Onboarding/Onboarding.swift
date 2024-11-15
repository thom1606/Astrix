//
//  Onboarding.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct Onboarding: View {
    var body: some View {
        VStack {
            Header()
            NavigationStack {
                OnboardingStepWelcome()
                    .padding(24)
            }
        }
    }
}

#Preview {
    Onboarding()
}
