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
        if !hasSetup { return "Hang tight!" }
        return "Welcome to Astrix"
    }

    var description: String {
        if !hasSetup { return "We're just getting things ready for you. Almost there!" }
        return "Enhance your workflow with Astrix and experience a new level of productivity and efficiency."
    }

    func load() {
        do {
            try Scripting.shared.updateSystemScripts()
            // TODO: also setup the default AppStorage values here
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
        VStack(alignment: .leading) {
            ZStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                if #available(macOS 15.0, *) {
                    if hasSetup {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 160, weight: .semibold))
                            .padding(.bottom, 42)
                            .symbolEffect(.wiggle, options: .repeating)
                    } else {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 160, weight: .semibold))
                            .padding(.bottom, 42)
                            .symbolEffect(.rotate.clockwise.byLayer, options: .repeating)

                    }
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 42)
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
            NavigationLink {
                OnboardingStepNotifications()
                    .navigationBarBackButtonHidden(true)
            } label: {
                Text("Get started")
            }.disabled(!hasSetup)
                .buttonStyle(MainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .onAppear(perform: load)
    }
}

#Preview {
    NavigationStack {
        OnboardingStepWelcome()
    }
}
