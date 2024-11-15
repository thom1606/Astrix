//
//  SHake.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//
import SwiftUI

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var enabled: Bool
    var animatableData: CGFloat

    init(shakesPerUnit: CGFloat = 3, amount: CGFloat = 10, enabled: Bool) {
        self.shakesPerUnit = shakesPerUnit
        self.amount = amount
        self.enabled = enabled
        self.animatableData = enabled ? 1 : 0
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        if enabled {
            let shake = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
            return ProjectionTransform(CGAffineTransform(translationX: shake, y: 0))
        } else {
            return ProjectionTransform(CGAffineTransform(translationX: 0, y: 0))
        }
    }
}

extension View {
    func shake(enabled: Bool, amount: CGFloat = 10, shakesPerUnit: CGFloat = 3) -> some View {
        self.modifier(Shake(shakesPerUnit: shakesPerUnit, amount: amount, enabled: enabled))
    }
}
