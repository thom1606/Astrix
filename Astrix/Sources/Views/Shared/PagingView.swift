//
//  PagingView.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//

import SwiftUI

struct PagingView<Content: View>: View {
    @Binding var selection: Int
    let content: Content
    let pageCount: Int

    init(selection: Binding<Int>, pageCount: Int, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.pageCount = pageCount
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                content
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .offset(x: -CGFloat(selection) * geometry.size.width)
            .animation(.easeInOut, value: selection)
        }
    }
}
