//
//  WaitSecondsActionFields.swift
//  AstrixSettings
//
//  Fields for a "Wait for Seconds" action: how long to pause before the next action
//  runs (e.g. give a service a moment to boot before opening its URL).
//

import SwiftUI

struct WaitSecondsActionFields: View {
    @Binding var action: WorkspaceAction

    var body: some View {
        SettingsRow("Seconds") {
            HStack(spacing: 6) {
                TextField("Seconds", text: secondsText)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Stepper("", value: $action.seconds, in: 0...86400)
                    .labelsHidden()
            }
        }
    }

    /// Numbers only — non-digits are stripped as they're typed; stays in sync with the
    /// stepper, which mutates `action.seconds` directly.
    private var secondsText: Binding<String> {
        Binding(
            get: { String(action.seconds) },
            set: { action.seconds = min(Int($0.filter(\.isNumber)) ?? 0, 86400) }
        )
    }
}
