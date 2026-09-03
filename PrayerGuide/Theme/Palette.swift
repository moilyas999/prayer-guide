import SwiftUI

enum Palette {
    static let canvas = Color(red: 0.94, green: 0.96, blue: 0.93)
    static let card = Color.white
    static let ink = Color(red: 0.10, green: 0.18, blue: 0.15)
    static let muted = Color(red: 0.35, green: 0.42, blue: 0.38)
    static let leaf = Color(red: 0.07, green: 0.36, blue: 0.24)
    static let leafSoft = Color(red: 0.16, green: 0.48, blue: 0.34)
    static let highlight = Color(red: 0.86, green: 0.94, blue: 0.88)
}

enum British {
    static let locale = Locale(identifier: "en_GB")

    static func clockFormat(uses24Hour: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = uses24Hour ? "HH:mm" : "h:mm a"
        return formatter
    }

    static func gregorianDate(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: date)
    }

    static func hijriDate(_ date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = locale
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    static func countdown(until end: Date, now: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            let hourWord = hours == 1 ? "hour" : "hours"
            let minuteWord = minutes == 1 ? "minute" : "minutes"
            if minutes == 0 {
                return "in \(hours) \(hourWord)"
            }
            return "in \(hours) \(hourWord) \(minutes) \(minuteWord)"
        }
        if minutes > 0 {
            let minuteWord = minutes == 1 ? "minute" : "minutes"
            return "in \(minutes) \(minuteWord)"
        }
        return "now"
    }
}
