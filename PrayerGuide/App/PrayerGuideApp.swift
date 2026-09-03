import SwiftUI

@main
struct PrayerGuideApp: App {
    @StateObject private var settings: SettingsStore
    @StateObject private var location: LocationService
    @StateObject private var model: TodayModel

    init() {
        let settings = SettingsStore()
        let location = LocationService()
        _settings = StateObject(wrappedValue: settings)
        _location = StateObject(wrappedValue: location)
        _model = StateObject(wrappedValue: TodayModel(settings: settings, location: location))
    }

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environmentObject(settings)
                .environmentObject(location)
                .environmentObject(model)
                .tint(Palette.leaf)
                .onAppear {
                    if settings.usesDeviceLocation {
                        location.requestWhenInUse()
                    }
                    model.refreshPlaceAndTimes()
                }
                .onChange(of: location.coordinate?.latitude) { _, _ in
                    model.refreshPlaceAndTimes()
                }
                .onChange(of: location.coordinate?.longitude) { _, _ in
                    model.refreshPlaceAndTimes()
                }
                .onChange(of: location.authorization) { _, _ in
                    model.refreshPlaceAndTimes()
                }
        }
    }
}
