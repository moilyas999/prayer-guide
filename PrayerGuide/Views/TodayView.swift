import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: TodayModel
    @State private var showCities = false
    @State private var showSettings = false
    @ScaledMetric(relativeTo: .title2) private var rowMinHeight: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                    dates
                    nextPrayer
                    prayerList
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCities) {
                CitySearchView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsScreen()
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                showCities = true
            } label: {
                HStack(spacing: 10) {
                    Text(model.place.displayName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 8)
                    Text("Change city")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.dusk)
                        .lineLimit(1)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(minHeight: 56)
                .background(Palette.cityFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(model.place.displayName)
            .accessibilityHint("Change city")

            Button {
                showSettings = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Palette.muted)
                    .frame(width: 44, height: 56)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var dates: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(British.hijriDate(model.now, timeZone: model.place.timeZone))
                .font(.body.weight(.medium))
                .foregroundStyle(Palette.ink)
            Text(British.gregorianDate(model.now, timeZone: model.place.timeZone))
                .font(.body)
                .foregroundStyle(Palette.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private var nextPrayer: some View {
        Group {
            if let next = model.next {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Next")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.muted)
                        .textCase(.uppercase)
                        .tracking(1.1)
                    Text(next.name.title)
                        .font(.system(size: 48, weight: .medium, design: .serif))
                        .foregroundStyle(Palette.ink)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(British.countdown(until: next.time, now: model.now))
                        .font(.title2)
                        .foregroundStyle(Palette.dusk)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Next \(next.name.title), \(British.countdown(until: next.time, now: model.now))")
            }
        }
    }

    private var prayerList: some View {
        VStack(spacing: 0) {
            if let today = model.today {
                ForEach(SalahName.allCases) { name in
                    let time = today.time(for: name)
                    let isCurrent = model.current == name
                    let isPast = isPastPrayer(name)
                    prayerRow(name: name, time: time, isCurrent: isCurrent, isPast: isPast)
                    if name != .isha {
                        Rectangle()
                            .fill(Palette.hairline)
                            .frame(height: 1)
                    }
                }
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(width: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func prayerRow(name: SalahName, time: Date, isCurrent: Bool, isPast: Bool) -> some View {
        HStack(alignment: .center, spacing: 16) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(isCurrent ? Palette.dusk : Color.clear)
                .frame(width: 3, height: 28)
            Text(name.title)
                .font(.system(size: 24, weight: isCurrent ? .semibold : .regular, design: .serif))
            Spacer(minLength: 12)
            Text(model.formatted(time))
                .font(.system(size: 24, weight: isCurrent ? .semibold : .regular, design: .default))
                .monospacedDigit()
        }
        .foregroundStyle(rowInk(isCurrent: isCurrent, isPast: isPast))
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, minHeight: rowMinHeight, alignment: .leading)
        .padding(.vertical, 4)
        .background(isCurrent ? Palette.highlight : Color.clear)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(name: name, time: time, isCurrent: isCurrent))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func rowInk(isCurrent: Bool, isPast: Bool) -> Color {
        if isCurrent { return Palette.dusk }
        if isPast { return Palette.muted.opacity(0.7) }
        return Palette.ink
    }

    private func isPastPrayer(_ name: SalahName) -> Bool {
        guard let current = model.current,
              let currentIndex = SalahName.allCases.firstIndex(of: current),
              let nameIndex = SalahName.allCases.firstIndex(of: name)
        else { return false }
        return nameIndex < currentIndex
    }

    private func accessibilityLabel(name: SalahName, time: Date, isCurrent: Bool) -> String {
        let clock = model.formatted(time)
        if isCurrent {
            return "\(name.title), current, \(clock)"
        }
        return "\(name.title), \(clock)"
    }
}
