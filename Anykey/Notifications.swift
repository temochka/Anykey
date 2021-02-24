//
//  Notifications.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/17/21.
//

import Foundation
import UserNotifications

class Notifications {
    private let notificationCenter: UNUserNotificationCenter
    private var isOptedIn: Bool

    init() {
        isOptedIn = true
        notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert], completionHandler: { granted, _ in
            self.isOptedIn = granted
        })
    }

    func configError(error: ConfigError) {
        switch error {
        case .access(let description):
            notify(title: "Config error", body: description)
        case .invalid(let description):
            notify(title: "Config error", body: description)
        case .unknown(let description):
            notify(title: "Config error", body: description)
        }
    }

    func triggeredHotkey(hotkey: Hotkey) {
        notify(title: "Hotkey triggered", body: hotkey.title)
    }

    private func notify(title: String, body: String) {
        guard isOptedIn else { return }

        let bannerContent = UNMutableNotificationContent()
        bannerContent.title = title
        bannerContent.body = body
        bannerContent.sound = UNNotificationSound.default

        let id = "anykey_\(NSDate().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: id, content: bannerContent, trigger: nil)
        notificationCenter.add(request) { _ in }
    }
}
