import XCTest
@testable import PrayerGuide

final class PrayerAlertPlanTests: XCTestCase {
    func testLeadTimeMovesFireDateEarlier() {
        let now = london(2026, 9, 3, hour: 0, minute: 1)
        let events = PrayerAlertPlan.weekEvents(
            from: now,
            place: .london,
            method: .muslimWorldLeague,
            madhhab: .standard,
            enabled: [.dhuhr],
            lead: .fifteenMinutes
        )
        XCTAssertFalse(events.isEmpty)
        if let event = events.first(where: { $0.name == .dhuhr }) {
            XCTAssertEqual(event.prayerTime.timeIntervalSince(event.fireDate), 15 * 60, accuracy: 1)
            XCTAssertTrue(event.identifier.hasPrefix(PrayerAlertPlan.weekPrefix))
            XCTAssertTrue(event.identifier.contains("dhuhr"))
        }
    }

    func testPastPrayersOnTheFirstDayAreOmitted() {
        let now = london(2026, 9, 3, hour: 16, minute: 0)
        let events = PrayerAlertPlan.weekEvents(
            from: now,
            place: .london,
            method: .muslimWorldLeague,
            madhhab: .standard,
            enabled: Set(SalahName.allCases),
            lead: .atTime
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Place.london.timeZone
        let todayEvents = events.filter { calendar.isDate($0.prayerTime, inSameDayAs: now) }
        XCTAssertFalse(todayEvents.contains { $0.name == .fajr || $0.name == .dhuhr || $0.name == .asr })
        XCTAssertTrue(todayEvents.contains { $0.name == .maghrib })
        XCTAssertTrue(todayEvents.contains { $0.name == .isha })
        XCTAssertEqual(events.filter { $0.name == .fajr }.count, 6)
        XCTAssertLessThanOrEqual(events.count, SalahName.allCases.count * PrayerAlertPlan.scheduledDays)
    }

    func testDisabledPrayerIsNotScheduled() {
        let now = london(2026, 9, 3, hour: 0, minute: 1)
        let events = PrayerAlertPlan.weekEvents(
            from: now,
            place: .london,
            method: .muslimWorldLeague,
            madhhab: .standard,
            enabled: [.fajr, .isha],
            lead: .atTime
        )
        XCTAssertTrue(events.allSatisfy { $0.name == .fajr || $0.name == .isha })
        XCTAssertFalse(events.contains { $0.name == .dhuhr })
    }

    func testSnapshotNamesTheNextPrayer() {
        let now = london(2026, 9, 3, hour: 12, minute: 0)
        let snapshot = PrayerSnapshot.make(
            place: .london,
            method: .muslimWorldLeague,
            madhhab: .standard,
            uses24HourClock: true,
            now: now
        )
        XCTAssertEqual(snapshot.next?.name, .dhuhr)
        XCTAssertEqual(snapshot.current, .fajr)
        XCTAssertTrue(snapshot.nextSentence().contains("Dhuhr"))
        XCTAssertTrue(snapshot.nextSentence().contains("13:01"))
    }

    func testAlertBodyIsHonest() {
        let event = PrayerAlertEvent(
            name: .fajr,
            prayerTime: Date(),
            fireDate: Date(),
            identifier: "test",
            lead: .fiveMinutes
        )
        XCTAssertEqual(PrayerAlertPlan.body(for: event), "Fajr in 5 minutes.")
        let atTime = PrayerAlertEvent(
            name: .isha,
            prayerTime: Date(),
            fireDate: Date(),
            identifier: "test",
            lead: .atTime
        )
        XCTAssertEqual(PrayerAlertPlan.body(for: atTime), "It is time for Isha.")
    }

    private func london(_ year: Int, _ month: Int, _ day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Place.london.timeZone
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        return calendar.date(from: parts)!
    }
}
