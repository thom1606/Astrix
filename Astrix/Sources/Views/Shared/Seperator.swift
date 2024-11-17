//
//  Seperator.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//

import SwiftUI

struct Seperator: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("ElementsLightenBackground"))
                .blendMode(.lighten)
            Rectangle()
                .fill(Color(red: 0.37, green: 0.37, blue: 0.37).opacity(0.18))
                .blendMode(.colorDodge)

        }
        .frame(height: 1)
    }
}

#Preview {
    Seperator()
}
