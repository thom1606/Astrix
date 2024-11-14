//
//  OnboardingStepFinal.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct OnboardingStepFinal: View {
    func handleComplete() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Let's go")
            Text("You are all ready to get going with Astrix!")
            Button(action: handleComplete) {
                Text("Let's go")
            }
        }
    }
}

#Preview {
    OnboardingStepFinal()
}
