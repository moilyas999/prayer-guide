import Foundation

enum CalculationMethodOption: String, CaseIterable, Identifiable {
    case muslimWorldLeague
    case egyptian
    case ummAlQura
    case isna
    case karachi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority"
        case .ummAlQura: return "Umm al-Qura"
        case .isna: return "ISNA"
        case .karachi: return "University of Karachi"
        }
    }

    var detail: String {
        switch self {
        case .muslimWorldLeague: return "Fajr 18°, Isha 17°. Used widely outside a national board."
        case .egyptian: return "Fajr 19.5°, Isha 17.5°."
        case .ummAlQura: return "Fajr 18.5°, Isha 90 minutes after Maghrib."
        case .isna: return "Islamic Society of North America. Fajr and Isha 15°."
        case .karachi: return "University of Islamic Sciences, Karachi. Fajr and Isha 18°."
        }
    }

    var fajrAngle: Double {
        switch self {
        case .muslimWorldLeague: return 18
        case .egyptian: return 19.5
        case .ummAlQura: return 18.5
        case .isna: return 15
        case .karachi: return 18
        }
    }

    var ishaAngle: Double {
        switch self {
        case .muslimWorldLeague: return 17
        case .egyptian: return 17.5
        case .ummAlQura: return 0
        case .isna: return 15
        case .karachi: return 18
        }
    }

    var ishaIntervalMinutes: Int {
        self == .ummAlQura ? 90 : 0
    }

    var dhuhrAdjustmentMinutes: Int {
        switch self {
        case .ummAlQura: return 0
        default: return 1
        }
    }
}

enum AsrMadhhab: String, CaseIterable, Identifiable {
    case standard
    case hanafi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .hanafi: return "Hanafi"
        }
    }

    var detail: String {
        switch self {
        case .standard: return "Earlier Asr (Shafi‘i, Maliki, Hanbali)."
        case .hanafi: return "Later Asr, when the shadow is twice the object plus its noon shadow."
        }
    }

    var shadowLength: Double {
        self == .hanafi ? 2 : 1
    }
}

enum SalahName: String, CaseIterable, Identifiable {
    case fajr, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}

struct DailyPrayers: Equatable {
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date

    func time(for salah: SalahName) -> Date {
        switch salah {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }

    func nextSalah(at now: Date) -> (name: SalahName, time: Date)? {
        for name in SalahName.allCases {
            let when = time(for: name)
            if when > now {
                return (name, when)
            }
        }
        return nil
    }

    func currentSalah(at now: Date) -> SalahName? {
        if now >= isha { return .isha }
        if now >= maghrib { return .maghrib }
        if now >= asr { return .asr }
        if now >= dhuhr { return .dhuhr }
        if now >= fajr { return .fajr }
        return nil
    }
}

enum PrayerTimeEngine {
    static func times(
        latitude: Double,
        longitude: Double,
        on date: Date,
        timeZone: TimeZone,
        method: CalculationMethodOption,
        madhhab: AsrMadhhab
    ) -> DailyPrayers? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        return times(
            latitude: latitude,
            longitude: longitude,
            year: year,
            month: month,
            day: day,
            method: method,
            madhhab: madhhab
        )
    }

    static func times(
        latitude: Double,
        longitude: Double,
        year: Int,
        month: Int,
        day: Int,
        method: CalculationMethodOption,
        madhhab: AsrMadhhab
    ) -> DailyPrayers? {
        guard let today = SolarTime(year: year, month: month, day: day, latitude: latitude, longitude: longitude) else {
            return nil
        }
        let next = nextGregorianDay(year: year, month: month, day: day)
        guard let tomorrow = SolarTime(year: next.year, month: next.month, day: next.day, latitude: latitude, longitude: longitude) else {
            return nil
        }

        guard
            var dhuhr = utcDate(year: year, month: month, day: day, hours: today.transit),
            let sunrise = utcDate(year: year, month: month, day: day, hours: today.sunrise),
            let sunset = utcDate(year: year, month: month, day: day, hours: today.sunset),
            let asr = utcDate(year: year, month: month, day: day, hours: today.afternoon(shadowLength: madhhab.shadowLength)),
            let tomorrowSunrise = utcDate(year: next.year, month: next.month, day: next.day, hours: tomorrow.sunrise)
        else {
            return nil
        }

        let night = tomorrowSunrise.timeIntervalSince(sunset)
        let nightPortion = latitude > 48 ? (1.0 / 7.0) : 0.5

        var fajr = utcDate(year: year, month: month, day: day, hours: today.hourAngle(-method.fajrAngle, afterTransit: false))
        let safeFajr = sunrise.addingTimeInterval(-nightPortion * night)
        if fajr == nil || safeFajr > fajr! {
            fajr = safeFajr
        }

        var isha: Date?
        if method.ishaIntervalMinutes > 0 {
            isha = sunset.addingTimeInterval(Double(method.ishaIntervalMinutes) * 60)
        } else {
            isha = utcDate(year: year, month: month, day: day, hours: today.hourAngle(-method.ishaAngle, afterTransit: true))
            let safeIsha = sunset.addingTimeInterval(nightPortion * night)
            if isha == nil || safeIsha < isha! {
                isha = safeIsha
            }
        }

        dhuhr = dhuhr.addingTimeInterval(Double(method.dhuhrAdjustmentMinutes) * 60)

        guard let fajr, let isha else { return nil }

        return DailyPrayers(
            fajr: roundedMinute(fajr),
            sunrise: roundedMinute(sunrise),
            dhuhr: roundedMinute(dhuhr),
            asr: roundedMinute(asr),
            maghrib: roundedMinute(sunset),
            isha: roundedMinute(isha)
        )
    }
}

// MARK: - Astronomy (Adhan / Astronomical Algorithms)

private struct SolarCoordinates {
    let declination: Double
    let rightAscension: Double
    let apparentSiderealTime: Double

    init(julianDay jd: Double) {
        let t = (jd - 2_451_545.0) / 36_525.0
        let l0 = unwind(280.4664567 + 36_000.76983 * t + 0.0003032 * t * t)
        let lp = unwind(218.3165 + 481_267.8813 * t)
        let omega = unwind(125.04452 - 1_934.136261 * t + 0.0020708 * t * t + pow(t, 3) / 450_000)
        let lambda = d2r(apparentSolarLongitude(t: t, meanLongitude: l0))
        let theta0 = meanSiderealTime(t)
        let dPsi = nutationLongitude(l0: l0, lp: lp, omega: omega)
        let dEps = nutationObliquity(l0: l0, lp: lp, omega: omega)
        let eps0 = 23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * pow(t, 3)
        let epsApp = d2r(eps0 + 0.00256 * cos(d2r(125.04 - 1_934.136 * t)))

        declination = r2d(asin(sin(epsApp) * sin(lambda)))
        rightAscension = unwind(r2d(atan2(cos(epsApp) * sin(lambda), cos(lambda))))
        apparentSiderealTime = theta0 + dPsi * cos(d2r(eps0 + dEps))
    }
}

private struct SolarTime {
    let latitude: Double
    let longitude: Double
    let solar: SolarCoordinates
    let previous: SolarCoordinates
    let next: SolarCoordinates
    let approxTransit: Double
    let transit: Double
    let sunrise: Double
    let sunset: Double

    init?(year: Int, month: Int, day: Int, latitude: Double, longitude: Double) {
        let jd = julianDay(year: year, month: month, day: day)
        let solar = SolarCoordinates(julianDay: jd)
        let previous = SolarCoordinates(julianDay: jd - 1)
        let next = SolarCoordinates(julianDay: jd + 1)
        let m0 = approximateTransit(longitude: longitude, sidereal: solar.apparentSiderealTime, rightAscension: solar.rightAscension)
        let altitude = -50.0 / 60.0
        let transit = correctedTransit(
            m0: m0,
            longitude: longitude,
            sidereal: solar.apparentSiderealTime,
            rightAscension: solar.rightAscension,
            previousRA: previous.rightAscension,
            nextRA: next.rightAscension
        )
        let sunrise = correctedHourAngle(
            m0: m0,
            angle: altitude,
            latitude: latitude,
            longitude: longitude,
            afterTransit: false,
            sidereal: solar.apparentSiderealTime,
            rightAscension: solar.rightAscension,
            previousRA: previous.rightAscension,
            nextRA: next.rightAscension,
            declination: solar.declination,
            previousDeclination: previous.declination,
            nextDeclination: next.declination
        )
        let sunset = correctedHourAngle(
            m0: m0,
            angle: altitude,
            latitude: latitude,
            longitude: longitude,
            afterTransit: true,
            sidereal: solar.apparentSiderealTime,
            rightAscension: solar.rightAscension,
            previousRA: previous.rightAscension,
            nextRA: next.rightAscension,
            declination: solar.declination,
            previousDeclination: previous.declination,
            nextDeclination: next.declination
        )
        guard transit.isFinite, sunrise.isFinite, sunset.isFinite else { return nil }
        self.latitude = latitude
        self.longitude = longitude
        self.solar = solar
        self.previous = previous
        self.next = next
        self.approxTransit = m0
        self.transit = transit
        self.sunrise = sunrise
        self.sunset = sunset
    }

    func hourAngle(_ angle: Double, afterTransit: Bool) -> Double {
        correctedHourAngle(
            m0: approxTransit,
            angle: angle,
            latitude: latitude,
            longitude: longitude,
            afterTransit: afterTransit,
            sidereal: solar.apparentSiderealTime,
            rightAscension: solar.rightAscension,
            previousRA: previous.rightAscension,
            nextRA: next.rightAscension,
            declination: solar.declination,
            previousDeclination: previous.declination,
            nextDeclination: next.declination
        )
    }

    func afternoon(shadowLength: Double) -> Double {
        let tangent = abs(latitude - solar.declination)
        let inverse = shadowLength + tan(d2r(tangent))
        let angle = r2d(atan(1.0 / inverse))
        return hourAngle(angle, afterTransit: true)
    }
}

private func d2r(_ value: Double) -> Double { value * .pi / 180 }
private func r2d(_ value: Double) -> Double { value * 180 / .pi }

private func unwind(_ angle: Double) -> Double {
    angle - 360 * floor(angle / 360)
}

private func normalizeToScale(_ value: Double, max: Double) -> Double {
    value - max * floor(value / max)
}

private func quadrantShift(_ angle: Double) -> Double {
    var value = angle
    while value < -180 { value += 360 }
    while value > 180 { value -= 360 }
    return value
}

private func julianDay(year: Int, month: Int, day: Int, hours: Double = 0) -> Double {
    let y = month > 2 ? year : year - 1
    let m = month > 2 ? month : month + 12
    let d = Double(day) + hours / 24
    let a = Int(Double(y) / 100)
    let b = Int(2 - a + a / 4)
    let i0 = Int(365.25 * Double(y + 4716))
    let i1 = Int(30.6001 * Double(m + 1))
    return Double(i0 + i1) + d + Double(b) - 1524.5
}

private func apparentSolarLongitude(t: Double, meanLongitude: Double) -> Double {
    let m = unwind(357.52911 + 35_999.05029 * t - 0.0001537 * t * t)
    let mRad = d2r(m)
    let center =
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(mRad)
        + (0.019993 - 0.000101 * t) * sin(2 * mRad)
        + 0.000289 * sin(3 * mRad)
    let longitude = meanLongitude + center
    let omega = 125.04 - 1_934.136 * t
    return unwind(longitude - 0.00569 - 0.00478 * sin(d2r(omega)))
}

private func meanSiderealTime(_ t: Double) -> Double {
    let jd = t * 36_525 + 2_451_545.0
    let theta = 280.46061837 + 360.98564736629 * (jd - 2_451_545) + 0.000387933 * t * t - pow(t, 3) / 38_710_000
    return unwind(theta)
}

private func nutationLongitude(l0: Double, lp: Double, omega: Double) -> Double {
    (-17.2 / 3600) * sin(d2r(omega))
        - (1.32 / 3600) * sin(2 * d2r(l0))
        - (0.23 / 3600) * sin(2 * d2r(lp))
        + (0.21 / 3600) * sin(2 * d2r(omega))
}

private func nutationObliquity(l0: Double, lp: Double, omega: Double) -> Double {
    (9.2 / 3600) * cos(d2r(omega))
        + (0.57 / 3600) * cos(2 * d2r(l0))
        + (0.1 / 3600) * cos(2 * d2r(lp))
        - (0.09 / 3600) * cos(2 * d2r(omega))
}

private func interpolate(_ y2: Double, _ y1: Double, _ y3: Double, _ n: Double) -> Double {
    let a = y2 - y1
    let b = y3 - y2
    let c = b - a
    return y2 + n / 2 * (a + b + n * c)
}

private func interpolateAngles(_ y2: Double, _ y1: Double, _ y3: Double, _ n: Double) -> Double {
    let a = unwind(y2 - y1)
    let b = unwind(y3 - y2)
    let c = b - a
    return y2 + n / 2 * (a + b + n * c)
}

private func altitude(latitude: Double, declination: Double, hourAngle: Double) -> Double {
    r2d(
        asin(
            sin(d2r(latitude)) * sin(d2r(declination))
                + cos(d2r(latitude)) * cos(d2r(declination)) * cos(d2r(hourAngle))
        )
    )
}

private func approximateTransit(longitude: Double, sidereal: Double, rightAscension: Double) -> Double {
    normalizeToScale((rightAscension + (-longitude) - sidereal) / 360, max: 1)
}

private func correctedTransit(
    m0: Double,
    longitude: Double,
    sidereal: Double,
    rightAscension: Double,
    previousRA: Double,
    nextRA: Double
) -> Double {
    let theta = unwind(sidereal + 360.985647 * m0)
    let a = unwind(interpolateAngles(rightAscension, previousRA, nextRA, m0))
    let h = quadrantShift(theta - (-longitude) - a)
    return (m0 + h / -360) * 24
}

private func correctedHourAngle(
    m0: Double,
    angle: Double,
    latitude: Double,
    longitude: Double,
    afterTransit: Bool,
    sidereal: Double,
    rightAscension: Double,
    previousRA: Double,
    nextRA: Double,
    declination: Double,
    previousDeclination: Double,
    nextDeclination: Double
) -> Double {
    let term1 = sin(d2r(angle)) - sin(d2r(latitude)) * sin(d2r(declination))
    let term2 = cos(d2r(latitude)) * cos(d2r(declination))
    let ratio = term1 / term2
    guard abs(ratio) <= 1 else { return .nan }
    let h0 = r2d(acos(ratio))
    let m = afterTransit ? m0 + h0 / 360 : m0 - h0 / 360
    let theta = unwind(sidereal + 360.985647 * m)
    let a = unwind(interpolateAngles(rightAscension, previousRA, nextRA, m))
    let delta = interpolate(declination, previousDeclination, nextDeclination, m)
    let h = theta - (-longitude) - a
    let alt = altitude(latitude: latitude, declination: delta, hourAngle: h)
    let term3 = alt - angle
    let term4 = 360 * cos(d2r(delta)) * cos(d2r(latitude)) * sin(d2r(h))
    guard term4 != 0 else { return .nan }
    return (m + term3 / term4) * 24
}

private func utcDate(year: Int, month: Int, day: Int, hours: Double) -> Date? {
    guard hours.isFinite else { return nil }
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = year
    components.month = month
    components.day = day
    components.hour = 0
    components.minute = 0
    components.second = 0
    guard let base = components.date else { return nil }
    return base.addingTimeInterval(hours * 3600)
}

private func roundedMinute(_ date: Date) -> Date {
    let seconds = date.timeIntervalSince1970
    let whole = floor(seconds)
    let extra = (whole.truncatingRemainder(dividingBy: 60)) >= 30 ? 60.0 : 0
    let floored = floor(seconds / 60) * 60
    return Date(timeIntervalSince1970: floored + extra)
}

private func nextGregorianDay(year: Int, month: Int, day: Int) -> (year: Int, month: Int, day: Int) {
    var components = DateComponents()
    components.calendar = Calendar(identifier: .gregorian)
    components.timeZone = TimeZone(secondsFromGMT: 0)
    components.year = year
    components.month = month
    components.day = day
    let next = components.date!.addingTimeInterval(86_400)
    let parts = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: next)
    return (parts.year!, parts.month!, parts.day!)
}
