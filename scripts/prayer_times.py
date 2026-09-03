#!/usr/bin/env python3
"""On-device Adhan-equivalent prayer times (Astronomical Algorithms)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

DEG = math.pi / 180.0
RAD = 180.0 / math.pi


def d2r(value: float) -> float:
    return value * DEG


def r2d(value: float) -> float:
    return value * RAD


def unwind(angle: float) -> float:
    return angle - 360.0 * math.floor(angle / 360.0)


def normalize_to_scale(value: float, max_value: float) -> float:
    return value - max_value * math.floor(value / max_value)


def quadrant_shift(angle: float) -> float:
    while angle < -180:
        angle += 360
    while angle > 180:
        angle -= 360
    return angle


def julian_day(year: int, month: int, day: int, hours: float = 0.0) -> float:
    y = year if month > 2 else year - 1
    m = month if month > 2 else month + 12
    d = day + hours / 24.0
    a = math.trunc(y / 100)
    b = math.trunc(2 - a + math.trunc(a / 4))
    i0 = math.trunc(365.25 * (y + 4716))
    i1 = math.trunc(30.6001 * (m + 1))
    return i0 + i1 + d + b - 1524.5


def julian_century(jd: float) -> float:
    return (jd - 2451545.0) / 36525.0


def mean_solar_longitude(t: float) -> float:
    return unwind(280.4664567 + 36000.76983 * t + 0.0003032 * t * t)


def mean_lunar_longitude(t: float) -> float:
    return unwind(218.3165 + 481267.8813 * t)


def ascending_lunar_node(t: float) -> float:
    return unwind(125.04452 - 1934.136261 * t + 0.0020708 * t * t + (t**3) / 450000.0)


def mean_solar_anomaly(t: float) -> float:
    return unwind(357.52911 + 35999.05029 * t - 0.0001537 * t * t)


def solar_equation_of_center(t: float, mean_anomaly: float) -> float:
    m = d2r(mean_anomaly)
    return (
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m)
        + (0.019993 - 0.000101 * t) * math.sin(2 * m)
        + 0.000289 * math.sin(3 * m)
    )


def apparent_solar_longitude(t: float, mean_longitude: float) -> float:
    longitude = mean_longitude + solar_equation_of_center(t, mean_solar_anomaly(t))
    omega = 125.04 - 1934.136 * t
    return unwind(longitude - 0.00569 - 0.00478 * math.sin(d2r(omega)))


def mean_obliquity(t: float) -> float:
    return 23.439291 - 0.013004167 * t - 0.0000001639 * t * t + 0.0000005036 * t**3


def apparent_obliquity(t: float, epsilon0: float) -> float:
    return epsilon0 + 0.00256 * math.cos(d2r(125.04 - 1934.136 * t))


def mean_sidereal_time(t: float) -> float:
    jd = t * 36525 + 2451545.0
    theta = 280.46061837 + 360.98564736629 * (jd - 2451545) + 0.000387933 * t * t - (t**3) / 38710000
    return unwind(theta)


def nutation_longitude(l0: float, lp: float, omega: float) -> float:
    return (
        (-17.2 / 3600) * math.sin(d2r(omega))
        - (1.32 / 3600) * math.sin(2 * d2r(l0))
        - (0.23 / 3600) * math.sin(2 * d2r(lp))
        + (0.21 / 3600) * math.sin(2 * d2r(omega))
    )


def nutation_obliquity(l0: float, lp: float, omega: float) -> float:
    return (
        (9.2 / 3600) * math.cos(d2r(omega))
        + (0.57 / 3600) * math.cos(2 * d2r(l0))
        + (0.1 / 3600) * math.cos(2 * d2r(lp))
        - (0.09 / 3600) * math.cos(2 * d2r(omega))
    )


@dataclass
class SolarCoordinates:
    declination: float
    right_ascension: float
    apparent_sidereal_time: float

    @classmethod
    def from_jd(cls, jd: float) -> "SolarCoordinates":
        t = julian_century(jd)
        l0 = mean_solar_longitude(t)
        lp = mean_lunar_longitude(t)
        omega = ascending_lunar_node(t)
        lam = d2r(apparent_solar_longitude(t, l0))
        theta0 = mean_sidereal_time(t)
        d_psi = nutation_longitude(l0, lp, omega)
        d_eps = nutation_obliquity(l0, lp, omega)
        eps0 = mean_obliquity(t)
        eps_app = d2r(apparent_obliquity(t, eps0))
        declination = r2d(math.asin(math.sin(eps_app) * math.sin(lam)))
        ra = unwind(r2d(math.atan2(math.cos(eps_app) * math.sin(lam), math.cos(lam))))
        apparent_sidereal = theta0 + d_psi * math.cos(d2r(eps0 + d_eps))
        return cls(declination, ra, apparent_sidereal)


def interpolate(y2: float, y1: float, y3: float, n: float) -> float:
    a = y2 - y1
    b = y3 - y2
    c = b - a
    return y2 + n / 2 * (a + b + n * c)


def interpolate_angles(y2: float, y1: float, y3: float, n: float) -> float:
    a = unwind(y2 - y1)
    b = unwind(y3 - y2)
    c = b - a
    return y2 + n / 2 * (a + b + n * c)


def altitude(lat: float, declination: float, hour_angle: float) -> float:
    return r2d(
        math.asin(
            math.sin(d2r(lat)) * math.sin(d2r(declination))
            + math.cos(d2r(lat)) * math.cos(d2r(declination)) * math.cos(d2r(hour_angle))
        )
    )


def approximate_transit(longitude: float, sidereal: float, ra: float) -> float:
    return normalize_to_scale((ra + (-longitude) - sidereal) / 360.0, 1)


def corrected_transit(m0: float, longitude: float, sidereal: float, ra: float, prev_ra: float, next_ra: float) -> float:
    theta = unwind(sidereal + 360.985647 * m0)
    a = unwind(interpolate_angles(ra, prev_ra, next_ra, m0))
    h = quadrant_shift(theta - (-longitude) - a)
    return (m0 + h / -360.0) * 24


def corrected_hour_angle(
    m0: float,
    angle: float,
    lat: float,
    lon: float,
    after: bool,
    sidereal: float,
    ra: float,
    prev_ra: float,
    next_ra: float,
    dec: float,
    prev_dec: float,
    next_dec: float,
) -> float:
    term1 = math.sin(d2r(angle)) - math.sin(d2r(lat)) * math.sin(d2r(dec))
    term2 = math.cos(d2r(lat)) * math.cos(d2r(dec))
    ratio = term1 / term2
    if abs(ratio) > 1:
        return float("nan")
    h0 = r2d(math.acos(ratio))
    m = m0 + h0 / 360.0 if after else m0 - h0 / 360.0
    theta = unwind(sidereal + 360.985647 * m)
    a = unwind(interpolate_angles(ra, prev_ra, next_ra, m))
    delta = interpolate(dec, prev_dec, next_dec, m)
    h = theta - (-lon) - a
    alt = altitude(lat, delta, h)
    term3 = alt - angle
    term4 = 360 * math.cos(d2r(delta)) * math.cos(d2r(lat)) * math.sin(d2r(h))
    if term4 == 0:
        return float("nan")
    return (m + term3 / term4) * 24


@dataclass
class SolarTime:
    observer_lat: float
    observer_lon: float
    solar: SolarCoordinates
    prev: SolarCoordinates
    nxt: SolarCoordinates
    approx: float
    transit: float
    sunrise: float
    sunset: float

    @classmethod
    def create(cls, year: int, month: int, day: int, lat: float, lon: float) -> "SolarTime":
        jd = julian_day(year, month, day)
        solar = SolarCoordinates.from_jd(jd)
        prev = SolarCoordinates.from_jd(jd - 1)
        nxt = SolarCoordinates.from_jd(jd + 1)
        m0 = approximate_transit(lon, solar.apparent_sidereal_time, solar.right_ascension)
        altitude_deg = -50.0 / 60.0
        transit = corrected_transit(
            m0, lon, solar.apparent_sidereal_time, solar.right_ascension, prev.right_ascension, nxt.right_ascension
        )
        sunrise = corrected_hour_angle(
            m0, altitude_deg, lat, lon, False, solar.apparent_sidereal_time,
            solar.right_ascension, prev.right_ascension, nxt.right_ascension,
            solar.declination, prev.declination, nxt.declination,
        )
        sunset = corrected_hour_angle(
            m0, altitude_deg, lat, lon, True, solar.apparent_sidereal_time,
            solar.right_ascension, prev.right_ascension, nxt.right_ascension,
            solar.declination, prev.declination, nxt.declination,
        )
        return cls(lat, lon, solar, prev, nxt, m0, transit, sunrise, sunset)

    def hour_angle(self, angle: float, after: bool) -> float:
        return corrected_hour_angle(
            self.approx, angle, self.observer_lat, self.observer_lon, after,
            self.solar.apparent_sidereal_time, self.solar.right_ascension,
            self.prev.right_ascension, self.nxt.right_ascension,
            self.solar.declination, self.prev.declination, self.nxt.declination,
        )

    def afternoon(self, shadow_length: float) -> float:
        tangent = abs(self.observer_lat - self.solar.declination)
        inverse = shadow_length + math.tan(d2r(tangent))
        angle = r2d(math.atan(1.0 / inverse))
        return self.hour_angle(angle, True)


METHODS = {
    "mwl": {"fajr": 18.0, "isha": 17.0, "isha_interval": 0, "dhuhr_adj": 1},
    "egypt": {"fajr": 19.5, "isha": 17.5, "isha_interval": 0, "dhuhr_adj": 1},
    "ummAlQura": {"fajr": 18.5, "isha": 0.0, "isha_interval": 90, "dhuhr_adj": 0},
    "isna": {"fajr": 15.0, "isha": 15.0, "isha_interval": 0, "dhuhr_adj": 1},
    "karachi": {"fajr": 18.0, "isha": 18.0, "isha_interval": 0, "dhuhr_adj": 1},
}


def hours_to_utc(year: int, month: int, day: int, hours: float) -> datetime | None:
    if hours != hours:
        return None
    base = datetime(year, month, day, tzinfo=timezone.utc)
    return base + timedelta(hours=hours)


def round_minute(moment: datetime) -> datetime:
    extra = 1 if moment.second >= 30 else 0
    return moment.replace(second=0, microsecond=0) + timedelta(minutes=extra)


def calculate(
    lat: float,
    lon: float,
    year: int,
    month: int,
    day: int,
    method: str = "mwl",
    hanafi: bool = False,
    tz_name: str = "UTC",
) -> dict[str, str]:
    params = METHODS[method]
    today = SolarTime.create(year, month, day, lat, lon)
    tomorrow = SolarTime.create(*(datetime(year, month, day) + timedelta(days=1)).timetuple()[:3], lat, lon)

    dhuhr = hours_to_utc(year, month, day, today.transit)
    sunrise = hours_to_utc(year, month, day, today.sunrise)
    sunset = hours_to_utc(year, month, day, today.sunset)
    asr = hours_to_utc(year, month, day, today.afternoon(2 if hanafi else 1))
    fajr = hours_to_utc(year, month, day, today.hour_angle(-params["fajr"], False))

    next_day = datetime(year, month, day) + timedelta(days=1)
    tomorrow_sunrise = hours_to_utc(next_day.year, next_day.month, next_day.day, tomorrow.sunrise)
    night = (tomorrow_sunrise - sunset).total_seconds() if tomorrow_sunrise and sunset else 0

    high_lat = 1 / 7 if lat > 48 else 0.5
    safe_fajr = sunrise - timedelta(seconds=high_lat * night) if sunrise else None
    if fajr is None or (safe_fajr and safe_fajr > fajr):
        fajr = safe_fajr

    if params["isha_interval"]:
        isha = sunset + timedelta(minutes=params["isha_interval"]) if sunset else None
    else:
        isha = hours_to_utc(year, month, day, today.hour_angle(-params["isha"], True))
        safe_isha = sunset + timedelta(seconds=high_lat * night) if sunset else None
        if isha is None or (safe_isha and safe_isha < isha):
            isha = safe_isha

    maghrib = sunset
    dhuhr = dhuhr + timedelta(minutes=params["dhuhr_adj"]) if dhuhr else None

    zone = ZoneInfo(tz_name)
    names = {
        "fajr": fajr,
        "sunrise": sunrise,
        "dhuhr": dhuhr,
        "asr": asr,
        "maghrib": maghrib,
        "isha": isha,
    }
    out = {}
    for key, value in names.items():
        if value is None:
            out[key] = "—"
            continue
        local = round_minute(value).astimezone(zone)
        out[key] = local.strftime("%H:%M")
    return out


CITIES = {
    "London": (51.50853, -0.12574, "Europe/London"),
    "Makkah": (21.42664, 39.82563, "Asia/Riyadh"),
    "Jakarta": (-6.21462, 106.84513, "Asia/Jakarta"),
    "Lagos": (6.45407, 3.39467, "Africa/Lagos"),
    "New York": (40.71427, -74.00597, "America/New_York"),
    "Sao Paulo": (-23.5475, -46.63611, "America/Sao_Paulo"),
}


def main() -> None:
    date = datetime(2026, 9, 3)
    print(f"MWL standard, {date.date()}")
    for name, (lat, lon, tz) in CITIES.items():
        times = calculate(lat, lon, date.year, date.month, date.day, tz_name=tz)
        print(f"{name:12} Fajr {times['fajr']}  Dhuhr {times['dhuhr']}  Asr {times['asr']}  Maghrib {times['maghrib']}  Isha {times['isha']}")


if __name__ == "__main__":
    main()
