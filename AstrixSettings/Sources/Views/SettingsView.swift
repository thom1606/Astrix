//
//  SettingsView.swift
//  AstrixSettings
//
//  The Settings window's tab container.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            RecommendationsSettingsView()
                .tabItem {
                    Label("Recommendations", systemImage: "wand.and.stars")
                }
            WorkspacesSettingsView()
                .tabItem {
                    Label("Workspaces", systemImage: "square.grid.2x2")
                }
        }
        .frame(width: 680, height: 600)
    }
}

#Preview {
    SettingsView()
}
