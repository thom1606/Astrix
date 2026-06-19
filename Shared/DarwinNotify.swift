//
//  DarwinNotify.swift
//  Astrix
//
//  Tiny wrapper over Darwin notifications — process-wide, payload-free signals
//  that work across the sandboxed Astrix targets (App Group entitlement aside,
//  these need no special permission). Incoming signals are forwarded to the
//  in-process `NotificationCenter` under the same name so observers can use Swift
//  closures or SwiftUI `.onReceive`.
//

import Foundation

enum DarwinNotify {
    private static var bridged = Set<String>()

    /// Post a signal to every running Astrix process.
    static func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil, nil, true
        )
    }

    /// Begin forwarding a Darwin signal to `NotificationCenter.default` under the
    /// same name. Idempotent — safe to call more than once per name.
    static func startBridging(_ name: String) {
        guard !bridged.contains(name) else { return }
        bridged.insert(name)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, cfName, _, _ in
                guard let raw = cfName?.rawValue as String? else { return }
                NotificationCenter.default.post(name: Notification.Name(raw), object: nil)
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }
}
