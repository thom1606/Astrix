//
//  OnboardingStepFinal.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import Cocoa
import FinderSync

struct OnboardingStepFinal: View {
    func handleComplete() {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["pluginkit", "-e", "use", "-i", "com.thom1606.Astrix.FinderTools"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                if #available(macOS 15.0, *) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 64)
                        .symbolEffect(.wiggle.byLayer, options: .repeating)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 64)
                }
            }
            Text("Ready to Start?")
                .foregroundStyle(Color(NSColor.labelColor))
                .font(.system(size: 19, weight: .semibold))
                .padding(.bottom, 3)
            Text("You are all set to begin your journey with Astrix! Try adding Astrix to your Finder toolbar and enjoy a more streamlined workflow.")
                .foregroundStyle(Color(NSColor.secondaryLabelColor))
                .font(.system(size: 19, weight: .regular))
                .padding(.bottom, 20)
            Button(action: handleComplete) {
                Text("Let's go!")
            }
            .buttonStyle(MainButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingStepFinal()
}
