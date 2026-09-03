import Foundation

enum AppGroup {
    static let suiteName = "group.ai.desklink.prayerguide"

    static var defaults: UserDefaults {
        migrateIfNeeded()
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    private static func migrateIfNeeded() {
        let suite = UserDefaults(suiteName: suiteName) ?? .standard
        let flag = "prayerguide.migratedToGroup"
        guard suite.object(forKey: flag) == nil else { return }
        let standard = UserDefaults.standard
        for key in SharedKeys.all {
            if suite.object(forKey: key) == nil, let value = standard.object(forKey: key) {
                suite.set(value, forKey: key)
            }
        }
        suite.set(true, forKey: flag)
    }
}

enum SharedKeys {
    static let cityID = "prayerguide.cityID"
    static let method = "prayerguide.method"
    static let madhhab = "prayerguide.madhhab"
    static let clock24 = "prayerguide.clock24"
    static let notifications = "prayerguide.notifications"
    static let location = "prayerguide.location"
    static let alertLead = "prayerguide.alertLead"
    static let enabledAlerts = "prayerguide.enabledAlerts"
    static let placeName = "prayerguide.placeName"
    static let placeSubtitle = "prayerguide.placeSubtitle"
    static let placeLat = "prayerguide.placeLat"
    static let placeLon = "prayerguide.placeLon"
    static let placeTZ = "prayerguide.placeTZ"

    static let all = [
        cityID, method, madhhab, clock24, notifications, location,
        alertLead, enabledAlerts, placeName, placeSubtitle, placeLat, placeLon, placeTZ,
    ]
}

enum AlertLeadTime: Int, CaseIterable, Identifiable {
    case atTime = 0
    case fiveMinutes = 5
    case fifteenMinutes = 15

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var title: String {
        switch self {
        case .atTime: return "At time"
        case .fiveMinutes: return "5 min before"
        case .fifteenMinutes: return "15 min before"
        }
    }

    var notice: String {
        switch self {
        case .atTime: return "It is time"
        case .fiveMinutes: return "in 5 minutes"
        case .fifteenMinutes: return "in 15 minutes"
        }
    }
}

enum SharedPreferences {
    static func place(from defaults: UserDefaults = AppGroup.defaults) -> Place {
        let name = defaults.string(forKey: SharedKeys.placeName)
        let lat = defaults.object(forKey: SharedKeys.placeLat) as? Double
        let lon = defaults.object(forKey: SharedKeys.placeLon) as? Double
        let tzID = defaults.string(forKey: SharedKeys.placeTZ)
        if let name, let lat, let lon, let tzID, let timeZone = TimeZone(identifier: tzID) {
            return Place(
                displayName: name,
                subtitle: defaults.string(forKey: SharedKeys.placeSubtitle) ?? "",
                latitude: lat,
                longitude: lon,
                timeZone: timeZone,
                cityID: defaults.string(forKey: SharedKeys.cityID)
            )
        }
        return Place.london
    }

    static func savePlace(_ place: Place, to defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(place.displayName, forKey: SharedKeys.placeName)
        defaults.set(place.subtitle, forKey: SharedKeys.placeSubtitle)
        defaults.set(place.latitude, forKey: SharedKeys.placeLat)
        defaults.set(place.longitude, forKey: SharedKeys.placeLon)
        defaults.set(place.timeZone.identifier, forKey: SharedKeys.placeTZ)
        if let cityID = place.cityID {
            defaults.set(cityID, forKey: SharedKeys.cityID)
        }
    }

    static func method(from defaults: UserDefaults = AppGroup.defaults) -> CalculationMethodOption {
        CalculationMethodOption(rawValue: defaults.string(forKey: SharedKeys.method) ?? "") ?? .muslimWorldLeague
    }

    static func madhhab(from defaults: UserDefaults = AppGroup.defaults) -> AsrMadhhab {
        AsrMadhhab(rawValue: defaults.string(forKey: SharedKeys.madhhab) ?? "") ?? .standard
    }

    static func uses24HourClock(from defaults: UserDefaults = AppGroup.defaults) -> Bool {
        defaults.object(forKey: SharedKeys.clock24) as? Bool ?? false
    }

    static func notificationsEnabled(from defaults: UserDefaults = AppGroup.defaults) -> Bool {
        defaults.bool(forKey: SharedKeys.notifications)
    }

    static func alertLead(from defaults: UserDefaults = AppGroup.defaults) -> AlertLeadTime {
        AlertLeadTime(rawValue: defaults.integer(forKey: SharedKeys.alertLead)) ?? .atTime
    }

    static func enabledAlerts(from defaults: UserDefaults = AppGroup.defaults) -> Set<SalahName> {
        guard let stored = defaults.string(forKey: SharedKeys.enabledAlerts) else {
            return Set(SalahName.allCases)
        }
        if stored.isEmpty { return [] }
        return Set(stored.split(separator: ",").compactMap { SalahName(rawValue: String($0)) })
    }

    static func saveEnabledAlerts(_ names: Set<SalahName>, to defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(names.map(\.rawValue).sorted().joined(separator: ","), forKey: SharedKeys.enabledAlerts)
    }
}
