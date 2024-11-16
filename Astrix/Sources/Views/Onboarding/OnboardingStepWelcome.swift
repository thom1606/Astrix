//
//  OnboardingStepWelcome.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct OnboardingStepWelcome: View {
    @Binding var pageSelection: Int
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
        let dispatchGroup = DispatchGroup()

        // Enter the dispatch group for the script update
        dispatchGroup.enter()
        do {
            try Scripting.shared.updateSystemScripts()

            // Leave the dispatch group after the script update is done
            dispatchGroup.leave()
        } catch {
            // Handle errors and leave the dispatch group
            dispatchGroup.leave()
        }
        
        // Enter the dispatch group for the minimum delay
        dispatchGroup.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dispatchGroup.leave()
        }
        
        // Notify when both tasks are complete
        dispatchGroup.notify(queue: .main) {
            withAnimation {
                hasSetup = true
            }
        }
    }

    func handleNext() {
        let userDefaults = UserDefaults(suiteName: Constants.Id.DefaultsDomain)
        userDefaults?.set(Scripting.shared.getFirstInstalledTerminal().rawValue, forKey: "defaultTerminal")
        userDefaults?.set(Scripting.shared.getFirstInstalledEditor().rawValue, forKey: "defaultEditor")

        pageSelection += 1
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
                            .padding(.bottom, 64)
                            .symbolEffect(.wiggle, options: .repeating)
                    } else {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 160, weight: .semibold))
                            .padding(.bottom, 64)
                            .symbolEffect(.rotate.clockwise.byLayer, options: .repeating)

                    }
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 160, weight: .semibold))
                        .padding(.bottom, 64)
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
            Button(action: handleNext) {
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
        OnboardingStepWelcome(pageSelection: .constant(0))
    }
}
