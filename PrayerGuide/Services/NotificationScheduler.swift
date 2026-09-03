import Foundation
import UserNotifications

enum NotificationScheduler {
    static let categoryID = "prayerguide.salah"

    static func apply(enabled: Bool, today: DailyPrayers?, tomorrowFajr: Date?, timeZone: TimeZone) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: SalahName.allCases.map(\.notificationID))
        await center.removePendingNotificationRequests(withIdentifiers: ["fajr-tomorrow"])

        guard enabled, let today else { return }

        let granted = await requestPermission()
        guard granted else { return }

        for name in SalahName.allCases {
            schedule(name: name.title, at: today.time(for: name), identifier: name.notificationID, timeZone: timeZone)
        }
        if let tomorrowFajr {
            schedule(name: SalahName.fajr.title, at: tomorrowFajr, identifier: "fajr-tomorrow", timeZone: timeZone)
        }
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    private static func schedule(name: String, at date: Date, identifier: String, timeZone: TimeZone) {
        guard date > Date() else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let content = UNMutableNotificationContent()
        content.title = "Prayer Guide"
        content.body = "It is time for \(name)."
        content.sound = .default
        content.categoryIdentifier = categoryID
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

private extension SalahName {
    var notificationID: String { "prayerguide.\(rawValue)" }
}
