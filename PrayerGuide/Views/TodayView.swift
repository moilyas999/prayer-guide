import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: TodayModel
    @EnvironmentObject private var settings: SettingsStore
    @State private var showCities = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    nextCard
                    prayerList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationTitle("Prayer Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Palette.leaf)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showCities) {
                CitySearchView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsScreen()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showCities = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(model.place.displayName)
                        .font(.title2.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(Palette.ink)
            }
            .accessibilityHint("Choose a city")

            Text(model.place.subtitle)
                .font(.subheadline)
                .foregroundStyle(Palette.muted)

            Text(British.gregorianDate(model.now, timeZone: model.place.timeZone))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.ink)

            Text(British.hijriDate(model.now, timeZone: model.place.timeZone))
                .font(.subheadline)
                .foregroundStyle(Palette.leafSoft)
        }
    }

    private var nextCard: some View {
        Group {
            if let next = model.next {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next prayer")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(next.name.title)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.formatted(next.time))
                        .font(.system(size: 44, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(British.countdown(until: next.time, now: model.now))
                        .font(.title3)
                        .foregroundStyle(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Palette.leaf)
                )
            }
        }
    }

    private var prayerList: some View {
        VStack(spacing: 0) {
            if let today = model.today {
                ForEach(SalahName.allCases) { name in
                    let time = today.time(for: name)
                    let isNext = model.next?.name == name
                    HStack {
                        Text(name.title)
                            .font(.title3.weight(isNext ? .semibold : .regular))
                        Spacer()
                        Text(model.formatted(time))
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(isNext ? Palette.leaf : Palette.ink)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(isNext ? Palette.highlight : Palette.card)
                    if name != .isha {
                        Divider().overlay(Color.black.opacity(0.06))
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}
