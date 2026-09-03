#!/usr/bin/env python3
"""Build the shipped worldwide city list from GeoNames (CC-BY 4.0)."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

CITIES_TXT = Path("/tmp/geonames/cities15000.txt")
COUNTRIES_TXT = Path("/tmp/geonames/countryInfo.txt")
OUT = Path(__file__).resolve().parents[1] / "PrayerGuide" / "Data" / "cities.json"

# Always keep these (name, country ISO) even if they fall below the population cut.
REQUIRED = {
    ("London", "GB"),
    ("Makkah", "SA"),
    ("Mecca", "SA"),
    ("Jakarta", "ID"),
    ("Lagos", "NG"),
    ("New York City", "US"),
    ("New York", "US"),
    ("São Paulo", "BR"),
    ("Sao Paulo", "BR"),
}

MIN_POPULATION = 50_000
KEEP_FEATURE_CODES = {"PPLC", "PPLA"}


def load_countries() -> dict[str, str]:
    names: dict[str, str] = {}
    for line in COUNTRIES_TXT.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        names[parts[0]] = parts[4]
    return names


def parse_cities() -> list[dict]:
    countries = load_countries()
    rows: list[dict] = []
    for line in CITIES_TXT.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) < 18:
            continue
        geoname_id = parts[0]
        name = parts[1]
        ascii_name = parts[2]
        lat = float(parts[4])
        lon = float(parts[5])
        feature = parts[7]
        iso = parts[8]
        admin = parts[10]
        population = int(parts[14] or 0)
        tz = parts[17]
        country = countries.get(iso, iso)
        rows.append(
            {
                "id": geoname_id,
                "name": name,
                "ascii": ascii_name,
                "country": country,
                "iso": iso,
                "admin": admin,
                "lat": round(lat, 5),
                "lon": round(lon, 5),
                "tz": tz,
                "pop": population,
                "feature": feature,
            }
        )
    return rows


def select(rows: list[dict]) -> list[dict]:
    by_country: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_country[row["iso"]].append(row)

    chosen: dict[str, dict] = {}
    for row in rows:
        keep = (
            row["feature"] in KEEP_FEATURE_CODES
            or row["pop"] >= MIN_POPULATION
            or (row["name"], row["iso"]) in REQUIRED
            or (row["ascii"], row["iso"]) in REQUIRED
        )
        if keep:
            chosen[row["id"]] = row

    # Guarantee every country in the dump has at least one city.
    for iso, group in by_country.items():
        if any(row["iso"] == iso for row in chosen.values()):
            continue
        best = max(group, key=lambda r: (r["feature"] == "PPLC", r["pop"]))
        chosen[best["id"]] = best

    selected = list(chosen.values())
    selected.sort(key=lambda r: (-r["pop"], r["name"]))
    return selected


def compact(rows: list[dict]) -> dict:
    countries = {}
    cities = []
    for row in rows:
        countries[row["iso"]] = row["country"]
        cities.append(
            [
                row["id"],
                row["name"],
                row["ascii"] if row["ascii"] != row["name"] else "",
                row["iso"],
                row["admin"],
                row["lat"],
                row["lon"],
                row["tz"],
                row["pop"],
            ]
        )
    return {
        "source": "GeoNames cities15000, CC-BY 4.0",
        "countries": countries,
        "cities": cities,
    }


def main() -> None:
    rows = select(parse_cities())
    payload = compact(rows)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    isos = {row[3] for row in payload["cities"]}
    names = {row[1] for row in payload["cities"]} | {row[2] for row in payload["cities"]}
    required_ok = all(any(n in names for n in aliases) for aliases in (
        ("London",),
        ("Makkah", "Mecca"),
        ("Jakarta",),
        ("Lagos",),
        ("New York City", "New York"),
        ("São Paulo", "Sao Paulo"),
    ))
    print(f"Wrote {len(payload['cities'])} cities across {len(isos)} countries to {OUT}")
    print(f"Required cities present: {required_ok}")
    print(f"File size: {OUT.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
