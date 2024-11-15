//
//  CloseButton.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct CloseButton: View {
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Button {
            dismissWindow()
        } label: {
            Image(systemName: "multiply")
        }
        .buttonStyle(RoundButtonStyle(size: .small))
    }
}

#Preview {
    CloseButton()
}
