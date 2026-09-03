# My Five

Worldwide salah times for iPhone. Completely free. **DeskLink.ai**

This is a new, standalone App Store listing. It is **not** Umrah Guide and **not** Instructor Go. Do not copy branding, assets, or copy from those apps, and **never change Instructor Go or Umrah Guide bundle IDs**.

- **Display name:** My Five
- **Bundle ID:** `ai.desklink.prayerguide` only
- **Version:** 1.0 (build 2)
- **Devices:** iPhone, iOS 17 or later
- **Language:** English (United Kingdom)
- **Signing in this repository:** `DEVELOPMENT_TEAM` is left empty. Automatic signing.

## Archive notes (App Store Connect)

When you archive on a Mac:

1. Open `PrayerGuide.xcodeproj` and select the **PrayerGuide** scheme.
2. Signing & Capabilities → **Automatically manage signing**.
3. Team: **Desklink LTD** (`C74BFDFLFD`). Do not put that team on Instructor Go or Umrah Guide, and do not change those apps’ identifiers.
4. Product → Archive → Distribute App → App Store Connect.
5. Export compliance: the target sets `ITSAppUsesNonExemptEncryption` to `NO`.
6. Privacy Policy URL (GitHub Pages from `docs/`): `https://moilyas999.github.io/prayer-guide/privacy.html`
7. Support URL: `https://moilyas999.github.io/prayer-guide/support.html`

Linux CI cannot compile this project. Build, test, and archive only on macOS.

## What the app does

One calm home screen: city, Hijri and Gregorian dates, a large next-prayer name with countdown, then the five times in a clear list. The current prayer is highlighted. Tap the city to search. Settings sit behind a small ••• control.

Search a shipped worldwide city list (GeoNames, all countries, latitude and longitude). Times are calculated **on the device** with an Adhan-equivalent astronomical method. There is no live prayer-times API.

Optional **Use my location** (When In Use). If the user declines, the city picker still works.

Settings: calculation method (Muslim World League default, plus Egyptian, Umm al-Qura, ISNA, Karachi), Asr madhhab (standard or Hanafi), 12- or 24-hour clock, and optional local notifications at prayer time.

No Qibla, no Qur’an, no adverts, no in-app purchases, no accounts, no analytics, no tracking.

## Open in Xcode

1. Install **Xcode 15** or later.
2. Open `PrayerGuide.xcodeproj`.
3. Select the **PrayerGuide** scheme.
4. Choose an iPhone simulator or device and press Run.

```bash
xcodebuild -project PrayerGuide.xcodeproj -scheme PrayerGuide -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## App Privacy answers

Use these answers in App Store Connect. They match `PrivacyInfo.xcprivacy`.

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | **No** → **Data Not Collected** |
| Tracking | Not used |
| Location | Used on device only to calculate times. Never sent off the device. Optional. |
| Accounts, analytics, ads, crash reporters | None |
| Required Reason API | UserDefaults only, reason **CA92.1** (app settings) |

## Project layout

```
PrayerGuide.xcodeproj/    Xcode project + shared PrayerGuide scheme
PrayerGuide/              SwiftUI app (offline, no CocoaPods, no SPM)
PrayerGuideTests/         XCTest
docs/                     GitHub Pages privacy and support
scripts/                  City list, icon, and project generators
```

City list source: [GeoNames](https://www.geonames.org/) cities15000 (CC BY 4.0). Prayer times follow the Adhan / *Astronomical Algorithms* method, computed in-process.

```bash
python3 scripts/generate_cities.py   # needs a local GeoNames dump
python3 scripts/generate_app_icon.py
python3 scripts/generate_xcode_project.py
python3 scripts/prayer_times.py      # sanity-check sample cities
```
