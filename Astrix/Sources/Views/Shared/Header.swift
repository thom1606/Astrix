//
//  Header.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct Header: View {
    var title: LocalizedStringKey = ""

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
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Header(title: "Settings")
        .frame(width: 425, height: 600)
}
