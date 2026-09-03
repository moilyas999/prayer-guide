import Foundation

struct PrayerAlertEvent: Equatable {
    let name: SalahName
    let prayerTime: Date
    let fireDate: Date
    let identifier: String
    let lead: AlertLeadTime
}

enum PrayerAlertPlan {
    static let weekPrefix = "prayerguide.week."
    static let alarmPrefix = "prayerguide.alarm."
    static let scheduledDays = 7

    static func weekEvents(
        from now: Date,
        place: Place,
        method: CalculationMethodOption,
        madhhab: AsrMadhhab,
        enabled: Set<SalahName>,
        lead: AlertLeadTime
    ) -> [PrayerAlertEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        let start = calendar.startOfDay(for: now)
        var events: [PrayerAlertEvent] = []
        for offset in 0..<scheduledDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            guard let prayers = PrayerTimeEngine.times(
                latitude: place.latitude,
                longitude: place.longitude,
                on: day,
                timeZone: place.timeZone,
                method: method,
                madhhab: madhhab
            ) else { continue }
            for name in SalahName.allCases where enabled.contains(name) {
                let prayerTime = prayers.time(for: name)
                let fireDate = prayerTime.addingTimeInterval(-Double(lead.minutes) * 60)
                guard fireDate > now else { continue }
                events.append(
                    PrayerAlertEvent(
                        name: name,
                        prayerTime: prayerTime,
                        fireDate: fireDate,
                        identifier: weekIdentifier(day: day, name: name, timeZone: place.timeZone),
                        lead: lead
                    )
                )
            }
        }
        return events
    }

    static func weekIdentifier(day: Date, name: SalahName, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let stamp = String(format: "%04d%02d%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        return "\(weekPrefix)\(stamp).\(name.rawValue)"
    }

    static func body(for event: PrayerAlertEvent) -> String {
        switch event.lead {
        case .atTime:
            return "It is time for \(event.name.title)."
        case .fiveMinutes, .fifteenMinutes:
            return "\(event.name.title) \(event.lead.notice)."
        }
    }

    static func alarmIdentifier(name: SalahName, scope: String) -> String {
        "\(alarmPrefix)\(scope).\(name.rawValue)"
    }
}
