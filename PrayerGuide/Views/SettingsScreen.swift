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

                Section("Display") {
                    Picker("Clock", selection: $settings.uses24HourClock) {
                        Text("12-hour").tag(false)
                        Text("24-hour").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Alerts") {
                    Toggle("Prayer alerts", isOn: $settings.notificationsEnabled)
                    if settings.notificationsEnabled {
                        Picker("When", selection: $settings.alertLead) {
                            ForEach(AlertLeadTime.allCases) { lead in
                                Text(lead.title).tag(lead)
                            }
                        }
                        ForEach(SalahName.allCases) { name in
                            Toggle(name.title, isOn: settings.binding(for: name))
                        }
                    }
                    if notificationDenied {
                        Text("Notifications are switched off in iOS Settings. My Five cannot show alerts until you allow them.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    } else {
                        Text("Local reminders on this iPhone only. My Five does not use a push server, and nothing is sent anywhere. If iOS asks for permission, that is only so these on-device alerts can appear. The next seven days are scheduled, then refreshed when you open the app or change a setting.")
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                    }
                }

                Section("About") {
                    LabeledContent("App", value: AppCopy.name)
                    LabeledContent("Company", value: "DeskLink.ai")
                    LabeledContent("Version", value: Self.versionLabel)
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
            .onChange(of: settings.usesDeviceLocation) { _, enabled in
                if enabled {
                    location.requestWhenInUse()
                }
                model.refreshPlaceAndTimes()
            }
            .onChange(of: settings.method) { _, _ in model.refreshPlaceAndTimes() }
            .onChange(of: settings.madhhab) { _, _ in model.refreshPlaceAndTimes() }
            .onChange(of: settings.uses24HourClock) { _, _ in model.refreshPlaceAndTimes() }
            .onChange(of: settings.alertLead) { _, _ in model.refreshPlaceAndTimes() }
            .onChange(of: settings.enabledAlerts) { _, _ in model.refreshPlaceAndTimes() }
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
        }
    }

    private static var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        return "\(version) (\(build))"
    }
}
