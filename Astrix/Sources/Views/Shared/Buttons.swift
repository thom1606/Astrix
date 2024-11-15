//
//  Buttons.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//

import SwiftUI

enum Sizes {
    case small
    case medium
}

struct RoundButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    var size: Sizes = .medium
    @State private var isHovered = false

    var finalSize: CGFloat {
        if size == .medium { return 52 }
        return 44
    }

    var iconSize: CGFloat {
        if size == .medium { return 24 }
        return 19
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: finalSize, height: finalSize)
            .background(
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
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
                                endRadius: finalSize / 2
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
                                endRadius: finalSize / 2
                            )
                        )
                        .blendMode(.normal)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                }
            )
            .foregroundColor(isEnabled ? Color(NSColor.labelColor) : Color(NSColor.tertiaryLabelColor))
            .clipShape(Circle())
            .font(.system(size: iconSize, weight: .medium))
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct MainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    var size: Sizes = .medium
    var errored: Bool = false
    var fullWidth: Bool = false
    @State private var isHovered = false

    var finalSize: CGFloat {
        if size == .medium { return 52 }
        return 44
    }

    var horizontalPadding: CGFloat {
        if size == .medium { return 25 }
        return 20
    }

    var fontSize: CGFloat {
        if size == .medium { return 19 }
        return 17
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: finalSize)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 500)
                        .fill(Color.white.opacity(0.06))
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
                                endRadius: finalSize / 2
                            )
                        )
                        .frame(width: finalSize, height: finalSize)
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
                                endRadius: finalSize / 2
                            )
                        )
                        .frame(width: finalSize, height: finalSize)
                        .scaleEffect(x: 3, y: 1, anchor: .top)
                        .blendMode(.normal)
                        .opacity(configuration.isPressed || isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: (configuration.isPressed || isHovered) && isEnabled)
                }
            )
            .foregroundColor(isEnabled ? Color(NSColor.labelColor) : Color(NSColor.tertiaryLabelColor))
            .clipShape(RoundedRectangle(cornerRadius: 500))
            .font(.system(size: fontSize, weight: .medium))
            .shake(enabled: errored)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
