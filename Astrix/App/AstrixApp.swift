//
//  AstrixApp.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import SwiftData

@main
struct AstrixApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.titleVisibility = .hidden
                        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        window.standardWindowButton(.zoomButton)?.isHidden = true
//                        window.isOpaque = false
//                        window.backgroundColor = .clear
//                        window.contentView?.wantsLayer = true
//                        window.contentView?.layer?.cornerRadius = 80 // Updated corner radius
//                        window.contentView?.layer?.masksToBounds = false
//                        window.hasShadow = false
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 425, height: 600)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    }
}
