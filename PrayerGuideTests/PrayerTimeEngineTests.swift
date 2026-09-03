import XCTest
@testable import PrayerGuide

final class PrayerTimeEngineTests: XCTestCase {
    func testPlausibleTimesForSixCitiesOn3September2026() {
        let cases: [(String, Double, Double, String, String, String, String, String)] = [
            ("London", 51.50853, -0.12574, "Europe/London", "04:45", "13:01", "19:43", "21:13"),
            ("Makkah", 21.42664, 39.82563, "Asia/Riyadh", "04:49", "12:21", "18:35", "19:46"),
            ("Jakarta", -6.21462, 106.84513, "Asia/Jakarta", "04:43", "11:53", "17:52", "18:58"),
            ("Lagos", 6.45407, 3.39467, "Africa/Lagos", "05:29", "12:47", "18:52", "19:58"),
            ("New York", 40.71427, -74.00597, "America/New_York", "04:49", "12:56", "19:25", "20:55"),
            ("Sao Paulo", -23.5475, -46.63611, "America/Sao_Paulo", "05:00", "12:07", "17:57", "19:07"),
        ]

        for item in cases {
            let prayers = PrayerTimeEngine.times(
                latitude: item.1,
                longitude: item.2,
                year: 2026,
                month: 9,
                day: 3,
                method: .muslimWorldLeague,
                madhhab: .standard
            )
            XCTAssertNotNil(prayers, item.0)
            guard let prayers else { continue }

            let zone = TimeZone(identifier: item.3)!
            XCTAssertEqual(clock(prayers.fajr, zone), item.4, "\(item.0) Fajr")
            XCTAssertEqual(clock(prayers.dhuhr, zone), item.5, "\(item.0) Dhuhr")
            XCTAssertEqual(clock(prayers.maghrib, zone), item.6, "\(item.0) Maghrib")
            XCTAssertEqual(clock(prayers.isha, zone), item.7, "\(item.0) Isha")
            XCTAssertLessThan(prayers.fajr, prayers.dhuhr, item.0)
            XCTAssertLessThan(prayers.dhuhr, prayers.asr, item.0)
            XCTAssertLessThan(prayers.asr, prayers.maghrib, item.0)
            XCTAssertLessThan(prayers.maghrib, prayers.isha, item.0)
        }
    }

    func testHanafiAsrIsLaterThanStandard() {
        let standard = PrayerTimeEngine.times(
            latitude: 51.50853,
            longitude: -0.12574,
            year: 2026,
            month: 9,
            day: 3,
            method: .muslimWorldLeague,
            madhhab: .standard
        )
        let hanafi = PrayerTimeEngine.times(
            latitude: 51.50853,
            longitude: -0.12574,
            year: 2026,
            month: 9,
            day: 3,
            method: .muslimWorldLeague,
            madhhab: .hanafi
        )
        XCTAssertNotNil(standard)
        XCTAssertNotNil(hanafi)
        if let standard, let hanafi {
            XCTAssertGreaterThan(hanafi.asr, standard.asr)
        }
    }

    func testUmmAlQuraIshaIsNinetyMinutesAfterMaghrib() {
        let prayers = PrayerTimeEngine.times(
            latitude: 21.42664,
            longitude: 39.82563,
            year: 2026,
            month: 9,
            day: 3,
            method: .ummAlQura,
            madhhab: .standard
        )
        XCTAssertNotNil(prayers)
        if let prayers {
            XCTAssertEqual(prayers.isha.timeIntervalSince(prayers.maghrib), 90 * 60, accuracy: 60)
        }
    }

    func testNextPrayerAfterIshaIsNilForThatDay() {
        let prayers = PrayerTimeEngine.times(
            latitude: 51.50853,
            longitude: -0.12574,
            year: 2026,
            month: 9,
            day: 3,
            method: .muslimWorldLeague,
            madhhab: .standard
        )
        XCTAssertNotNil(prayers)
        if let prayers {
            let afterIsha = prayers.isha.addingTimeInterval(60)
            XCTAssertNil(prayers.nextSalah(at: afterIsha))
            XCTAssertEqual(prayers.currentSalah(at: afterIsha), .isha)
            XCTAssertEqual(prayers.nextSalah(at: prayers.fajr.addingTimeInterval(-60))?.name, .fajr)
        }
    }

    func testCurrentPrayerFollowsTheFiveWindows() {
        let prayers = PrayerTimeEngine.times(
            latitude: 51.50853,
            longitude: -0.12574,
            year: 2026,
            month: 9,
            day: 3,
            method: .muslimWorldLeague,
            madhhab: .standard
        )
        XCTAssertNotNil(prayers)
        guard let prayers else { return }

        XCTAssertNil(prayers.currentSalah(at: prayers.fajr.addingTimeInterval(-60)))
        XCTAssertEqual(prayers.currentSalah(at: prayers.fajr.addingTimeInterval(60)), .fajr)
        XCTAssertEqual(prayers.currentSalah(at: prayers.dhuhr.addingTimeInterval(60)), .dhuhr)
        XCTAssertEqual(prayers.currentSalah(at: prayers.asr.addingTimeInterval(60)), .asr)
        XCTAssertEqual(prayers.currentSalah(at: prayers.maghrib.addingTimeInterval(60)), .maghrib)
        XCTAssertEqual(prayers.currentSalah(at: prayers.isha.addingTimeInterval(60)), .isha)
    }

    private func clock(_ date: Date, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
