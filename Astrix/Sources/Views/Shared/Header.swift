//
//  Header.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct Header: View {
    var title: String = ""

    var body: some View {
        ZStack {
            HStack {
                CloseButton()
                Spacer()
            }
            Text(title)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .font(.largeTitle.bold())
                .foregroundStyle(Color(NSColor.labelColor))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Header(title: "Settings")
        .frame(width: 425, height: 600)
}