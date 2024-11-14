//
//  MainView.swift
//  Astrix
//
//  Created by Thom van den Broek on 14/11/2024.
//

import SwiftUI

struct MainView: View {
    @AppStorage("defaultEditor", store: UserDefaults(suiteName: "group.com.thom1606.Astrix")) private var defaultEditor = SupportedApps.textEdit.rawValue
    @AppStorage("defaultTerminal", store: UserDefaults(suiteName: "group.com.thom1606.Astrix")) private var defaultTerminal = SupportedApps.terminal.rawValue

    var body: some View {
        ScrollView {
            VStack {
                Picker("Default editor", selection: $defaultEditor) {
                    ForEach(Constants.Scripting.SupportedEditorApplications, id: \.0.rawValue) {
                        Text($1)
                    }
                }
                Picker("Default terminal", selection: $defaultTerminal) {
                    ForEach(Constants.Scripting.SupportedTerminalApplications, id: \.0.rawValue) {
                        Text($1)
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    MainView()
}
