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
    private func customizeWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.styleMask.remove(.titled)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
            }
            .frame(width: 425, height: 600)
            .background(WindowBackground())
            .onAppear {
                if let window = NSApplication.shared.windows.first {
                    customizeWindow(window)
                }
            }
        }
        .defaultSize(width: 425, height: 600)
    }
}
