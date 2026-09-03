import SwiftUI
import WidgetKit

struct TodayPrayersWidget: Widget {
    let kind = "MyFiveToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayPrayersProvider()) { entry in
            TodayPrayersView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("The five prayer times for today.")
        .supportedFamilies([.systemMedium])
    }
}

struct TodayPrayersProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry { PrayerTimeline.placeholder() }
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(PrayerTimeline.placeholder())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        completion(PrayerTimeline.timeline())
    }
}

struct TodayPrayersView: View {
    let entry: PrayerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.snapshot.place.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Spacer()
                Text(British.shortGregorian(entry.snapshot.now, timeZone: entry.snapshot.place.timeZone))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            if let today = entry.snapshot.today {
                ForEach(SalahName.allCases) { name in
                    let isCurrent = entry.snapshot.current == name
                    HStack {
                        Text(name.title)
                            .font(.system(size: 16, weight: isCurrent ? .semibold : .regular, design: .serif))
                        Spacer()
                        Text(entry.snapshot.formatted(today.time(for: name)))
                            .font(.system(size: 16, weight: isCurrent ? .semibold : .regular))
                            .monospacedDigit()
                    }
                    .foregroundStyle(isCurrent ? Palette.dusk : Palette.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(isCurrent ? Palette.highlight : Color.clear)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { Palette.canvas }
    }
}
