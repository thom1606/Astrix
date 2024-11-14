//
//  OnboardingStepWelcome.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct OnboardingStepWelcome: View {
    @State private var hasSetup = false

    var title: String {
        if !hasSetup { return "Setting up" }
        return "Welcome"
    }

    var description: String {
        if !hasSetup { return "We're just getting our things together." }
        return "Enhance your workflow with Astrix."
    }

    func load() {
        do {
            try Scripting.shared.updateSystemScripts()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    hasSetup = true
                }
            }
        } catch {
            // TODO: handle errors and wait before allowing the user to click the button
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .foregroundStyle(.white)
                .font(.headline.weight(.semibold))
                .animation(.snappy, value: title)
                .contentTransition(.numericText(countsDown: true))
            Text(description)
                .foregroundStyle(.white)
                .font(.body)
                .animation(.snappy, value: description)
                .contentTransition(.numericText(countsDown: true))
            NavigationLink {
                OnboardingStepNotifications()
                    .navigationBarBackButtonHidden(true)
            } label: {
                Text("Get started")
            }.disabled(!hasSetup)
        }
        .onAppear(perform: load)
    }
}

#Preview {
    NavigationStack {
        OnboardingStepWelcome()
    }
}
