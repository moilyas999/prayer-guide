import XCTest
@testable import PrayerGuide

final class CityCatalogTests: XCTestCase {
    func testCatalogCoversRequiredCitiesAndEveryCountry() {
        let catalog = CityCatalog(bundle: Bundle(for: LocationService.self))
        XCTAssertGreaterThan(catalog.cities.count, 1000)

        let countries = Set(catalog.cities.map(\.countryCode))
        XCTAssertGreaterThanOrEqual(countries.count, 190)

        XCTAssertNotNil(catalog.cities.first { $0.name == "London" && $0.countryCode == "GB" })
        XCTAssertNotNil(catalog.search("Makkah").first)
        XCTAssertNotNil(catalog.search("Jakarta").first { $0.countryCode == "ID" })
        XCTAssertNotNil(catalog.search("Lagos").first { $0.countryCode == "NG" })
        XCTAssertNotNil(catalog.search("New York").first { $0.countryCode == "US" })
        XCTAssertNotNil(catalog.search("Sao Paulo").first { $0.countryCode == "BR" })
    }

    func testSearchPrefersExactNameMatches() {
        let catalog = CityCatalog(bundle: Bundle(for: LocationService.self))
        let london = catalog.search("London").first
        XCTAssertEqual(london?.countryCode, "GB")
        XCTAssertEqual(london?.timeZoneIdentifier, "Europe/London")
    }
}
