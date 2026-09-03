import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedCityID: String {
        didSet { defaults.set(selectedCityID, forKey: Keys.cityID) }
    }

    @Published var method: CalculationMethodOption {
        didSet { defaults.set(method.rawValue, forKey: Keys.method) }
    }

    @Published var madhhab: AsrMadhhab {
        didSet { defaults.set(madhhab.rawValue, forKey: Keys.madhhab) }
    }

    @Published var uses24HourClock: Bool {
        didSet { defaults.set(uses24HourClock, forKey: Keys.clock24) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    @Published var usesDeviceLocation: Bool {
        didSet { defaults.set(usesDeviceLocation, forKey: Keys.location) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, catalog: CityCatalog = .shared) {
        self.defaults = defaults
        let fallback = catalog.defaultCity()?.id ?? Place.london.cityID ?? ""
        selectedCityID = defaults.string(forKey: Keys.cityID) ?? fallback
        method = CalculationMethodOption(rawValue: defaults.string(forKey: Keys.method) ?? "") ?? .muslimWorldLeague
        madhhab = AsrMadhhab(rawValue: defaults.string(forKey: Keys.madhhab) ?? "") ?? .standard
        uses24HourClock = defaults.object(forKey: Keys.clock24) as? Bool ?? false
        notificationsEnabled = defaults.bool(forKey: Keys.notifications)
        usesDeviceLocation = defaults.bool(forKey: Keys.location)
    }

    private enum Keys {
        static let cityID = "prayerguide.cityID"
        static let method = "prayerguide.method"
        static let madhhab = "prayerguide.madhhab"
        static let clock24 = "prayerguide.clock24"
        static let notifications = "prayerguide.notifications"
        static let location = "prayerguide.location"
    }
}
