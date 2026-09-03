import SwiftUI
import WidgetKit

struct PrayerEntry: TimelineEntry {
    let date: Date
    let snapshot: PrayerSnapshot
}

enum PrayerTimeline {
    static func placeholder() -> PrayerEntry {
        PrayerEntry(date: Date(), snapshot: PrayerSnapshot.current())
    }

    static func timeline(now: Date = Date()) -> Timeline<PrayerEntry> {
        let snapshot = PrayerSnapshot.current(at: now)
        var entries = [PrayerEntry(date: now, snapshot: snapshot)]
        var dates: [Date] = []
        if let today = snapshot.today {
            dates.append(contentsOf: SalahName.allCases.map { today.time(for: $0) })
        }
        if let tomorrow = snapshot.tomorrow {
            dates.append(contentsOf: SalahName.allCases.map { tomorrow.time(for: $0) })
        }
        for stamp in dates where stamp > now {
            entries.append(
                PrayerEntry(
                    date: stamp,
                    snapshot: PrayerSnapshot.current(at: stamp)
                )
            )
        }
        let reload = snapshot.next?.time ?? now.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(reload))
    }
}

struct NextPrayerWidget: Widget {
    let kind = "MyFiveNextPrayer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerView(entry: entry)
        }
        .configurationDisplayName("Next prayer")
        .description("Name and countdown for the next prayer.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry { PrayerTimeline.placeholder() }
    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(PrayerTimeline.placeholder())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        completion(PrayerTimeline.timeline())
    }
}

struct NextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PrayerEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(inlineText)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.next?.name.title ?? "—")
                    .font(.headline)
                countdown
                    .font(.caption)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("Next")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.muted)
                    .textCase(.uppercase)
                Text(entry.snapshot.next?.name.title ?? "—")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                countdown
                    .font(.subheadline)
                    .foregroundStyle(Palette.dusk)
                Spacer(minLength: 0)
                Text(entry.snapshot.place.displayName)
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Palette.canvas }
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if let next = entry.snapshot.next, next.time > entry.date {
            Text(timerInterval: entry.date...next.time, countsDown: true)
                .monospacedDigit()
        } else {
            Text("now")
        }
    }

    private var inlineText: String {
        guard let next = entry.snapshot.next else { return AppCopy.name }
        return "\(next.name.title) · \(entry.snapshot.formatted(next.time))"
    }
}
