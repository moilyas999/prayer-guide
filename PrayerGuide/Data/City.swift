import Foundation

struct City: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let asciiName: String
    let countryCode: String
    let countryName: String
    let adminCode: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let population: Int

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var subtitle: String {
        let admin = displayAdmin
        if admin.isEmpty {
            return countryName
        }
        return "\(admin), \(countryName)"
    }

    var searchBlob: String {
        "\(name) \(asciiName) \(countryName) \(countryCode) \(adminCode)".lowercased()
    }

    private var displayAdmin: String {
        let trimmed = adminCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.count == 2 || trimmed.count == 3, trimmed.uppercased() == trimmed {
            return ""
        }
        return trimmed
    }
}

struct Place: Equatable {
    var displayName: String
    var subtitle: String
    var latitude: Double
    var longitude: Double
    var timeZone: TimeZone
    var cityID: String?

    static let london = Place(
        displayName: "London",
        subtitle: "United Kingdom",
        latitude: 51.50853,
        longitude: -0.12574,
        timeZone: TimeZone(identifier: "Europe/London") ?? TimeZone(secondsFromGMT: 0)!,
        cityID: "2643743"
    )
}
