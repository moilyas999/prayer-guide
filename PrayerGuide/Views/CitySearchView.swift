import SwiftUI

struct CitySearchView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var model: TodayModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    private var results: [City] {
        CityCatalog.shared.search(query)
    }

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        Text("Type a city. The list stays on this iPhone.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                            .listRowBackground(Color.clear)
                    }
                }
                Section {
                    ForEach(results) { city in
                        Button {
                            settings.selectedCityID = city.id
                            settings.usesDeviceLocation = false
                            model.refreshPlaceAndTimes()
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .foregroundStyle(Palette.ink)
                                    Text(city.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                if city.id == settings.selectedCityID, !settings.usesDeviceLocation {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Palette.dusk)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "City or country")
            .navigationTitle("Choose a city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
