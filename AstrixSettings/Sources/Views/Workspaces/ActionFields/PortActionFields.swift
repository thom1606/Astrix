//
//  PortActionFields.swift
//  AstrixSettings
//
//  The port field shared by the "Wait for Port" and "Kill Port" actions — wait until a
//  TCP port accepts connections, or free a port by terminating whatever holds it.
//

import SwiftUI

struct PortActionFields: View {
    @Binding var action: WorkspaceAction

    var body: some View {
        SettingsRow("Port") {
            TextField("Port", text: portText, prompt: Text("e.g. 5000"))
                .labelsHidden()
                .frame(width: 120)
        }

        // Only the wait action waits; the kill action acts immediately.
        if action.type == .waitForPort {
            SettingsRow("Timeout") {
                TextField("Timeout", text: timeoutText, prompt: Text("10"))
                    .labelsHidden()
                    .frame(width: 120)
            }
        }
    }

    /// Two-way bridge so an empty field reads as "no port" (0).
    private var portText: Binding<String> {
        Binding(
            get: { action.port == 0 ? "" : String(action.port) },
            set: { action.port = Int($0.filter(\.isNumber)) ?? 0 }
        )
    }

    /// Timeout in seconds; empty reads as 0, which the runner treats as the 10s default.
    private var timeoutText: Binding<String> {
        Binding(
            get: { action.seconds == 0 ? "" : String(action.seconds) },
            set: { action.seconds = Int($0.filter(\.isNumber)) ?? 0 }
        )
    }
}
