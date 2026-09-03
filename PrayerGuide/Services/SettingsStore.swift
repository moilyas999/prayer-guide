import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedCityID: String {
        didSet { defaults.set(selectedCityID, forKey: SharedKeys.cityID) }
    }

    @Published var method: CalculationMethodOption {
        didSet { defaults.set(method.rawValue, forKey: SharedKeys.method) }
    }

    @Published var madhhab: AsrMadhhab {
        didSet { defaults.set(madhhab.rawValue, forKey: SharedKeys.madhhab) }
    }

    @Published var uses24HourClock: Bool {
        didSet { defaults.set(uses24HourClock, forKey: SharedKeys.clock24) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: SharedKeys.notifications) }
    }

    @Published var usesDeviceLocation: Bool {
        didSet { defaults.set(usesDeviceLocation, forKey: SharedKeys.location) }
    }

    @Published var alertLead: AlertLeadTime {
        didSet { defaults.set(alertLead.rawValue, forKey: SharedKeys.alertLead) }
    }

    @Published var enabledAlerts: Set<SalahName> {
        didSet { SharedPreferences.saveEnabledAlerts(enabledAlerts, to: defaults) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = AppGroup.defaults, catalog: CityCatalog = .shared) {
        self.defaults = defaults
        let fallback = catalog.defaultCity()?.id ?? Place.london.cityID ?? ""
        selectedCityID = defaults.string(forKey: SharedKeys.cityID) ?? fallback
        method = SharedPreferences.method(from: defaults)
        madhhab = SharedPreferences.madhhab(from: defaults)
        uses24HourClock = SharedPreferences.uses24HourClock(from: defaults)
        notificationsEnabled = SharedPreferences.notificationsEnabled(from: defaults)
        usesDeviceLocation = defaults.bool(forKey: SharedKeys.location)
        alertLead = SharedPreferences.alertLead(from: defaults)
        enabledAlerts = SharedPreferences.enabledAlerts(from: defaults)
    }

    func binding(for name: SalahName) -> Binding<Bool> {
        Binding(
            get: { self.enabledAlerts.contains(name) },
            set: { enabled in
                var next = self.enabledAlerts
                if enabled {
                    next.insert(name)
                } else {
                    next.remove(name)
                }
                self.enabledAlerts = next
            }
        )
    }
}
