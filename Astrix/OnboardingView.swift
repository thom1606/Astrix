//
//  OnboardingView.swift
//  Astrix
//
//  First-launch onboarding. Mocked for now: a welcome screen highlighting what
//  Astrix does. The "Get started" button also requests notification permission.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    /// Called when the user finishes onboarding.
    let onComplete: () -> Void

    /// The warm background tint (#FBE8D7).
    private let backgroundColor = Color(red: 251 / 255, green: 232 / 255, blue: 215 / 255)

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundColor

            // Subtle noise texture, blended with color dodge.
            Image("noise")
                .resizable()
                .scaledToFill()
                .blendMode(.colorDodge)
                .allowsHitTesting(false)

            // Decorative artwork pinned to the bottom edge.
            Image("onboarding-decorations")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)

            content
        }
        // Fixed to the window size for deterministic centering. The hosting view
        // (FullBleedHostingView) reports no safe-area insets, so this fills the whole
        // window — background under the transparent title bar, decorations flush at
        // the bottom.
        .frame(width: 460, height: 600)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            getStartedButton
                .padding(28)                  // equal inset from the right and bottom
        }
        .environment(\.colorScheme, .light)   // text stays dark on the light background
    }

    private var content: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: 8) {
                Text("Welcome to Astrix")
                    .font(.largeTitle.bold())
                Text("Open folders in your favorite editor or terminal, right from Finder.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()

            VStack(alignment: .leading, spacing: 18) {
                FeatureRow(icon: "terminal", title: "Open in Terminal", description: "Jump into any folder in your terminal of choice.")
                FeatureRow(icon: "chevron.left.forwardslash.chevron.right", title: "Open in Editor", description: "Launch your editor right where you need it.")
                FeatureRow(icon: "wand.and.stars", title: "Smart Suggestions", description: "Astrix suggests the right editor for each project.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)   // fill the width so children center deterministically
        .padding(40)
    }

    @ViewBuilder
    private var getStartedButton: some View {
        if #available(macOS 26.0, *) {
            Button(action: getStarted) { getStartedLabel }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.white).interactive(), in: .capsule)
        } else {
            Button(action: getStarted) {
                getStartedLabel.background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
        }
    }

    /// The button's label, sized to 36pt tall (10pt vertical padding) with 32pt of
    /// horizontal padding.
    private var getStartedLabel: some View {
        Text("Get started")
            .padding(.vertical, 10)
            .padding(.horizontal, 32)
    }

    /// Request notification permission, then finish onboarding once the user has
    /// responded to the system prompt.
    private func getStarted() {
        NotificationManager.requestAuthorization { _ in
            onComplete()
        }
    }
}

/// A single highlighted feature row in the onboarding screen.
private struct FeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .frame(width: 460, height: 600)
}
