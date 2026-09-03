import Foundation
import UserNotifications

enum NotificationScheduler {
    static let categoryID = "prayerguide.salah"
    static let presentationDelegate = PresentationDelegate()

    static func installDelegate() {
        UNUserNotificationCenter.current().delegate = presentationDelegate
    }

    static func apply(now: Date = Date(), defaults: UserDefaults = AppGroup.defaults) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let weekIDs = pending.map(\.identifier).filter { $0.hasPrefix(PrayerAlertPlan.weekPrefix) }
        await center.removePendingNotificationRequests(withIdentifiers: weekIDs)

        guard SharedPreferences.notificationsEnabled(from: defaults) else { return }

        let granted = await requestPermission()
        guard granted else { return }

        let place = SharedPreferences.place(from: defaults)
        let events = PrayerAlertPlan.weekEvents(
            from: now,
            place: place,
            method: SharedPreferences.method(from: defaults),
            madhhab: SharedPreferences.madhhab(from: defaults),
            enabled: SharedPreferences.enabledAlerts(from: defaults),
            lead: SharedPreferences.alertLead(from: defaults)
        )
        for event in events {
            schedule(
                title: AppCopy.name,
                body: PrayerAlertPlan.body(for: event),
                at: event.fireDate,
                identifier: event.identifier,
                timeZone: place.timeZone
            )
        }
    }

    static func scheduleAlarm(name: SalahName, at date: Date, scope: String, timeZone: TimeZone, clock: String) async -> Bool {
        let granted = await requestPermission()
        guard granted else { return false }
        guard date > Date() else { return false }
        schedule(
            title: "\(AppCopy.name) alarm",
            body: "\(name.title) · \(clock)",
            at: date,
            identifier: PrayerAlertPlan.alarmIdentifier(name: name, scope: scope),
            timeZone: timeZone
        )
        return true
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
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    private static func schedule(title: String, body: String, at date: Date, identifier: String, timeZone: TimeZone) {
        guard date > Date() else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.interruptionLevel = .timeSensitive
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    final class PresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .sound]
        }
    }
}
