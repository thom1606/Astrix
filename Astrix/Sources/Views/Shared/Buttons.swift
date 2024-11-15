//
//  Buttons.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//

import SwiftUI

struct RoundButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    var size: ElementSize = .medium
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.value, height: size.value)
            .background(
                ZStack {
                    Circle()
                        .fill(Color("ElementsLightenBackground"))
                        .blendMode(.lighten)
                    Circle()
                        .fill(Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.18))
                        .blendMode(.colorDodge)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.14),
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .blendMode(.colorDodge)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(NSColor.labelColor).opacity(0.07),
                                    Color(NSColor.labelColor).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .blendMode(.normal)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                }
            )
            .foregroundColor(isEnabled ? Color(NSColor.labelColor) : Color(NSColor.tertiaryLabelColor))
            .clipShape(Circle())
            .font(.system(size: size.iconSize, weight: .medium))
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct MainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    var size: ElementSize = .medium
    var errored: Bool = false
    var fullWidth: Bool = false
    @State private var isHovered = false

    var horizontalPadding: CGFloat {
        if size == .medium { return 25 }
        return 20
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: size.value)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 500)
                        .fill(Color("ElementsLightenBackground"))
                        .blendMode(.lighten)
                    RoundedRectangle(cornerRadius: 500)
                        .fill(Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.18))
                        .blendMode(.colorDodge)
                    if errored {
                        RoundedRectangle(cornerRadius: 500)
                            .fill(.red.opacity(0.3))
                            .blendMode(.plusDarker)
                    }
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.14),
                                    Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .frame(width: size.value, height: size.value)
                        .scaleEffect(x: 3, y: 1, anchor: .bottom)
                        .blendMode(.colorDodge)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(NSColor.labelColor).opacity(0.07),
                                    Color(NSColor.labelColor).opacity(0)
                                ]),
                                center: .bottom,
                                startRadius: 0,
                                endRadius: size.value / 2
                            )
                        )
                        .frame(width: size.value, height: size.value)
                        .scaleEffect(x: 3, y: 1, anchor: .top)
                        .blendMode(.normal)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                }
            )
            .foregroundColor(isEnabled ? Color(NSColor.labelColor) : Color(NSColor.tertiaryLabelColor))
            .clipShape(RoundedRectangle(cornerRadius: 500))
            .font(.system(size: size.fontSize, weight: .medium))
            .shake(enabled: errored)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
