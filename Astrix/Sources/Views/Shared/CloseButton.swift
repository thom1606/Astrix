//
//  CloseButton.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct CloseButton: View {
    var body: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Image(systemName: "multiply")
        }
        .buttonStyle(RoundButtonStyle(size: .small))
    }
}

#Preview {
    CloseButton()
}
