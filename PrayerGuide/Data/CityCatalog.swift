import Foundation

struct CityCatalog {
    static let shared = CityCatalog()

    let cities: [City]

    init(bundle: Bundle = .main) {
        if let url = bundle.url(forResource: "cities", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            self.init(jsonData: data)
        } else {
            cities = []
        }
    }

    init(jsonData: Data) {
        guard
            let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let countryMap = root["countries"] as? [String: String],
            let rows = root["cities"] as? [[Any]]
        else {
            cities = []
            return
        }
        cities = rows.compactMap { row in
            guard row.count >= 9 else { return nil }
            let values = row.map { item -> String in
                if let text = item as? String { return text }
                if let number = item as? NSNumber { return number.stringValue }
                return String(describing: item)
            }
            return City(
                id: values[0],
                name: values[1],
                asciiName: values[2].isEmpty ? values[1] : values[2],
                countryCode: values[3],
                countryName: countryMap[values[3]] ?? values[3],
                adminCode: values[4],
                latitude: Double(values[5]) ?? 0,
                longitude: Double(values[6]) ?? 0,
                timeZoneIdentifier: values[7],
                population: Int(values[8]) ?? 0
            )
        }
    }

    func city(id: String) -> City? {
        cities.first { $0.id == id }
    }

    func search(_ query: String, limit: Int = 60) -> [City] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return Array(cities.prefix(limit))
        }
        let needle = trimmed.lowercased()
        let aliases = Self.aliases[needle] ?? []
        return cities
            .filter { city in
                city.searchBlob.contains(needle) || aliases.contains(where: { city.searchBlob.contains($0) })
            }
            .sorted { lhs, rhs in
                let leftExact = lhs.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                    || lhs.asciiName.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                let rightExact = rhs.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                    || rhs.asciiName.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
                if leftExact != rightExact { return leftExact }
                if lhs.population != rhs.population { return lhs.population > rhs.population }
                return lhs.name < rhs.name
            }
            .prefix(limit)
            .map { $0 }
    }

    func nearest(latitude: Double, longitude: Double) -> City? {
        cities.min { lhs, rhs in
            haversine(latitude, longitude, lhs.latitude, lhs.longitude)
                < haversine(latitude, longitude, rhs.latitude, rhs.longitude)
        }
    }

    func defaultCity() -> City? {
        city(id: Place.london.cityID ?? "")
            ?? cities.first { $0.name == "London" && $0.countryCode == "GB" }
    }

    private static let aliases: [String: [String]] = [
        "mecca": ["makkah"],
        "makkah": ["makkah", "mecca"],
        "new york": ["new york"],
        "sao paulo": ["são paulo", "sao paulo"],
        "são paulo": ["são paulo", "sao paulo"],
    ]
}

private func haversine(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
    let earth = 6_371.0
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    return earth * 2 * atan2(sqrt(a), sqrt(1 - a))
}
