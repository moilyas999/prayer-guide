import Combine
import Foundation
import WidgetKit

@MainActor
final class TodayModel: ObservableObject {
    @Published private(set) var snapshot: PrayerSnapshot
    @Published private(set) var now = Date()

    let settings: SettingsStore
    let location: LocationService
    let catalog: CityCatalog

    private var timer: AnyCancellable?

    var place: Place { snapshot.place }
    var today: DailyPrayers? { snapshot.today }
    var next: (name: SalahName, time: Date)? { snapshot.next }
    var current: SalahName? { snapshot.current }

    init(settings: SettingsStore, location: LocationService, catalog: CityCatalog = .shared) {
        self.settings = settings
        self.location = location
        self.catalog = catalog
        self.snapshot = PrayerSnapshot.make(
            place: Place.london,
            method: settings.method,
            madhhab: settings.madhhab,
            uses24HourClock: settings.uses24HourClock,
            now: Date()
        )
        refreshPlaceAndTimes()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                let previousDay = self.civilDay(self.now)
                self.now = date
                if self.civilDay(date) != previousDay {
                    self.refreshPlaceAndTimes()
                } else {
                    self.snapshot = PrayerSnapshot(
                        place: self.snapshot.place,
                        today: self.snapshot.today,
                        tomorrow: self.snapshot.tomorrow,
                        uses24HourClock: self.settings.uses24HourClock,
                        now: date
                    )
                }
            }
    }

    func refreshPlaceAndTimes() {
        let place = resolvePlace()
        SharedPreferences.savePlace(place)
        snapshot = PrayerSnapshot.make(
            place: place,
            method: settings.method,
            madhhab: settings.madhhab,
            uses24HourClock: settings.uses24HourClock,
            now: now
        )
        Task {
            await NotificationScheduler.apply(now: now)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func formatted(_ date: Date) -> String {
        snapshot.formatted(date)
    }

    private func resolvePlace() -> Place {
        if settings.usesDeviceLocation, location.isAuthorized, let coordinate = location.coordinate {
            if let nearest = catalog.nearest(latitude: coordinate.latitude, longitude: coordinate.longitude) {
                return Place(
                    displayName: nearest.name,
                    subtitle: "Near \(nearest.subtitle)",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    timeZone: .current,
                    cityID: nearest.id
                )
            }
            return Place(
                displayName: "Current location",
                subtitle: "From this device",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZone: .current,
                cityID: nil
            )
        }
        if let city = catalog.city(id: settings.selectedCityID) ?? catalog.defaultCity() {
            return Place(
                displayName: city.name,
                subtitle: city.subtitle,
                latitude: city.latitude,
                longitude: city.longitude,
                timeZone: city.timeZone,
                cityID: city.id
            )
        }
        return Place.london
    }

    private func civilDay(_ date: Date) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = snapshot.place.timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
