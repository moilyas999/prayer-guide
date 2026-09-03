import Combine
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class TodayModel: ObservableObject {
    @Published private(set) var place: Place
    @Published private(set) var today: DailyPrayers?
    @Published private(set) var tomorrowFajr: Date?
    @Published private(set) var now = Date()

    let settings: SettingsStore
    let location: LocationService
    let catalog: CityCatalog

    private var timer: AnyCancellable?

    init(settings: SettingsStore, location: LocationService, catalog: CityCatalog = .shared) {
        self.settings = settings
        self.location = location
        self.catalog = catalog
        self.place = Place.london
        refreshPlaceAndTimes()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                let previousDay = self.civilDay(self.now)
                self.now = date
                if self.civilDay(date) != previousDay {
                    self.refreshPlaceAndTimes()
                }
            }
    }

    func refreshPlaceAndTimes() {
        place = resolvePlace()
        today = PrayerTimeEngine.times(
            latitude: place.latitude,
            longitude: place.longitude,
            on: now,
            timeZone: place.timeZone,
            method: settings.method,
            madhhab: settings.madhhab
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            tomorrowFajr = PrayerTimeEngine.times(
                latitude: place.latitude,
                longitude: place.longitude,
                on: tomorrow,
                timeZone: place.timeZone,
                method: settings.method,
                madhhab: settings.madhhab
            )?.fajr
        }
        Task {
            await NotificationScheduler.apply(
                enabled: settings.notificationsEnabled,
                today: today,
                tomorrowFajr: tomorrowFajr,
                timeZone: place.timeZone
            )
        }
    }

    var next: (name: SalahName, time: Date)? {
        if let today, let upcoming = today.nextSalah(at: now) {
            return upcoming
        }
        if let tomorrowFajr {
            return (.fajr, tomorrowFajr)
        }
        return nil
    }

    func formatted(_ date: Date) -> String {
        let formatter = British.clockFormat(uses24Hour: settings.uses24HourClock)
        formatter.timeZone = place.timeZone
        return formatter.string(from: date)
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
        calendar.timeZone = place.timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
