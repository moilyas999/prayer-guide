import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var model: TodayModel
    @Environment(\.dismiss) private var dismiss
    @State private var notificationDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use my location", isOn: $settings.usesDeviceLocation)
                        .onChange(of: settings.usesDeviceLocation) { _, enabled in
                            if enabled {
                                location.requestWhenInUse()
                            }
                            model.refreshPlaceAndTimes()
                        }
                    if let message = location.lastError, settings.usesDeviceLocation {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    } else {
                        Text("Optional. Times are calculated on this device. If you decline, pick a city instead.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }

                Section("Calculation") {
                    Picker("Method", selection: $settings.method) {
                        ForEach(CalculationMethodOption.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    Text(settings.method.detail)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)

                    Picker("Asr madhhab", selection: $settings.madhhab) {
                        ForEach(AsrMadhhab.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    Text(settings.madhhab.detail)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
                .onChange(of: settings.method) { _, _ in model.refreshPlaceAndTimes() }
                .onChange(of: settings.madhhab) { _, _ in model.refreshPlaceAndTimes() }

                Section("Display") {
                    Picker("Clock", selection: $settings.uses24HourClock) {
                        Text("12-hour").tag(false)
                        Text("24-hour").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notifications") {
                    Toggle("Remind me at prayer time", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            Task {
                                if enabled {
                                    let allowed = await NotificationScheduler.requestPermission()
                                    if !allowed {
                                        notificationDenied = true
                                        settings.notificationsEnabled = false
                                    }
                                }
                                model.refreshPlaceAndTimes()
                            }
                        }
                    if notificationDenied {
                        Text("Notifications are switched off in iOS Settings.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    } else {
                        Text("A local reminder at each of the five times. Nothing is sent to a server.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "Prayer Guide")
                    LabeledContent("Company", value: "DeskLink.ai")
                    LabeledContent("Version", value: "1.0 (1)")
                    Text("Completely free. No adverts, no purchases, no accounts, and no analytics. Prayer times are calculated on your iPhone from a shipped city list.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
