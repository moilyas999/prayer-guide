import SwiftUI

enum AppCopy {
    static let name = "My Five"
}

enum Palette {
    /// Warm linen paper. Quiet, not a branded green or gold theme.
    static let canvas = Color(red: 0.965, green: 0.949, blue: 0.922)
    static let ink = Color(red: 0.145, green: 0.125, blue: 0.102)
    static let muted = Color(red: 0.45, green: 0.40, blue: 0.35)
    static let dusk = Color(red: 0.27, green: 0.31, blue: 0.41)
    static let highlight = Color(red: 0.91, green: 0.875, blue: 0.81)
    static let hairline = Color(red: 0.80, green: 0.75, blue: 0.68)
    static let cityFill = Color(red: 0.988, green: 0.978, blue: 0.958)
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
