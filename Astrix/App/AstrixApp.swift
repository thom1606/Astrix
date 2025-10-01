//
//  AstrixApp.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI
import SwiftData
import Sparkle

@main
struct AstrixApp: App {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        // Initialize variables
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    private func customizeWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.styleMask.remove(.titled)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
    }

    var body: some Scene {
        Window("Astrix", id: "main") {
            ZStack {
                ContentView(updater: updaterController.updater)
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
        .commands {
            CommandGroup(replacing: .newItem) {
                // Disable the "New Window" menu item
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
