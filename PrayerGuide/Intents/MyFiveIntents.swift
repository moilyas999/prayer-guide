import AppIntents
import Foundation

struct NextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "What’s the next prayer?"
    static var description = IntentDescription("Speak the next prayer name and time. Calculated on this iPhone.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let snapshot = PrayerSnapshot.current()
        let sentence = snapshot.nextSentence()
        return .result(value: sentence, dialog: IntentDialog(stringLiteral: sentence))
    }
}

struct SetAlarmForNextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "Set alarm for next prayer"
    static var description = IntentDescription("Schedules a local reminder on this iPhone for the next prayer. This is not a Clock app alarm.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = PrayerSnapshot.current()
        guard let next = snapshot.next else {
            return .result(dialog: "No upcoming prayer time is available.")
        }
        let allowed = await NotificationScheduler.scheduleAlarm(
            name: next.name,
            at: next.time,
            scope: "next",
            timeZone: snapshot.place.timeZone,
            clock: snapshot.formatted(next.time)
        )
        if allowed {
            return .result(
                dialog: "Local reminder set for \(next.name.title) at \(snapshot.formatted(next.time)). It stays on this iPhone and is not a Clock alarm."
            )
        }
        return .result(dialog: "Allow notifications for My Five in iOS Settings to set a local reminder.")
    }
}

struct SetAlarmsForTodaysPrayersIntent: AppIntent {
    static var title: LocalizedStringResource = "Set alarms for today’s five prayers"
    static var description = IntentDescription("Schedules local reminders on this iPhone for the remaining prayers today. These are not Clock app alarms.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = PrayerSnapshot.current()
        guard let today = snapshot.today else {
            return .result(dialog: "Today’s prayer times are not available.")
        }
        var names: [String] = []
        for name in SalahName.allCases {
            let time = today.time(for: name)
            guard time > snapshot.now else { continue }
            let allowed = await NotificationScheduler.scheduleAlarm(
                name: name,
                at: time,
                scope: "today",
                timeZone: snapshot.place.timeZone,
                clock: snapshot.formatted(time)
            )
            if !allowed {
                return .result(dialog: "Allow notifications for My Five in iOS Settings to set local reminders.")
            }
            names.append(name.title)
        }
        if names.isEmpty {
            return .result(dialog: "Today’s five prayers have already passed.")
        }
        return .result(
            dialog: "Local reminders set for \(list(names)). They stay on this iPhone and are not Clock alarms."
        )
    }

    private func list(_ names: [String]) -> String {
        guard names.count > 1 else { return names.first ?? "" }
        if names.count == 2 { return "\(names[0]) and \(names[1])" }
        return names.dropLast().joined(separator: ", ") + ", and \(names.last ?? "")"
    }
}

struct MyFiveShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .navy }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPrayerIntent(),
            phrases: [
                "What's the next prayer in \(.applicationName)",
                "Next prayer in \(.applicationName)",
            ],
            shortTitle: "Next prayer",
            systemImageName: "clock"
        )
        AppShortcut(
            intent: SetAlarmForNextPrayerIntent(),
            phrases: [
                "Set alarm for next prayer in \(.applicationName)",
                "Alarm for next prayer in \(.applicationName)",
            ],
            shortTitle: "Alarm for next",
            systemImageName: "alarm"
        )
        AppShortcut(
            intent: SetAlarmsForTodaysPrayersIntent(),
            phrases: [
                "Set alarms for today's prayers in \(.applicationName)",
                "Alarms for today's five prayers in \(.applicationName)",
            ],
            shortTitle: "Alarms for today",
            systemImageName: "bell"
        )
    }
}
