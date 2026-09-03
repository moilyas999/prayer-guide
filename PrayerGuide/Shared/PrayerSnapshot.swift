import Foundation

struct PrayerSnapshot: Equatable {
    let place: Place
    let today: DailyPrayers?
    let tomorrow: DailyPrayers?
    let uses24HourClock: Bool
    let now: Date

    var next: (name: SalahName, time: Date)? {
        if let today, let upcoming = today.nextSalah(at: now) {
            return upcoming
        }
        if let tomorrow, tomorrow.fajr > now {
            return (.fajr, tomorrow.fajr)
        }
        return nil
    }

    var current: SalahName? {
        today?.currentSalah(at: now)
    }

    func formatted(_ date: Date) -> String {
        let formatter = British.clockFormat(uses24Hour: uses24HourClock)
        formatter.timeZone = place.timeZone
        return formatter.string(from: date)
    }

    func nextSentence() -> String {
        guard let next else {
            return "No upcoming prayer time is available."
        }
        return "Next is \(next.name.title) at \(formatted(next.time))."
    }

    static func current(at now: Date = Date(), defaults: UserDefaults = AppGroup.defaults) -> PrayerSnapshot {
        make(
            place: SharedPreferences.place(from: defaults),
            method: SharedPreferences.method(from: defaults),
            madhhab: SharedPreferences.madhhab(from: defaults),
            uses24HourClock: SharedPreferences.uses24HourClock(from: defaults),
            now: now
        )
    }

    static func make(
        place: Place,
        method: CalculationMethodOption,
        madhhab: AsrMadhhab,
        uses24HourClock: Bool,
        now: Date
    ) -> PrayerSnapshot {
        let today = PrayerTimeEngine.times(
            latitude: place.latitude,
            longitude: place.longitude,
            on: now,
            timeZone: place.timeZone,
            method: method,
            madhhab: madhhab
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now)
        let tomorrow = tomorrowDate.flatMap { day in
            PrayerTimeEngine.times(
                latitude: place.latitude,
                longitude: place.longitude,
                on: day,
                timeZone: place.timeZone,
                method: method,
                madhhab: madhhab
            )
        }
        return PrayerSnapshot(
            place: place,
            today: today,
            tomorrow: tomorrow,
            uses24HourClock: uses24HourClock,
            now: now
        )
    }
}
