//
//  NotificationManager.swift
//  Astrix
//
//  Notifications are owned solely by the main agent app. It holds the permission
//  and posts every notification. Other targets never post or request directly:
//   • the Finder extension *relays* (queues + signals the main app),
//   • the Settings app *requests via a signal* and reads the persisted status.
//
//  This keeps notifications coming from a single identity (the main app), instead
//  of each sandboxed target asking for its own permission.
//

import Foundation
import UserNotifications

enum NotificationManager {
    private static var defaults: UserDefaults { .astrixShared }

    // MARK: - Authorization (main app)

    /// Request authorization, then persist the resulting status for other targets.
    static func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            persistStatus()
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    /// The live authorization status of this process, delivered on the main queue.
    static func currentStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// Persist the current status to the shared suite so the Settings app can show
    /// it without owning notifications itself, then signal the change.
    static func persistStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            defaults.set(settings.authorizationStatus.rawValue, forKey: Constants.DefaultsKey.notificationAuthStatus)
            DarwinNotify.post(Constants.DarwinSignal.notificationStatusChanged)
        }
    }

    // MARK: - Relay (other targets → main app)

    /// Queue a notification for the main agent app to post. Used by the Finder
    /// extension so every notification comes from the main app's identity.
    static func relay(title: String, body: String) {
        var queue = pendingQueue()
        queue.append(PendingNotification(title: title, body: body))
        if let data = try? JSONEncoder().encode(queue) {
            defaults.set(data, forKey: Constants.DefaultsKey.pendingNotifications)
        }
        DarwinNotify.post(Constants.DarwinSignal.postNotification)
    }

    // MARK: - Main app host

    /// Called once by the main agent app on launch: posts anything already queued,
    /// publishes the current status, and listens for relay/request signals.
    static func startHost() {
        persistStatus()
        drainQueue()

        DarwinNotify.startBridging(Constants.DarwinSignal.postNotification)
        DarwinNotify.startBridging(Constants.DarwinSignal.requestNotificationAccess)

        NotificationCenter.default.addObserver(forName: .init(Constants.DarwinSignal.postNotification), object: nil, queue: .main) { _ in
            drainQueue()
        }
        NotificationCenter.default.addObserver(forName: .init(Constants.DarwinSignal.requestNotificationAccess), object: nil, queue: .main) { _ in
            requestAuthorization()
        }
    }

    /// Post a notification directly from the main agent app — used for events the main
    /// app itself raises, like a tracked workspace process crashing. Other (sandboxed)
    /// targets must use `relay` instead; only the main app holds the permission.
    static func notify(title: String, body: String, logURL: URL? = nil) {
        post(title: title, body: body, logURL: logURL)
    }

    /// Post a single notification now. Only the main app calls this (via the queue).
    /// A `logURL` is carried in `userInfo` so tapping the notification can open that
    /// task's log (handled by the main app's `UNUserNotificationCenterDelegate`).
    private static func post(title: String, body: String, logURL: URL? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let logURL {
            content.userInfo[Constants.NotificationUserInfo.logPath] = logURL.path
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private static func drainQueue() {
        let queue = pendingQueue()
        guard !queue.isEmpty else { return }
        defaults.removeObject(forKey: Constants.DefaultsKey.pendingNotifications)
        for item in queue {
            post(title: item.title, body: item.body)
        }
    }

    private static func pendingQueue() -> [PendingNotification] {
        guard let data = defaults.data(forKey: Constants.DefaultsKey.pendingNotifications),
              let decoded = try? JSONDecoder().decode([PendingNotification].self, from: data) else { return [] }
        return decoded
    }
}

private struct PendingNotification: Codable {
    let title: String
    let body: String
}
